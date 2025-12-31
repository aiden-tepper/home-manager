{ config, pkgs, ... }:

{
  imports = [ ../common.nix ];

  home = {
    username = "localaiden";
    homeDirectory = "/Users/localaiden";
  };
}
