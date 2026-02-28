return {
  "lervag/vimtex",
  lazy = false, -- vimtex needs to load immediately on startup to hijack the .tex filetype
  init = function()
    -- lock in skim as the default viewer
    vim.g.vimtex_view_method = "skim"

    -- use latexmk for compiling (this is the default, but good to be explicit)
    vim.g.vimtex_compiler_method = "latexmk"
    
    -- keeps your screen from getting hijacked by the quickfix window every time you make a typo
    vim.g.vimtex_quickfix_mode = 0 
  end,
}
