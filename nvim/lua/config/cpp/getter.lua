local M = {}

local function text(node, buf)
    return vim.treesitter.get_node_text(node, buf)
end

local function fail(message)
    error(message, 0)
end

-- Tree-sitter understands syntax, not C++ types. Deliberately generate a
-- C++14 by-value getter (auto), rather than pretending to resolve typedefs.
function M.generate(name)
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype ~= 'cpp' then
        fail('Use a C++ buffer (:setfiletype cpp for a misdetected .h file).')
    end
    local ok, parser = pcall(vim.treesitter.get_parser, buf, 'cpp')
    if not ok or not parser then
        fail('C++ parser unavailable. Run :TSInstall cpp, wait, then retry.')
    end
    parser:parse() -- Refresh the tree after any edits.
    local node = vim.treesitter.get_node({ bufnr = buf, ignore_injections = true })
    while node and node:type() ~= 'field_declaration' do
        node = node:parent()
    end
    if not node then fail('Place the cursor on a data member declaration.') end
    local body = node:parent()
    local class = body and body:parent()
    if not class or (class:type() ~= 'class_specifier' and class:type() ~= 'struct_specifier') then
        fail('Only direct class/struct members are supported.')
    end
    if class:has_error() then fail('Fix syntax errors in this class first.') end
    local fields = node:field('declarator')
    if #fields ~= 1 or fields[1]:type() ~= 'field_identifier' then
        fail('Use a single plain data member; pointers, references, arrays and methods are not supported.')
    end
    for child in node:iter_children() do
        if child:type() == 'bitfield_clause' or child:type() == 'storage_class_specifier' then
            fail('Bitfields and storage-qualified members are not supported.')
        end
    end
    local member = text(fields[1], buf)
    if not name or name == '' then
        name = member:gsub('^m_', ''):gsub('_+$', '')
        if name == member then name = 'get' .. member:sub(1, 1):upper() .. member:sub(2) end
    end
    if not name:match('^[a-zA-Z][a-zA-Z0-9_]*$') then fail('Use a simple getter identifier starting with a letter.') end
    -- Reject keywords as well as names colliding with existing direct members.
    local keywords = ' alignas alignof and and_eq asm auto bitand bitor bool break case catch char char8_t char16_t char32_t class compl concept const consteval constexpr constinit const_cast continue co_await co_return co_yield decltype default delete do double dynamic_cast else enum explicit export extern false float for friend goto if inline int long mutable namespace new noexcept not not_eq nullptr operator or or_eq private protected public register reinterpret_cast requires return short signed sizeof static static_assert static_cast struct switch template this thread_local throw true try typedef typeid typename union unsigned using virtual void volatile wchar_t while xor xor_eq '
    if keywords:find(' ' .. name .. ' ', 1, true) or name:find('__', 1, true) then
        fail('Getter name is a keyword or reserved identifier.')
    end
    local function collides(n)
        if (n:type() == 'field_identifier' or n:type() == 'type_identifier') and text(n, buf) == name then
            return true
        end
        for child in n:iter_children() do
            -- Do not search method bodies, initializers, or nested classes.
            if child:type() ~= 'compound_statement' and child:type() ~= 'field_initializer_list'
                and child:type() ~= 'class_specifier' and child:type() ~= 'struct_specifier'
                and collides(child) then return true end
        end
        return false
    end
    if collides(body) then fail('A member with that name already exists; supply another name.') end
    local class_name = class:field('name')[1]
    if class_name and text(class_name, buf) == name then fail('Getter cannot have the class name.') end

    local row, _, endrow = body:range()
    if row == endrow then fail('Expand the class onto multiple lines first.') end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local classrow = class:range()
    local indent = lines[classrow + 1]:match('^%s*')
    local width = vim.bo[buf].shiftwidth
    if width == 0 then width = vim.bo[buf].tabstop end
    local unit = vim.bo[buf].expandtab and string.rep(' ', width) or '\t'
    local insertion, access_indent
    for child in body:iter_children() do
        if child:type() == 'access_specifier' and text(child, buf) == 'public' then
            local r = child:range()
            if lines[r + 1]:match('^%s*public%s*:%s*$') then
                insertion = r + 1
                access_indent = lines[r + 1]:match('^%s*')
                break
            end
        end
    end
    local added = {}
    if not insertion then
        -- Append a new section just before the closing brace. This leaves the
        -- access of every existing declaration unchanged, even in structs.
        if not lines[endrow + 1]:match('^%s*}') then fail('Put the class closing brace on its own line first.') end
        insertion = endrow
        access_indent = indent
        added[#added + 1] = access_indent .. 'public:'
    end
    added[#added + 1] = access_indent .. unit .. 'auto ' .. name .. '() const { return this->' .. member .. '; }'
    -- Buffer line APIs use zero-based rows and an exclusive end. Equal start
    -- and end means insertion; one call also makes this a single undo step.
    vim.api.nvim_buf_set_lines(buf, insertion, insertion, false, added)
end

function M.setup()
    vim.api.nvim_create_user_command('CppGetter', function(opts)
        local ok, err = pcall(M.generate, opts.args)
        if not ok then vim.notify(tostring(err), vim.log.levels.WARN, { title = 'CppGetter' }) end
    end, { nargs = '?', desc = 'Generate a public C++ getter for the member under the cursor' })
    vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('CppGetter', { clear = true }),
        pattern = 'cpp',
        callback = function(event)
            vim.keymap.set('n', '<leader>cg', '<Cmd>CppGetter<CR>', {
                buffer = event.buf, desc = 'Generate C++ getter',
            })
        end,
    })
end

return M
