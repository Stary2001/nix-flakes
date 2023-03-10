{ ... } : 
{
  fileSystems."/srv/http/9net.org/user-stary" =
    { device = "/home/stary/www";
      fsType = "none";
      options = [ "bind" ];
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "stary2001.co.uk" = { enableACME = true; forceSSL = true; };

      "9net.org" = {
        enableACME = true; forceSSL = true;
	serverAliases = ["www.9net.org"];
        
        root = "/data/http/";

        locations."= /".return = "302 https://stary.zone/";
        locations."/.well-known/keybase.txt".root = "/data/http";

        locations."~ ^/~(.+?)(/.*)?$" = {
          alias = "/srv/http/9net.org/user-$1/$2";
          extraConfig = "autoindex on;";
        };

        locations."/_matrix" = {
          proxyPass = "http://172.31.0.1:8008";
          extraConfig = "access_log off;";
        };
      };

      "matrix" = {
        enableACME = true; forceSSL = true;
	serverName = "9net.org";
        locations."/".proxyPass = "http://172.31.0.1:8008";
        listen = [
          { addr = "0.0.0.0"; port = 8448; ssl = true; }
          { addr = "[::]"; port = 8448; ssl = true; }
        ];
      };

      "api.9net.org" = {
        enableACME = true; addSSL = true;
        locations."/".proxyPass = "http://172.31.0.1:6969";
      };

      "bernoulli.9net.org" = { enableACME = true; forceSSL = true; };

      "blog.9net.org" = {
        enableACME = true; addSSL = true;
        locations."/2019/10/godot/".return = "301 https://stary.zone/blog/godot/";
        locations."/".return = "301 https://stary.zone/blog/";
      };

      "parts.9net.org" = {
        enableACME = true; forceSSL = true;
        # TODO, inventree uses a unix socket.
      };

      "git.9net.org" = {
        enableACME = true; forceSSL = true;
        locations."/".proxyPass = "http://172.31.0.70/";
        extraConfig = "client_max_body_size 1g;";
      };

      "git-registry.9net.org" = {
        enableACME = true; forceSSL = true;
        locations."/".proxyPass = "http://172.31.0.70:5005/";
        extraConfig = "client_max_body_size 1g;";
      };

      "grafana.9net.org" = {
        enableACME = true; forceSSL = true;
        locations."/".proxyPass = "http://172.31.0.1:3000/";
      };

      "hass.9net.org" = {
        enableACME = true; forceSSL = true;

        locations."/" = {
          proxyPass = "http://172.31.0.223:8123";
          proxyWebsockets = true;
          extraConfig = "proxy_buffering off;";
        };
      };

      "influx.9net.org" = {
        enableACME = true; forceSSL = true;
        locations."/".proxyPass = "http://172.31.0.1:8086/";
      };

      "sono.9net.org" = {
        # TODO complex site

        enableACME = true; forceSSL = true;
        root = "/data/http-sono";
      };

      "zerotier.9net.org" = {
        enableACME = true; forceSSL = true;
        locations."/".proxyPass = "http://172.31.0.1:4000/";
      };

      "znc.9net.org" = {
        enableACME = true; forceSSL = true;
        locations."/".proxyPass = "http://172.31.0.1:1338/";
      };

      "bethel.me.uk" = {
        enableACME = true; forceSSL = true;
        root = "/srv/http/bethel.me.uk";
      };

      "ezekiel.bethel.me.uk" = {
        # Deprecated
        enableACME = true; forceSSL = true;
        globalRedirect = "chloe.bethel.me.uk";
      };

      "chloe.bethel.me.uk" = {
        enableACME = true; forceSSL = true;
        root = "/srv/http/chloe.bethel.me.uk";
      };

      "chloe.science" = {
        enableACME = true; forceSSL = true;
        root = "/srv/http/chloe.science";
      };

      "chloe-is.online" = {
        enableACME = true; forceSSL = true;
        root = "/srv/http/chloe-is.online";
      };

      "stary.zone" = {
        enableACME = true; forceSSL = true;
        root = "/srv/http/stary.zone";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "me@chloe-is.online";
    };

    certs = {
    };
  };

  services.oauth2_proxy = {
    enable = true;
    httpAddress = "http://0.0.0.0:4180";
    provider = "google";
    email = {
      addresses = "mctinfoilball@gmail.com";
    };

    keyFile = "/nix/persist/oauth2_proxy.secrets";
  };

  services.oauth2_proxy.nginx = {
    virtualHosts = [ "zerotier.9net.org" ];
  };
}
