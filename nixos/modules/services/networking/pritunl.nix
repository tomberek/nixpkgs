{ config, lib, pkgs, utils, ... }:
with lib;
let
  cfg = config.services.pritunl;
  stateDir = "/var/lib/pritunl";
in
{

  options = {
    services.pritunl.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether or not to enable the pritunl service";
    };

    services.pritunl.host_id = mkOption {
      type = types.string;
      default = "None";
      description = "Host ID";
    };

    services.pritunl.ssl = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable TLS";
    };

    services.pritunl.staticCache = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable TLS";
    };

    services.pritunl.port = mkOption {
      type = types.int;
      default = 9700;
      description = "The port to use for the web interface";
    };

    services.pritunl.pooler = mkOption {
      type = types.boolean;
      default = true;
      description = "Whether or not to use the pooler";
    };

    services.pritunl.tempDir = mkOption {
      type = types.str;
      default = "/tmp/pritunl_%r";
      description = "Where to store the temproray data";
    };

    services.pritunl.logDir = mkOption {
      type = types.str;
      default = "/var/log/pritunl.log";
      description = "Where to store log data";
    };

    services.pritunl.wwwDir = mkOption {
      type = types.str;
      default = "${pritunl}/lib/python2.7/site-packages/usr/share/pritunl/www";
      description = "Where to serve the web interface from";
    };

    services.pritunl.runDir = mkOption {
      type = types.str;
      default = "/var/run";
      description = "Where to to put run files";
    };

    services.pritunl.uuidPath = mkOption {
      type = types.str;
      default = "${stateDir}/pritunl.uuid";
      description = "Where to place this instance's UUITD";
    };

    services.pritunl.setupKeyPath = mkOption {
      type = types.str;
      default = "${stateDir}/setup_key";
      description = "Where to place this instance's setup key";
    };

    services.pritunl.bindAddr = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind to";
    };

    services.pritunl.mongodbURI = mkOption {
      type = types.str;
      default = "mongodb://localhost:27017/pritunl";
      description = "MongoDB URI";
    };

    services.pritunl.mongodbCollectionPrefix = mkOption {
      type = types.str;
      default = "None";
      description = "Prefix to use for pritunl collection";
    };

    services.pritunl.mongodbReadPreference = mkOption {
      type = types.str;
      default = "None";
      description = "MongoDB read prefrence";
    };

    services.pritunl.localAddressInterface = mkOption {
      type = types.str;
      default = "auto";
      description = "Local address interface to bind to";
    };

  };

  config = mkIf cfg.enable {

    users.users.pritunl = {
      uid = config.ids.uids.pritunl;
      description = "Pritunl daemon user";
      home = "${stateDir}";
    };

    systemd.services.pritunl = {
      description = "Pritunl daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      preStart = ''
        # Ensure privacy of state and data.
        chown pritunl -R "${stateDir}"
        chmod go-wrx -R "${stateDir}"
      '';

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pritunl}/bin/pritunl start -c ${pritunlConf}";
        User = "pritunl";
        PermissionsStartOnly = true;
        UMask = "0077";
        WorkingDirectory = "${stateDir}";
      };
    };
  };
}
