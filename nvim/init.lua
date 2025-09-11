vim.opt.mouse = 'a'
vim.opt.tabstop = 4
vim.opt.ignorecase = true
vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.expandtab = true

require("config.lazy")

local tree = require("nvim-tree")
tree.setup({
    view = {
        width = 20
    }
})

vim.opt.termguicolors = true
require("bufferline").setup()
require("lualine").setup()
vim.cmd("NvimTreeOpen")
vim.cmd("TransparentEnable")
vim.opt.splitright = true
vim.g.mapleader = " "
vim.filetype.add({
    extension = {
        yuck = "lisp",
    },
})

require("fzf-lua").register_ui_select()
vim.keymap.set('n', '<leader>f', ':FzfLua files<CR>', { desc = 'Go to next tab' })
vim.keymap.set('n', '<leader><S-f>', function()
    vim.lsp.buf.format()
end, { desc = "Format file" })

vim.keymap.set('n', "<leader>p", ":FzfLua<CR>", { desc = "Fzflua palette" })
vim.keymap.set('n', "<leader><Tab>", ":BufferLineCycleNext<CR>", { desc = "Next tab" })
vim.keymap.set('n', "<leader><S-Tab>", ":BufferLineCyclePrev<CR>", { desc = "Prev tab" })
vim.keymap.set('n', "<leader>.", ":FzfLua lsp_code_actions<CR>", { desc = "View code actions" })
vim.keymap.set('n', '<leader>c', ':CopilotChatToggle<CR>');
