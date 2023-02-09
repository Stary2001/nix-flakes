{
  description = "system configuration for goddard";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    common.url = "github:stary2001/nix-flakes?dir=common";
    common.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        (import ./hardware-configuration.nix)
        (import ./legacy.nix)

        inputs.common.nixosModules.nine-net
        inputs.common.nixosModules.ssh-keys
        inputs.common.nixosModules.locale

        ({ inputs, lib, ... }: {
          nixpkgs.config.allowUnfree = true;

          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';

          networking = {
            useDHCP = false;

            hostName = "goddard"; # Define your hostname.
            hostId = "765a774a";

            useNetworkd = true;
            interfaces = {
              "ens3" = {
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
          ];

          # none (tm)
          networking.firewall.allowedUDPPorts = [
          ];

          networking.firewall.extraStopCommands = ''
            iptables -D nixos-fw -p tcp --source 172.31.0.6/32 --dport 4180 -j nixos-fw-accept || true
          '';

          networking.firewall.extraCommands = ''
            iptables -A nixos-fw -p tcp --source 172.31.0.6/32 --dport 4180 -j nixos-fw-accept
          '';

          services.openssh.enable = true;

          users.users.stary = {
            isNormalUser = true;
            createHome = true;
            extraGroups = [ "wheel" ];
          };

          system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;
          system.stateVersion = "21.11";
        })
      ];
    };
  };
}
