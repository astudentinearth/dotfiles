return {
  "rmagatti/auto-session",
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    suppressed_dirs = { "~/", "~/src", "~/Downloads", "/" },
    bypass_save_filetypes = { 'NvimTree', 'alpha', 'dashboard'},
    -- log_level = 'debug',
  },
}
