local M = {}
function M.setup()
    local ls = require('luasnip')
    ls.add_snippets('cpp', {
        ls.snippet('strliteral', {
            ls.text_node('using namespace std::literals::string_literals;'),
        }),
    }, { key = 'cpp-custom' })
end
return M
