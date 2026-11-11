return {
    "mrjones2014/legendary.nvim",
    lazy = false,
    priority = 10000,
    opts = {
        extensions = { lazy_nvim = true },
        sort = { frecency = false },
        funcs = vim.list_extend({
            {
                function()
                    local names, seen = {}, {}
                    for _, client in ipairs(vim.lsp.get_clients()) do
                        if not seen[client.name] then
                            seen[client.name] = true
                            table.insert(names, client.name)
                        end
                    end
                    if #names == 0 then
                        vim.notify('No active LSPs to restart', vim.log.levels.INFO)
                        return
                    end
                    vim.lsp.enable(names, false)
                    vim.schedule(function()
                        vim.lsp.enable(names, true)
                    end)
                end,
                description = 'Restart all active LSPs',
            },
            { function() require('telescope.builtin').find_files() end, description = 'Find files' },
            { function() require('fzf-lua').live_grep() end, description = 'Search project text' },
            { function() require('fzf-lua').live_grep({ resume = true }) end, description = 'Resume project text search' },
            { function() require('fzf-lua').lsp_workspace_symbols() end, description = 'Search workspace symbols' },
            { function() vim.cmd('Neotree toggle') end, description = 'Toggle file explorer' },
            { function() require('config.biome').format() end, description = 'Format file' },
            { function() vim.lsp.buf.code_action() end, description = 'Code actions' },
            { function() require('telescope.builtin').colorscheme() end, description = 'Choose installed colorscheme' },
        }, require('config.cpp.legendary')),
    },
}
