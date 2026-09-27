{ config, pkgs, lib, ... }:

let
  # Selawik — Microsoft's OFL Segoe-UI-metric substitute. An OUTLINE (sans)
  # font: renders cleanly in GTK4/Pango and fuzzel, unlike bitmap fonts
  # (gohufont) which GTK4 aliases. The upstream repo is SOURCE-ONLY (UFO/.glyphs, no
  # compiled TTF), so this vendors a prebuilt TTF tracked in the repo at
  # dotfiles/fonts/selawik.ttf rather than building from UFO with fontmake.
  selawik = pkgs.stdenvNoCC.mkDerivation {
    pname = "selawik";
    version = "1.01";
    src = ./dotfiles/fonts/selawik.ttf;
    dontUnpack = true;
    installPhase = ''
      install -Dm644 "$src" "$out/share/fonts/truetype/Selawik.ttf"
    '';
    meta = {
      description = "Selawik — open-source metric-compatible Segoe UI substitute";
      homepage = "https://github.com/microsoft/Selawik";
      license = lib.licenses.ofl;
      platforms = lib.platforms.all;
    };
  };

  two-slice = pkgs.stdenvNoCC.mkDerivation {
    pname = "two-slice-font";
    version = "1.0";
    src = pkgs.fetchurl {
      url = "https://joefatula.com/assets/Two%20Slice.ttf";
      name = "two-slice.ttf";
      hash = "sha256-OCoIOLhkXGPP1RRS3biK0SOXfpY+l25DyAM/kwRmZEs=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm644 "$src" "$out/share/fonts/truetype/Two Slice.ttf"
    '';
    meta = {
      description = "2px-tall pixel font by Joe Fatula";
      homepage = "https://joefatula.com/twoslice.html";
      license = lib.licenses.cc-by-sa-40;
      platforms = lib.platforms.all;
    };
  };
in
{
  # =========================================================================
  # Fonts
  # =========================================================================
  fonts.packages = with pkgs; [
    cm_unicode
    font-awesome
    gohufont
    google-fonts
    material-icons
    selawik
    terminus_font
    two-slice
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  # System-wide font defaults (what apps get when they ask for a GENERIC
  # family). monospace/terminal = gohufont (bitmap, crisp in foot/waybar via
  # the AA-off rule in home.nix). sansSerif = Selawik (OUTLINE): everything
  # asking for generic "Sans" — GTK apps like nm-connection-editor / nm-applet
  # / Nautilus dialogs, and any GTK4 surface — gets a clean outline face
  # rather than an aliased bitmap.
  fonts.fontconfig.defaultFonts = {
    monospace = [ "gohufont" ];
    sansSerif = [ "Selawik" ];
    serif = [ "Selawik" ];
  };

  # =========================================================================
  # System Packages
  # =========================================================================
  environment.systemPackages = with pkgs; [

    # =========================================================================
    # Libraries & Dependencies
    # =========================================================================
    libgcc
    libnotify
    nspr # Netscape Portable Runtime, a platform-neutral API for system-level and libc-like functions. For Windsurf.
    nss # security
    zlib

    # =========================================================================
    # Development Tools
    # =========================================================================
    sox
    gh
    zip
    android-tools
    clang
    code-cursor
    claude-code
    deno
    dwdiff
    gcc
    git
    # Google Cloud CLI: gcloud, gsutil, bq. Base SDK only -- no extra
    # components. To add some later (e.g. gke-gcloud-auth-plugin for kubectl
    # against GKE, or alpha/beta subcommands) replace this line with:
    #   (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
    #     gke-gcloud-auth-plugin
    #   ]))
    # `gcloud components install` does NOT work on nix -- the store is
    # read-only, so components must be declared here instead.
    google-cloud-sdk
    graphviz  # dot
    jq
    # nodejs_20
    nodejs_22
    # nodejs_23
    poppler-utils
    postgresql
    # prisma
    prisma-engines
    python3
    python3Packages.pip

    python313
    python313Packages.numpy
    python313Packages.opencv4
    python313Packages.pip
    python313Packages.virtualenv

    rubberband
    tmux
    vsh  # hashicorp vault sh
    # hcp  # hashicorp
    jdk25
    gradle

    ydotool

    # =========================================================================
    # Desktop/GUI Applications
    # =========================================================================
    brave
    evince
    google-chrome
    libreoffice-fresh
    nautilus
    adwaita-icon-theme  # GTK icon theme; blueman-applet tray icon needs it
    signal-desktop
    zoom-us
    shotcut

    wev

    # =========================================================================
    # Media & Creative
    # =========================================================================
    kdePackages.kolourpaint
    audacity
    chafa
    feh
    ffmpeg-full
    libva-utils   # vainfo -- verifies the VAAPI setup in configuration.nix
    font-manager
    ghostscript
    gimp
    imagemagick
    inkscape
    pinta
    tesseract
    obs-studio
    vlc

    # =========================================================================
    # Wayland/Hyprland Tools
    # =========================================================================
    brightnessctl
    dunst
    foot
    fuzzel
    grim
    hyprcursor
    hypridle
    hyprlock
    hyprpicker
    hyprshot
    # hyprpanel
    playerctl
    pulseaudio  # Provides pactl and other PA utilities for PipeWire-Pulse
    slurp
    waybar
    wayland-utils
    wdisplays
    wl-clipboard

    # =========================================================================
    # System Utilities
    # =========================================================================
    bash-completion
    bc
    btop
    busybox
    dconf-editor
    dtrx
    eza
    fastfetch
    flyctl
    fprintd
    fzf
    gnome-keyring
    seahorse  # GUI for managing gnome-keyring
    htop
    ibus
    inotify-tools
    killall
    lm_sensors
    lshw
    networkmanagerapplet
    openssl
    rclone
    # papirus-icon-theme # not really used by anything, but dolphin
    pasystray
    pavucontrol
    # python311Full  # Removed: has been deprecated in nixos-unstable
    starship
    toybox
    tree
    udiskie
    uv
    wget
    xclip
    yarn
    yazi

    # =========================================================================
    # Networking Tools
    # =========================================================================
    dig
    ngrok
    nmap
    sshfs

    # =========================================================================
    # Documentation & Publishing
    # =========================================================================
    pandoc
    # texliveFull is the non-deprecated top-level scheme (same content as the
    # old texlive.combined.scheme-full, which nixpkgs is removing in 27.05).
    texliveFull

    # =========================================================================
    # Media Production
    # =========================================================================
    espeak

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

    # =========================================================================
    # Commented/Archived Packages
    # =========================================================================
    # local net
    # dnsmasq ???? couldn't figure this out
    # hostapd
    # exfatprogs

  ];
}
