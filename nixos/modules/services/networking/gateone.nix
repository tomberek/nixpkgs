{ config, lib, pkgs, ...}:
with lib;
let
  cfg = config.services.gateone;
in
{
options = {
    services.gateone = {
      enable = mkEnableOption "GateOne server";
      pidDir = mkOption {
        default = "/run/gateone";
        type = types.path;
        description = ''Path of pid files for GateOne.'';
      };
      settingsDir = mkOption {
        default = "/var/lib/gateone";
        type = types.path;
        description = ''Path of configuration files for GateOne.'';
      };
    };
};
config = mkIf cfg.enable {
  environment.systemPackages = with pkgs.pythonPackages; [
    gateone pkgs.openssh pkgs.procps pkgs.coreutils pkgs.cacert pkgs.openssl];

  users.extraUsers.gateone = {
    description = "GateOne privilege separation user";
    uid = config.ids.uids.gateone;
    home = cfg.settingsDir;
  };
  users.extraGroups.gateone.gid = config.ids.gids.gateone;

  systemd.services.gateone = with pkgs; {
    description = "GateOne web-based terminal";
    path = [ pythonPackages.gateone nix openssh procps coreutils cacert openssl ];
    preStart = ''
      if [ ! -d ${cfg.settingsDir} ] ; then
        mkdir -m 0750 -p ${cfg.settingsDir}
        chown -R gateone.gateone ${cfg.settingsDir}
      fi
      if [ ! -d ${cfg.pidDir} ] ; then
        mkdir -m 0750 -p ${cfg.pidDir}
        chown -R gateone.gateone ${cfg.pidDir}
      fi
      '';
    environment = { SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt"; };
    serviceConfig = {
      ExecStart = ''${pythonPackages.gateone}/bin/gateone --settings_dir=${cfg.settingsDir} --pid_file=${cfg.pidDir}/gateone.pid --gid=${toString config.ids.gids.gateone} --uid=${toString config.ids.uids.gateone}'';
      User = "gateone";
      Group = "gateone";
      WorkingDirectory = cfg.settingsDir;
    };

    wantedBy = [ "multi-user.target" ];
    requires = [ "network.target" ];
  };
};
}
  
