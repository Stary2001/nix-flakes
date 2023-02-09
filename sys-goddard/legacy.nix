{config, pkgs, ...}:
{
  nine_net = {
    enable = true;
    node_name = "stary_goddard";
    ipv4_address = "172.31.0.3";
  };

  #networking.nat.enable = true;
  #networking.nat.internalInterfaces = ["ve-+"];
  #networking.nat.externalInterface = "ens3";

  #systemd.network.networks."40-veth" = {
  #  name = "ve-*";
  #  # Do nothing, hopefully
  #};

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "goddard.9net.org" =        { enableACME = true; forceSSL = true; };
      "flood.home.9net.org" =     { enableACME = true; forceSSL = true; locations."/".proxyPass = "http://172.31.1.7"; };
      "syncthing.home.9net.org" = { enableACME = true; forceSSL = true; locations."/".proxyPass = "http://172.31.1.7"; };
      "plex.home.9net.org" = {
        enableACME = true; addSSL = true;
        locations."/".proxyPass = "http://172.31.1.7:32400";

        extraConfig = ''
        gzip on;
        gzip_vary on;
        gzip_min_length 1000;
        gzip_proxied any;
        gzip_types text/plain text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
        gzip_disable "MSIE [1-6]\.";

        # Forward real ip and host to Plex
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        #When using ngx_http_realip_module change $proxy_add_x_forwarded_for to '$http_x_forwarded_for,$realip_remote_addr'
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Sec-WebSocket-Extensions $http_sec_websocket_extensions;
        proxy_set_header Sec-WebSocket-Key $http_sec_websocket_key;
        proxy_set_header Sec-WebSocket-Version $http_sec_websocket_version;

        # Websockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";

        # Buffering off send to the client as soon as the data is received from Plex.
        proxy_redirect off;
        proxy_buffering off;
        '';
      };
      "smokeping.home.9net.org" = {
        enableACME = true; forceSSL = true;
        locations."= /".return = "301 /smokeping.fcgi";
        locations."/".proxyPass = "http://172.31.1.7";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "chloe@9net.org";
    };

    certs = {
    };
  };

  users.users.oauth2_proxy.group = "oauth2_proxy";
  users.groups.oauth2_proxy = {};
  services.oauth2_proxy = {
    # clientID/clientSecret
    keyFile = "/nix/persist/oauth2_proxy.secrets";

    enable = true;
    httpAddress = "http://0.0.0.0:4180";
    provider = "google";
    nginx = {
      virtualHosts = [
        "flood.home.9net.org"
        "syncthing.home.9net.org"
        "smokeping.home.9net.org"
      ];
    };
    email = {
      addresses = "mctinfoilball@gmail.com";
    };
  };
}
