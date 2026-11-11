local M = {}
function M.text(node, buf) return vim.treesitter.get_node_text(node, buf or 0) end
function M.context()
    if vim.bo.filetype ~= 'cpp' then error('Use a C++ buffer.', 0) end
    local ok, parser = pcall(vim.treesitter.get_parser, 0, 'cpp')
    if not ok or not parser then error('Install the parser with :TSInstall cpp first.', 0) end
    parser:parse()
    local node = vim.treesitter.get_node({ ignore_injections = true })
    local class = node
    while class and class:type() ~= 'class_specifier' and class:type() ~= 'struct_specifier' do class = class:parent() end
    if not class or class:has_error() then error('Place the cursor inside a syntactically valid class/struct.', 0) end
    local name = class:field('name')[1]
    if not name or name:type() ~= 'type_identifier' then error('Only named, non-specialized classes are supported.', 0) end
    return node, class, M.text(name), class:field('body')[1]
end
function M.walk(node, visit)
    if visit(node) == false then return end
    for child in node:iter_children() do M.walk(child, visit) end
end
function M.function_node(node)
    local found
    M.walk(node, function(n)
        if n:type() == 'compound_statement' then return false end
        if n:type() == 'function_declarator' then found = found or n; return false end
    end)
    return found
end
function M.public_insert(class, body, additions)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local start, _, finish = body:range()
    if start == finish then error('Expand the class onto multiple lines first.', 0) end
    local row, indent
    for child in body:iter_children() do
        local r = child:range()
        if child:type() == 'access_specifier' and M.text(child) == 'public'
            and lines[r + 1]:match('^%s*public%s*:%s*$') then
            row, indent = r + 1, lines[r + 1]:match('^%s*'); break
        end
    end
    local out = {}
    if not row then
        if not lines[finish + 1]:match('^%s*}') then error('Put the closing brace on its own line.', 0) end
        row = finish
        indent = lines[class:range() + 1]:match('^%s*')
        out[1] = indent .. 'public:'
    end
    local width = vim.bo.shiftwidth == 0 and vim.bo.tabstop or vim.bo.shiftwidth
    local unit = vim.bo.expandtab and string.rep(' ', width) or '\t'
    for _, line in ipairs(additions) do out[#out + 1] = indent .. unit .. line end
    vim.api.nvim_buf_set_lines(0, row, row, false, out)
end
return M
