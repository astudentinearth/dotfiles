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
vim.g.mapleader = " "
vim.filetype.add({
    extension = {
        yuck = "lisp",
    },
})


vim.keymap.set('n', '<leader>f', ':FzfLua files<CR>', { desc = 'Go to next tab' })
vim.keymap.set('n', '<leader><S-f>', function()
    vim.lsp.buf.format()
end, { desc = "Format file" })
