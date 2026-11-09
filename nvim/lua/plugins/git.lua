return {
    {
        "lewis6991/gitsigns.nvim",
        name = "gitsigns",
        priority = 1000,
        opts = {
            current_line_blame = true,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol",
                delay = 500,
            },
            current_line_blame_formatter = " <author>, <author_time:%Y-%m-%d> - <summary>",
        },
        config = function(_, opts)
            local function set_blame_highlight()
                vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { link = "Comment" })
            end

            vim.api.nvim_create_autocmd("ColorScheme", {
                group = vim.api.nvim_create_augroup("GitBlameHighlight", { clear = true }),
                callback = set_blame_highlight,
            })
            require("gitsigns").setup(opts)
            set_blame_highlight()
        end,
    }
}

-- "lewis6991/gitsigns.nvim"
