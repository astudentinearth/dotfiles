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
vim.keymap.set('n', "gt", ":bnext<CR>", { desc = "Next tab" })
vim.keymap.set('n', "gT", ":bprev<CR>", { desc = "Prev tab" })
vim.keymap.set('n', "g.", ":FzfLua lsp_code_actions<CR>", { desc = "View code actions" })
vim.keymap.set("n", "grr", "<cmd>FzfLua lsp_references<cr>", { silent = true })
vim.keymap.set("n", "gri", "<cmd>FzfLua lsp_implementations<cr>", { silent = true })
vim.keymap.set("n", "grt", "<cmd>FzfLua lsp_typedefs<cr>", { silent = true })
vim.keymap.set("n", "grd", function() vim.diagnostic.open_float() end );
vim.keymap.set('n', '<leader>c', ':CopilotChatToggle<CR>');
vim.keymap.set('n', '<leader>b', ':NvimTreeToggle<CR>');
vim.keymap.set('n', '<leader>w', ':bdelete<CR>');
vim.keymap.set('n', '<leader>s', ':Copilot suggest');

vim.lsp.enable("biome");


vim.api.nvim_create_user_command("OrganizeImports", function()
  local bufnr = vim.api.nvim_get_current_buf()
  -- Grab the ts_ls client attached to the current buffer
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "ts_ls" })
  
  if #clients == 0 then
    vim.notify("ts_ls isn't attached to this buffer tbh", vim.log.levels.WARN)
    return
  end

  -- Fire the command using the modern exec_cmd API
  clients[1]:exec_cmd({
    command = "_typescript.organizeImports",
    arguments = { vim.api.nvim_buf_get_name(bufnr) },
    title = "Organize Imports"
  }, { bufnr = bufnr })
end, { desc = "Organize TypeScript imports with ts_ls" })
