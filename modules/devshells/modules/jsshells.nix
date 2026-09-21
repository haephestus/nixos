{ pkgs }:

{
  nodejs_22 = pkgs.mkShell {
    name = "nodejs_22";
    buildInputs = with pkgs; [
      nodejs_22
      yarn
      live-server
      vercel-pkg
    ];
  };

  bun = pkgs.mkShell {
    name = "bun";
    buildInputs = with pkgs; [
      bun
    ];
  };
}
