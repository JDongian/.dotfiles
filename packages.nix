{ config, pkgs, lib, ... }:

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
    terminus_font
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

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
    android-tools
    clang
    code-cursor
    claude-code
    deno
    dwdiff
    gcc
    git
    graphviz  # dot
    jq
    # nodejs_20
    nodejs_22
    # nodejs_23
    nix-ld  # dirty
    poppler-utils
    postgresql
    # prisma
    prisma-engines
    python3
    python3Packages.pip
    rubberband
    tmux
    vsh  # hashicorp vault sh
    # hcp  # hashicorp

    # =========================================================================
    # Desktop/GUI Applications
    # =========================================================================
    brave
    evince
    google-chrome
    nautilus
    signal-desktop
    zoom-us

    # =========================================================================
    # Media & Creative
    # =========================================================================
    audacity
    feh
    ffmpeg-full
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
    swww
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
    htop
    ibus
    killall
    lm_sensors
    lshw
    networkmanagerapplet
    openssl
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

    # =========================================================================
    # Documentation & Publishing
    # =========================================================================
    pandoc
    texlive.combined.scheme-full

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
