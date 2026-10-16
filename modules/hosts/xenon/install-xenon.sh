#!/usr/bin/env bash
set -euo pipefail

host=xenon
users=(alice root)
main_user=alice
main_uid=1000
main_gid=100
repo=${REPO_URL:-https://github.com/ma4700/nixos-config}
branch=${BRANCH:-main}
work=/tmp/dots
persist=/mnt/persist
luks_name=cryptroot # has to match disko.nix
boot_part=/dev/disk/by-partlabel/xenon-boot # partition names have to match disko.nix
crypt_part=/dev/disk/by-partlabel/xenon-crypt
min_free_gib=40
scan=/tmp/xenon-hardware-scan.nix

export NIX_CONFIG="experimental-features = nix-command flakes"

say() { printf '\n>> %s\n' "$*"; }
note() { printf '   %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
ask() { local a; read -rp "   $1 [y/N] " a; [[ $a == [yY]* ]]; }
trap 'printf "failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

if [[ $EUID -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi
export HOME=/root # sudo -E keeps /home/nixos, which makes nix warn

say "checking that we booted in UEFI mode"
[[ -d /sys/firmware/efi ]] || die "not in UEFI mode, reboot and pick the UEFI entry for the usb stick (F12)"

say "checking the network"
online=false
for i in 1 2 3 4 5 6; do
  if curl -fsS --max-time 5 -o /dev/null https://github.com 2>/dev/null; then
    online=true
    break
  fi
  note "github.com not reachable yet ($i/6), retrying in 5s"
  sleep 5
done
$online || die "no internet. plug in ethernet or run: nmcli device wifi connect <SSID> --ask"
iface=$(ip -o route get 1.1.1.1 2>/dev/null | sed -n 's/.* dev \([^ ]*\).*/\1/p' | head -n1)
note "online${iface:+ via $iface}"

say "cloning $repo ($branch) to $work"
rm -rf "$work"
git clone --branch "$branch" "$repo" "$work"
cd "$work"
note "at $(git rev-parse --short HEAD): $(git log -1 --format=%s)"
flake="$work#$host"

say "checking the config against this machine (downloads flake inputs, takes a minute)"
# shellcheck disable=SC2016 # ${...} is nix, not bash
cfg=$(nix eval --raw "$work#nixosConfigurations.$host.config" --apply \
  'c: "${c.hardware.nvidia.prime.intelBusId} ${c.hardware.nvidia.prime.nvidiaBusId} ${toString c.boot.initrd.availableKernelModules}"')
read -r want_intel want_nvidia want_initrd <<<"$cfg"

# pci vendor id -> bus id of its display controller, in the PCI:bus:dev:fn form nix wants
gpu_bus_id() {
  local dev bus slot fn
  for dev in /sys/bus/pci/devices/*; do
    [[ $(<"$dev/vendor") == "$1" && $(<"$dev/class") == 0x03* ]] || continue
    IFS=':.' read -r _ bus slot fn <<<"${dev##*/}"
    printf 'PCI:%d:%d:%d\n' "0x$bus" "0x$slot" "0x$fn"
    return 0
  done
  return 0
}
have_intel=$(gpu_bus_id 0x8086)
have_nvidia=$(gpu_bus_id 0x10de)

problems=()
if [[ -z $have_intel ]]; then
  problems+=("no Intel GPU visible, set Config > Display > Graphics Device to Hybrid Graphics in the BIOS")
elif [[ $have_intel != "$want_intel" ]]; then
  problems+=("intelBusId is $want_intel in configuration.nix, this machine has $have_intel")
fi
if [[ -z $have_nvidia ]]; then
  problems+=("no NVIDIA GPU visible")
elif [[ $have_nvidia != "$want_nvidia" ]]; then
  problems+=("nvidiaBusId is $want_nvidia in configuration.nix, this machine has $have_nvidia")
fi

if ! nixos-generate-config --no-filesystems --show-hardware-config >"$scan" 2>/dev/null; then
  problems+=("nixos-generate-config failed, so the initrd modules weren't checked")
fi
read -ra scan_initrd <<<"$(sed -n 's/.*boot\.initrd\.availableKernelModules = \[\(.*\)\];.*/\1/p' "$scan" | tr -d '"')"
missing=()
for m in "${scan_initrd[@]}"; do
  [[ " $want_initrd " == *" $m "* ]] || missing+=("$m")
done
if (( ${#missing[@]} )); then
  problems+=("the hardware scan wants these initrd modules, add them to hardware-configuration.nix: ${missing[*]}")
fi

if (( ${#problems[@]} )); then
  for p in "${problems[@]}"; do note "! $p"; done
  note "best is to fix it in the repo, push and re-run. continuing installs the config as it is."
  ask "continue anyway?" || die "aborted, nothing was changed"
else
  note "gpus at $have_intel (intel) and $have_nvidia (nvidia) match, initrd modules cover the hardware scan"
fi

say "finding the disk"
if [[ -n ${DISK:-} ]]; then
  disk=$DISK
else
  mapfile -t disks < <(lsblk -dpno NAME,TRAN | awk '$2 == "nvme" { print $1 }')
  (( ${#disks[@]} == 1 )) || die "expected one nvme disk, found ${#disks[@]}${disks[*]:+: ${disks[*]}}. pick one with: DISK=/dev/... bash $0"
  disk=${disks[0]}
fi
disk=$(readlink -f "$disk")
[[ -b $disk ]] || die "$disk isn't a block device"
parttypes=$(lsblk -no PARTTYPE "$disk")
[[ ${parttypes,,} == *ebd0a0a2-b9e5-4433-87c0-68b6b72699c7* ]] \
  || die "no windows partition on $disk, this script only installs next to windows"

# true if the partition link exists and sits on $disk
part_on_disk() { [[ -e $1 && $(lsblk -no PKNAME "$(readlink -f "$1")") == "${disk##*/}" ]]; }

if part_on_disk "$boot_part" && part_on_disk "$crypt_part"; then
  reuse=true
elif [[ -e $boot_part || -e $crypt_part ]]; then
  die "only one of xenon-boot/xenon-crypt exists on $disk, or it's on another disk. check with lsblk -o NAME,PARTLABEL"
else
  reuse=false
  sector=$(blockdev --getss "$disk")
  first=$(sgdisk -F "$disk" | tail -n1)
  last=$(sgdisk -E "$disk" | tail -n1)
  [[ $first =~ ^[0-9]+$ && $last =~ ^[0-9]+$ ]] || die "couldn't read the free space on $disk from sgdisk"
  free_gib=0
  if (( last > first )); then
    free_gib=$(( (last - first + 1) * sector / 1024 ** 3 ))
  fi
  (( free_gib >= min_free_gib )) \
    || die "the largest free space on $disk is ${free_gib}G, need ${min_free_gib}G. shrink C: in Windows' Disk Management first"
fi

echo
lsblk -o NAME,SIZE,FSTYPE,PARTLABEL,MOUNTPOINTS "$disk"
echo
if $reuse; then
  note "xenon-boot and xenon-crypt are there from an earlier run. both get erased, windows stays."
  word=WIPE
else
  note "windows stays as it is. this adds, in the ${free_gib}G of free space:"
  note "  xenon-boot   1G     esp for grub and the kernels (windows keeps its own)"
  note "  xenon-crypt  rest   luks2 with btrfs subvolumes root, nix and persist"
  word=INSTALL
fi
read -rp "   type $word to continue: " answer
[[ $answer == "$word" ]] || die "aborted, nothing was changed"

say "preparing the partitions"
umount -R /mnt 2>/dev/null || true
cryptsetup close "$luks_name" 2>/dev/null || true
if ! $reuse; then
  sgdisk -n 0:0:+1G -t 0:EF00 -c 0:xenon-boot "$disk"
  sgdisk -n "0:0:$last" -t 0:8309 -c 0:xenon-crypt "$disk"
  partprobe "$disk" 2>/dev/null || true
fi
udevadm settle
for p in "$boot_part" "$crypt_part"; do
  for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -e $p ]] && break; sleep 1; done
  part_on_disk "$p" || die "$p didn't show up on $disk"
done
note "wiping old signatures, so disko formats both from scratch"
wipefs -a "$(readlink -f "$boot_part")" "$(readlink -f "$crypt_part")"

say "formatting and mounting with disko"
note "you'll be asked for the luks passphrase, you need it on every boot"
nix run github:nix-community/disko/latest -- --mode format,mount --flake "$flake"
if ! mountpoint -q "$persist" || ! mountpoint -q /mnt/boot; then
  die "$persist or /mnt/boot isn't mounted, disko.nix doesn't match what this script expects"
fi

say "setting passwords in $persist/passwords"
note "stored as yescrypt hashes, read at boot through hashedPasswordFile"
mkdir -p "$persist/passwords"
chmod 700 "$persist/passwords"
for user in "${users[@]}"; do
  while true; do
    read -rsp "   password for $user: " pw1; echo
    read -rsp "   again: " pw2; echo
    [[ -n $pw1 && $pw1 == "$pw2" ]] && break
    note "empty or they don't match, try again"
  done
  (umask 077; printf '%s' "$pw1" | nix shell nixpkgs#mkpasswd -c mkpasswd -m yescrypt -s > "$persist/passwords/$user")
  chmod 600 "$persist/passwords/$user"
done
unset pw1 pw2

say "seeding /persist"
note "machine-id, so the first boot has one to bind mount"
mkdir -p "$persist/etc"
[[ -s $persist/etc/machine-id ]] || systemd-machine-id-setup --root="$persist"
note "copying the repo to /persist/home/$main_user/dots, so it's ~/dots after boot"
mkdir -p "$persist/home/$main_user"
rm -rf "$persist/home/$main_user/dots"
cp -a "$work" "$persist/home/$main_user/dots"
cp "$scan" "$persist/home/$main_user/dots/xenon-hardware-scan.nix"
chown -R "$main_uid:$main_gid" "$persist/home/$main_user"

say "running nixos-install (this is the slow part)"
note "root has no prompt here, its password comes from $persist/passwords/root"
nixos-install --root /mnt --flake "$flake" --no-root-passwd
sync

trap - ERR
say "done. reboot, pull the usb stick and enter the luks passphrase at boot."
note "grub is now first in the boot order, its \"Windows\" entry starts windows."
note "if windows puts itself first again, use F12 at power-on or Boot Order Lock in the BIOS."
note "after logging in: touch /imperm-test, reboot, and check that it's gone"
note "xenon-hardware-scan.nix in ~/dots is this machine's hardware scan (untracked),"
note "compare it with hardware-configuration.nix, then delete it."
