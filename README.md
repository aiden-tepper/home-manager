## Aiden's Home Manager Configuration

### Installation

1) Install Determinate Nix:
```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

2) Initial setup (first time only):
```bash
# For macOS
nix run github:nix-community/home-manager -- switch --flake .#macbook

# For Arch Linux
nix run github:nix-community/home-manager -- switch --flake .#spectre
```

### Usage

This configuration supports multiple hosts:

#### macOS (aarch64-darwin)
```bash
home-manager switch --flake .#macbook
# or use the Makefile
make update              # defaults to macbook host
make update-macbook      # explicit target
```

#### Arch Linux (x86_64-linux)
```bash
home-manager switch --flake .#spectre
# or use the Makefile
make update HOST=spectre # override default host
make update-spectre      # explicit target
```

### Structure

- `common.nix` - Shared configuration for all hosts
- `hosts/macbook.nix` - macOS-specific configuration
- `hosts/spectre.nix` - Arch Linux-specific configuration
- `nvim.nix` - Neovim configuration
- `widgets.nix` - Custom shell widgets (weather, usage)

