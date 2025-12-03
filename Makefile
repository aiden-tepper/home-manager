.PHONY: update
update:
	home-manager switch --flake .#aiden

.PHONY: clean
clean:
	nix-collect-garbage -d
