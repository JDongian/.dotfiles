{ config, pkgs, ... }:

{
  # Home Manager basic configuration
  home.username = "joshua";
  home.homeDirectory = "/home/joshua";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager.
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # =========================================================================
  # Neovim
  # =========================================================================
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraConfig = ''
      colorscheme vim

      filetype plugin indent on

      set foldmethod=indent
      autocmd InsertLeave * set nopaste

      set expandtab
      set ignorecase
      set incsearch
      set linebreak
      set number
      set shiftwidth=4
      set showbreak=+++
      set smartcase
      set smartindent
      set softtabstop=4
      set timeoutlen=200

      " Tab management
       nnoremap nh :noh<cr>
       nnoremap <C-t>  :tabnew<CR>
       nnoremap te     :tabedit<Space>
       nnoremap tl     :tabnext<CR>
       nnoremap th     :tabprev<CR>
       nnoremap tL     :tablast<CR>
       nnoremap tm     :tabm<Space>
       nnoremap td     :tabclose<CR>

      " Reselect visual block after indent/dedent
      vnoremap < <gv
      vnoremap > >gv

      " Open man page for word under cursor
      nnoremap ? :Man <cword>

      " Quick DOS/UNIX line endings
      cmap dosfile e ++ff=dos %
      cmap unixfile e ++ff=unix %

      " Dragging lines
      nnoremap <C-j> :m+<CR>
      nnoremap <C-k> :m-2<CR>

      " netrw - toggle file explorer
      function! ToggleVExplorer()
        if exists("t:expl_buf_num")
          let expl_win_num = bufwinnr(t:expl_buf_num)
          if expl_win_num != -1
            let cur_win_nr = winnr()
            exec expl_win_num . 'wincmd w'
            close
            exec cur_win_nr . 'wincmd w'
            unlet t:expl_buf_num
          else
            unlet t:expl_buf_num
          endif
        else
          exec '1wincmd w'
          Vexplore
          let t:expl_buf_num = bufnr("%")
        endif
      endfunction
      map <silent> <C-F> :call ToggleVExplorer()<CR>
      let g:netrw_browse_split = 4
      let g:netrw_altv = 1
      let g:netrw_liststyle=3
      set autochdir

      syntax enable

      " Tabbing for specific file types
      augroup filetype_indent
        autocmd!
        autocmd FileType c,cpp,h,python setlocal expandtab
        autocmd FileType make setlocal noexpandtab
        autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4
      augroup END

      " Highlight trailing whitespace or leading tabs
      highlight BadWhitespace ctermbg=darkred guibg=darkred
      augroup bad_whitespace
        autocmd!
        autocmd BufRead,BufNewFile *.c,*.cpp,*.h,*.py,*.pyw match BadWhitespace /\(\s\+$\)\|\(^\t\+\)/
      augroup END
    '';
  };

  # =========================================================================
  # Hyprland
  # =========================================================================
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {};  # We'll use extraConfig for your full config
    extraConfig = ''
      # https://wiki.hyprland.org/Configuring/

      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor=eDP-1,1920x1080@60.01,0x0,1.0

      # See https://wiki.hyprland.org/Configuring/Keywords/
      $terminal = foot
      $fileManager = nautilus
      $menu = fuzzel
      $lock = hyprlock

      # Autostart necessary processes (like notifications daemons, status bars, etc.)
      # Or execute your favorite apps at launch like this:

      exec-once = $terminal
      # handled by home manager
      # exec-once = waybar &
      exec-once = pasystray &
      exec-once = blueman-applet &
      exec-once = nm-applet &
      exec-once = udiskie -a &
      exec-once = gammastep -l "37.79681473973986:-122.40482387121416" -t "6500K:2000K" &
      exec-once = swww-daemon && swww img ~/Pictures/wallpapers/nix-wallpaper-nineish-solarized-dark.png
      exec-once = [workspace 1 silent] SHELL=btop foot -F
      exec-once = [workspace 9 silent] google-chrome-stable
      exec-once = [workspace 8 silent] $terminal


      # See https://wiki.hyprland.org/Configuring/Environment-variables/

      env = HYPRCURSOR_THEME,McMojave
      env = HYPRCURSOR_SIZE,32


      # Refer to https://wiki.hyprland.org/Configuring/Variables/
      # https://wiki.hyprland.org/Configuring/Variables/#general
      general {
          gaps_in = 0
          gaps_out = 0

          border_size = 1

          # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
          col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
          col.inactive_border = rgba(595959aa)

          # Set to true enable resizing windows by clicking and dragging on borders and gaps
          resize_on_border = true

          # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
          allow_tearing = false

          layout = dwindle
      }

      # https://wiki.hyprland.org/Configuring/Variables/#decoration
      decoration {
          rounding = 0
          # rounding = 10

          # Change transparency of focused and unfocused windows
          # active_opacity = 1.0
          # inactive_opacity = 0.9

          shadow {
              enabled = false
          }

          # https://wiki.hyprland.org/Configuring/Variables/#blur
          blur {
              enabled = true
              size = 2
              passes = 1

              vibrancy = 0.1696
          }
      }

      # https://wiki.hyprland.org/Configuring/Variables/#animations
      animations {
          # enabled = false
          enabled = true

          # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

          bezier = easeOutQuint,0.23,1,0.32,1
          bezier = easeInOutCubic,0.65,0.05,0.36,1
          bezier = linear,0,0,1,1
          bezier = almostLinear,0.5,0.5,0.75,1.0
          bezier = quick,0.15,0,0.1,1

          animation = global, 1, 10, default
          animation = border, 1, 5.39, easeOutQuint
          animation = windows, 1, 3, easeOutQuint
          animation = fade, 1, 2, quick
          animation = layers, 1, 3, easeOutQuint
          animation = workspaces, 0, 1, almostLinear, fade
      }

      # Ref https://wiki.hyprland.org/Configuring/Workspace-Rules/
      # "Smart gaps" / "No gaps when only"
      # uncomment all if you wish to use that.
      # workspace = w[tv1], gapsout:0, gapsin:0
      # workspace = f[1], gapsout:0, gapsin:0
      # windowrulev2 = bordersize 0, floating:0, onworkspace:w[tv1]
      # windowrulev2 = rounding 0, floating:0, onworkspace:w[tv1]
      # windowrulev2 = bordersize 0, floating:0, onworkspace:f[1]
      # windowrulev2 = rounding 0, floating:0, onworkspace:f[1]

      # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
      dwindle {
          pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = true # You probably want this
      }

      # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
      master {
          new_status = master
      }

      # https://wiki.hyprland.org/Configuring/Variables/#misc
      misc {
          force_default_wallpaper = 0
          disable_hyprland_logo = true
      }


      #############
      ### INPUT ###
      #############

      # https://wiki.hyprland.org/Configuring/Variables/#input
      input {
          kb_layout = us,us
          kb_variant = dvorak,
          kb_model =
          kb_options=ctrl:nocaps
          kb_rules =

          follow_mouse = 1

          sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

          touchpad {
              natural_scroll = false
          }
      }

      # https://wiki.hyprland.org/Configuring/Variables/#gestures
      gestures {
          workspace_swipe = false
      }

      # Example per-device config
      # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
      device {
          name = epic-mouse-v1
          sensitivity = -0.5
      }


      ###################
      ### KEYBINDINGS ###
      ###################

      # See https://wiki.hyprland.org/Configuring/Keywords/
      $mainMod = SUPER # Sets "Windows" key as main modifier

      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      # bind = $mainMod, R, exec, $menu
      # bind = $mainMod, P, pseudo, # dwindle


      bind = $mainMod ALT, L, exec, $lock

      bind = $mainMod SHIFT, C, killactive,
      bind = $mainMod SHIFT, Q, exit,

      binde = $mainMod SHIFT, L, resizeactive, 80 0
      binde = $mainMod SHIFT, H, resizeactive, -80 0
      binde = $mainMod SHIFT, K, resizeactive, 0 -80
      binde = $mainMod SHIFT, J, resizeactive, 0 80

      bind = $mainMod, Tab, cyclenext,
      bind = $mainMod, RETURN, exec, $terminal
      bind = $mainMod, SPACE, exec, $menu
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod, V, togglefloating,
      bind = $mainMod, Z, togglesplit, # dwindle
      bind = $mainMod, F, fullscreen,

      # Move focus with mainMod + arrow keys
      bind = $mainMod, H, movefocus, l
      bind = $mainMod, L, movefocus, r
      bind = $mainMod, K, movefocus, u
      bind = $mainMod, J, movefocus, d

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10
      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspacesilent, 1
      bind = $mainMod SHIFT, 2, movetoworkspacesilent, 2
      bind = $mainMod SHIFT, 3, movetoworkspacesilent, 3
      bind = $mainMod SHIFT, 4, movetoworkspacesilent, 4
      bind = $mainMod SHIFT, 5, movetoworkspacesilent, 5
      bind = $mainMod SHIFT, 6, movetoworkspacesilent, 6
      bind = $mainMod SHIFT, 7, movetoworkspacesilent, 7
      bind = $mainMod SHIFT, 8, movetoworkspacesilent, 8
      bind = $mainMod SHIFT, 9, movetoworkspacesilent, 9
      bind = $mainMod SHIFT, 0, movetoworkspacesilent, 10

      # Example special workspace (scratchpad)
      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      # Scroll through existing workspaces with mainMod + scroll
      # bind = $mainMod, mouse_down, workspace, e+1
      # bind = $mainMod, mouse_up, workspace, e-1

      # # # /resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      # Laptop multimedia keys for volume and LCD brightness
      bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindel = ,XF86MonBrightnessUp, exec, brightnessctl s 10%+
      bindel = ,XF86MonBrightnessDown, exec, brightnessctl s 10%-

      # Requires playerctl
      bindl = , XF86AudioNext, exec, playerctl next
      bindl = , XF86AudioPause, exec, playerctl play-pause
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioPrev, exec, playerctl previous

      # Screenshot a window
      # bind = $mainMod, PRINT, exec, hyprshot -m window
      # Screenshot a monitor
      # bind = , PRINT, exec, hyprshot -m output
      # Screenshot a region
      # bind = $shiftMod, PRINT, exec, hyprshot -m region
      bind = $mainMod, PRINT, exec, hyprshot -m region
      bind = , PRINT, exec, hyprshot -z -m output

      # Cursor zoom controls:
      # - $mod + mouse wheel: zoom in/out
      # - $mod + +/-: zoom in/out
      # - $mod + numpad +/-: zoom in/out
      # - $mod + shift + any zoom key: reset zoom

      binde = $mainMod SHIFT, equal, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 1.3}')
      binde = $mainMod, minus, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 0.6}')

      ##############################
      ### WINDOWS AND WORKSPACES ###
      ##############################

      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

      # Example windowrule v1
      # windowrule = float, ^(kitty)$

      # Example windowrule v2
      # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$

      # Ignore maximize requests from apps. You'll probably like this.
      windowrulev2 = suppressevent maximize, class:.*

      # Fix some dragging issues with XWayland
      windowrulev2 = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0
    '';
  };

  # Hyprlock config (no native Home Manager module, use file)
  home.file.".config/hypr/hyprlock.conf".text = ''
    # BACKGROUND
    background {
        monitor =
        path = ~/.config/hypr/wall.jpg
        blur_passes = 0
    #     contrast = 0.8916
    #     brightness = 0.8916
    #     vibrancy = 0.8916
    #     vibrancy_darkness = 0.0
    }

    # GENERAL
    general {
        no_fade_in = true
        no_fade_out = true
        grace = 0
        disable_loading_bar = true
        # hide_cursor = true
        ignore_empty_input = true
        immediate_render = true
        text_trim = true
        fractional_scaling = 2
        screencopy_mode = 0
        fail_timeout = 0
    }

    # AUTH
    auth {
        pam:enabled = true
        pam:module = hyprlock
        fingerprint:enabled = true
        fingerprint:ready_message = (Scan fingerprint to unlock)
        fingerprint:present_message = Scanning fingerprint
        fingerprint:retry_delay = 0
    }

    # Time
    label {
        monitor =
        text = cmd[update:1000] echo "<span>$(date +"%I:%M")</span>"
        color = rgba(216, 222, 233, 0.80)
        font_size = 60
        font_family = OpenSans-Regular
        position = 30, -8
        halign = center
        valign = center
    }

    # Day-Month-Date
    label {
        monitor =
        text = cmd[update:1000] echo -e "$(date +"%A, %B %d")"
        color = rgba(216, 222, 233, .80)
        font_size = 19
        font_family = OpenSans-Regular
        position = 35, -60
        halign = center
        valign = center
    }

    # USER-BOX
    shape {
        monitor =
        size = 520, 550
        color = rgba(0, 0, 0, 0.4)
        rounding = -1
        border_size = 0
        rotate = 0
        xray = false # if true, make a "hole" in the background (rectangle of specified size, no rotation)

        position = 34, -190
        halign = center
        valign = center
    }

    # INPUT FIELD
    input-field {
        monitor =
        size = 320, 55
        outline_thickness = 0
        dots_size = 0.2 # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.2 # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = true
        outer_color = rgba(255, 255, 255, 0)
        inner_color = rgba(255, 255, 255, 0.1)
        font_color = rgb(200, 200, 200)
        fade_on_empty = false
        font_family = OpenSans-Regular
        placeholder_text =
        hide_input = false
        position = 34, -268
        halign = center
        valign = center
    }
  '';

  # =========================================================================
  # Waybar
  # =========================================================================
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "sway/window" ];
        modules-right = [
          "temperature"
          "disk"
          "custom/swap"
          "memory"
          "cpu"
          "custom/iops"
          "custom/keyboard-layout"
          "backlight"
          "tray"
          "battery"
          "clock"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };

        battery = {
          interval = 10;
          states = {
            warning = 30;
            critical = 15;
          };
          format = "  {icon}  {capacity}%";
          format-discharging = "{icon}  {capacity}%";
          format-icons = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
          tooltip = true;
        };

        clock = {
          interval = 1;
          format = "{:%a, %b %e %H:%M:%S %p}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
        };

        cpu = {
          interval = 2;
          format = " {usage}%";
          states = {
            warning = 70;
            critical = 90;
          };
        };

        disk = {
          interval = 5;
          format = " {percentage_used}%";
          tooltip-format = "{used}/{total}";
          path = "/";
        };

        "custom/keyboard-layout" = {
          exec = "swaymsg -t get_inputs | grep -m1 'xkb_active_layout_name' | cut -d '\"' -f4";
          interval = 30;
          format = "  {}";
          signal = 1;
          tooltip = false;
        };

        memory = {
          interval = 5;
          format = " {}%";
          states = {
            warning = 70;
            critical = 90;
          };
        };

        network = {
          interval = 5;
          format-wifi = "{essid} ({signalStrength}%)";
          format-ethernet = "  {ifname}: {ipaddr}/{cidr}";
          format-disconnected = "⚠  Disconnected";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        temperature = {
          critical-threshold = 80;
          interval = 5;
          format = "{icon} {temperatureC}°C";
          format-icons = [ "" "" "" "" "" ];
          tooltip = true;
        };

        backlight = {
          device = "intel_backlight";
          format = "{icon} {percent}%";
          format-icons = [ "░" "▒" "▓" "█" ];
          on-scroll-up = "brightnessctl -q set 1%+";
          on-scroll-down = "brightnessctl -q set 1%-";
        };

        tray = {
          icon-size = 18;
          spacing = 10;
        };

        "custom/iops" = {
          interval = 5;
          exec = "iostat -dx | awk '/^sda/ {print $4 \"/\" $5}'";
          format = "IOPS {}";
        };

        "custom/swap" = {
          interval = 5;
          exec = "free -m | awk '/Swap/ {printf \"%.0f\", $3/$2*100}'";
          format = " {}%";
        };
      };
    };

    style = ''
      * {
      	font-size: 10px;
      	font-family: gohufont;
      }

      window#waybar {
      	background: #000000;
      	color: #fdf6e3;
      }

      #workspaces button {
      	padding: 0;
      	color: #fdf6e3;
      }
      #workspaces button.active {
      	color: #268bd2;
      }

      #memory,
      #cpu,
      #battery,
      #clock,
      #backlight,
      #bluetooth,
      #pulseaudio,
      #pulseaudio,
      #tray,
      #temperature,
      #disk {
      	padding: 0 4px;
      }
    '';
  };

  # =========================================================================
  # Tmux
  # =========================================================================
  programs.tmux = {
    enable = true;
    mouse = true;
    extraConfig = ''
      # set -g status-style 'bg=colour18 fg=colour137 dim'
      set -g status-left '''
      set -g status-right '#[fg=colour233,bg=colour10] %d/%m #[fg=colour233,bg=colour9] %H:%M:%S '
      set -g status-right-length 50
      set -g status-left-length 20

      setw -g window-status-current-style 'fg=colour1 bg=colour19 bold'
      setw -g window-status-current-format ' #I#[fg=colour249]:#[fg=colour255]#W#[fg=colour249]#F '

      setw -g window-status-style 'fg=colour9 bg=colour18'
      setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

      setw -g window-status-bell-style 'fg=colour255 bg=colour1 bold'

      # messages
      set -g message-style 'fg=colour232 bg=colour16 bold'
    '';
  };

  # =========================================================================
  # Bash
  # =========================================================================
  programs.bash = {
    enable = true;
    historySize = 500;
    historyFileSize = 90000;
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
    shellOptions = [
      "checkwinsize"
      "histappend"
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      HISTTIMEFORMAT = "%F %T";
    };

    shellAliases = {
      vim = "nvim";
      ls = "eza";
    };

    bashrcExtra = ''
      # Only run in interactive shells
      [[ $- != *i* ]] && return
      # Enable bash programmable completion features in interactive shells
      if [ -f /usr/share/bash-completion/bash_completion ]; then
      	. /usr/share/bash-completion/bash_completion
      elif [ -f /etc/bash_completion ]; then
      	. /etc/bash_completion
      fi

      # Disable the bell
      iatest=$(expr index "$-" i)
      if [[ $iatest -gt 0 ]]; then bind "set bell-style visible"; fi

      # Append to history after each command
      PROMPT_COMMAND='history -a'

      # Ignore case on auto-completion
      if [[ $iatest -gt 0 ]]; then bind "set completion-ignore-case on"; fi

      # Show auto-completion list automatically, without double tab
      if [[ $iatest -gt 0 ]]; then bind "set show-all-if-ambiguous On"; fi

      # Starship prompt (guarded)
      if [[ $TERM != "dumb" ]]; then
        eval "$(starship init bash)"
      fi

      # NVM initialization
    '';
  };

  # =========================================================================
  # Git
  # =========================================================================
  programs.git = {
    enable = true;
    userName = "Joshua Dong";
    userEmail = "jdong42@gmail.com";

    extraConfig = {
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
  programs.starship = {
    enable = true;
    enableBashIntegration = false;  # Disable auto-injection, we handle it manually
    settings = {
      add_newline = false;

      character = {
        success_symbol = "[\\$](white)";
        error_symbol = "[\\$](white)";
      };

      line_break = {
        disabled = true;
      };

      status = {
        disabled = false;
        symbol = "";
      };

      package = {
        disabled = true;
      };

      shlvl = {
        symbol = "#";
      };
    };
  };

  # =========================================================================
  # Foot Terminal
  # =========================================================================
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "gohufont:size=10";
      };
      colors = {
        background = "000000";
        foreground = "ffffff";
      };
    };
  };

  # =========================================================================
  # Fuzzel Launcher
  # =========================================================================
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "OpenSans-Regular:size=10";
        prompt = "🔍";
        horizontal-pad = 16;
        vertical-pad = 16;
      };
      colors = {
        background = "000000dd";
        text = "f8f8f2ff";
        match = "8be9fdff";
        selection-match = "8be9fdff";
        selection = "44475add";
        selection-text = "f8f8f2ff";
        border = "444444ff";
      };
      border = {
        width = 1;
        radius = 0;
      };
    };
  };
}
