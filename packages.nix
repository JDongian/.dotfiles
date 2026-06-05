{ config, pkgs, lib, ... }:

let
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
    terminus_font
    two-slice
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

    grim
    ydotool

    # =========================================================================
    # Desktop/GUI Applications
    # =========================================================================
    brave
    evince
    google-chrome
    libreoffice-fresh
    nautilus
    signal-desktop
    zoom-us
    shotcut

    wev

    # =========================================================================
    # Media & Creative
    # =========================================================================
    kdePackages.kolourpaint
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
