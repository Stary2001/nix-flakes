{
  description = "system configuration for bernoulli";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    common.url = "github:stary2001/nix-flakes?dir=common";
  };

  outputs = inputs: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [ 
        (import ./hardware-configuration.nix)
        (import ./persist.nix)
        (import ./nginx.nix)

        inputs.common.nixosModules.ssh-keys
        inputs.common.nixosModules.locale

        ({ inputs, lib, ... }: {
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';

          boot.loader.grub.enable = true;
          boot.loader.grub.version = 2;
          boot.loader.grub.device = "/dev/sda";

          networking = {
            hostName = "bernoulli"; # Define your hostname.
            useNetworkd = true;

            defaultGateway = "172.31.0.1";
            interfaces = {
              enp6s18 = {
                ipv4.addresses = [ { address = "172.31.0.6"; prefixLength = 16; } ];
                ipv6.addresses = [ { address = "fd99:9999:9999::6"; prefixLength = 48; } ];
              };
            };

            nameservers = [ "8.8.8.8" ];
          };

          networking.firewall.enable = true;
          networking.firewall.allowedTCPPorts = [
            22 # ssh
            80 # http
            443 # https
            8448 # matrix
          ];

          # none (tm)
          networking.firewall.allowedUDPPorts = [
          ];

          services.openssh.enable = true;

          users.users.stary = {
            isNormalUser = true;
            createHome = true;
            extraGroups = [ "wheel" ];
          };

          users.users.remote-builder = {
            isNormalUser = true;
            openssh.authorizedKeys.keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZ5oA4xKTGRKwQBixd+lvkH5aRAIuLzjd2UzjOb/ZtAI1U+JFYMEF2WzjSXKSVb2j8P7+qU/KtoidumMoV/2gcb7aZ1BLJGOnLTASUPaX4zCmY/GBDDYwkJ4vCLYlU7jhVUdFSJzZEtxN3PYa0wFE0lOITyUOWOgRpzXA2QNmkInfnc0wj4ElbybAgvGX9kpVJPvgOnqIZvfsxJ3UfPHDo1AfXgPX0chpY79sBMuaMFfd9NFQU12+H4S5aU4ZX07UkXG0S9z0XapLATyBSs21hsX/18ARu+11CA3ppKjn+8pVuxvYwzGbs51GmH6RXOjHRYuGXXFPlN7Y7t73wGegypQWBJSZgDrfHTwNQ6WAyBjX8X6wT2U76WH99p7O75/K99cOMZMDjGJfORJzCXZ7eXqb08pdcBcQ/x09Hm5D7GFiGEDNQAFrR0FpKdgHaKovVgkIKTmFVHXEjGmzDMxX+YK5wiGriNQ+Z4Mvw47zMXt6Aq5upg+Ueo4Rzmcm29FU= root@goddard"];
          };

          system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;
          system.stateVersion = "22.11";
        })
      ];
    };
  };
}
