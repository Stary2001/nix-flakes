{
  description = "system configuration for bernoulli";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [ ({ inputs, lib, ... }: {
        system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;
        system.stateVersion = "22.11";
      }) ];
    };
  };
}
