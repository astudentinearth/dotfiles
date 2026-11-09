return {
--[[
{
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("nvim-tree").setup {}
    end,
},
]]
{
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    window = {
      position = "left",
      width = 20,
      mappings = {
        ["<C-x>"] = "open_split",
        ["<C-v>"] = "open_vsplit",
        ["O"] = function(state)
          local node = state.tree:get_node()
          if node and (node.type == "file" or node.type == "directory") then
            local _, err = vim.ui.open(node:get_id())
            if err then
              vim.notify(tostring(err), vim.log.levels.ERROR)
            end
          end
        end,
      },
    },
    filesystem = {
      window = {
        mappings = {
          ["<C-x>"] = "open_split", -- Override filesystem's clear_filter mapping.
        },
      },
      bind_to_cwd = false,
      follow_current_file = { enabled = false },
      use_libuv_file_watcher = true,
    },
  },
},
{
  "antosha417/nvim-lsp-file-operations",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-neo-tree/neo-tree.nvim", -- Load after Neo-tree for file-operation integration
  },
  config = function()
    require("lsp-file-operations").setup()
  end,
},
{
  'stevearc/oil.nvim',
  opts = {},
}
}
