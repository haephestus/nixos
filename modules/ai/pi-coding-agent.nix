{ pkgs, ... }:
{
  programs.pi-coding-agent = {
    enable = true;
    # which pi-coding-agent package to use
    packages = pkgs.pi-coding-agent;
    # Directory holding Pi Coding Agent’s configuration files.
    # "${config.home.homeDirectory}/.pi/agent"
    configDir = "";
    # The value is either:
    #  Inline content as a string
    #  A path to a file containing the content
    #  The configured content is written to AGENTS.md inside programs.pi-coding-agent.configDir (default ~/.pi/agent/AGENTS.md).
    context = "";
    # Extra packages available to Pi Coding Agent. These are added to the PATH of the wrapped pi binary.
    # Needed for packages installed by pi (e.g. npm:@termdraw/pi requires npm and bun).
    extraPackages = [
      pkgs.nodejs
      pkgs.bun
    ];
    # Keybindings configuration written to ~/.pi/agent/keybindings.json.
    # See https://pi.dev/docs/latest/keybindings for the documentation.
    keybings = { };
    # Custom model providers written to ~/.pi/agent/models.json.
    # provider = { baseUrl, api, apiKey, compat, and a models list with id, name, reasoning, etc.}
    models = { };
    # Configuration written to ~/.pi/agent/settings.json. See https://pi.dev/docs/latest/settings for the documentation.
    settings = { };
  };
}
