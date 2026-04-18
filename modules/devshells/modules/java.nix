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

  baseBuildInputs = with pkgs; [
    openjdk21 # for tools
    openjdk17 # for projects
    gradle # Mod projects are usually Gradle-based
    cfr
  ];

  baseLDenv = {
    NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
    NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
      stdenv.cc.cc.lib
      openssl
      zlib
    ];
  };
in
{
  mc_dev = pkgs.mkShell {
    name = "minecraft-java-mod-devshell";
    buildInputs =
      baseBuildInputs
      ++ (with pkgs; [
        nix-ld
      ]);

    shellHook = ''
      echo "[✔] Java Minecraft Modding Shell Ready"

      # Set Java 21 as default
      export JAVA_HOME=${pkgs.openjdk21}
      export PATH=$JAVA_HOME/bin:$PATH

      # Java 17 explicitly exposed
      export JAVA_HOME_17=${pkgs.openjdk17}
      echo "Default JAVA_HOME set to: $JAVA_HOME (Java 21)"
      echo "JAVA_HOME_17 available at: $JAVA_HOME_17"

    '';
    inherit (baseLDenv) NIX_LD NIX_LD_LIBRARY_PATH;
  };
}
