{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.sourcehut;
  scfg = cfg.builds;
  rcfg = config.services.redis;
  iniKey = "builds.sr.ht";

  drv = pkgs.sourcehut.buildsrht;
in
{
  options.services.sourcehut.builds = {
    user = mkOption {
      type = types.str;
      default = "buildsrht";
      description = ''
        User for builds.sr.ht.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 5002;
      description = ''
        Port to run the "builds" module on.
      '';
    };

    database = mkOption {
      type = types.str;
      default = "builds.sr.ht";
      description = ''
        PostgreSQL database name for builds.sr.ht.
      '';
    };

    statePath = mkOption {
      type = types.path;
      default = "${cfg.statePath}/buildsrht";
      description = ''
        State path for builds.sr.ht.
      '';
    };

    enableWorker = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Run workers for builds.sr.ht.
        Perform manually on machine: `cd ${scfg.statePath}/images; docker build -t qemu -f qemu/Dockerfile .`
      '';
    };

    images = mkOption {
      type = types.attrsOf (types.attrsOf (types.attrsOf types.package));
      default = { };
      example = lib.literalExample ''(let
          # Pinning unstable to allow usage with flakes and limit rebuilds.
          pkgs_unstable = builtins.fetchGit {
              url = "https://github.com/NixOS/nixpkgs";
              rev = "ff96a0fa5635770390b184ae74debea75c3fd534";
              ref = "nixos-unstable";
          };
          image_from_nixpkgs = pkgs_unstable: (import ("${pkgs.sourcehut.buildsrht}/lib/images/nixos/image.nix") {
            pkgs = (import pkgs_unstable {});
          });
        in
        {
          nixos.unstable.x86_64 = image_from_nixpkgs pkgs_unstable;
        }
      )'';
      description = ''
        Images for builds.sr.ht. Each package should be distro.release.arch and point to a /nix/store/package/root.img.qcow2.
      '';
    };



  };

  config = with scfg; let
    image_dirs = lib.lists.flatten (
      lib.attrsets.mapAttrsToList
        (distro: revs:
          lib.attrsets.mapAttrsToList
            (rev: archs:
              lib.attrsets.mapAttrsToList
                (arch: image:
                  pkgs.runCommandNoCC "buildsrht-images" { } ''
                    mkdir -p $out/${distro}/${rev}/${arch}
                    ln -s ${image}/*.qcow2 $out/${distro}/${rev}/${arch}/root.img.qcow2
                  '')
                archs)
            revs)
        scfg.images);
    image_dir_pre = pkgs.symlinkJoin {
      name = "builds.sr.ht-worker-images-pre";
      paths = image_dirs ++ [
        "${pkgs.sourcehut.buildsrht}/lib/images"
      ];
    };
    image_dir = pkgs.runCommandNoCC "builds.sr.ht-worker-images" { } ''
      mkdir -p $out/images
      cp -Lr ${image_dir_pre}/* $out/images
    '';
  in
  lib.mkIf (cfg.enable && elem "builds" cfg.services) {
    users = {
      users = {
        "${user}" = {
          group = user;
          extraGroups = if cfg.builds.enableWorker then [ "docker" ] else [ ];
          description = "builds.sr.ht user";
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
        "d ${statePath} 0755 ${user} ${user} -"
      ] ++ (lib.optionals cfg.builds.enableWorker
        [ "d ${statePath}/logs 0775 ${user} ${user} - -" ]
      );

      services = {
        buildsrht = import ./service.nix { inherit config pkgs lib; } scfg drv iniKey
          {
            after = [ "postgresql.service" "network.target" ];
            requires = [ "postgresql.service" ];
            wantedBy = [ "multi-user.target" ];

            description = "builds.sr.ht website service";

            serviceConfig.ExecStart = "${cfg.python}/bin/gunicorn ${drv.pname}.app:app -b ${cfg.address}:${toString port}";

            # Hack to bypass this hack: https://git.sr.ht/~sircmpwn/core.sr.ht/tree/master/item/srht-update-profiles#L6
          } // { preStart = " "; };

        buildsrht-worker = {
          enable = scfg.enableWorker;
          after = [ "postgresql.service" "network.target" ];
          requires = [ "postgresql.service" ];
          wantedBy = [ "multi-user.target" ];
          partOf = [ "buildsrht.service" ];
          description = "builds.sr.ht worker service";
          path = [ pkgs.openssh pkgs.docker ];
          serviceConfig = {
            Type = "simple";
            User = user;
            Group = "nginx";
            Restart = "always";
          };
          serviceConfig.ExecStart = "${pkgs.sourcehut.buildsrht}/bin/builds.sr.ht-worker";
        };
      };
    };


    services.sourcehut.settings = {
      # URL builds.sr.ht is being served at (protocol://domain)
      "builds.sr.ht".origin = mkDefault "http://builds.sr.ht.local";
      # Address and port to bind the debug server to
      "builds.sr.ht".debug-host = mkDefault "0.0.0.0";
      "builds.sr.ht".debug-port = mkDefault port;
      # Configures the SQLAlchemy connection string for the database.
      "builds.sr.ht".connection-string = mkDefault "postgresql:///${database}?user=${user}&host=/var/run/postgresql";
      # Set to "yes" to automatically run migrations on package upgrade.
      "builds.sr.ht".migrate-on-upgrade = mkDefault "yes";
      # builds.sr.ht's OAuth client ID and secret for meta.sr.ht
      # Register your client at meta.example.org/oauth
      "builds.sr.ht".oauth-client-id = mkDefault null;
      "builds.sr.ht".oauth-client-secret = mkDefault null;
      # The redis connection used for the celery worker
      "builds.sr.ht".redis = mkDefault "redis://${rcfg.bind}:${toString rcfg.port}/3";
      # The shell used for ssh
      "builds.sr.ht".shell = mkDefault "runner-shell";

      # Location for build logs, images, and control command
    } // lib.attrsets.optionalAttrs scfg.enableWorker {
      "builds.sr.ht::worker".name = mkDefault "runner.sr.ht.local";
      "builds.sr.ht::worker".buildlogs = mkDefault "${scfg.statePath}/logs";
      "builds.sr.ht::worker".images = mkDefault "${image_dir}/images";
      "builds.sr.ht::worker".controlcmd = mkDefault "${image_dir}/images/control";
      "builds.sr.ht::worker".timeout = mkDefault "3m";
    };

    services.nginx.virtualHosts."builds.${cfg.hostName}" = {
      forceSSL = true;
      locations."/".proxyPass = "http://${cfg.address}:${toString port}";
      locations."/query".proxyPass = "http://${cfg.address}:${toString (port + 100)}";
      locations."/static".root = "${pkgs.sourcehut.buildsrht}/${pkgs.sourcehut.python.sitePackages}/buildsrht";
    };
  };
}
