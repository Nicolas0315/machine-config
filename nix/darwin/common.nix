{ pkgs, ... }:
{
  environment.systemPackages = import ../packages.nix { inherit pkgs; };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  programs.zsh.enable = true;

  system.defaults = {
    NSGlobalDomain.AppleShowAllExtensions = true;
    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };
  };

  system.stateVersion = 6;
}
