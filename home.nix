{ config, pkgs, lib, inputs, ... }:

{
  # Home Manager basic configuration
  home.username = "joshua";
  home.homeDirectory = "/home/joshua";
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # =========================================================================
  # Neovim
  # =========================================================================
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = true;
    withPython3 = true;
    plugins = with pkgs.vimPlugins; [
      goyo-vim
    ];
    extraConfig = builtins.readFile ./dotfiles/nvim/init.vim;
  };

  # =========================================================================
  # Hyprland
  # =========================================================================
  wayland.windowManager.hyprland = {
    enable = true;
    # NOTE: there is no `configType` option in the HM hyprland module — adding
    # one breaks evaluation. `extraConfig` is already raw hyprlang text, and
    # `settings = {}` means HM generates nothing of its own to clash with it.
    settings = {};
    extraConfig = builtins.readFile ./dotfiles/hypr/hyprland.conf;
  };

  # Hyprlock config (no native Home Manager module yet)
  home.file.".config/hypr/hyprlock.conf".source = ./dotfiles/hypr/hyprlock.conf;

  # Hypridle config (no native Home Manager module yet)
  home.file.".config/hypr/hypridle.conf".source = ./dotfiles/hypr/hypridle.conf;

  # hyprlock as a managed user service so a crashed locker auto-respawns and
  # reattaches to the surviving session-lock surface (allow_session_lock_restore).
  # Triggered by hypridle's lock_cmd; not auto-started at login.
  systemd.user.services.hyprlock = {
    Unit = {
      Description = "Hyprlock screen locker";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.hyprlock}/bin/hyprlock";
      Restart = "on-failure";
      RestartSec = 1;
      StartLimitBurst = 10;
    };
  };

  # =========================================================================
  # Waybar
  # =========================================================================
  # Use original config files with proper FontAwesome unicode
  home.file.".config/waybar/config".source = ./dotfiles/waybar/config.jsonc;
  home.file.".config/waybar/style.css".source = ./dotfiles/waybar/style.css;

  # Enable waybar package (but not the systemd service, since we start it from Hyprland)
  programs.waybar.enable = false;

  # =========================================================================
  # Tmux
  # =========================================================================
  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./dotfiles/tmux/tmux.conf;
  };

  # =========================================================================
  # Bash
  # =========================================================================
  programs.bash = {
    enable = true;
    historySize = 500;
    historyFileSize = 90000;

    bashrcExtra = ''
      # Only run interactive shell stuff if we're interactive
      if [[ $- == *i* ]]; then
        # Enable bash programmable completion features in interactive shells
        if [ -f /usr/share/bash-completion/bash_completion ]; then
        	. /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
        	. /etc/bash_completion
        fi

        # Disable the bell
        bind "set bell-style visible"

        # Append to history after each command
        PROMPT_COMMAND='history -a'

        # Ignore case on auto-completion
        bind "set completion-ignore-case on"

        # Show auto-completion list automatically, without double tab
        bind "set show-all-if-ambiguous On"

        # Starship prompt (managed by Home Manager)
        eval "$(starship init bash)"

        # NVM initialization
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
      fi
    '';

    shellAliases = {
      ls = "eza --icons";
      ll = "eza -l --icons";
      la = "eza -la --icons";
    };
  };

  # =========================================================================
  # Git
  # =========================================================================
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Joshua Dong";
        email = "jdong42@gmail.com";
      };
      safe = {
        directory = "/etc/nixos";
      };
    };

    ignores = [
      "**/.claude/settings.local.json"
    ];
  };

  # =========================================================================
  # Starship
  # =========================================================================
  home.file.".config/starship.toml".source = ./dotfiles/starship.toml;
  programs.starship = {
    enable = true;
    enableBashIntegration = false;  # We handle init manually in bashrcExtra
  };

  # =========================================================================
  # Fuzzel Launcher
  # =========================================================================
  home.file.".config/fuzzel/fuzzel.ini".source = ./dotfiles/fuzzel/fuzzel.ini;

  # =========================================================================
  # Foot Terminal
  # =========================================================================
  home.file.".config/foot/foot.ini".source = ./dotfiles/foot/foot.ini;
  programs.foot.enable = true;

  # =========================================================================
  # Brave — force XWayland to restore middle-click (primary-selection) paste
  # =========================================================================
  # Symptom (2026-06): selecting text in foot and middle-clicking into Brave
  # stopped pasting (foot->foot still works). Cause: a Brave update started
  # auto-running under native Wayland (Ozone). Chromium-family browsers do not
  # implement primary-selection PASTE under native Wayland, so middle-click
  # into Brave does nothing; under XWayland, XWayland bridges X11 PRIMARY and
  # it works. We don't set NIXOS_OZONE_WL, so the Nix wrapper passes no
  # --ozone-platform flag and Brave picks Wayland on its own — pin it to x11.
  # Brave reads ~/.config/brave-flags.conf at launch (Chromium flags-file
  # convention). To go back to native Wayland later, delete this / set
  # --ozone-platform=wayland (and accept middle-paste stays broken upstream).
  home.file.".config/brave-flags.conf".text = ''
    --ozone-platform=x11
  '';
  home.file.".config/chrome-flags.conf".text = ''
    --ozone-platform=x11
  '';

  # =========================================================================
  # Font Configuration
  # =========================================================================
  fonts.fontconfig.enable = true;

  # Disable antialiasing for gohufont to prevent scaling/blurring at 2K
  xdg.configFile."fontconfig/conf.d/75-disable-gohufont-antialiasing.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <description>Disable anti-aliasing for gohufont bitmap font</description>
      <match target="font">
        <test name="family" compare="eq">
          <string>gohufont</string>
        </test>
        <edit name="antialias" mode="assign">
          <bool>false</bool>
        </edit>
        <edit name="hinting" mode="assign">
          <bool>true</bool>
        </edit>
        <edit name="hintstyle" mode="assign">
          <const>hintfull</const>
        </edit>
      </match>
    </fontconfig>
  '';

  # =========================================================================
  # Misc Programs
  # =========================================================================
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  # =========================================================================
  # Cursor Theme
  # =========================================================================
  home.sessionVariables = {
    XCURSOR_THEME = "McMojave";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "McMojave";
    HYPRCURSOR_SIZE = "24";

    # Claude Code (and other Node CLIs using the `open` package) launch a
    # browser via $BROWSER, NOT xdg-open. With $BROWSER unset and no
    # x-www-browser/www-browser/sensible-browser on PATH, the fallback chain
    # is empty and browser-based OAuth logins silently fail — even though
    # plain `xdg-open` works. Point $BROWSER at xdg-open so it honors the
    # same default-browser (brave-browser.desktop) setting that already works.
    BROWSER = "xdg-open";
  };

  # =========================================================================
  # User Packages
  # =========================================================================
  home.packages = with pkgs; [
    # McMojave hyprcursor theme
    inputs.mcmojave-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
