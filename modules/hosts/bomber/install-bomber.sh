#!/usr/bin/env bash
# Install script for the bomber host. Run it from the minimal NixOS iso,
# booted in UEFI mode:
#
#   curl -O https://raw.githubusercontent.com/styro4700/dots/main/modules/hosts/bomber/install.sh
#   bash install.sh
set -euo pipefail

host=bomber
users=(alice root)
main_user=alice
main_uid=1000
main_gid=100
repo=${REPO_URL:-https://github.com/styro4700/dots}
branch=${BRANCH:-main}
work=/tmp/dots
persist=/mnt/persist
luks_name=cryptroot # has to match disko.nix

export NIX_CONFIG="experimental-features = nix-command flakes"

say() { printf '\n>> %s\n' "$*"; }
note() { printf '   %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
trap 'printf "failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

if [[ $EUID -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi
export HOME=/root # sudo -E keeps /home/nixos, which makes nix warn

say "checking that we booted in UEFI mode"
[[ -d /sys/firmware/efi ]] || die "not in UEFI mode, reboot and pick the UEFI entry for the usb stick (F12)"

say "enabling zram swap (the iso lives in ram and evaluating the flake is memory hungry)"
if [[ -z $(swapon --show --noheadings) ]]; then
  modprobe zram
  zdev=$(zramctl --find --size "$(awk '/MemTotal/ {print $2}' /proc/meminfo)K" --algorithm zstd)
  mkswap "$zdev" >/dev/null
  swapon "$zdev"
  note "swap on $zdev"
else
  note "swap already active"
fi

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

say "reading the target disk from disko.nix (downloads flake inputs, takes a minute)"
disk=$(nix eval --raw "$work#nixosConfigurations.$host.config.disko.devices.disk.main.device")
[[ -b $(readlink -f "$disk") ]] || die "$disk doesn't exist, check ls -l /dev/disk/by-id and fix disko.nix"
echo
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS "$(readlink -f "$disk")"
echo
note "everything on $disk will be erased."
read -rp "   type WIPE to continue: " answer
[[ $answer == WIPE ]] || die "aborted, nothing was changed"

say "partitioning and encrypting $disk with disko"
note "1G esp on /boot, then luks2 with btrfs subvolumes root, nix and persist"
note "you'll be asked for the luks passphrase, you need it on every boot"
swapoff "$persist/swapfile" 2>/dev/null || true
umount -R /mnt 2>/dev/null || true
cryptsetup close "$luks_name" 2>/dev/null || true
nix run github:nix-community/disko/latest -- --mode destroy,format,mount --yes-wipe-all-disks --flake "$flake"
mountpoint -q "$persist" || die "$persist isn't mounted, disko.nix doesn't match what this script expects"

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
cp -a "$work" "$persist/home/$main_user/dots"
chown -R "$main_uid:$main_gid" "$persist/home/$main_user"

say "adding a temporary 8G swapfile on the new disk, evaluating the config needs more than the 8G of ram"
btrfs filesystem mkswapfile --size 8g "$persist/swapfile"
swapon "$persist/swapfile"

say "running nixos-install (this is the slow part)"
note "root has no prompt here, its password comes from $persist/passwords/root"
nixos-install --root /mnt --flake "$flake" --no-root-passwd
sync

say "removing the temporary swapfile"
swapoff "$persist/swapfile"
rm "$persist/swapfile"

trap - ERR
say "done. reboot, pull the usb stick and enter the luks passphrase at boot."
note "after logging in: touch /imperm-test, reboot, and check that it's gone"
