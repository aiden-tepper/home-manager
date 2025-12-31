.PHONY: update
update:
	home-manager switch --flake .#macbook

.PHONY: clean
clean:
	nix-collect-garbage -d
