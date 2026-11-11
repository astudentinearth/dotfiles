-- Run from the repository root, with a C++ parser on runtimepath:
-- nvim --headless -u NONE '+set rtp+=/path/to/parser-parent' -l dotfiles/nvim/tests/cpp/getter.lua
package.path = './dotfiles/nvim/lua/?.lua;' .. package.path
local getter = require('config.cpp.getter')
local function run(source, member, name)
    vim.cmd('enew!')
    vim.bo.filetype = 'cpp'
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 4
    local lines = vim.split(source, '\n', { plain = true })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    for row, line in ipairs(lines) do
        local col = line:find(member, 1, true)
        if col then vim.api.nvim_win_set_cursor(0, { row, col - 1 }); break end
    end
    local ok, err = pcall(getter.generate, name)
    local result = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    return ok, result, err
end
local ok, result = run('class Foo {\n    int count_;\n};', 'count_')
assert(ok and result:find('public:\n    auto count() const { return this->count_; }', 1, true), result)
ok, result = run('class Foo {\npublic:\n    void f();\nprivate:\n    int m_count = 0;\n};', 'm_count')
assert(ok and result:find('public:\n    auto count() const', 1, true), result)
ok, result = run('struct Foo {\n    std::string label;\n};', 'label', 'labelCopy')
assert(ok and result:find('auto labelCopy() const', 1, true), result)
for _, field in ipairs({ 'int *value_;', 'int &value_;', 'int value_[2];', 'int value_, other_;', 'int value_ : 3;', 'static int value_;', 'int value_();' }) do
    local source = 'class Foo {\n    ' .. field .. '\n};'
    ok, result = run(source, 'value_')
    assert(not ok and result == source, 'Should reject: ' .. field)
end
for _, name in ipairs({ 'count_', 'class', 'Foo', 'bad-name' }) do
    ok = run('class Foo {\n    int count_;\n};', 'count_', name)
    assert(not ok, 'Should reject name: ' .. name)
end
ok = run('class Foo {\npublic:\n    int count() const;\nprivate:\n    int count_;\n};', 'count_')
assert(not ok, 'Should reject duplicate getter')
ok, result = run('class Outer {\n    class Inner {\n        int count_;\n    };\n};', 'count_')
assert(ok and result:find('    public:\n        auto count()', 1, true), result)
print('CppGetter tests passed')
