dev_env() {
  nix develop /etc/nixos/modules/devshells#"$1" --command zsh
}
