{ config, pkgs, lib, ... } :
with lib;
{
   options.nine_net = {
     enable = mkEnableOption "nine_net";
     node_name = mkOption {
       type = types.str;
       description = ''
         Node name to use for tinc.
       '';
     };
     ipv4_address = mkOption {
       type = types.str;
       description = ''
         IPv4 address to use for tinc.
       '';
     };
   };

   config = mkIf config.nine_net.enable {
    services.zerotierone = {
      enable = true;
      joinNetworks = [ "8b9c961d1de00107" ];
    };

    networking.bridges."9net-bridge" = { interfaces = [ "zts2axmha2" ]; };
    networking.interfaces."9net-bridge" = {
      ipv4 = {
        addresses = [ { address = "${config.nine_net.ipv4_address}"; prefixLength = 16; } ];
      };
    };

    # https://github.com/NixOS/nixpkgs/issues/30904
    systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
      "" # clear old command
      "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --any --ignore 9net-bridge"
    ];

    environment.systemPackages = [ pkgs.zerotierone ];
  };
}
