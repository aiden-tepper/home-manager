## Aiden's Home Manager Configuration

### Installation

1) Install Determinate Nix:
```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

### Usage

This configuration supports multiple hosts:

#### macOS (aarch64-darwin)
```bash
home-manager switch --flake .#macbook
# or use the Makefile
make update
```

#### Arch Linux (x86_64-linux)
```bash
home-manager switch --flake .#spectre
```

### Structure

- `common.nix` - Shared configuration for all hosts
- `hosts/macbook.nix` - macOS-specific configuration
- `hosts/spectre.nix` - Arch Linux-specific configuration
- `nvim.nix` - Neovim configuration
- `widgets.nix` - Custom shell widgets (weather, usage)

