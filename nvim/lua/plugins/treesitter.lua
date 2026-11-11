return {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = function()
        if vim.fn.executable('tree-sitter') == 1 then
            vim.cmd('TSUpdate')
        end
    end,
    config = function()
        if vim.fn.executable('tree-sitter') == 0 then
            vim.schedule(function()
                vim.notify(
                    'C++ parser installation skipped: tree-sitter CLI is missing. '
                        .. 'Apply the Nix configuration, restart Neovim, then run :TSInstall cpp.',
                    vim.log.levels.WARN,
                    { title = 'Tree-sitter' }
                )
            end)
            return
        end
        require('nvim-treesitter').install({ 'cpp' })
    end,
}
