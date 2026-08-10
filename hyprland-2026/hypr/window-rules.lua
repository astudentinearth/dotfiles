
hl.window_rule({
    name = "pavucontrol-position",
    match = { class = "org.pulseaudio.pavucontrol" },
    move = { 1319, 40 }
})

local float = function (class)
    hl.window_rule({ match = { class = class }, float = true})
end

float("Emulator")
float("qt6ct")
float("xdg-desktop-portal-gtk")
float("org.kde.dolphin")
float("org.kde.ark")
float("org.deskflow.deskflow")
float("gjs")

-- blur bars 

hl.layer_rule({
    match = { namespace = "gtk4-layer-shell" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.1
})

