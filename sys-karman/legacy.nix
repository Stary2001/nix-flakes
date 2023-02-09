{config, pkgs, ...}:
let customSmartdNotify = pkgs.writeScript "smartd-notify.sh" ''
      #! ${pkgs.runtimeShell}
      {
      ${pkgs.coreutils}/bin/cat << EOF
      From: smartd on ${config.networking.hostName} <automated@9net.org>
      To: Chloe <chloe@9net.org>
      Subject: $SMARTD_SUBJECT
      $SMARTD_FULLMESSAGE
      EOF
      ${pkgs.smartmontools}/sbin/smartctl -a -d "$SMARTD_DEVICETYPE" "$SMARTD_DEVICE"
      } | /run/wrappers/bin/sendmail -i "chloe@9net.org"
  '';
in
{
  imports = [ ];

  fileSystems."/".options = [ "defaults" "size=2G" "mode=755" ];

  nine_net = {
    enable = true;
    node_name = "stary_nas";
    ipv4_address = "172.31.1.7";
  };

  boot.initrd.network.ssh = {
    enable = true;
    hostKeys = [ "/etc/nixos/config/secrets/ssh_host_rsa_key" "/etc/nixos/config/secrets/ssh_host_ed25519_key" ];
  };

  boot.extraModulePackages = [
    # crap usb wifi
    config.boot.kernelPackages.rtl88x2bu
  ];

  boot.kernel.sysctl = {
    # https://docs.syncthing.net/users/faq.html#inotify-limits
    # Add more inotify watches.

    "fs.inotify.max_user_watches" = 204800;
  };

  services.smokeping = {
    enable = true;
    hostName = "192.168.0.71";
    host = null;

    targetConfig = ''
      probe = FPing
      menu = Top
      title = Network Latency Grapher
      remark = Welcome to the SmokePing website of hacking society. \
               Here you will learn all about the latency of our network.

      + GoogleDNS
      menu = Google DNS
      title = Google DNS 8.8.8.8
      host = 8.8.8.8

      + Local
      menu = Local
      title = Router
      host = 192.168.0.1
    '';
  };

  services.syncthing = {
    enable = true;
    overrideDevices = false;
    overrideFolders = false;

    dataDir = "/data/syncthing";

    openDefaultPorts = true;
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /export 192.168.0.65(rw,fsid=0,no_subtree_check)
      /export/syncthing 192.168.0.65(rw,nohide,insecure,no_subtree_check)
      /export/media 192.168.0.65(rw,nohide,insecure,no_subtree_check)
    '';
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
  };

  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["ve-+"];
  networking.nat.externalInterface = "enp4s0";

  networking.nat.extraCommands = ''
    iptables -t nat -A nixos-nat-pre -p tcp -d 172.31.1.7 --dport 3000 -j DNAT --to 10.0.0.2:3000
  '';

  systemd.network.networks."40-veth" = {
    name = "ve-*";
    # Do nothing, hopefully
  };

  containers.torrent = {
    autoStart = true;

    privateNetwork = true;
    hostAddress = "10.0.0.1";
    localAddress = "10.0.0.2";

    bindMounts = {
      "/var/lib/rtorrent" = {
        hostPath = "/var/lib/rtorrent";
        isReadOnly = false;
      };

      "/data/rtorrent" = {
        hostPath = "/data/rtorrent";
        isReadOnly = false;
      };

     "/var/lib/flood" = {
        hostPath = "/var/lib/flood";
        isReadOnly = false;
      };

      "/etc/wireguard/mullvad.key" = {
        hostPath = "/etc/wireguard/mullvad.key";
        isReadOnly = true;
      };
    };

    config = {
      imports = [ ./container-torrent.nix ];
    };
  };

  services.vnstat.enable = true;

  services.zfs.autoSnapshot.enable = true;
  services.zfs.autoScrub.enable = true;

  users.users.stary.extraGroups = [ "libvirtd" ];
   virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";

    #qemu.ovmf.package = pkgs.OVMF.override { secureBoot = true; tpmSupport = true; };
    #qemu.swtpm.enable = true;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "karman.9net.org" = { default = true; };
      "172.31.1.7" = { locations."/" = { root = "/data/misc/web"; extraConfig = "autoindex on;"; }; };
      "flood.home.9net.org" = { locations."/" = { proxyPass = "http://10.0.0.2:3000"; extraConfig = "allow 172.31.0.3; deny all;"; }; };

      # security: "dude trust me"
      "syncthing.home.9net.org" = {
        locations."/" = {
          extraConfig = ''
            proxy_set_header Host localhost;
            proxy_pass http://localhost:8384;
            allow 172.31.0.3;
            deny all;
          '';
        };
      };

      "smokeping.home.9net.org" = { locations."/" = { proxyPass = "http://localhost:8081"; extraConfig = "allow 172.31.0.3; deny all;"; }; };
    };
  };

  services.plex = {
    enable = true;
    openFirewall = true;
  };

  services.samba-wsdd = {
    enable = true;
    interface = "enp4s0";
    hostname = "karman";
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    
    shares = {
      data = {
        path = "/data";
        browseable = "yes";
        "guest ok" = "no";
        writeable = "yes";
        "create mask" = "0644";
  "directory mask" = "0755";
        comment = "big data";
  "valid users" = "stary";
      };
    };
  };

  programs.ssh.forwardX11 = true;
  services.openssh.forwardX11 = true;

  services.smartd = {
    enable = true;
    # Workaround for stock smartctl not including To in its emails...
    # TODO: PR?
    notifications.mail.enable = false;
    notifications.wall.enable = false;
    notifications.x11.enable = false;
    defaults.monitored = "-m <nomailer> -M exec ${customSmartdNotify}";
  };

  programs.msmtp = {
    enable = true;
    accounts.default = {
      auth = true;
      tls = true;
      tls_starttls = true;
      host = "mail9.mymailcheap.com";
      port = 587;

      user = "automated@9net.org";
      from = "automated@9net.org";

      passwordeval = "${pkgs.coreutils}/bin/cat /etc/nixos/config/secrets/email-password.txt";
    };
  };

  # added on 22.11 upgrade
  security.polkit.enable = true;  
}