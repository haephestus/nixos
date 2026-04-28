{ pkgs }:

let
  libstdcxx = pkgs.stdenv.cc.cc.lib;
  python = pkgs.python313;

  basepkgs = with pkgs; [
    zstd
    python
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
in
{
  pyshell = pkgs.mkShell {
    name = "pyshell";
    buildInputs = basepkgs ++ (with pkgs; [ python313Packages.watchdog ]);
    shellHook = ''
      export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zstd}/lib:$LD_LIBRARY_PATH
      echo "🐍 General Python 3.12 Dev Shell Loaded"
      if [ -f .env/bin/activate ]; then
        source .env/bin/activate
      fi
    '';
  };

  pyflask = pkgs.mkShell {
    name = "pyflask";
    buildInputs = basepkgs ++ (with pkgs; [ python313Packages.flask ]);
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
      basepkgs
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
    buildInputs = basepkgs;
    shellHook = ''
      export LD_LIBRARY_PATH=${libstdcxx}/lib:${pkgs.zstd}/lib:$LD_LIBRARY_PATH
      echo "🧠 Cerebrum-Daemon Shell Loaded"
      if [ -f .direnv/python-3.13/bin/activate ]; then
        source .direnv/python-3.13/bin/activate
      fi
    '';
  };
}
