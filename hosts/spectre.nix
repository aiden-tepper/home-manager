{ config, pkgs, ... }:

{
  imports = [ ../common.nix ];

  home = {
    username = "aiden";
    homeDirectory = "/home/aiden";
  };

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    kitty
    waybar
    rofi
    swww
    dunst
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hyprland.conf;
}
