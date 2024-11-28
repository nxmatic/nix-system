{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mountMavenShadowRepositories;
  script = pkgs.writeScriptBin "mount-maven-shadow-repositories.sh" (builtins.readFile ./scripts/mount-maven-shadow-repositories.sh);
in
{
  options = {
    services.mountMavenShadowRepositories = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the mount-maven-shadow-repositories service.";
      };

      mountPoints = mkOption {
        type = types.listOf types.str;
        default = [];
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
    # Use nix-darwin to manage the launchd service
    services.launchd.jobs.mount-maven-shadow-repositories = {
      enable = true;
      program = cfg.scriptPath;
      programArguments = cfg.mountPoints;
      runAtLoad = true;
      keepAlive = true;
      environment = {
        PATH = "/usr/sbin:${pkgs.rsync}/bin:${pkgs.yq}/bin:$PATH";
      };
      user = "root";  # Run the job with root privileges
    };
  };
}