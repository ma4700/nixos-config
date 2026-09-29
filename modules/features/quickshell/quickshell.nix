{ self, inputs, ... }: {

  perSystem = { pkgs, self', ... }: {

    # bluetooth pairing agent the bar talks to, see qs-bt-agent.c
    packages.qsBtAgent = pkgs.stdenv.mkDerivation {
      name = "qs-bt-agent";
      src = ./qs-bt-agent.c;
      dontUnpack = true;
      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = [ pkgs.systemd ];
      buildPhase = ''
        $CC -O2 -Wall -Wextra -o qs-bt-agent $src $(pkg-config --cflags --libs libsystemd)
      '';
      installPhase = ''
        install -Dm755 qs-bt-agent $out/bin/qs-bt-agent
      '';
      meta.mainProgram = "qs-bt-agent";
    };

    packages.myQuickshell = inputs.wrapper-modules.wrappers.quickshell.wrap {
      inherit pkgs;
      configDir = pkgs.runCommand "quickshell-config" { } ''
        mkdir -p $out
        cp -r ${./qml}/* $out/
        cat > $out/Theme.qml <<'EOF'
        import QtQuick

        QtObject {
            readonly property color bg: "${self.theme.base00}"
            readonly property color dim: "${self.theme.base03}"
            readonly property color mid: "${self.theme.base05}"
            readonly property color fg: "${self.theme.base06}"
            readonly property color bright: "${self.theme.base07}"
            readonly property color red: "${self.theme.red}"
            readonly property color green: "${self.theme.green}"
            readonly property color yellow: "${self.theme.yellow}"
        }
        EOF
        cat > $out/WallpaperPath.qml <<'EOF'
        import QtQuick

        QtObject {
            readonly property string path: "file://${self.wallpaper}"
        }
        EOF
        cat > $out/BluetoothFeature.qml <<'EOF'
        pragma Singleton
        import Quickshell

        Singleton {
            readonly property bool enabled: ${if self.bluetoothEnabled then "true" else "false"}
            readonly property string agent: "${if self.bluetoothEnabled then "${self'.packages.qsBtAgent}/bin/qs-bt-agent" else ""}"
        }
        EOF
      '';
    };
  };
}
