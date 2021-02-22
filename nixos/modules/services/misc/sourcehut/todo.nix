{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.sourcehut;
  cfgIni = cfg.settings;
  scfg = cfg.todo;
  iniKey = "todo.sr.ht";

  rcfg = config.services.redis;
  drv = pkgs.sourcehut.todosrht;
in
{
  options.services.sourcehut.todo = {
    user = mkOption {
      type = types.str;
      default = "todosrht";
      description = ''
        User for todo.sr.ht.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 5003;
      description = ''
        Port to run the "todo" module on.
      '';
    };

    database = mkOption {
      type = types.str;
      default = "todo.sr.ht";
      description = ''
        PostgreSQL database name for todo.sr.ht.
      '';
    };

    statePath = mkOption {
      type = types.path;
      default = "${cfg.statePath}/todosrht";
      description = ''
        State path for todo.sr.ht.
      '';
    };
  };

  config = with scfg; lib.mkIf (cfg.enable && elem "todo" cfg.services) {
    users = {
      users = {
        "${user}" = {
          group = user;
          description = "meta.sr.ht user";
        };
      };
      groups = {
        "${user}" = { };
      };
    };

    services.postgresql = {
      authentication = ''
        local ${database} ${user} trust
      '';
      ensureDatabases = [ database ];
      ensureUsers = [
        {
          name = user;
          ensurePermissions = { "DATABASE \"${database}\"" = "ALL PRIVILEGES"; };
        }
      ];
    };

    systemd = {
      tmpfiles.rules = [
        "d ${statePath} 0750 ${user} ${user} -"
      ];

      services = {
        todosrht = import ./service.nix { inherit config pkgs lib; } scfg drv iniKey {
          after = [ "postgresql.service" "network.target" ];
          requires = [ "postgresql.service" ];
          wantedBy = [ "multi-user.target" ];

          description = "todo.sr.ht website service";

          script = "${cfg.python}/bin/gunicorn ${drv.pname}.app:app -b ${cfg.address}:${toString port}";
        };

        todosrht-webhooks = {
          after = [ "postgresql.service" "network.target" ];
          requires = [ "postgresql.service" ];
          wantedBy = [ "multi-user.target" ];

          description = "todo.sr.ht webhooks service";
          serviceConfig = {
            Type = "simple";
            User = user;
            Restart = "always";
          };

          script = "${cfg.python}/bin/celery -A ${drv.pname}.webhooks worker --loglevel=info";
        };
      };
    };

    services.sourcehut.settings = {
      # URL todo.sr.ht is being served at (protocol://domain)
      "todo.sr.ht".origin = mkDefault "http://todo.${cfg.originBase}";
      # Address and port to bind the debug server to
      "todo.sr.ht".debug-host = mkDefault "0.0.0.0";
      "todo.sr.ht".debug-port = mkDefault port;
      # Configures the SQLAlchemy connection string for the database.
      "todo.sr.ht".connection-string = mkDefault "postgresql:///${database}?user=${user}&host=/var/run/postgresql";
      # Set to "yes" to automatically run migrations on package upgrade.
      "todo.sr.ht".migrate-on-upgrade = mkDefault "yes";
      # todo.sr.ht's OAuth client ID and secret for meta.sr.ht
      # Register your client at meta.example.org/oauth
      "todo.sr.ht".oauth-client-id = mkDefault null;
      "todo.sr.ht".oauth-client-secret = mkDefault null;
      # Outgoing email for notifications generated by users
      "todo.sr.ht".notify-from = mkDefault "CHANGEME@example.org";
      # The redis connection used for the webhooks worker
      "todo.sr.ht".webhooks = mkDefault "redis://${rcfg.bind}:${toString rcfg.port}/1";
      # Network-key
      "todo.sr.ht".network-key = mkDefault null;

      # Path for the lmtp daemon's unix socket. Direct incoming mail to this socket.
      # Alternatively, specify IP:PORT and an SMTP server will be run instead.
      "todo.sr.ht::mail".sock = mkDefault "/tmp/todo.sr.ht-lmtp.sock";
      # The lmtp daemon will make the unix socket group-read/write for users in this
      # group.
      "todo.sr.ht::mail".sock-group = mkDefault "postfix";

      "todo.sr.ht::mail".posting-domain = mkDefault "todo.${cfg.originBase}";
    };

    services.nginx.virtualHosts."todo.${cfg.originBase}" = {
      forceSSL = true;
      locations."/".proxyPass = "http://${cfg.address}:${toString port}";
      locations."/query".proxyPass = "http://${cfg.address}:${toString (port + 100)}";
      locations."/static".root = "${pkgs.sourcehut.todosrht}/${pkgs.sourcehut.python.sitePackages}/todosrht";
    };
  };
}
