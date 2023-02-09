{
  description = "system configuration for rock5";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    common.url = "github:stary2001/nix-flakes?dir=common";
    rock5b-nixos.url = "github:aciceri/rock5b-nixos";
  };

  outputs = inputs: let
    system = "aarch64-linux";
  in {
    nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [ 
        (import ./hardware-configuration.nix)
        (import ./legacy.nix)
        (import ./asterisk.nix)

        inputs.common.nixosModules.nine-net
        inputs.common.nixosModules.ssh-keys
        inputs.rock5b-nixos.nixosModules.kernel
        inputs.common.nixosModules.locale

        ({ inputs, lib, ... }: {
          nixpkgs.config.allowUnfree = true;

          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';

          networking = {
            useDHCP = false;

            hostName = "rock5"; # Define your hostname.
            hostId = "b8f50e18";
          
            useNetworkd = true;
            interfaces = {
              "enP4p65s0" = {
                useDHCP = true;
              };
            };

            nameservers = [ "8.8.8.8" ];
          };

          networking.firewall.enable = true;
          networking.firewall.allowedTCPPorts = [
            22 # ssh
            80 # http
            443 # https
            5355 # llmnr
            5201 # iperf

            5060 # sip
          ];

          networking.firewall.allowedUDPPorts = [
            67 # dhcp
            5060 # sip udp
          ];

          services.openssh.enable = true;

          users.users.stary = {
            isNormalUser = true;
            createHome = true;
            extraGroups = [ "wheel" ];
          };

          system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;
          system.stateVersion = "22.11";
        })
      ];
    };
  };
}
