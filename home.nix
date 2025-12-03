{ lib, pkgs, ... }:

{
  imports = [ ./widgets.nix ];

  home = {
    packages = with pkgs; [
      cbonsai lazygit bat fd
    ];

    username = "localaiden";
    homeDirectory = "/Users/localaiden";

    # You do not need to change this if you're reading this in the future.
    # Don't ever change this after the first build.  Don't ask questions.
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    functions = {
    r = ''
      for cmd in $history
        if test "$cmd" != "r"
          eval $cmd
          return
        end
      end
    '';
    };
    interactiveShellInit = "set fish_greeting"; # disable greeting
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableInteractive = true;
    settings = builtins.fromTOML (builtins.readFile ./dotfiles/starship.toml);
  };

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

  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
  };
  xdg.configFile."zellij/config.kdl".source = ./dotfiles/zellij/config.kdl;
  xdg.configFile."zellij/layouts".source = ./dotfiles/zellij/layouts;
}
