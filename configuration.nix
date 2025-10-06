{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];
  # nixpkgs.overlays = [
  #   (import ./overlays/code-cursor-latest.nix)
  # ];


  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 32;
  boot.loader.systemd-boot.consoleMode = "keep";
  boot.loader.efi.canTouchEfiVariables = true;

  # Fix ThinkPad T490s audio volume issues
  boot.kernelParams = [ "snd_hda_intel.dmic_detect=0" ];

  # Optional: may help with mute LED keys
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=auto
  '';

  # Enable disk encryption with LUKS
  boot.initrd.luks.devices."luks-d2e857c5-e64e-4ec9-ad84-9794dea3ebf2".device = "/dev/disk/by-uuid/d2e857c5-e64e-4ec9-ad84-9794dea3ebf2";

  # https://nixos.wiki/wiki/Laptop
  powerManagement.enable = true;
  # https://nixos.wiki/wiki/Hibernation
  # boot.kernelParams = ["resume_offset=73617408"];
  # boot.resumeDevice = "/dev/disk/by-uuid/c3645c55-a6db-46e9-8866-f00fece29064";
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 15779; # MBs
    }
  ];

  services.logind = {
    lidSwitch = "suspend"; # Hibernate on lid close
  };

  systemd.services.hibernate-on-low-battery = {
    description = "Hibernate when battery is critically low";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ $(cat /sys/class/power_supply/BAT*/capacity) -le 5 ] && [ $(cat /sys/class/power_supply/AC*/online) -eq 0 ]; then /run/current-system/sw/bin/systemctl hibernate; fi'";
    };
  };

  systemd.timers.hibernate-on-low-battery = {
    description = "Check battery percentage and hibernate if needed";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitActiveSec = "1min"; # Check every minute
      Unit = "hibernate-on-low-battery.service";
    };
  };

  services.udisks2.enable = true;


  # Networking
  networking.hostName = "tile";
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = lib.mkForce "none";
  services.resolved.enable = true;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # services.libinput = {
  #   enable = true;
  #   touchpad = {
  #     tapToClick = false;
  #   };
  # };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
    };
  };

  # test this
  # blueman-applet, blueman-manager
  services.blueman.enable = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.greetd = {
    enable = true;
    vt = 7;
    settings = {
      default_session = {
        user = "joshua";  # Replace with your username
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      };
    };
  };

  programs.hyprland.enable = true;
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  programs.waybar.enable = true;


  console.keyMap = "dvorak";

  # Wallpaper management
  # systemd.user.services.swww = {
  #   description = "Swww Wallpaper Service";
  #   serviceConfig = {
  #     ExecStart = "${pkgs.swww}/bin/swww daemon";
  #     Restart = "always";
  #   };
  # };

  # gtk = {
  #   enable = true;
  #   theme = {
  #     name = "TokyoNight";
  #     package = pkgs.libsForQt5.breeze-gtk;
  #   };
  #   iconTheme = {
  #     name = "Papirus-Dark";
  #   };
  #   gtk3 = {
  #     extraConfig.gtk-application-prefer-dark-theme = true;
  #   };
  # }; 

  # Enable XDG portals for Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal
    ];
  };

  fonts.packages = with pkgs; [
    cm_unicode
    font-awesome
    gohufont
    google-fonts
    material-icons
    terminus_font
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  programs.nix-ld.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # local net
    # dnsmasq ???? couldn't figure this out
    # hostapd

    # libs
    nss # security
    nspr # Netscape Portable Runtime, a platform-neutral API for system-level and libc-like functions. For Windsurf.
    zlib
    yazi

    # Development tools
    # exfatprogs
    vsh  # hashicorp vault sh
    # hcp  # hashicorp
    jq
    dwdiff
    git
    neovim
    tmux
    htop
    btop
    wget
    clang
    python3
    python3Packages.pip
    deno
    gcc
    # nodejs_20
    nodejs_22
    # nodejs_23
    # prisma
    prisma-engines
    android-tools
    nix-ld  # dirty
    code-cursor
    # pkgs.code-cursor
    poppler-utils

    postgresql
    graphviz  # dot
    rubberband

    # Utilities
    yarn
    toybox
    python311Full
    ffmpeg-full
    espeak
    nmap
    dig
    ngrok
    busybox
    bash-completion
    fastfetch
    fzf
    tree
    lm_sensors
    xclip
    openssl
    dtrx
    killall
    fprintd
    networkmanagerapplet
    dconf-editor
    pasystray
    pavucontrol
    gnome-keyring
    uv
    flyctl

    papirus-icon-theme # not really used by anything, but dolphin

    ibus
    udiskie

    # Wayland utilities
    fuzzel
    wayland-utils
    wl-clipboard
    grim
    slurp
    dunst
    hyprlock
    hypridle
    swww
    hyprpicker
    hyprshot
    # hyprpanel
    waybar
    hyprcursor
    wdisplays

    foot
    nautilus

    brightnessctl
    playerctl


    # # support both 32-bit and 64-bit applications
    # wineWowPackages.stable

    # # support 32-bit only
    # wine

    # # support 64-bit only
    # (wine.override { wineBuild = "wine64"; })

    # # support 64-bit only
    # wine64

    # # wine-staging (version with experimental features)
    # wineWowPackages.staging

    # # winetricks (all versions)
    # winetricks

    # # native wayland support (unstable)
    # wineWowPackages.waylandFull

    # Media and design
    gimp
    feh
    imagemagick
    inkscape
    font-manager
    audacity
    vlc
    eza
    tesseract
    ghostscript

    pinta

    zoom-us
    evince
    google-chrome
    brave

    # Miscellaneous
    starship
    libgcc
    bc
    libnotify
    lshw

  ];

  environment.variables = {
    PRISMA_ENGINES_DIRECTORY = "${pkgs.prisma-engines}/bin";
  };

  # # services.gnome3.gnome-keyring.enable = true;
  # services.gnome-keyring = {
  #   enable = true;
  #   # Enable support for managing SSH keys
  #   ssh = true;
  #   # Enable support for managing GPG keys
  #   gpg = true;
  # };

  # Make sure your PAM configuration loads the keyring in your desktop
  # security.pam.services.login.extraSessionModules = [ "gnome-keyring" ];

  programs.starship.enable = true;

  services.fprintd.enable = true;

  services.pulseaudio.enable = false;
  # Enable rtkit for PipeWire real-time scheduling
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.openssh.enable = true;
  services.tailscale.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  users.users.joshua = {
    isNormalUser = true;
    description = "Joshua Dong";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  nixpkgs.config.allowUnfree = true;

  virtualisation.docker.enable = true;

  system.stateVersion = "24.11";
}
