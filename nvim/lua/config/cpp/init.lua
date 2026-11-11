local M = {}
function M.setup()
    require('config.cpp.getter').setup()
    local commands = {
        CppRuleOf3 = { function() require('config.cpp.rules').generate(3) end, 'Generate defaulted Rule of 3 members' },
        CppRuleOf5 = { function() require('config.cpp.rules').generate(5) end, 'Generate defaulted Rule of 5 members' },
        CppOutline = { function(opts)
            local target = require('config.cpp.outline').generate(opts.args)
            vim.cmd('sbuffer ' .. target)
        end, 'Define member in an implementation file' },
    }
    for name, spec in pairs(commands) do
        vim.api.nvim_create_user_command(name, function(opts)
            local ok, err = pcall(spec[1], opts)
            if not ok then vim.notify(tostring(err), vim.log.levels.WARN, { title = name }) end
        end, { nargs = name == 'CppOutline' and '?' or 0, complete = name == 'CppOutline' and 'file' or nil, desc = spec[2] })
    end
    vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('CppHelpers', { clear = true }),
        pattern = 'cpp',
        callback = function(event)
            for key, command in pairs({ ['<leader>c3'] = 'CppRuleOf3', ['<leader>c5'] = 'CppRuleOf5', ['<leader>co'] = 'CppOutline' }) do
                vim.keymap.set('n', key, '<Cmd>' .. command .. '<CR>', { buffer = event.buf, desc = commands[command][2] })
            end
        end,
    })
end
return M
