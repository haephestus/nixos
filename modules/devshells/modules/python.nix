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
    python312Packages.pip
    gcc
    gnumake
  ];

  baseLDenv = {
    NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
    NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
      stdenv.cc.cc.lib
      openssl
      zlib
    ];
  };

  # common shellHook for all environments
  commonShellHook = ''
    echo "Python312 dev shell"

    # export runtime linker explicitly
    export NIX_LD=$(nix eval --raw nixpkgs#stdenv.cc.cc.lib)/lib/ld-linux-x86-64.so.2
    export LD_LIBRARY_PATH=$(nix eval --raw nixpkgs#stdenv.cc.cc.lib)/lib:$LD_LIBRARY_PATH
  '';
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

        python312Packages.jinja2
        python312Packages.asyncpg
        python312Packages.fastapi
        python312Packages.slowapi
        python312Packages.playwright
        python312Packages.apscheduler
        python312Packages.fastapi-cli
        python312Packages.itsdangerous
        python312Packages.beautifulsoup4
        python312Packages.python-dateutil
        python312Packages.python-multipart
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
      ++ (with pkgs.python312Packages; [
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
