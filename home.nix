{ lib, pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      cbonsai
    ];

    username = "localaiden";
    homeDirectory = "/Users/localaiden";

    # You do not need to change this if you're reading this in the future.
    # Don't ever change this after the first build.  Don't ask questions.
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;

  programs.lazygit.enable = true;
  programs.bat.enable = true;
  programs.fd.enable = true;

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.git = {
    enable = true;
    settings.user.name = "Aiden Tepper";
    settings.user.email = "aidenjtep@gmail.com";
  };
}
