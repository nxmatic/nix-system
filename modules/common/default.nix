{
  self,
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./primaryUser.nix
    ./nixpkgs.nix
    ./dnsmasq.nix
    ./qemu.nix
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
    };
  };

  user = {
    description = "Stephane Lacoin";
    home = "${
      if pkgs.stdenvNoCC.isDarwin
      then "/Users"
      else "/home"
    }/${config.user.name}";
    shell = pkgs.zsh;
  };

  # bootstrap home manager using system config
  hm = {
    imports = [
      ../home-manager
    ];
  };

  # let nix manage home-manager profiles and use global nixpkgs
  home-manager = {
    extraSpecialArgs = {inherit self inputs;};
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    backupFileExtension = "nix-backup";
  };

  # zen-browser = {
  #    enable = false;
  #    packages = pkgs.zen-browser-unwrapped;
  #  };

  # environment setup
  environment = {
    variables = {
      XDG_RUNTIME_DIR = "${config.user.home}/.xdg";
    };

    systemPackages = import ./system-packages.nix {
      inherit pkgs inputs config;
    };

    etc = {
      home-manager.source = "${inputs.home-manager}";
      nixpkgs.source = "${inputs.nixpkgs}";
    };

    # list of acceptable shells in /etc/shells
    shells = with pkgs; [bash zsh fish];
  };

  services.tailscale = {
    enable = true;
    #logDir = config.logDir or null; # Use the value of the logDir option, or null if it is not set
  };

  fonts = {
    packages = with pkgs; [powerline-fonts];
  };
}
