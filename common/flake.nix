{
  description = "system configuration for bernoulli";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };

  outputs = inputs: let
    system = "x86_64-linux";
  in {
      nixosModules = {
        nine-net = {pkgs, ...}: {
          imports = [./9net.nix];
        };
      };
  };
}
