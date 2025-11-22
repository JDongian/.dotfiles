{ config, pkgs, ... }:

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
    extraConfig = builtins.readFile ./dotfiles/nvim/init.vim;
  };

  # =========================================================================
  # Hyprland
  # =========================================================================
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {};
    extraConfig = builtins.readFile ./dotfiles/hypr/hyprland.conf;
  };

  # Hyprlock config (no native Home Manager module yet)
  home.file.".config/hypr/hyprlock.conf".source = ./dotfiles/hypr/hyprlock.conf;

  # =========================================================================
  # Waybar
  # =========================================================================
  # Use original config files with proper FontAwesome unicode
  home.file.".config/waybar/config".source = ./dotfiles/waybar/config.jsonc;
  home.file.".config/waybar/style.css".source = ./dotfiles/waybar/style.css;

  # Enable waybar service
  programs.waybar.enable = true;

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
  # Foot Terminal
  # =========================================================================
  home.file.".config/foot/foot.ini".source = ./dotfiles/foot/foot.ini;
  programs.foot.enable = true;

  # =========================================================================
  # Fuzzel Launcher
  # =========================================================================
  home.file.".config/fuzzel/fuzzel.ini".source = ./dotfiles/fuzzel/fuzzel.ini;
  programs.fuzzel.enable = true;

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
  # User Packages
  # =========================================================================
  home.packages = with pkgs; [
    # Add user-specific packages here if needed
  ];
}
