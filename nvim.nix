{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
  };

  # symlink ~/.config/home-manager/dotfiles/nvim -> ~/.config/nvim
  xdg.configFile."nvim".source = ./dotfiles/nvim;

  # runtime dependencies
  home.packages = with pkgs; [
    # tools
    ripgrep
    fd
    lazygit
    gcc
    fzf
    tree-sitter
    luarocks

    # LSPs
    lua-language-server
    typescript-language-server
    bash-language-server
    vscode-langservers-extracted
    taplo
    ruff
    clang-tools
    nixd

    # formatters
    stylua
    prettierd
    rustfmt
    kdlfmt
    shfmt
    nixfmt
  ];
}
