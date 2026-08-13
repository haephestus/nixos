{
  # Hooks direnv into the interactive shell so a project's .envrc auto-loads on
  # `cd` (and unloads on leave). nix-direnv adds fast, cached `use flake` support
  # and keeps the built devshell from being garbage-collected.
  #
  # With this enabled, entering a project that has a `.envrc` (e.g. the mod's
  # `use flake /etc/nixos/modules/devshells#mc`) makes JAVA_HOME, gradle and
  # NIX_LD_LIBRARY_PATH available automatically — so `idea-oss` and `./gradlew`
  # launched from that shell inherit the right environment.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # enableZshIntegration is on by default; listed here for clarity.
    enableZshIntegration = true;
  };
}
