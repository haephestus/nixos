{
  pkgs,
}:
# ── Python dev shells ───────────────────────────────────────────────────────
# One module for every Python devshell — collapsed from the former
#
#   * general / web / CLI   → pyshell, pyflask, pyml, pycerebrum (Python 3.13)
#   * Steward-Daemon        → steward (Python 3.13 + FastAPI; AI deps via venv)
#   * nix-ld / GUI-capable  → python, fastapi, insight (Python 3.12-era)
#
# All shells activate a project venv if one exists; two activation paths are
# honoured, matching each shell's own docs:
#   .env/bin/activate                  (pyshell / pyflask / pyml)
#   .direnv/python-3.13/bin/activate   (pycerebrum / steward)

let
  inherit (pkgs)
    stdenv
    lib
    openssl
    zlib
    ;

  python313 = pkgs.python313;
  python312 = pkgs.python312;
  libstdcxx = stdenv.cc.cc.lib;

  # General-purpose Python 3.13 base (pyshell / pyflask / pyml / pycerebrum).
  pyBase = with pkgs; [
    zstd
    python313
    libstdcxx
    virtualenv
    playwright-driver.browsers

    python313Packages.pydantic
    python313Packages.requests
    python313Packages.ipython
    python313Packages.typer
    python313Packages.rich
    python313Packages.pip
  ];

  # Steward base: stable FastAPI stack from nixpkgs; the fast-moving AI deps
  # (langchain, ollama, chromadb/lancedb) come from the project venv via pip.
  stewardBase = with pkgs; [
    python313
    libstdcxx
    zstd
    sqlite
    virtualenv
    gcc
    gnumake

    python313Packages.fastapi
    python313Packages.uvicorn
    python313Packages.pydantic
    python313Packages.httpx
    python313Packages.apscheduler
    python313Packages.python-multipart
    python313Packages.python-dateutil

    python313Packages.typer
    python313Packages.rich
    python313Packages.pip
    python313Packages.watchdog
  ];

  # nix-ld shells (python / fastapi / insight) share this base.
  baseBuildInputs = with pkgs; [
    python312
    python313Packages.pip
    gcc
    gnumake
  ];

  # LD runtime env for binaries that dlopen GUI/browser libs (Playwright,
  # GTK, ALSA, etc.) via nix-ld.
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
      pkgs.libX11
      pkgs.libXcomposite
      pkgs.libXdamage
      pkgs.libXext
      pkgs.libXfixes
      pkgs.libXrandr
      pkgs.libxcb
      pkgs.mesa
      pkgs.gtk3
      pkgs.pango
      pkgs.cairo
      pkgs.alsa-lib
      pkgs.at-spi2-atk
      pkgs.at-spi2-core
    ];
  };

  commonShellHook = ''
    echo "Python312 dev shell"

    export NIX_LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH:$LD_LIBRARY_PATH"
  '';
in
{
  # ── General / web / ML / OCR ──────────────────────────────────────────────
  pyshell = pkgs.mkShell {
    name = "pyshell";
    buildInputs = pyBase ++ [ pkgs.python313Packages.watchdog ];
    shellHook = ''
      export LD_LIBRARY_PATH=${libstdcxx}/lib:${pkgs.zstd}/lib:$LD_LIBRARY_PATH
      echo "🐍 General Python 3.12 Dev Shell Loaded"
      if [ -f .env/bin/activate ]; then
        source .env/bin/activate
      fi
    '';
  };

  pyflask = pkgs.mkShell {
    name = "pyflask";
    buildInputs = pyBase ++ [ pkgs.python313Packages.flask ];
    shellHook = ''
      export LD_LIBRARY_PATH=${libstdcxx}/lib:$LD_LIBRARY_PATH
      echo "🌐 Flask Webdev Python Shell Loaded"
      if [ -f .env/bin/activate ]; then
        source .env/bin/activate
      fi
    '';
  };

  pyml = pkgs.mkShell {
    name = "pyml";
    buildInputs =
      pyBase
      ++ (with pkgs; [
        python313Packages.scikit-learn
        python313Packages.statsmodels
        python313Packages.torchvision
        python313Packages.matplotlib
        python313Packages.jupyterlab
        python313Packages.notebook
        python313Packages.opencv4
        python313Packages.pytorch
        python313Packages.seaborn
        python313Packages.pandas
        python313Packages.numpy
        python313Packages.scipy
      ]);
    shellHook = ''
      export LD_LIBRARY_PATH=${libstdcxx}/lib:$LD_LIBRARY_PATH
      echo "🧠 Machine Learning Python Shell Loaded"
      if [ -f .env/bin/activate ]; then
        source .env/bin/activate
      fi
    '';
  };

  pycerebrum = pkgs.mkShell {
    name = "pycerebrum";
    # Python modules + system-level compiled tools (OCR / PyMuPDF).
    buildInputs =
      pyBase
      ++ (with pkgs; [
        python313Packages.pymupdf
        python313Packages.ocrmypdf
        tesseract
        ghostscript
      ]);
    shellHook = ''
      # tesseract pathing + shared libs so PyMuPDF & OCRmyPDF don't crash.
      export LD_LIBRARY_PATH=${libstdcxx}/lib:${pkgs.zstd}/lib:${pkgs.tesseract}/lib:$LD_LIBRARY_PATH
      export TESSDATA_PREFIX="${pkgs.tesseract}/share/tessdata"

      echo "🧠 Cerebrum-Daemon Shell Loaded (with OCR & PyMuPDF capabilities)"
      if [ -f .direnv/python-3.13/bin/activate ]; then
        source .direnv/python-3.13/bin/activate
      fi
    '';
  };

  # ── Steward-Daemon ────────────────────────────────────────────────────────
  steward = pkgs.mkShell {
    name = "steward";
    buildInputs = stewardBase;
    shellHook = ''
      export LD_LIBRARY_PATH=${libstdcxx}/lib:${pkgs.zstd}/lib:$LD_LIBRARY_PATH
      echo "🏛️  Steward-Daemon Shell (FastAPI + Ollama/LangChain via venv)"

      # Project venv for the pip-only AI deps (langchain, ollama, chromadb/lancedb).
      if [ ! -d .direnv/python-3.13 ]; then
        echo "→ first run: python -m venv .direnv/python-3.13 && pip install langchain ollama chromadb"
      fi
      if [ -f .direnv/python-3.13/bin/activate ]; then
        source .direnv/python-3.13/bin/activate
      fi
    '';
  };

  # ── nix-ld / GUI-capable ──────────────────────────────────────────────────
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

      # Create the lock file directory postgres expects.
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
