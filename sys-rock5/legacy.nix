{ config, lib, pkgs, ...}:
{
  # Rock5 stuff
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.consoleLogLevel = lib.mkDefault 7;

  # End Rock5 stuff

  nine_net = {
    enable = true;
    ipv4_address = "172.31.0.5";
  };

  # IoT WiFi config
  services.hostapd = {
    enable = true;
    interface = "wlan0";
    ssid = "iot";
    wpa = true;
    countryCode = "GB";
    channel = 6;
    
    extraConfig = ''
      bridge=br0
      wpa_psk_file=/nix/persist/etc/hostapd-psk
      wpa_pairwise=TKIP CCMP

      #ht_capab=[HT40-][DSSS_CCK-40][SHORT-GI-20]
      ht_capab=[SHORT-GI-20]

      ieee80211n=1
    '';
  };
  
  services.zerotierone.joinNetworks = [ "8b9c961d1ddf236e" ];
  networking.bridges."br0" = { interfaces = [ "zts2ausptt" ]; };

  systemd.network.networks."bridge" = {
    name = "br0";
    address = [ "172.30.0.1/24" ];

    networkConfig = {
      DHCPServer = true;
      IPMasquerade = "ipv4";
    };
    
    dhcpServerConfig = {
      PoolOffset = 10;
      PoolSize = 200;
      EmitDNS = true;
      DNS = "8.8.8.8";
    };

    dhcpServerStaticLeases = [
      {
        dhcpServerStaticLeaseConfig = {
          MACAddress = "70:88:6b:14:9f:5c";
          Address = "172.30.0.2";
        };
      }
    ];
  };
}
