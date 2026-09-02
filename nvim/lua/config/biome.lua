-- Biome-aware formatting and source actions.
-- Uses the built-in vim.lsp API only (nvim 0.11+); nvim-lspconfig is still
-- installed, but purely for the `lsp/*.lua` definitions on the runtimepath.

local M = {}

--- The biome client attached to `bufnr`, or nil.
local function biome_client(bufnr)
    return vim.lsp.get_clients({ bufnr = bufnr, name = "biome" })[1]
end

--- Whole-buffer range, mark-like indexing: {row, col}, row 1-based, col 0-based.
--- See `:h vim.lsp.buf.code_action()` and `:h api-indexing`.
local function whole_buffer_range(bufnr)
    local last = vim.api.nvim_buf_line_count(bufnr)
    local text = vim.api.nvim_buf_get_lines(bufnr, last - 1, last, true)[1] or ""
    return { start = { 1, 0 }, ["end"] = { last, #text } }
end

--- Request Biome source actions over the whole buffer, not just at the cursor.
--- Biome only offers `source.organizeImports.biome` when the requested range
--- covers the import block, so asking at the cursor silently returns nothing.
--- `kind` nil requests every "source" action and lets the user pick.
local function biome_source_action(kind)
    local bufnr = vim.api.nvim_get_current_buf()
    local client = biome_client(bufnr)
    if not client then
        vim.notify("biome is not attached to this buffer", vim.log.levels.WARN)
        return
    end
    vim.lsp.buf.code_action({
        context = { only = { kind or "source" }, diagnostics = {} },
        range = whole_buffer_range(bufnr),
        filter = function(action, client_id)
            return client_id == client.id
                and (kind == nil or vim.startswith(action.kind or "", kind))
        end,
        apply = kind ~= nil,
    })
end

--- Format, preferring Biome so a second client cannot re-format over its
--- output. Without this, tsgo re-formats TS/TSX using tabstop/shiftwidth
--- instead of biome.json and inflates the diff until lint-staged reverts it.
function M.format()
    local bufnr = vim.api.nvim_get_current_buf()
    local opts = { bufnr = bufnr, async = false }
    if biome_client(bufnr) then
        opts.name = "biome"
    end
    vim.lsp.buf.format(opts)
end

vim.api.nvim_create_user_command("OrganizeImports", function()
    biome_source_action("source.organizeImports.biome")
end, { desc = "Organize imports (Biome)" })

vim.api.nvim_create_user_command("BiomeFixAll", function()
    biome_source_action("source.fixAll.biome")
end, { desc = "Apply Biome's safe fixes to the buffer" })

vim.api.nvim_create_user_command("BiomeAssist", function()
    biome_source_action(nil)
end, { desc = "Pick from Biome's source/assist actions" })

return M
