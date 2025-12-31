{ config, pkgs, ... }:

{
  imports = [ ../common.nix ];

  home = {
    username = "aiden";
    homeDirectory = "/home/aiden";
  };
}
