{
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (pkgs)
    stdenv
    lib
    openssl
    zlib
    ;

  baseBuildInputs = with pkgs; [
    python312
    python313Packages.pip
    gcc
    gnumake
  ];

  baseLDenv = {
    NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
    NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
      stdenv.cc.cc.lib
      openssl
      zlib
      pkgs.glib
      pkgs.nss
      pkgs.nspr
      pkgs.atk
      pkgs.cups
      pkgs.dbus
      pkgs.expat
      pkgs.libdrm
      pkgs.xorg.libX11
      pkgs.xorg.libXcomposite
      pkgs.xorg.libXdamage
      pkgs.xorg.libXext
      pkgs.xorg.libXfixes
      pkgs.xorg.libXrandr
      pkgs.xorg.libxcb
      pkgs.mesa
      pkgs.gtk3
      pkgs.pango
      pkgs.cairo
      pkgs.alsa-lib
      pkgs.at-spi2-atk
      pkgs.at-spi2-core
    ];
  };

  # common shellHook for all environments
  commonShellHook = ''
    echo "Python312 dev shell"

    # export runtime linker explicitly
    export NIX_LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH:$LD_LIBRARY_PATH"  '';
in
{
  python = pkgs.mkShell {
    buildInputs = baseBuildInputs;
    shellHook = commonShellHook;
    inherit (baseLDenv) NIX_LD NIX_LD_LIBRARY_PATH;
  };

  fastapi = pkgs.mkShell {
    buildInputs =
      baseBuildInputs
      ++ (with pkgs; [
        watchman
        postgrest
        postgresql
        virtualenv
        tailwindcss_4
        playwright-driver.browsers

        python313Packages.jinja2
        python313Packages.asyncpg
        python313Packages.fastapi
        python313Packages.slowapi
        python313Packages.playwright
        python313Packages.apscheduler
        python313Packages.fastapi-cli
        python313Packages.itsdangerous
        python313Packages.beautifulsoup4
        python313Packages.python-dateutil
        python313Packages.python-multipart
      ]);
    shellHook = commonShellHook + ''
      export PGDATA=$PWD/.postgres
      export PGHOST=$PWD/.postgres

      export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
      export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
      export PLAYWRIGHT_HOST_PLATFORM_OVERIDE="ubunut-24.04"

      # Create the lock file directory postgres expects
      mkdir -p $PWD/.postgres/run
      export PGDATA=$PWD/.postgres
      export PGUSER=$(whoami)

      if [ ! -f $PGDATA/PG_VERSION ]; then
        echo "Initializing PostgreSQL..."
        initdb --auth=trust --no-locale --encoding=UTF8
      fi

      pg_ctl status -o "-k $PWD/.postgres/run" || \
      pg_ctl start -o "-k $PWD/.postgres/run -h \"\"" -l $PGDATA/postgres.log

      createdb pixelparty 2>/dev/null || true
    '';
    inherit (baseLDenv) NIX_LD NIX_LD_LIBRARY_PATH;
  };

  insight = pkgs.mkShell {
    buildInputs =
      baseBuildInputs
      ++ (with pkgs.python313Packages; [
        scikit-learn
        statsmodels
        matplotlib
        virtualenv
        jupyterlab
        ipykernel
        notebook
        jupytext
        pandas
        numpy
        pip
      ]);
    shellHook = commonShellHook;
    inherit (baseLDenv) NIX_LD NIX_LD_LIBRARY_PATH;
  };
}
