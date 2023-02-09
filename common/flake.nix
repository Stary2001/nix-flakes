{
  description = "system configuration for bernoulli";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };

  outputs = inputs: let
    system = "x86_64-linux";
    myKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJjUz1FruDlg5VNmvd4wi7DiXbMJcN4ujr8KtQ6OhlSc stary@pc"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+q372oe3sFtBQPAH93L397gYGYrjeGewzoOW97gSy1 stary@wheatley"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLg5nSbedQYRzm4BAU1OIYpaiTwP+afCAE3BvPcG7OI eddsa-key-20210602" # Windows VM
    ];
  in {
      nixosModules = {
        nine-net = {pkgs, ...}: {
          imports = [./9net.nix];
        };
        avahi = {pkgs, ...}: {
          imports = [./avahi.nix];
        };
        ssh-keys = {pkgs, ...}: {
          users.users.root.openssh.authorizedKeys.keys = myKeys;
          users.users.stary.openssh.authorizedKeys.keys = myKeys;
        };
      };


  };
}
