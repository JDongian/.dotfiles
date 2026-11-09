-- https://wiki.hypr.land/configuring/
-- API reference: share/hypr/stubs/hl.meta.lua in the hyprland package.

-- Host-specific monitor config is required from ~/.config/hypr/monitor.lua
require("monitor")

local terminal    = "foot"
local fileManager = "nautilus"
local menu        = "fuzzel"
local lock        = "hyprlock"
local mainMod     = "SUPER"

hl.on("hyprland.start", function()
    -- Start gnome-keyring with SSH support for password management
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh")
    hl.exec_cmd(terminal)
    hl.exec_cmd("waybar")
    hl.exec_cmd("pasystray --notify=sink_default --notify=source_default")
    hl.exec_cmd("ags-nm-panel")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("udiskie -a -T")
    hl.exec_cmd('gammastep -l "37.79681473973986:-122.40482387121416" -t "6500K:2000K"')
    hl.exec_cmd("SHELL=btop foot -F", { workspace = "1 silent" })
    hl.exec_cmd("google-chrome-stable --disable-background-mode", { workspace = "9 silent" })
    hl.exec_cmd(terminal, { workspace = "8 silent" })
end)

hl.env("HYPRCURSOR_THEME", "McMojave")
hl.env("HYPRCURSOR_SIZE", "48")
hl.env("XCURSOR_THEME", "McMojave")
hl.env("XCURSOR_SIZE", "48")
hl.env("HYPRSHOT_DIR", "/home/joshua/tmp/screenshots/")

hl.config({
    cursor = {
        no_hardware_cursors = false,
        enable_hyprcursor   = true,
    },

    general = {
        gaps_in     = 0,
        gaps_out    = 0,
        border_size = 1,
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,
        layout        = "dwindle",
    },

    decoration = {
        rounding = 0,
        shadow   = { enabled = false },
        blur = {
            enabled  = true,
            size     = 2,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },
    master  = { new_status = "master" },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        -- Fail-closed: if the locker crashes, keep the lock surface alive so a
        -- respawned hyprlock can reattach instead of exposing the desktop.
        allow_session_lock_restore = true,
    },

    -- Hyprland's own logger is off by default; without this, hyprland.log only
    -- contains aquamarine/libinput chatter and exit/crash reasons are invisible.
    debug = { disable_logs = false },

    input = {
        kb_layout    = "us,us",
        kb_variant   = "dvorak,",
        kb_model     = "",
        kb_options   = "ctrl:nocaps",
        kb_rules     = "",
        follow_mouse = 1,
        sensitivity  = 0, -- -1.0 - 1.0, 0 means no modification.
        touchpad     = { natural_scroll = false },
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",     enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",     enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",    enabled = true,  speed = 3,    bezier = "easeOutQuint" })
hl.animation({ leaf = "fade",       enabled = true,  speed = 2,    bezier = "quick" })
hl.animation({ leaf = "layers",     enabled = true,  speed = 3,    bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = false, speed = 1,    bezier = "almostLinear", style = "fade" })

-- New syntax (0.51+): Uncomment to enable 3-finger horizontal workspace switching
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

-- Fix ydotool mouse acceleration issue (https://github.com/ReimuNotMoe/ydotool/issues/158)
-- Without flat accel_profile, mouse positions are doubled
for _, name in ipairs({ "ydotoold-virtual-device", "ydotoold-virtual-device-1",
                        "ydotoold-virtual-device-2", "ydotoold-virtual-device-3" }) do
    hl.device({ name = name, accel_profile = "flat" })
end

---------------------
---- KEYBINDINGS ----
---------------------

local function bind(keys, dsp, opts) hl.bind(mainMod .. " + " .. keys, dsp, opts) end

bind("ALT + L", hl.dsp.exec_cmd(lock))

bind("SHIFT + C", hl.dsp.window.close())
-- Power menu — Super+Shift+Q used to instantly kill the WM, which was too easy
-- to fat-finger and lost an entire session's worth of windows. Now it's a
-- fuzzel prompt with Cancel as the default action.
bind("SHIFT + Q", hl.dsp.exec_cmd([[case "$(printf 'Cancel\nLock\nSleep\nHibernate\nReboot\nShut Down\n' | fuzzel --dmenu --lines=6 --prompt 'Power: ')" in Lock) loginctl lock-session ;; Sleep) systemctl suspend ;; Hibernate) systemctl hibernate ;; Reboot) systemctl reboot ;; "Shut Down") systemctl poweroff ;; esac]]))

bind("SHIFT + L", hl.dsp.window.resize({ x = 80,  y = 0,   relative = true }), { repeating = true })
bind("SHIFT + H", hl.dsp.window.resize({ x = -80, y = 0,   relative = true }), { repeating = true })
bind("SHIFT + K", hl.dsp.window.resize({ x = 0,   y = -80, relative = true }), { repeating = true })
bind("SHIFT + J", hl.dsp.window.resize({ x = 0,   y = 80,  relative = true }), { repeating = true })

bind("Tab",    hl.dsp.window.cycle_next())
bind("RETURN", hl.dsp.exec_cmd(terminal))
bind("SPACE",  hl.dsp.exec_cmd(menu))
-- Cycle keyboard layout (us(dvorak) <-> us, per the input block above).
-- `all` covers every keyboard: this laptop enumerates seven of them, so a
-- per-device bind would leave most of them on the old layout.
bind("SHIFT + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))
bind("E", hl.dsp.exec_cmd(fileManager))
bind("V", hl.dsp.window.float({ action = "toggle" }))
bind("Z", hl.dsp.layout("togglesplit"))
bind("F", hl.dsp.window.fullscreen())

-- Notifications. Wayland dunst has no native hotkeys, so dunstctl does it:
-- N recalls the most recently dismissed notification, SHIFT+N clears the deck.
bind("N",         hl.dsp.exec_cmd("dunstctl history-pop"))
bind("SHIFT + N", hl.dsp.exec_cmd("dunstctl close-all"))

bind("H", hl.dsp.focus({ direction = "left" }))
bind("L", hl.dsp.focus({ direction = "right" }))
bind("K", hl.dsp.focus({ direction = "up" }))
bind("J", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    bind(tostring(i % 10),              hl.dsp.focus({ workspace = i }))
    bind("SHIFT + " .. tostring(i % 10), hl.dsp.window.move({ workspace = i, follow = false }))
end

bind("S",         hl.dsp.workspace.toggle_special("magic"))
bind("SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

bind("mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),      { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("~/.local/bin/brightness-osd 10%+"),               { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.local/bin/brightness-osd 10%-"),               { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Lid: blank the panel, do not sleep. logind is set to "ignore" for the lid
-- on AC (hyprpower [lid] ac), so nothing else acts on it. Only the compositor
-- can power down its own output -- acpid sees the lid event too, but it runs
-- as root and cannot reach this session.
hl.bind("switch:on:Lid Switch",  hl.dsp.dpms({ action = "off" }), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ action = "on" }),  { locked = true })

bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -z -m output"))

-- Cursor zoom: SHIFT+equal zooms in, minus zooms out.
local function zoom(f)
    return function() hl.config({ cursor = { zoom_factor = math.max(1, hl.get_config("cursor.zoom_factor") * f) } }) end
end
bind("SHIFT + equal", zoom(1.3), { repeating = true })
bind("minus",         zoom(0.6), { repeating = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })

hl.layer_rule({ name = "ags-nm-panel-no-anim", match = { namespace = "ags-nm-panel" }, no_anim = true })

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
