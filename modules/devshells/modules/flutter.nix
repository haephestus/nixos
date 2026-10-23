{ pkgs }:
let
  androidPkgs = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [
      "34"
      "35"
      "36"
    ];
    buildToolsVersions = [
      "34.0.0"
      "35.0.0"
      "36.0.0"
    ];
    includeNDK = true;
    # Keep in sync with Flutter's default ndkVersion
    # (packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt).
    # Flutter 3.41 pins NDK 28.2.13676358; without it Gradle tries to
    # auto-install the NDK at build time and fails on NixOS.
    ndkVersions = [
      "27.0.12077973"
      "28.2.13676358"
    ];
    cmakeVersions = [ "3.22.1" ];
    includeSources = false;
    includeSystemImages = false;
    includeEmulator = false;
    abiVersions = [
      "armeabi-v7a"
      "arm64-v8a"
      "x86_64"
    ];
  };
  # Short hash of the SDK store path. Used to name the writable copy so it is
  # rebuilt automatically whenever the SDK derivation above changes.
  sdkId = builtins.substring 0 12 (builtins.baseNameOf androidPkgs.androidsdk);

  # git wrapper: runs the Nix-built git without the shell's LD_LIBRARY_PATH,
  # which avoids the "libpcre2-8.so.0: no version information" warning.
  cleanGit = pkgs.writeShellScriptBin "git" ''
    exec env -u LD_LIBRARY_PATH ${pkgs.git}/bin/git "$@"
  '';
