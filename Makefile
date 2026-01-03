# Default host (can be overridden: make update HOST=macbook, or use explicit targets)
HOST ?= spectre

.PHONY: update
update:
	home-manager switch --flake .#$(HOST)

.PHONY: update-macbook
update-macbook:
	home-manager switch --flake .#macbook

.PHONY: update-spectre
update-spectre:
	home-manager switch --flake .#spectre

.PHONY: clean
clean:
	nix-collect-garbage -d
