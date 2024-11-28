{ pkgs, ... }: let

  dollar = "$";

  path = pkgs.writeScript "flox-direnv-rc.sh" (builtins.readFile ./flox-direnv-rc.sh);

in {
  programs.direnv = {

    stdlib = ''
      export FLOX_RCPATH="${path}"
    '';
  };
}
