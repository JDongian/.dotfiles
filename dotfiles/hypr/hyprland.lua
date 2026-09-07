-- Hyprland config, Lua format.
--
-- Migrated from hyprlang (hyprland.conf) because hyprlang is deprecated as of
-- 0.55 and is slated for removal "1 - 2 releases" after that
-- (https://hypr.land/news/26_lua/) — i.e. 0.57, and we run 0.56.2.
--
-- Reference: https://wiki.hypr.land/Configuring/Start/ and the upstream
-- example at Hyprland/example/hyprland.lua.
--
-- NOTE: the monitor config is per-host and lives in `monitor.lua`, written by
-- flake.nix via extraLuaFiles. Home Manager emits its `require("monitor")`
-- automatically (autoLoad defaults to true), ABOVE this file's contents — so
-- there is deliberately no explicit require here. This replaces the old
-- `source = ~/.config/hypr/monitor.conf`.

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "foot"
local fileManager = "nautilus"
local menu        = "fuzzel"
local lock        = "hyprlock"

-------------------
---- AUTOSTART ----
-------------------

-- hyprlang's bare `exec-once = ...` becomes an explicit hyprland.start hook.
-- The trailing `&` from the old config is dropped: hl.exec_cmd does not block,
-- so backgrounding was always redundant (and `&` would now be passed to the
-- shell as part of the command).
hl.on("hyprland.start", function()
    -- gnome-keyring with SSH support for password management
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh")
    hl.exec_cmd(terminal)
    hl.exec_cmd("waybar")
    hl.exec_cmd("pasystray")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("udiskie -a")
    hl.exec_cmd('gammastep -l "37.79681473973986:-122.40482387121416" -t "6500K:2000K"')
    hl.exec_cmd("awww-daemon && awww img ~/Pictures/wallpapers/nix-wallpaper-nineish-solarized-dark.png")

    -- The old `[workspace N silent]` exec prefix is now a window-rule table
    -- passed as exec_cmd's second argument. `silent` is NOT a separate key --
    -- it is a suffix on the workspace string, same as the hyprlang form.
    hl.exec_cmd("SHELL=btop foot -F",   { workspace = "1 silent" })
    hl.exec_cmd("google-chrome-stable", { workspace = "9 silent" })
    hl.exec_cmd(terminal,               { workspace = "8 silent" })
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("HYPRCURSOR_THEME", "McMojave")
hl.env("HYPRCURSOR_SIZE", "48")
hl.env("XCURSOR_THEME", "McMojave")
hl.env("XCURSOR_SIZE", "48")
hl.env("HYPRSHOT_DIR", "/home/joshua/tmp/screenshots/")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    cursor = {
        no_hardware_cursors = false,
        enable_hyprcursor   = true,
    },

    general = {
        gaps_in  = 0,
        gaps_out = 0,

        border_size = 1,

        -- hyprlang's `col.active_border = rgba(a) rgba(b) 45deg` becomes a
        -- nested table; a gradient is { colors = {...}, angle = N }.
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on
        -- borders and gaps
        resize_on_border = true,

        -- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 0,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled  = true,
            size     = 2,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
    dwindle = {
        -- pseudotile option removed in Hyprland 0.55.0 (it was a no-op);
        -- toggle via `mainMod + P` keybind instead
        preserve_split = true, -- You probably want this
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        -- Fail-closed: if the locker crashes, keep the lock surface alive so a
        -- respawned hyprlock can reattach instead of exposing the desktop.
        allow_session_lock_restore = true,
    },

    -- Hyprland's own logger is off by default; without this, hyprland.log only
    -- contains aquamarine/libinput chatter and exit/crash reasons are invisible.
    debug = {
        disable_logs = false,
    },

    input = {
        kb_layout  = "us,us",
        kb_variant = "dvorak,",
        kb_model   = "",
        kb_options = "ctrl:nocaps",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Bezier curves and animations. `bezier = name,a,b,c,d` becomes hl.curve with
-- the four numbers as two control points, and each `animation = leaf, on,
-- speed, curve[, style]` becomes an hl.animation table.
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },  { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },    { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global",     enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",     enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",    enabled = true,  speed = 3,    bezier = "easeOutQuint" })
hl.animation({ leaf = "fade",       enabled = true,  speed = 2,    bezier = "quick" })
hl.animation({ leaf = "layers",     enabled = true,  speed = 3,    bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = false, speed = 1,    bezier = "almostLinear", style = "fade" })

---------------
---- INPUT ----
---------------

-- Per-device config.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- Fix ydotool mouse acceleration issue
-- (https://github.com/ReimuNotMoe/ydotool/issues/158)
-- Without flat accel_profile, mouse positions are doubled
hl.device({ name = "ydotoold-virtual-device",   accel_profile = "flat" })
hl.device({ name = "ydotoold-virtual-device-1", accel_profile = "flat" })
hl.device({ name = "ydotoold-virtual-device-2", accel_profile = "flat" })
hl.device({ name = "ydotoold-virtual-device-3", accel_profile = "flat" })

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(lock))

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.kill())

-- Power menu — Super+Shift+Q used to instantly kill the WM, which was too easy
-- to fat-finger and lost an entire session's worth of windows. Now it's a
-- fuzzel prompt with Cancel as the default action.
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(
    [[case "$(printf 'Cancel\nSleep\nHibernate\nReboot\nShut Down\n' | fuzzel --dmenu --lines=5 --prompt 'Power: ')" in Sleep) systemctl suspend ;; Hibernate) systemctl hibernate ;; Reboot) systemctl reboot ;; "Shut Down") systemctl poweroff ;; esac]]
))

-- `binde` (repeating) is now the { repeating = true } bind flag.
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 80,  y = 0 }),   { repeating = true })
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -80, y = 0 }),   { repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0,   y = -80 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0,   y = 80 }),  { repeating = true })

hl.bind(mainMod .. " + Tab",    hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Z",      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ action = "toggle" }))

-- Move focus with mainMod + hjkl
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9], and move the active window there
-- with mainMod + SHIFT + [0-9]. `follow = false` is the new spelling of the
-- old `movetoworkspacesilent` dispatcher.
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness.
-- `bindel` = locked (works while the screen is locked) + repeating.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),{ locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"),                        { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"),                        { locked = true, repeating = true })

-- Requires playerctl. `bindl` = locked only.
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("PRINT",               hl.dsp.exec_cmd("hyprshot -z -m output"))

-- Cursor zoom controls
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.exec_cmd(
    [[hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 1.3}')]]
), { repeating = true })
hl.bind(mainMod .. " + minus", hl.dsp.exec_cmd(
    [[hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 0.6}')]]
), { repeating = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})
