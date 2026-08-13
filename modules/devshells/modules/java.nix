{
  pkgs ? import <nixpkgs>,
}:

let
  inherit (pkgs)
    stdenv
    lib
    openssl
    zlib
    ;

  # vscode-java debug/test bundles loaded into the jdtls server. The jdtls server
  # needs these to serve `vscode.java.startDebugSession` (nvim-dap) and the
  # `vscode.java.*` test commands — without them DAP/test is a silent no-op.
  # Exported as JDTLS_BUNDLES_DIR; the nvim config globs `*/server/*.jar` (the
  # exact set vscode-java feeds to jdtls). Bundles are only *referenced* by the
  # LSP; the debug JVM is spawned by jdtls itself.
  javaDebugBundles = pkgs.symlinkJoin {
    name = "vscode-java-debug-bundles";
    paths = [
      pkgs.vscode-extensions.vscjava.vscode-java-debug
      pkgs.vscode-extensions.vscjava.vscode-java-test
    ];
  };

  # Forge/Fabric 1.20.1 MDKs pin Gradle 8.1.1 (see gradle/wrapper/gradle-wrapper.properties).
  # nixpkgs only ships gradle_8 (8.14.4) and gradle_9 (9.x) — neither is compatible with
  # the old ForgeGradle 1.20.1 ships with, so build the exact distribution. Gradle 8.1
  # cannot run on JDK21, so it is bound to openjdk17 (same JVM as the 1.20.1 runtime).
  gradle8_1_1 = pkgs.gradle-packages.mkGradle {
    version = "8.1.1";
    hash = "sha256-4RHLmUhAfiY1EifavOSYIvuIw37nLx0VgqacaK8ucC8=";
    defaultJava = pkgs.jdk17;
  };

  # Native graphics libs that LWJGL/GLFW dlopen at runtime. Without these on the
  # loader path, Minecraft's dev client (runClient) dies with "glfwInit failed"
  # / "Unable to initialize GLFW" / "GLX: Failed to load GLX" on NixOS, even with
  # a display present.
  graphicsLibs = with pkgs; [
    libGL # libglvnd: libGL/libEGL/libGLX dispatchers
    libGLU
    glfw
    mesa # vendor impls (libGLX_mesa/libEGL_mesa) + OpenGL drivers
    wayland
    libX11
    libXext
    libXcursor
    libXrandr
    libXi
    libXinerama
    libXxf86vm
    libXtst
  ];

  # Loader-path env. `extraLibs` are appended to the base set so a shell can add
  # e.g. graphicsLibs only where it needs them.
  #
  # NIX_LD_LIBRARY_PATH alone is NOT enough for runClient: it is only honored by
  # the nix-ld loader (foreign binaries launched via its ld.so interpreter). The
  # gradle-spawned JVM is a Nix-built binary running under glibc, whose dlopen
  # searches LD_LIBRARY_PATH — so both vars must point at the same lib set, or
  # GLFW can't find libGL.so.1/libGLX.so.0 and dies with "GLX: Failed to load GLX".
  ldFor =
    extraLibs:
    let
      libPath = lib.makeLibraryPath (
        [
          stdenv.cc.cc.lib
          openssl
          zlib
        ]
        ++ extraLibs
      );
    in
    {
      NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
      NIX_LD_LIBRARY_PATH = libPath;
      LD_LIBRARY_PATH = libPath;
    };

  # Common shellHook: pin a default JDK but always expose both 17 and 21 so a
  # project can reach either. `defaultJdk` is a derivation (e.g. pkgs.openjdk17).
  javaEnvHook = defaultJdk: label: ''
    export JAVA_HOME_17=${pkgs.openjdk17}
    export JAVA_HOME_21=${pkgs.openjdk21}
    export JAVA_HOME=${defaultJdk}
    export PATH=$JAVA_HOME/bin:$PATH
    echo "[✔] ${label} — JAVA_HOME → ${defaultJdk}"
    echo "    JAVA_HOME_17=$JAVA_HOME_17"
    echo "    JAVA_HOME_21=$JAVA_HOME_21"
  '';

  # ── Minecraft / Forge modding shell ───────────────────────────────────────
  # Picks a default JDK (17 for 1.20.1, 21 for newer) but exposes both. Includes
  # graphicsLibs so runClient's LWJGL/GLFW can initialise on NixOS.
  #
  # NOTE: it intentionally does NOT bundle jetbrains.idea-oss. IntelliJ is already
  # installed once via home-manager; launch `idea-oss` from *inside* this shell so
  # it inherits JAVA_HOME + NIX_LD_LIBRARY_PATH. Same IDE version everywhere, no
  # duplicate download (bundling would pull a second copy from this flake's
  # possibly-different nixpkgs pin).
  mkMcShell =
    {
      defaultJdk,
      label,
      gradle ? pkgs.gradle,
    }:
    pkgs.mkShell (
      {
        name = "mc-mod-devshell-${label}";
        buildInputs = with pkgs; [
          openjdk17 # 1.20.1 runtime + Gradle 8.1.1 (cannot run on JDK21)
          openjdk21 # newer MC / general tooling AND the JVM that runs jdtls
          gradle # exact version per MC release: 8.1.1 for 1.20.1, default for latest
          cfr # decompiler
          jdt-language-server # nvim LSP (nvim-jdtls). Runs on JDK21 (see below)
          lombok # optional javaagent for jdtls; harmless for MC
          javaDebugBundles # jdtls DAP/test bundles (nvim-dap)
          nix-ld
        ];
        shellHook = ''
          ${javaEnvHook defaultJdk "Minecraft modding shell (${label})"}
          # jdtls >=1.34 requires JDK21 to *run*, but this shell's JAVA_HOME is
          # JDK17 (Gradle/Forge/runClient need it). The Neovim config launches
          # jdtls with `--java-executable $JAVA_HOME_21/bin/java`, so the LSP runs
          # on 21 while Gradle keeps 17 — they never collide. LOMBOK_JAR is picked
          # up by the same config as an optional -javaagent.
          export LOMBOK_JAR=${pkgs.lombok}/share/java/lombok.jar
          export JDTLS_BUNDLES_DIR=${javaDebugBundles}/share/vscode/extensions
          echo "    jdt-language-server on PATH for Neovim (jdtls runs on JDK21)"
          echo "    LOMBOK_JAR=$LOMBOK_JAR"
          echo "    JDTLS_BUNDLES_DIR=$JDTLS_BUNDLES_DIR  (nvim-dap/java-debug bundles)"
          echo "    Launch the IDE from here with: idea-oss   (inherits this env)"
        '';
      }
      // ldFor graphicsLibs
    );

  # ── Plain Java dev shell (no Minecraft, no graphics libs) ──────────────────
  # For CLI / neovim work. Ships jdt-language-server (Eclipse JDTLS) for nvim LSP
  # plus maven and gradle.
  mkJavaShell =
    { defaultJdk, label }:
    pkgs.mkShell (
      {
        name = "java-devshell-${label}";
        buildInputs = with pkgs; [
          openjdk17
          openjdk21
          gradle
          maven
          jdt-language-server # nvim LSP (nvim-jdtls / lspconfig `jdtls`)
          javaDebugBundles # jdtls DAP/test bundles (nvim-dap)
          nix-ld
        ];
        shellHook = ''
          ${javaEnvHook defaultJdk "Java dev shell (${label})"}
          export JDTLS_BUNDLES_DIR=${javaDebugBundles}/share/vscode/extensions
          echo "    jdt-language-server on PATH for Neovim LSP"
          echo "    JDTLS_BUNDLES_DIR=$JDTLS_BUNDLES_DIR  (nvim-dap/java-debug bundles)"
        '';
      }
      // ldFor [ ]
    );
in
{
  # Minecraft modding entry points
  mc_1_20_1 = mkMcShell {
    defaultJdk = pkgs.openjdk17;
    label = "1.20.1-jdk17";
    gradle = gradle8_1_1;
  };
  mc_latest = mkMcShell {
    defaultJdk = pkgs.openjdk21;
    label = "latest-jdk21";
  };

  # Plain Java entry points (neovim / CLI)
  java17 = mkJavaShell {
    defaultJdk = pkgs.openjdk17;
    label = "jdk17";
  };
  java21 = mkJavaShell {
    defaultJdk = pkgs.openjdk21;
    label = "jdk21";
  };
}
