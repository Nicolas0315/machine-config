{ config, lib, pkgs, ... }:
{
  home.packages = import ../packages.nix { inherit pkgs; };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";
        pull.ff = "only";
      };
    };
    starship.enable = true;
    zoxide.enable = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.stateVersion = "25.11";
}
