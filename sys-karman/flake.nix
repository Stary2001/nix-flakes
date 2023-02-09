{
  description = "system configuration for bernoulli";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    common.url = "github:stary2001/nix-flakes?dir=common";
  };

  outputs = inputs: let
    system = "x86_64-linux";
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
        inputs.common.nixosModules.ssh-keys inputs.common.nixosModules.avahi

        ({ inputs, lib, ... }: {
          nixpkgs.config.allowUnfree = true;

          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';

          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          boot.supportedFilesystems = [ "zfs" ];

          networking = {
            useDHCP = false;
            wireless.enable = true;

            hostName = "karman"; # Define your hostname.
            hostId = "3302c071";
          
            useNetworkd = true;
            interfaces = {
              "enp4s0" = {
                useDHCP = true;
              };

              "wlp0s20u2" = {
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

            111 2049 4000 4001 4002 20048 # nfsv3
            5357 # Samba WSDD
          ];

          networking.firewall.allowedUDPPorts = [
            111 2049 4000 4001 4002 20048 # nfsv3
            3702 # Samba WSDD
          ];

          time.timeZone = "Europe/London";
          i18n.defaultLocale = "en_GB.UTF-8";
          console = {
            font = "Lat2-Terminus16";
            keyMap = "uk";
          };

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
