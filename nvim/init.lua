vim.opt.mouse = 'a'
vim.opt.tabstop = 4
vim.opt.ignorecase = true
vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.scrolloff = 3
vim.opt.expandtab = true
vim.opt.autoread = true

-- Pick up external file changes while preserving buffers with unsaved edits.
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
    group = vim.api.nvim_create_augroup('AutoReload', { clear = true }),
    callback = function()
        if vim.fn.getcmdwintype() ~= '' or vim.fn.mode() == 'c' then
            return
        end
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf)
                and vim.bo[buf].buftype == ''
                and not vim.bo[buf].modified then
                vim.cmd('checktime ' .. buf)
            end
        end
    end,
})

require("config.lazy")

--[[ NvimTree configuration (kept for switching back).
local tree = require("nvim-tree")
tree.setup({
    view = {
        width = 20
    },
    sync_root_with_cwd = false,
    update_focused_file = {
        enable = false,
        update_root = false
    },
    actions = {
        change_dir = {
            enable = false,
            global = false
        }
    }
})

]]

vim.opt.termguicolors = true
require("lualine").setup()
--vim.cmd("TransparentEnable")
vim.opt.splitright = true
vim.g.mapleader = " "
vim.filetype.add({
    extension = {
        yuck = "lisp",
        mdx = "markdown"
    },
})
-- Markdown and MDX (mapped to markdown above) use English spellchecking.
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('MarkdownSpellcheck', { clear = true }),
    pattern = { 'markdown', 'mdx' },
    callback = function()
        vim.opt_local.spell = true
        vim.opt_local.spelllang = 'en'
    end,
})

local actions = require("telescope.actions")
vim.cmd("colorscheme tokyonight-night")

require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
            },
            n = {
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
            },
        },
    },
})

local fzf = require("fzf-lua")
require('telescope').load_extension('ui-select')
vim.keymap.set('n', '<leader>f', require('telescope.builtin').find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>t', fzf.lsp_workspace_symbols, { desc = 'Search workspace symbols' })
vim.keymap.set('n', '<leader>/', fzf.live_grep, { desc = 'Search project text' })
vim.keymap.set('n', '<leader>?', function()
    fzf.live_grep({ resume = true })
end, { desc = 'Resume project text search' })
vim.keymap.set('n', '<leader><S-f>', function()
    require("config.biome").format()
end, { desc = "Format file" })


vim.keymap.set('n', '<leader>p', '<Cmd>Legendary<CR>', { desc = 'Command palette' })
-- Kitty sends F6 for Command-P, including when running through tmux.
vim.keymap.set({ 'n', 'i', 'v' }, '<F1>', '<Cmd>FzfLua diagnostics_document<CR>', { desc = 'Document diagnostics', silent = true })
vim.keymap.set({ 'n', 'i', 'v' }, '<F6>', '<Cmd>Legendary<CR>', { desc = 'Command palette' })
vim.keymap.set('n', "g.", ":FzfLua lsp_code_actions<CR>", { desc = "View code actions" })
vim.keymap.set("n", "grr", "<cmd>FzfLua lsp_references<cr>", { silent = true })
vim.keymap.set("n", "gri", "<cmd>FzfLua lsp_implementations<cr>", { silent = true })
vim.keymap.set("n", "grt", "<cmd>FzfLua lsp_typedefs<cr>", { silent = true })
vim.keymap.set("n", "grd", function() vim.diagnostic.open_float() end);
-- vim.keymap.set('n', '<leader>b', ':NvimTreeToggle<CR>');
vim.keymap.set('n', '<leader>b', '<Cmd>Neotree toggle<CR>', { desc = 'Toggle file explorer' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>')

require("config.biome")


vim.keymap.set('i', '<C-j>', function()
    return vim.fn.pumvisible() == 1 and '<C-n>' or '<C-j>'
end, { expr = true, noremap = true })

vim.keymap.set('i', '<C-k>', function()
    return vim.fn.pumvisible() == 1 and '<C-p>' or '<C-k>'
end, { expr = true, noremap = true })


