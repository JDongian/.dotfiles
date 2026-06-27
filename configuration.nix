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

  # NOTE: Power management (powerManagement.enable, swapDevices, hibernation
  # resume, lid/suspend, the hibernate-on-low-battery timer, fprintd-resume
  # hook, and the MFi/fingerprint udev rules) moved to hosts/tile/power.nix —
  # one central place for the whole subsystem (2026-06-04).

  # TODO (deferred, "B3"): Secure Boot via lanzaboote + TPM2 LUKS auto-unlock.
  # Goal: replace the LUKS passphrase prompt at boot with TPM2-sealed unlock,
  # leaving only the user login password. Requires, in order:
  #   1. Add nix-community/lanzaboote as a flake input; generate signing keys
  #      and enroll them in the BIOS Secure Boot store (BIOS setup mode).
  #   2. Switch boot.loader.systemd-boot.enable → boot.lanzaboote.enable.
  #   3. Reboot, enable Secure Boot in firmware, verify `bootctl status`
  #      shows "Secure Boot: enabled (user)".
  #   4. systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 <luks-device>
  #      for both rootfs and swap LUKS volumes; keep an enrolled passphrase
  #      slot as recovery.
  # Why deferred: TPM2 unlock without Secure Boot is a real security
  # regression (rogue-OS / filesystem-confusion attack — see oddlama.org
  # write-up). Doing it right requires lanzaboote, which is a separate
  # multi-step project. NOTE: this needs boot.initrd.systemd.enable, which is
  # deliberately NOT set — turning it on (2026-05-17) silently broke
  # hibernation resume (LUKS-swap dependency ordering in the systemd initrd;
  # see hosts/tile/power.nix). If Secure Boot work re-enables it, the resume
  # path must be fixed first.

  # NOTE: lid/suspend-then-hibernate, HibernateDelay, the MFi + fingerprint
  # udev rules, and the fprintd-resume hook all moved to hosts/tile/power.nix
  # (2026-06-04). See that module for the full power-management picture.

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
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
      };
    };
  };

  programs.hyprland.enable = true;
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  # Waybar started from Hyprland config instead
  # programs.waybar.enable = true;


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

  # Enable gnome-keyring service
  # services.gnome.gnome-keyring.enable = true;

  # Enable gnome-keyring for greetd PAM (unlocks keyring on login)
  # security.pam.services.greetd.enableGnomeKeyring = true;

  programs.starship.enable = true;

  # Note: fprintd service is now enabled in host-specific hardware.nix if available

  services.pulseaudio.enable = false;
  # Enable rtkit for PipeWire real-time scheduling
  security.rtkit.enable = true;

  # Audit logging for signal delivery (catch SIGTERM culprits)
  security.auditd.enable = true;
  security.audit.rules = [
    "-a always,exit -F arch=b64 -S kill -S tkill -S tgkill -F a1=15 -k sigterm_track"
  ];

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
