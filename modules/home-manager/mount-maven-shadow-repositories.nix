{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.mountMavenShadowRepositories;
  script = pkgs.writeScriptBin "mount-maven-shadow-repositories.sh"
    (builtins.readFile ./mount-maven-shadow-repositories.sh);
  homeDir = config.home.homeDirectory;
  logPrefix = "${homeDir}/Library/Logs/tailscale";
in {
  options = {
    services.mountMavenShadowRepositories = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the mount-maven-shadow-repositories service.";
      };

      mountPoints = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of mount points for the shadowed repositories.";
      };

      scriptPath = mkOption {
        type = types.str;
        default = "${script}/bin/mount-maven-shadow-repositories.sh";
        description = "Path to the mount-maven-shadow-repositories script.";
      };
    };
  };

  config = mkIf cfg.enable {
    launchd.agents.mount-maven-shadow-repositories = {
      enable = true;
      config = {
        Label = "mount-maven-shadow-repositories";
        ProgramArguments = [ cfg.scriptPath ] ++ cfg.mountPoints;
        RunAtLoad = true;
        KeepAlive = true;
        EnvironmentVariables = {
          PATH = "/usr/sbin:${pkgs.coreutils}/bin:${pkgs.rsync}/bin:${pkgs.yq}/bin:$PATH";
        };
        StandardOutPath = "${logPrefix}-out.log";
        StandardErrorPath = "${logPrefix}-error.log";
      };
    };
  };
}
