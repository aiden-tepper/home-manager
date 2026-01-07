{ config, pkgs, ... }:

{
  imports = [ ../common.nix ];

  home = {
    username = "aiden";
    homeDirectory = "/home/aiden";
  };

  fonts.fontconfig.enable = true;

  # programs.noctalia-shell = {
  #   enable = true;
  # };

  programs.caelestia = {
    enable = true;
  };
  #   systemd = {
  #     enable = true;
  #     target = "graphical-session.target";
  #     environment = [ ];
  #   };
  #   settings = {
  #     bar.status.showBattery = true;
  #   };
  #   cli = {
  #     enable = true;
  #     settings = {
  #       theme.enableGtk = true;
  #     };
  #   };
  # };

  home.packages = with pkgs; [
    kitty
    # waybar
    rofi
    swww
    dunst
    # nerd-fonts.fira-code
    # nerd-fonts.jetbrains-mono
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hyprland.conf;
  # home.file.".config/caelestia/hypr-user.conf".source = ../dotfiles/hyprland.conf;
}
