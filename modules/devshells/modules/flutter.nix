{ pkgs }:
let
  androidPkgs = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [
      "33"
      "34"
    ];
    buildToolsVersions = [
      "33.0.0"
      "34.0.0"
    ];
    includeNDK = true;
    ndkVersions = [ "25.1.8937393" ];
    includeSources = false;
    includeSystemImages = false;
    includeEmulator = false;
    abiVersions = [
      "armeabi-v7a"
      "arm64-v8a"
      "x86_64"
    ];
  };
in
{
  flutter = pkgs.mkShell {
    name = "flutter-cli-shell";
    buildInputs = [
      # Android / Flutter tooling
      androidPkgs.androidsdk
      pkgs.openjdk17
      pkgs.flutter332
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
      # File picker dialog (IMPORTANT!)
      pkgs.zenity
      # Additional required libraries
      pkgs.libepoxy
      pkgs.pcre
      pkgs.pcre2
      pkgs.xz
      pkgs.icu
      pkgs.zlib
      pkgs.fontconfig
      pkgs.freetype
      pkgs.libpng
      pkgs.libjpeg
      # OpenGL/Mesa
      pkgs.mesa
      pkgs.mesa.drivers
      pkgs.libGL
      pkgs.libglvnd
      pkgs.vulkan-loader
      pkgs.vulkan-validation-layers
      # X11 libraries
      pkgs.xorg.libX11
      pkgs.xorg.libXext
      pkgs.xorg.libXi
      pkgs.xorg.libXrandr
      pkgs.xorg.libXinerama
      pkgs.xorg.libXcursor
      pkgs.xorg.libXrender
      pkgs.xorg.libxcb
      pkgs.libxkbcommon
      # Themes
      pkgs.adwaita-icon-theme
      pkgs.gnome-themes-extra
      # Additional utilities
      pkgs.coreutils
      pkgs.which
      pkgs.file
    ];
    ANDROID_SDK_ROOT = "${androidPkgs.androidsdk}/libexec/android-sdk";
    ANDROID_HOME = "${androidPkgs.androidsdk}/libexec/android-sdk";
    ANDROID_NDK_ROOT = "${androidPkgs.androidsdk}/libexec/android-sdk/ndk/25.1.8937393";
    JAVA_HOME = "${pkgs.openjdk17}";
    NIXPKGS_ACCEPT_ANDROID_SDK_LICENSE = "1";
    # GRADLE_OPTS = "-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx2048m";
    CHROME_EXECUTABLE = "chromium";
    shellHook = ''
      echo "Flutter CLI env with Android SDK + Linux desktop deps"
      echo "ANDROID_SDK_ROOT = $ANDROID_SDK_ROOT"
      echo "ANDROID_NDK_ROOT = $ANDROID_NDK_ROOT"
      # Accept Android licenses
      yes | sdkmanager --licenses 2>/dev/null || true
      # PKG_CONFIG_PATH setup
      export PKG_CONFIG_PATH="${pkgs.sysprof.dev}/lib/pkgconfig:${pkgs.glib.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
      # Set up library paths for Linux builds
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
          pkgs.mesa.drivers
          pkgs.libGL
          pkgs.libglvnd
          pkgs.xorg.libX11
          pkgs.xorg.libXext
          pkgs.xorg.libXi
          pkgs.xorg.libXrandr
          pkgs.xorg.libXcursor
          pkgs.fontconfig
          pkgs.freetype
          pkgs.icu
          pkgs.pcre
          pkgs.pcre2
          pkgs.libxkbcommon
          pkgs.vulkan-loader
        ]
      }:/run/current-system/sw/lib:$LD_LIBRARY_PATH
      # OpenGL/Mesa setup
      export LIBGL_DRIVERS_PATH=${pkgs.mesa.drivers}/lib/dri
      export __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json
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

      # Test zenity
      if command -v zenity &> /dev/null; then
        echo "✓ Zenity installed and available"
      else
        echo "✗ Warning: Zenity not found in PATH"
      fi

      echo ""
      echo "Run 'flutter doctor' to verify setup"
      echo "Run 'flutter doctor -v' for detailed diagnostics"
    '';
  };
}
