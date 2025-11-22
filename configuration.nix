{ config, pkgs, lib, ... }:

{
  # Note: hardware-configuration.nix and hardware-specific settings are now
  # imported via hosts/<hostname>/default.nix for better portability
  imports = [
    ./packages.nix
  ];

  # nixpkgs.overlays = [
  #   (import ./overlays/code-cursor-latest.nix)
  # ];


  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 32;
  boot.loader.systemd-boot.consoleMode = "keep";
  boot.loader.efi.canTouchEfiVariables = true;

  # Quiet boot - hide boot messages from login screen
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
  ];
  boot.consoleLogLevel = 3;

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

  # Renamed in nixos-unstable: lidSwitch → settings.Login.HandleLidSwitch
  services.logind.settings.Login.HandleLidSwitch = "suspend";

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
  # Note: hostname is now set in hosts/<hostname>/hardware.nix
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = lib.mkForce "none";
  # Don't wait for NetworkManager to finish starting
  systemd.services.NetworkManager-wait-online.enable = false;
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
    # vt option removed: VT is now fixed to VT1 in nixos-unstable
    settings = {
      default_session = {
        user = "joshua";
        # Renamed: greetd.tuigreet → tuigreet
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
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
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = ["gtk"];
      };
      hyprland = {
        default = ["hyprland" "gtk"];
      };
    };
  };

  programs.nix-ld.enable = true;

  # System packages are now organized in packages.nix

  # Exclude unwanted default packages
  environment.defaultPackages = lib.mkForce [];

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

  # Note: fprintd service is now enabled in host-specific hardware.nix if available

  services.pulseaudio.enable = false;
  # Enable rtkit for PipeWire real-time scheduling
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
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
