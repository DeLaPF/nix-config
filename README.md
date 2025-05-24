# My NixOS (and Home Manager) Configuration

## Install
`nixos-install --flake .#hostname`
`home-manager switch --flake .#username@hostname`

## Update
`sudo nixos-rebuild switch --flake .#hostname`
`home-manager switch --flake .#username@hostname`

## File Assertions (`nixos/modules/file-assertions.nix`)
An attempt at a solution to the problem of secrets in nixos.
I am not a fan of storing encrypted secrets in plainview (as occurs with sops/age).
It feels like there is somewhat of a consensus that nixos must be hermetic, thus all files
(including those containing secrets) must be managed by nix. But this isn't event true for sops/age,
since the private key used to encrypt everything is not managed by nix.
If sops/age rely on the non-hermetic machine environment, while still maintaining
a level of reasonable declarative-ness, why can't I do the same?
I can declare any number of files that expected to exist (and where), and specify
whether them not existing should break the build (fatal/assert) or just warn.
This feels like it could be an ok solution for secrets (could be better to support sops/age for encryption as well)
and a very good solution for instance specify config (relating to the unique setup of a given machine from a shared config)
like ssh keys, and wireguard configuration

This solution could arguably be made better by requiring hashes for the files that can be checked against.

### sysconfig
Basic example for wireguard, but can be extended to any config file.
Create a local directory `/etc/nixos/sysconfig`:
- `etc`
 - `wireguard`
  - `wg0.conf`
containing the instance's unique wireguard config.
From `sysconfig` run `sudo stow -t / .` to add config to etc.
This can be undone with `sudo stow -D -t / .`
