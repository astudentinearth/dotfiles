local C = require('config.cpp.common')
local M = {}
function M.generate(count)
    local _, class, name, body = C.context()
    local seen, has_constructor = {}, false
    for child in body:iter_children() do
        if child:type():match('^preproc') or child:type() == 'template_declaration' then
            error('Conditional members and member templates require manual review.', 0)
        end
        local fn
        local member_type = child:field('type')[1]
        if vim.tbl_contains({ 'declaration', 'field_declaration', 'function_definition' }, child:type())
            and not (member_type and vim.tbl_contains({ 'class_specifier', 'struct_specifier' }, member_type:type())) then
            fn = C.function_node(child)
        end
        if fn and child:type() ~= 'class_specifier' and child:type() ~= 'struct_specifier' then
            local decl = fn:field('declarator')[1]
            local n = decl and C.text(decl):gsub('%s+', '') or ''
            if n == '~' .. name then seen.destructor = true end
            if n == name then has_constructor = true end
            if n == name or n == 'operator=' then
                local params = fn:field('parameters')[1]
                local first = params and params:named_child(0)
                local param_type = first and first:field('type')[1]
                local p = first and C.text(first):gsub('%s+', '') or ''
                local kind
                if param_type and C.text(param_type) == name then
                    if p:find('&&', 1, true) then kind = 'move'
                    elseif p:find('&', 1, true) or n == 'operator=' then kind = 'copy' end
                end
                if kind then seen[kind .. (n == name and '_ctor' or '_assign')] = true end
            end
        end
    end
    local additions = {}
    local function add(key, declaration)
        if not seen[key] then additions[#additions + 1] = declaration end
    end
    -- Declaring a copy/move constructor suppresses the implicit default ctor.
    if not has_constructor then additions[#additions + 1] = name .. '() = default;' end
    add('destructor', '~' .. name .. '() = default;')
    add('copy_ctor', name .. '(const ' .. name .. '&) = default;')
    add('copy_assign', name .. '& operator=(const ' .. name .. '&) = default;')
    if count == 5 then
        add('move_ctor', name .. '(' .. name .. '&&) = default;')
        add('move_assign', name .. '& operator=(' .. name .. '&&) = default;')
    end
    if #additions == 0 then error('These special members are already declared.', 0) end
    C.public_insert(class, body, additions)
end
return M
