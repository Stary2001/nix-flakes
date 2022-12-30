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
      modules = [ 
        (import ./hardware-configuration.nix)
        ({ inputs, lib, ... }: {
          boot.loader.grub.enable = true;
          boot.loader.grub.version = 2;
          boot.loader.grub.device = "/dev/sda";

          networking.hostName = "bernoulli";

          time.timeZone = "Europe/London";
          i18n.defaultLocale = "en_GB.UTF-8";
          console = {
            font = "Lat2-Terminus16";
            keyMap = "gb";
          };

          services.openssh.enable = true;
          system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;
          system.stateVersion = "22.11";
        })
      ];
    };
  };
}
