{
  description = "My NixOS (and Home Manager) Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    hyprland,
    nix-colors,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    nixosConfigurations = 
      let
        sys1 = "refrigeratarr";
        sys2 = "prodesk";
      in
    {
      ${sys1} = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [ ./nixos/${sys1}/configuration.nix ];
      };
      ${sys2} = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [ ./nixos/${sys2}/configuration.nix ];
      };
    };

    homeConfigurations =
      let
        user1 = "admin@refrigeratarr";
        user2 = "admin@prodesk";
      in
    {
      ${user1} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs hyprland nix-colors;};
        modules = [ ./home-manager/${user1+".nix"} ];
      };
      ${user2} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [ ./home-manager/${user2+".nix"} ];
      };
    };
  };
}
