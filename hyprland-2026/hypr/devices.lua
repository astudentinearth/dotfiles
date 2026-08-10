
hl.device({
    name = "logitech-g305-1",
    sensitivity = -0.7
});

hl.device({
    name = "msnb0001:00-04f3:30aa-touchpad",
    sensitivity = -0.1
})


hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

hl.config({
    input = {
        kb_layout  = "tr",
        kb_variant = "",
        kb_model   = "",
        kb_options = "altwin:swap_lalt_lwin,ctrl:nocaps",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = -0.86, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            scroll_factor = 0.35
        },
    },
})


hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
