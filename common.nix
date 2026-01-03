{ pkgs, ... }:

{
  imports = [
    ./widgets.nix
    ./nvim.nix
  ];

  home = {
    packages = with pkgs; [
      cbonsai
      lazygit
      bat
      fd
      ripgrep
      devcontainer
      rust-analyzer
      github-copilot-cli
      cowsay
      docker
      docker-credential-helpers
      gnumake
      less
      openssh
      mesa
    ];

    # You do not need to change this if you're reading this in the future.
    # Don't ever change this after the first build.  Don't ask questions.
    stateVersion = "25.11";
  };

  nixpkgs.config.allowUnfree = true;

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
    interactiveShellInit = ''
      			set fish_greeting # disable greeting

      			# automatically start ssh-agent and add ssh key
      			if not set -q SSH_AUTH_SOCK
      				eval (ssh-agent -c)
      				ssh-add ~/.ssh/id_ed25519 2>/dev/null
      			end
      		'';
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
    settings.url."git@github.com:".insteadOf = "https://github.com/";
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.zellij = {
    enable = true;
  };
  xdg.configFile."zellij/config.kdl".source = ./dotfiles/zellij/config.kdl;
  xdg.configFile."zellij/layouts".source = ./dotfiles/zellij/layouts;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
