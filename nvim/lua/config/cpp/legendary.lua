-- Keep palette entries beside the C++ helpers. Commands are resolved when
-- selected, after config.cpp.setup() has registered them.
return {
    { function() vim.cmd('CppGetter') end, description = 'C++: Generate getter for member' },
    { function() vim.cmd('CppRuleOf3') end, description = 'C++: Generate Rule of 3 members' },
    { function() vim.cmd('CppRuleOf5') end, description = 'C++: Generate Rule of 5 members' },
    { function() vim.cmd('CppOutline') end, description = 'C++: Define member in implementation file' },
    {
        function()
            if vim.bo.filetype ~= 'cpp' then
                vim.notify('Use a C++ buffer.', vim.log.levels.WARN)
                return
            end
            vim.api.nvim_put({ 'using namespace std::literals::string_literals;' }, 'l', true, true)
        end,
        description = 'C++: Insert string literals namespace (strliteral)',
    },
}
