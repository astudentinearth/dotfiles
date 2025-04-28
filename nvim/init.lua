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


vim.cmd("NvimTreeOpen")
