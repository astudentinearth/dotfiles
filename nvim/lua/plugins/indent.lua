return {
    {
        -- Indent width is per-project, not per-filetype: C is 4 in limine-test
        -- while C++ is 2 in chip-8, and neither has an .editorconfig. Detect it
        -- from the buffer instead of mapping it by filetype. Defers to
        -- .editorconfig where one exists (override_editorconfig is off by
        -- default), so darkwrite keeps its own setting.
        "NMAC427/guess-indent.nvim",
        opts = {},
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {
            indent = { char = "│" },
            -- Off deliberately. ibl's scope needs a treesitter parser: nvim 0.12
            -- bundles `c` but not `cpp`/`typescript`, so leaving this on would
            -- light up scope in C files only and stay dark everywhere else.
            scope = { enabled = false },
            exclude = { filetypes = { "NvimTree", "oil" } },
        },
    },
}
