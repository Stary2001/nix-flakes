{config, pkgs, lib, ...}:
{
  disabledModules = [ "services/torrent/rtorrent.nix" ];
  imports = [ ../modules/rtorrent.nix ../modules/flood.nix ];

  environment.systemPackages = [ pkgs.rxvt_unicode.terminfo ];

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 3000 ];
  networking.firewall.allowedUDPPorts = [];

  networking.interfaces.eth0.ipv4.routes = [
    { address = "141.98.252.130"; prefixLength = 32; via = "10.0.0.1"; }
    { address = "172.31.0.0"; prefixLength = 16; via = "10.0.0.1"; }
  ];

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.65.107.17/32" "fc00:bbbb:bbbb:bb01::2:6b10/128" ];
      privateKeyFile = "/etc/wireguard/mullvad.key";
      peers = [
        { allowedIPs = [ "0.0.0.0/0" "::/0" ];
          publicKey  = "IJJe0TQtuQOyemL4IZn6oHEsMKSPqOuLfD5HoAWEPTY=";
          endpoint   = "141.98.252.130:51820"; }
      ];
    };
  };

  services.rtorrent = {
    enable = true;
    port = 56059; # port obtained via mullvad port forwarding
    dhtPort = 56431; # port obtained via mullvad port forwarding

    # yolo it
    useDHT = true;
    usePEX = true;
    useUDPTrackers = true;

    openFirewall = true;
    downloadDir = "/data/rtorrent/";

    configText = ''
      pieces.sync.always_safe.set=1
    '';
  };

  services.flood = {
    enable = true;
    listen = "0.0.0.0";
    hostName = "flood.home.9net.org";
    port = 3000;
    auth = "none";
  };

  systemd.services.rtorrent = {
    bindsTo = [ "wireguard-wg0.service" ];
    after = [ "wireguard-wg0.service" ];
  };

  systemd.services.resolvconf.enable = lib.mkForce false;
  systemd.services.hack-container-dns = {
    wantedBy = [ "network-online.target" ];
    description = "hack around container dns being bad";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 1 && echo \"nameserver 10.64.0.1\" > /etc/resolv.conf'";
      RemainAfterExit = "true";
    };
  };

  system.stateVersion = "21.11";
}
