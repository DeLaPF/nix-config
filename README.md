# My NixOS (and Home Manager) Configuration

## Install
`nixos-install --flake .#hostname`
`home-manager switch --flake .#username@hostname`

## Update
`sudo nixos-rebuild switch --flake .#hostname`
`home-manager switch --flake .#username@hostname`

## File Assertions (`nixos/modules/file-assertions.nix`)
(An attempt at a solution to the problem of secrets in nixos.)

I am not a fan of storing encrypted secrets in plainview (as occurs with sops/age).
It feels like there is somewhat of a consensus that nixos must be hermetic, thus all files
(including those containing secrets) must be managed by nix. But this isn't even true for sops/age,
since the private key used to encrypt everything is not managed by nix.
If sops/age rely on the non-hermetic machine environment, while still maintaining
a level of reasonable declarative-ness, why can't I do the same?

With `file-assertions` I can declare any number of files that are expected to exist (and where), and specify
whether them not existing should break the build or just warn (fatal = true or false).
These checks are handled at build time as they require access to files outside of the sandbox,
thus the result of the checks can be used during eval time, however than can be used for activation and run time.

### sysconfig
Basic example for wireguard, but can be extended to any config file.
- Create a local directory `/etc/nixos/sysconfig`:
    - `etc`
        - `wireguard`
            - `wg0.conf`
containing the instance's unique wireguard config.
- From `sysconfig` run `sudo stow -t / .` to add config to etc.
    - This can be undone with `sudo stow -D -t / .`
- Add a systemd.services.wg0 to handle startup of the tunnel automatically
- Or, alternatively, handle manually at runtime with `wg-quick <up|down> wg0`

## wg-quick
For mark isolated vpn routing:
- Disable DNS
- Add to Interface below Address (56910 is the name of the table, easiest to just name it after the listening port)
```
# Disable autrouting and create table for vpn
Table = off
PostUp = ip rule add fwmark $VPNONLY_FW_MARK table 56910
PostUp = ip route add 0.0.0.0/0 dev wg0 table 56910
```
- TODO: look into how to setup VPN DNS properly or use a non tracking provider for all
