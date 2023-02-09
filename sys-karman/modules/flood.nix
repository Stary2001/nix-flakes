{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.flood;
in {
  options = {
    services.flood = {
      enable = mkEnableOption "flood";

      hostName = mkOption {
        type = types.str;
        description = "FQDN for the Flood instance.";
      };

      listen = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host to bind Flood to.";
      };

      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Port to bind Flood to.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.flood;
        defaultText = literalExpression "pkgs.nodePackages.flood";
        description = ''
          The Flood package to use.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "flood";
        description = ''
          User which runs the flood service.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "flood";
        description = ''
          Group which runs the flood service.
        '';
      };

      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/flood";
        description = "Storage path of flood.";
      };

      auth = mkOption {
        type = types.str;
        default = "default";
        description = "Type of authentication to use.";
      };

      rpcSocket = mkOption {
        type = types.str;
        default = config.services.rtorrent.rpcSocket;
        defaultText = "config.services.rtorrent.rpcSocket";
        description = ''
          Path to rtorrent rpc socket.
        '';
      };

      nginx = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable nginx virtual host management.
            Further nginx configuration can be done by adapting <literal>services.nginx.virtualHosts.&lt;name&gt;</literal>.
            See <xref linkend="opt-services.nginx.virtualHosts"/> for further information.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd = {
        services.flood = {
          description = "Flood system service";
          after = [ "network.target" ];
          path = [ "${pkgs.mediainfo}" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
            Type = "simple";
            Restart = "on-failure";
            WorkingDirectory = cfg.dataDir;
            ExecStart="${cfg.package}/bin/flood --host=${cfg.listen} --port=${toString cfg.port} --auth=${cfg.auth} --rtsocket=${cfg.rpcSocket}";
            RuntimeDirectory = "flood";
            RuntimeDirectoryMode = 755;
          };
        };
        tmpfiles.rules = [ "d '${cfg.dataDir}' 0775 ${cfg.user} ${cfg.group} -" ];
      };

      users.groups."${cfg.group}" = {};

      users.users = {
        "${cfg.user}" = {
          home = cfg.dataDir;
          group = cfg.group;
          extraGroups = [ config.services.rtorrent.group ];
          description = "Flood Daemon user";
          isSystemUser = true;
        };
        "${config.services.rtorrent.user}" = {
          extraGroups = [ cfg.group ];
        };
      };
    }

    (mkIf cfg.nginx.enable {
      services = {
          nginx = {
            enable = true;
            virtualHosts = {
              ${cfg.hostName} = {
                locations = {
                  "/" = {
                    extraConfig = ''
                      proxy_pass 'http://localhost:${toString cfg.port}';
                    '';
                  };
                };
              };
            };
          };
        };
      })
    ]);
}
