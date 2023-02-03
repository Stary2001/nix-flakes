{
  description = "system configuration for bernoulli";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
        (import ./persist.nix)
        (import ./nginx.nix)

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

          users.users.remote-builder = {
            isNormalUser = true;
            openssh.authorizedKeys.keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCsQ7jQV3LpsQ6p2FQe0CQslBgt1p5YrPqQddsVylHzd2gniqcZFmJnzg29kiUMslNXzcxLF0JCE7JGItcCttbjpkPDgepKdkQkS49jo0wgW4It5mCT/FM3nGm16Z0Uk0G9U/WCAccpAANRLTGZhlFjVhVgNyIbL3AYXtC/sOTVcyp3rDaBQS8mc8M+eTIV88yOL7t3ZNWkgWV3nqj03JCSTtaerAa06L+mMXeolLfWLi29u6z9ECVpo3sWAMMuuyrLd/jtTpJo47SJoVtUJq6NKoc4iYZojf+bR5S4Rwn7L5bF4BUpAm7ooI8me8YbB2AchNEwAB6CYh8J4VJZsGZWVTR16Q3xuxAqc/nDd/7MkgNA/OAc6Ka+bvyjTDLuIBGKaVm9MrwfEgJNSjGogjA4Mtlaxy3vLtiTDR8R/xgL43K75l0PBT/a9/Vgat+zyFs/lBXaOw9PID7xgo9rh8Ba7YQpC8Q+L00A3vcpAvIMmiU8z9PVH21zPNhwi1NLCsM= stary@goddard"];
          };

          system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;
          system.stateVersion = "22.11";
        })
      ];
    };
  };
}
