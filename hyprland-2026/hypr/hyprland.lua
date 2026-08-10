require("env")
require("devices");
require("binds");
require("animations");
require("window-rules")

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper & mako & vicinae server & kdeconnect-indicator & zen-browser")
end)

hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 8,

        border_size      = 1,

        col              = {
            active_border   = "rgba(957FB8ff)",
            inactive_border = "rgba(54546Dff)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing    = false,

        layout           = "master",
    },

    decoration = {
        rounding         = 12,
        rounding_power   = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow           = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color        = "rgba(00000033)",
            scale = 2
        },

        blur             = {
            enabled  = true,
            size     = 4,
            passes   = 4,
            vibrancy = 0.1696,
            popups = true
        },
    },

    animations = {
        enabled = true,
    },
    misc = {
        force_default_wallpaper = -1,   -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})



local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name           = "suppress-maximize-events",
    match          = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name     = "fix-xwayland-drags",
    match    = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
