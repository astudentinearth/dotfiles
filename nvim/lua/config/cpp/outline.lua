local C = require('config.cpp.common')
local M = {}
function M.generate(destination)
    local node, class, name, body = C.context()
    local header = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(header)
    if path == '' or not path:match('%.h[px+]*$') and not path:match('%.hh$') then
        error('Run this from a named C++ header (.h, .hpp, .hxx, .hh).', 0)
    end
    local namespaces = {}
    local ancestor = class:parent()
    while ancestor do
        if ancestor:type() == 'namespace_definition' then
            local n = ancestor:field('name')[1]
            if not n then error('Anonymous namespaces are not supported.', 0) end
            table.insert(namespaces, 1, C.text(n))
        elseif ancestor:type() ~= 'declaration_list' and ancestor:type() ~= 'translation_unit' then
            error('Templates, nested/local classes and conditional classes are not supported.', 0)
        end
        ancestor = ancestor:parent()
    end
    while node and node:parent() ~= body do node = node:parent() end
    if not node or not vim.tbl_contains({ 'field_declaration', 'declaration', 'function_definition' }, node:type()) then
        error('Place the cursor on a direct member function.', 0)
    end
    local fn = C.function_node(node)
    if not fn then error('No member function found.', 0) end
    local decl = fn:field('declarator')[1]
    if not decl or not vim.tbl_contains({ 'field_identifier', 'identifier', 'destructor_name' }, decl:type()) then
        error('Operators and complex declarators are not supported yet.', 0)
    end
    local method = C.text(decl)
    local return_type = node:field('type')[1]
    if return_type and return_type:type() == 'type_identifier' then
        error('Qualify named return types first (for example Foo::Result or std::string).', 0)
    end
    if return_type and C.text(return_type) == 'auto' and not C.text(fn):find('->', 1, true) then
        error('Deduced auto return types must remain visible in the header; use an explicit return type.', 0)
    end
    local original = C.text(node)
    if original:match('=%s*0%s*;') or original:match('=%s*default') or original:match('=%s*delete') then
        error('Pure virtual, defaulted and deleted functions are not supported.', 0)
    end
    local unsupported
    C.walk(node, function(n)
        if n:type() == 'compound_statement' then return false end
        if vim.tbl_contains({ 'friend', 'constexpr', 'consteval', 'template_declaration', 'requires_clause',
            'attribute_declaration', 'attribute_specifier', 'try_statement' }, n:type())
            or C.text(n) == 'constexpr' or C.text(n) == 'consteval' then unsupported = true end
    end)
    if unsupported then error('Friend, constexpr, constrained, attributed and function-try declarations need manual handling.', 0) end
    local nr, nc = node:range()
    local base = vim.api.nvim_buf_get_offset(header, nr) + nc
    local function offset(n)
        local r, c, er, ec = n:range()
        return vim.api.nvim_buf_get_offset(header, r) + c - base,
            vim.api.nvim_buf_get_offset(header, er) + ec - base
    end
    local edits, header_edits = {}, {}
    local function replace(n, value)
        local s, e = offset(n)
        edits[#edits + 1] = { s, e, value }
    end
    replace(decl, name .. '::' .. method)
    C.walk(node, function(n)
        if n:type() == 'compound_statement' then return false end
        if n:type() == 'optional_parameter_declaration' then
            local value = n:field('default_value')[1]
            if not value then error('Unsupported default argument.', 0) end
            local s = offset(n)
            local v, e = offset(value)
            local prefix = original:sub(s + 1, v)
            local eq = prefix:match('.*()=')
            if not eq then error('Unsupported default argument.', 0) end
            edits[#edits + 1] = { s + eq - 1, e, '' }
            return false
        end
        if n:type() == 'explicit_function_specifier' or n:type() == 'virtual_specifier'
            or C.text(n) == 'virtual' or C.text(n) == 'static' or C.text(n) == 'inline' then
            if C.text(n) == 'inline' then
                local s, e = offset(n)
                header_edits[#header_edits + 1] = { s, e }
            end
            replace(n, ''); return false
        end
    end)
    table.sort(edits, function(a, b) return a[1] > b[1] end)
    local definition = original
    for _, edit in ipairs(edits) do
        definition = definition:sub(1, edit[1]) .. edit[3] .. definition:sub(edit[2] + 1)
    end
    local implementation = node:field('body')[1]
    local replacement
    if implementation then
        local start = offset(implementation)
        -- Constructor initializer lists belong with the implementation.
        for child in node:iter_children() do
            if child:type() == 'field_initializer_list' then start = offset(child) end
        end
        replacement = original:sub(1, start):gsub('%s+$', '') .. ';'
    else
        definition = definition:gsub(';%s*$', '') .. '\n{\n    // TODO: implement\n    throw "Not implemented";\n}'
    end
    -- An explicit inline declaration cannot remain in the header when its
    -- definition is only available in a .cpp translation unit.
    if #header_edits > 0 then
        replacement = replacement or original
        table.sort(header_edits, function(a, b) return a[1] > b[1] end)
        for _, edit in ipairs(header_edits) do
            replacement = replacement:sub(1, edit[1]) .. replacement:sub(edit[2] + 1)
        end
        replacement = replacement:gsub('^%s+', '')
    end
    definition = definition:gsub('^%s+', '')
    -- Preserve the namespace scope for parameter/return types as well as names.
    for i = #namespaces, 1, -1 do definition = 'namespace ' .. namespaces[i] .. ' {\n\n' .. definition .. '\n\n}' end

    local dir = vim.fs.dirname(path)
    if not destination or destination == '' then
        local stem = path:gsub('%.[^.]+$', '')
        local matches = {}
        for _, ext in ipairs({ '.cpp', '.cc', '.cxx' }) do
            local candidate = stem .. ext
            if vim.fn.filereadable(candidate) == 1 or vim.fn.bufexists(candidate) == 1 then matches[#matches + 1] = candidate end
        end
        if #matches > 1 then error('Multiple source files found; use :CppOutline path/to/file.cpp.', 0) end
        destination = matches[1] or stem .. '.cpp'
    else
        destination = vim.fn.fnamemodify(destination, ':p')
    end
    if destination == path then error('Destination must differ from the header.', 0) end
    if not destination:match('%.c[px+]*$') and not destination:match('%.cc$') then error('Choose a .cpp, .cc or .cxx file.', 0) end
    if vim.fn.isdirectory(vim.fs.dirname(destination)) == 0 then error('Destination directory does not exist.', 0) end
    local target = vim.fn.bufadd(destination)
    vim.fn.bufload(target)
    if not vim.bo[target].modifiable or vim.bo[target].readonly then error('Destination is not writable.', 0) end
    local lines = vim.api.nvim_buf_get_lines(target, 0, -1, false)
    -- Conservative: avoid silently generating a duplicate; overloads need review.
    if table.concat(lines, '\n'):find(name .. '::' .. method, 1, true) then
        error('A definition with this qualified name already exists (overloads require manual handling).', 0)
    end
    if not vim.bo[header].modifiable or vim.bo[header].readonly then error('Header is not writable.', 0) end
    local empty = #lines == 1 and lines[1] == ''
    local added = { '', definition }
    if empty then
        if vim.fs.dirname(destination) ~= dir then error('For a new source in another directory, create it with the correct #include first.', 0) end
        added = { '#include "' .. vim.fs.basename(path) .. '"', '', definition }
    end
    local newlines = vim.split(table.concat(added, '\n'), '\n', { plain = true })
    vim.api.nvim_buf_set_lines(target, empty and 0 or #lines, empty and 1 or #lines, false, newlines)
    vim.bo[target].filetype = 'cpp'
    if replacement then
        local sr, sc, er, ec = node:range()
        vim.api.nvim_buf_set_text(header, sr, sc, er, ec, vim.split(replacement, '\n', { plain = true }))
    end
    vim.notify('Definition added to ' .. destination .. '. Buffers are unsaved; undo separately in each buffer.', vim.log.levels.INFO)
    return target
end
return M
