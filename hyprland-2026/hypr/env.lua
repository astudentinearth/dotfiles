-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

local cfg = require("misc");

hl.env("XCURSOR_SIZE", cfg.theme.cursor_size)
hl.env("HYPRCURSOR_SIZE", cfg.theme.cursor_size)
hl.env("XCURSOR_THEME", cfg.theme.cursor)
hl.env("HYPRCURSOR_THEME", cfg.theme.cursor)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
