{ config, pkgs, lib, ... }:

{
  # Note: hardware-configuration.nix and hardware-specific settings are now
  # imported via hosts/<hostname>/default.nix for better portability
  imports = [
    ./packages.nix
  ];

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
  # multi-step project. NOTE: this needs boot.initrd.systemd.enable. That was
  # previously flagged here as a blocker because turning it on (2026-05-17)
  # silently broke hibernation resume. That is NO LONGER TRUE: as of
  # 2026-09-22 the option defaults to true in nixpkgs, tile is running a
  # systemd initrd, and hibernate/resume works (see hosts/tile/power.nix for
  # the journal evidence). So this is not an obstacle to the Secure Boot work.

  # NOTE: lid/suspend-then-hibernate, HibernateDelay, the MFi + fingerprint
  # udev rules, and the fprintd-resume hook all moved to hosts/tile/power.nix
  # (2026-06-04). See that module for the full power-management picture.

  services.udisks2.enable = true;

  # Firmware updates via LVFS/fwupd. Enabling this only makes the tooling
  # available — it does NOT auto-apply anything. Check with:
  #   fwupdmgr refresh          # pull the latest LVFS metadata
  #   fwupdmgr get-updates      # list pending firmware (BIOS, TB, etc.)
  #   fwupdmgr update           # apply — a deliberate, manual step
  # The T490s (Lenovo 20NY) exposes UEFI/ME/Thunderbolt updates on LVFS.
  services.fwupd.enable = true;


  # Networking
  # Note: hostname is now set in hosts/<hostname>/hardware.nix
  networking.networkmanager.enable = true;
  # Take DNS entirely away from NetworkManager and pin it to Cloudflare +
  # Google via systemd-resolved. NM won't push DHCP-provided resolvers, so
  # every lookup goes to 1.1.1.1 / 8.8.8.8 regardless of the network joined.
  # `networking.nameservers` feeds resolved's global DNS= and, with NM DNS
  # off, is the authoritative list (not just a fallback). `dnssec = false`
  # keeps captive-portal / split-horizon networks from breaking on validation.
  networking.networkmanager.dns = lib.mkForce "none";
  # Don't wait for NetworkManager to finish starting
  systemd.services.NetworkManager-wait-online.enable = false;
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "false";
      FallbackDNS = [ "1.1.1.1" "8.8.8.8" ];
    };
  };
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
    };
  };

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
        # setsid on the compositor (via --cmd) makes start-hyprland its own
        # session/process-group leader, so a group-directed signal — kill(0) /
        # kill(-pgid) — from any app running *inside* the Hyprland session cannot
        # escape upward and SIGTERM the compositor. On 2026-08-05 a Claude Code
        # Bash-subprocess teardown (kill(0) + kill(-pgid)) sprayed the login
        # session's process group, hit start-hyprland, and took the whole desktop
        # down (clean SIGTERM, not a crash). See memory: hyprland_group_sigterm.
        # --wait: setsid otherwise forks-and-returns immediately, which would make
        # greetd think the session ended at once and relogin-loop; --wait blocks
        # until start-hyprland actually exits, preserving normal session lifetime.
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd '${pkgs.util-linux}/bin/setsid --wait start-hyprland'";
      };
    };
  };

  programs.hyprland.enable = true;
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  # Waybar started from Hyprland config instead
  # programs.waybar.enable = true;


  console.keyMap = "dvorak";

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

    # Claude Code is installed DECLARATIVELY via the claude-code-overlay
    # (see flake.nix). Its built-in auto-updater must stay OFF or it npm-installs
    # a second copy into ~/.nvm/.../@anthropic-ai/claude-code that shadows the
    # nix one on PATH. This USED to live in home.nix, but Home Manager only
    # covers joshua -- root has its OWN ~/.claude.json with autoUpdates:true, and
    # `sudo claude` inherits joshua's nvm PATH. On 2026-08-19 root's claude
    # self-updated 2.1.217 -> 2.1.237 and wrote a ROOT-OWNED nvm copy, which
    # broke `claude` at next login (npm wrapper with no native binary) and made
    # `npm uninstall -g` fail with EACCES for joshua. Setting it here covers
    # every user including root. Bump claude through nix only.
    #
    # DISABLE_AUTOUPDATER only stops the BACKGROUND check -- `claude update`
    # still runs and would re-create the npm copy. DISABLE_UPDATES blocks both,
    # which is what a nix-managed install wants. Both are set: the former is
    # what the 2026-08-18 fix used and is still honored, the latter closes the
    # manual-update hole.
    DISABLE_AUTOUPDATER = "1";
    DISABLE_UPDATES = "1";
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
