-- Run from repo root: nvim --headless -u NONE '+set rtp+=PARSER_PARENT' -l dotfiles/nvim/tests/cpp/helpers.lua
package.path = './dotfiles/nvim/lua/?.lua;./dotfiles/nvim/lua/?/init.lua;' .. package.path
local rules = require('config.cpp.rules')
local outline = require('config.cpp.outline')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local counter = 0
local function buffer(source, needle)
    counter = counter + 1
    vim.cmd('enew!')
    vim.api.nvim_buf_set_name(0, dir .. '/test' .. counter .. '.hpp')
    vim.bo.filetype = 'cpp'
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 4
    local lines = vim.split(source, '\n', { plain = true })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    for r, line in ipairs(lines) do
        local c = line:find(needle, 1, true)
        if c then vim.api.nvim_win_set_cursor(0, { r, c - 1 }); break end
    end
    return vim.api.nvim_get_current_buf()
end
local function content(buf) return table.concat(vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false), '\n') end
buffer('class Foo {\n    int x_;\n};', 'x_')
rules.generate(3)
assert(content():find('Foo(const Foo&) = default;', 1, true))
assert(content():find('Foo() = default;', 1, true))
assert(not content():find('Foo&&', 1, true))
local before = content()
assert(not pcall(rules.generate, 3) and content() == before)
rules.generate(5)
assert(content():find('Foo(Foo&&) = default;', 1, true))
before = content()
assert(not pcall(rules.generate, 5) and content() == before)
buffer('class Foo {\npublic:\n    Foo(int);\n    ~Foo();\n    Foo(const Foo&) = delete;\n    Foo& operator=(const Foo&) = delete;\n};', 'Foo(int)')
rules.generate(5)
assert(not content():find('Foo() = default;', 1, true))
assert(not content():find('Foo(const Foo&) = default;', 1, true))
local h = buffer('namespace app {\nclass Foo {\npublic:\n    int value(int n = 3) const { return n; }\n};\n}', 'value')
local target = outline.generate()
assert(content(h):find('int value(int n = 3) const;', 1, true), content(h))
assert(content(target):find('namespace app {', 1, true))
assert(content(target):find('Foo::value(int n ', 1, true), content(target))
assert(not content(target):find('= 3', 1, true))
assert(content(target):find('{ return n; }', 1, true))
assert(not pcall(outline.generate), 'Reject duplicate')
-- Compile a moved definition to check declaration/definition consistency.
vim.fn.writefile(vim.api.nvim_buf_get_lines(h, 0, -1, false), vim.api.nvim_buf_get_name(h))
vim.fn.writefile(vim.api.nvim_buf_get_lines(target, 0, -1, false), vim.api.nvim_buf_get_name(target))
vim.fn.system({ 'c++', '-std=c++17', '-fsyntax-only', vim.api.nvim_buf_get_name(target) })
assert(vim.v.shell_error == 0, 'Generated implementation must compile')
h = buffer('class Foo {\npublic:\n    explicit Foo(int x = 1) : x_(x) {}\nprivate:\n    int x_;\n};', 'explicit')
target = outline.generate()
assert(content(h):find('explicit Foo(int x = 1);', 1, true), content(h))
assert(content(target):find('Foo::Foo(int x ', 1, true), content(target))
assert(content(target):find(': x_(x) {}', 1, true))
h = buffer('class Foo {\npublic:\n    static int value(int n = 2);\n};', 'value')
before = content(h)
target = outline.generate()
assert(content(h) == before)
assert(not content(target):find('static', 1, true))
assert(content(target):find('TODO: implement', 1, true))
h = buffer('class Foo {\npublic:\n    inline int value() { return 7; }\n};', 'value')
local existing = dir .. '/existing.cpp'
vim.fn.writefile({ '// Preserve this content', '#include "' .. vim.fs.basename(vim.api.nvim_buf_get_name(h)) .. '"' }, existing)
target = outline.generate(existing)
assert(content(target):find('// Preserve this content', 1, true))
assert(not content(h):find('inline', 1, true) and not content(target):find('inline', 1, true))
assert(content(h):find('int value();', 1, true))
vim.fn.writefile(vim.api.nvim_buf_get_lines(h, 0, -1, false), vim.api.nvim_buf_get_name(h))
vim.fn.writefile(vim.api.nvim_buf_get_lines(target, 0, -1, false), existing)
vim.fn.system({ 'c++', '-std=c++17', '-fsyntax-only', existing })
assert(vim.v.shell_error == 0, 'Explicit-inline move must compile')
for _, source in ipairs({
    'template<class T> class Foo {\n    int value();\n};',
    'class Foo {\n    virtual int value() = 0;\n};',
    'class Foo {\n    constexpr int value() { return 1; }\n};',
    'class Outer {\n    class Foo {\n        int value();\n    };\n};',
}) do
    buffer(source, 'value')
    before = content()
    assert(not pcall(outline.generate) and content() == before, source)
end
require('config.cpp').setup()
assert(vim.fn.exists(':CppRuleOf3') == 2 and vim.fn.exists(':CppOutline') == 2)
vim.fn.delete(dir, 'rf')
print('C++ helper tests passed')
