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
    myKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJjUz1FruDlg5VNmvd4wi7DiXbMJcN4ujr8KtQ6OhlSc stary@pc"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+q372oe3sFtBQPAH93L397gYGYrjeGewzoOW97gSy1 stary@wheatley"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLg5nSbedQYRzm4BAU1OIYpaiTwP+afCAE3BvPcG7OI eddsa-key-20210602" # Windows VM
          ];
  in {
    nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [ 
        (import ./hardware-configuration.nix)
        (import ./legacy.nix)

        inputs.common.nixosModules.nine-net
        inputs.rock5b-nixos.nixosModules.kernel

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
          ];

          networking.firewall.allowedUDPPorts = [
            67 # dhcp
          ];

          time.timeZone = "Europe/London";
          i18n.defaultLocale = "en_GB.UTF-8";
          console = {
            font = "Lat2-Terminus16";
            keyMap = "uk";
          };

          services.openssh.enable = true;
          users.users.root.openssh.authorizedKeys.keys = myKeys;

          users.users.stary = {
            isNormalUser = true;
            createHome = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = myKeys;
          };

          system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;
          system.stateVersion = "22.11";
        })
      ];
    };
  };
}