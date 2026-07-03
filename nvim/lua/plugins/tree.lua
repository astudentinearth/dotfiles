return {{
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
{
  "antosha417/nvim-lsp-file-operations",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-tree.lua", -- Integrates directly into your tree
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
