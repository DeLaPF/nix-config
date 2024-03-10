# My NixOS (and Home Manager) Configuration

## Install
`nixos-install --flake .#hostname`
`home-manager switch --flake .#username@hostname`

## Update
`sudo nixos-rebuild switch --flake .#hostname`
`home-manager switch --flake .#username@hostname`
