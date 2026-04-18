{
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML ''
      "$schema" = "https://starship.rs/config-schema.json"

      format = """
      [░▒▓](#a3aed2)\
      [  ](bg:#a3aed2 fg:#090c0c)\
      [](bg:#769ff0 fg:#a3aed2)\
      $directory\
      [](fg:#769ff0 bg:#394260)\
      $git_branch\
      $git_status\
      [](fg:#394260 bg:#212736)\
      $c\
      $cmake\
      $rust\
      $java\
      $dart\
      $nodejs\
      $python\
      [](fg:#212736 bg:#1d2230)\
      $time\
      [ ](fg:#1d2230)\
      \n$character"""

      [directory]
      style = "fg:#e3e5e5 bg:#769ff0"
      format = "[ $path ]($style)"
      truncation_length = 3
      truncation_symbol = "…/"

      [git_branch]
      symbol = ""
      style = "bg:#394260"
      format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)"

      [git_status]
      style = "bg:#394260"
      format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)"

      # --- Languages (your set) ---

      [c]
      symbol = ""
      style = "bg:#212736"
      format = "[[ $symbol ](fg:#769ff0 bg:#212736)]($style)"

      [cmake]
      symbol = "△"
      style = "bg:#212736"
      format = "[[ $symbol ](fg:#769ff0 bg:#212736)]($style)"

      [rust]
      symbol = ""
      style = "bg:#212736"
      format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)"

      [java]
      symbol = ""
      style = "bg:#212736"
      format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)"

      [dart]
      symbol = ""
      style = "bg:#212736"
      format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)"

      [nodejs]
      symbol = ""
      style = "bg:#212736"
      format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)"

      [python]
      symbol = ""
      style = "bg:#212736"
      format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)"

      # --- Time ---
      [time]
      disabled = false
      time_format = "%R"
      style = "bg:#1d2230"
      format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)"

      # --- Prompt ---
      [character]
      success_symbol = "[➜](bold fg:#9ece6a)"
      error_symbol = "[✗](bold fg:#f7768e)"
    '';
  };
}