in
{
  build = pkgs.buildFHSEnv {
    name = "flutter-env";
    targetPkgs = pkgs: [ ];
  };

  flutter = pkgs.mkShell {
    name = "flutter-cli-shell";
    buildInputs = [
      cleanGit

      # Android / Flutter tooling
      androidPkgs.androidsdk
      pkgs.openjdk17
      pkgs.flutter341
      pkgs.dart
      pkgs.gradle
      pkgs.clang
      pkgs.cmake
      pkgs.ninja
      pkgs.pkg-config
      # Linux desktop Flutter requirements - Core GTK stack
      pkgs.gtk3
      pkgs.glib
      pkgs.gdk-pixbuf
      pkgs.atk
      pkgs.cairo
      pkgs.pango
      pkgs.harfbuzz
      pkgs.sysprof
      pkgs.libsysprof-capture
      # File picker dialog (IMPORTANT!)
      pkgs.zenity
      # Additional required libraries
      pkgs.libepoxy
      pkgs.xz
      pkgs.icu
      pkgs.zlib
      pkgs.fontconfig
      pkgs.freetype
      pkgs.libpng
      pkgs.libjpeg
      pkgs.libsecret
      # OpenGL/Mesa
      pkgs.mesa
      pkgs.libGL
      pkgs.libglvnd
      pkgs.vulkan-loader
      pkgs.vulkan-validation-layers
      # X11 libraries
      pkgs.libX11
      pkgs.libXext
      pkgs.libXi
      pkgs.libXrandr
      pkgs.libXinerama
      pkgs.libXcursor
      pkgs.libXrender
      pkgs.libxcb
      pkgs.libxkbcommon
      # Themes
      pkgs.adwaita-icon-theme
      pkgs.gnome-themes-extra
      # Additional utilities
      pkgs.coreutils
      pkgs.which
      pkgs.file
    ];

    JAVA_HOME = "${pkgs.openjdk17.home}";
    NIX_SHELL = "1";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${pkgs.aapt}/bin/aapt2";
    CHROME_EXECUTABLE = "chromium";

    shellHook = ''
      echo "Flutter CLI env with Android SDK + Linux desktop deps"

      # --- 1. Writable Flutter SDK Workaround for NixOS ---
      FLUTTER_DEST="$HOME/.cache/flutter-sdk-3.41.6"
      if [ ! -d "$FLUTTER_DEST" ]; then
        echo "-> Creating a local mutable copy of Flutter SDK..."
        mkdir -p "$(dirname "$FLUTTER_DEST")"
        cp -r ${pkgs.flutter341} "$FLUTTER_DEST"
        chmod -R +w "$FLUTTER_DEST"
      fi
      mkdir -p "$FLUTTER_DEST/bin/cache"
      touch "$FLUTTER_DEST/bin/cache/engine.realm"
      export FLUTTER_ROOT="$FLUTTER_DEST"
      export PATH="$FLUTTER_ROOT/bin:$PATH"
      # ---------------------------------------------------

      # --- 2. Writable Android SDK Workaround for NixOS ---
      # The directory name includes the SDK store hash, so changing the SDK
      # definition above automatically produces a fresh copy.
      ANDROID_DEST="$HOME/.cache/android-sdk-${sdkId}"
      if [ ! -d "$ANDROID_DEST" ]; then
        echo "-> Creating a local mutable copy of Android SDK (one-time, several GB)..."
        mkdir -p "$(dirname "$ANDROID_DEST")"
        ANDROID_TMP="$ANDROID_DEST.tmp"
        rm -rf "$ANDROID_TMP"
        # -L dereferences symlinks so nothing points back into /nix/store
        cp -rL ${androidPkgs.androidsdk}/libexec/android-sdk "$ANDROID_TMP"
        chmod -R u+w "$ANDROID_TMP"
        # ndk-bundle duplicates the newest NDK and triggers the
        # "inconsistent location" warning, so drop it.
        rm -rf "$ANDROID_TMP/ndk-bundle"
        # Rename last, so an interrupted copy is never mistaken for a good one
        mv "$ANDROID_TMP" "$ANDROID_DEST"
      fi
      export ANDROID_SDK_ROOT="$ANDROID_DEST"
      export ANDROID_HOME="$ANDROID_DEST"
      # ---------------------------------------------------

      # --- 3. License acceptance (must target the WRITABLE copy) ---
      # The PATH `sdkmanager` (from the Nix androidsdk package) hardcodes
      # --sdk_root pointing into /nix/store, which is read-only: running it
      # "succeeds" only because errors were swallowed, and no license files
      # ever get written. Use the copy's own sdkmanager against the copy.
      if [ ! -d "$ANDROID_DEST/licenses" ]; then
        mkdir -p "$ANDROID_DEST/licenses"
        # Seed the license marker files from the pre-accepted Nix SDK
        cp -L ${androidPkgs.androidsdk}/libexec/android-sdk/licenses/* \
          "$ANDROID_DEST/licenses/" 2>/dev/null || true
      fi
      SDKMANAGER="$(find "$ANDROID_DEST/cmdline-tools" -path '*/bin/sdkmanager' -print -quit)"
      if [ -n "$SDKMANAGER" ]; then
        # Pick up any license versions the Nix SDK's files don't cover
        # (e.g. the NDK 28 license hash is newer than androidenv's list).
        yes | "$SDKMANAGER" --sdk_root="$ANDROID_DEST" --licenses >/dev/null
      fi
      # ---------------------------------------------------

      export ANDROID_NDK_ROOT="$ANDROID_DEST/ndk/28.2.13676358"

      echo "ANDROID_SDK_ROOT = $ANDROID_SDK_ROOT"
      echo "ANDROID_NDK_ROOT = $ANDROID_NDK_ROOT"

      # PKG_CONFIG_PATH setup
      export PKG_CONFIG_PATH="${pkgs.sysprof.dev}/lib/pkgconfig:${pkgs.glib.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"

      # Library paths for Flutter Linux builds
      export LD_LIBRARY_PATH=${
        pkgs.lib.makeLibraryPath [
          pkgs.glib
          pkgs.gtk3
          pkgs.cairo
          pkgs.pango
          pkgs.harfbuzz
          pkgs.gdk-pixbuf
          pkgs.atk
          pkgs.libepoxy
          pkgs.zlib
          pkgs.mesa
          pkgs.libGL
          pkgs.libglvnd
          pkgs.libX11
          pkgs.libXext
          pkgs.libXi
          pkgs.libXrandr
          pkgs.libXcursor
          pkgs.fontconfig
          pkgs.freetype
          pkgs.libxkbcommon
          pkgs.vulkan-loader
        ]
      }:/run/current-system/sw/lib:$LD_LIBRARY_PATH

      # OpenGL/Mesa setup
      export LIBGL_DRIVERS_PATH=${pkgs.mesa}/lib/dri
      export __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
      export VK_LAYER_PATH=${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d

      # GTK/Cursor theming
      export XCURSOR_THEME=Adwaita
      export XCURSOR_SIZE=24
      export GTK_THEME=Adwaita:dark

      # ICU data
      export ICU_DATA=${pkgs.icu}/share/icu/${pkgs.icu.version}

      # Add zenity to PATH (for file_picker)
      export PATH="${pkgs.zenity}/bin:$PATH"

      # Configure Flutter
      flutter config --android-sdk "$ANDROID_SDK_ROOT"
      flutter config --no-analytics

    '';
  };
}
