# C++ helpers and Tree-sitter hacking

All custom C++ features live here: `init.lua` registers commands/mappings,
`common.lua` contains shared syntax helpers, `getter.lua`, `rules.lua`, and
`outline.lua` implement the actions, and `snippets.lua` registers LuaSnip snippets.

| Command | Mapping (Space leader) | Action |
| --- | --- | --- |
| `:CppGetter [name]` | `Space c g` | Generate a getter |
| `:CppRuleOf3` | `Space c 3` | Add missing destructor, copy constructor, copy assignment |
| `:CppRuleOf5` | `Space c 5` | Also add move constructor and move assignment |
| `:CppOutline [path]` | `Space c o` | Define the cursor's method in a source buffer |

## Rule of 3 / Rule of 5

Place the cursor inside a class/struct. Missing special members are inserted in
a public section as `= default`. Existing declarations (including `= delete`
and private declarations) are retained. If there are no constructors, a default
constructor is also generated, since adding a copy/move constructor suppresses
the implicit default constructor. Repeating the action does not add duplicates
for ordinary signatures using the class name. Move operations do not receive
an unconditional `noexcept`; defaulting lets C++ infer their exception specs.

**These are scaffolding, not ownership inference.** Raw owning pointers need
handwritten copying/destruction; noncopyable fields may cause defaulted members
to be deleted. Review polymorphic destructor requirements yourself. Prefer the
Rule of Zero when possible. Alias-based or unusually qualified special-member
signatures are not resolved semantically. Conditional members and member
templates are rejected. Check clangd diagnostics after generation.

## Out-of-line definitions in implementation files

Put the cursor on a method declaration or an in-class definition and run
`:CppOutline`. The helper searches alongside the header for a same-stem `.cpp`,
`.cc`, or `.cxx`. Multiple matches require an explicit destination, for example
`:CppOutline src/widget.cpp` (relative to Neovim's working directory).
Otherwise it creates a same-stem `.cpp` buffer and adds an include of the header.
For a new file in another directory, first create it with the correct include.
Existing source files are assumed to already include the header.

The source opens in a split. **Neither file is written automatically.** Review
both buffers, then save them individually. Undo is per-buffer; when moving a
body, undo once in each buffer to roll the operation back.

- Existing bodies and constructor initializer lists move to the source; a
  declaration remains in the header.
- Declarations without bodies generate a TODO stub that throws a string literal
  so non-void methods do not silently fall through. Replace it before use; in
  `noexcept` functions it terminates, and exception-disabled projects must
  replace it before compiling.
- Default arguments stay in the header. `virtual`, `static`, `explicit`,
  `override`, `final`, and `inline` are removed from the source definition.
- Definitions are appended in namespace blocks matching the header. Header
  guards/conditional classes, templates, nested/local classes, operators,
  constexpr/consteval functions, pure/defaulted/deleted methods and deduced
  `auto` returns are intentionally unsupported.
- Named return types must be qualified; class-local aliases can require
  `Class::Type`. Tree-sitter cannot resolve aliases or macro meaning.
- An existing `Class::method` text match in the target blocks generation,
  conservatively including other overloads. This is a guard, not semantic
  duplicate detection. Inspect the source before proceeding.

The implementation works on AST ranges, applies signature edits right-to-left,
and edits only the selected method in the header. Definitions are appended to
the source buffer without overwriting its existing content. Cross-file editing
is not a transactional refactoring engine; review both sides.

## Tests

From the repository root, with a C++ parser on runtimepath:

```sh
nvim --headless -u NONE '+set rtp+=~/.local/share/nvim/site' -l dotfiles/nvim/tests/cpp/getter.lua
nvim --headless -u NONE '+set rtp+=~/.local/share/nvim/site' -l dotfiles/nvim/tests/cpp/helpers.lua
```

The helper tests also compile a generated implementation with `c++`.

# Getter generation walkthrough

## Usage

After applying the Home Manager configuration (adds `tree-sitter` CLI), restart
Neovim and let Lazy install `nvim-treesitter`. Its `main` branch requires Neovim
0.12+, tree-sitter CLI 0.26.1+, and a C compiler, curl and tar on PATH. The C++
parser installs asynchronously; if needed run `:TSInstall cpp` and wait.
This does not enable highlighting or change indentation settings.

In a C++ header, put the cursor on a field declaration and press **Space c g**,
or run `:CppGetter`. Use `:CppGetter customName` to override the name.
If a `.h` file was detected as C, use `:setfiletype cpp` first.

```cpp
class Counter {
    int count_ = 0;
public:
    auto count() const { return this->count_; } // generated
};
```

Naming: `count_` and `m_count` become `count`; `count` becomes `getCount`.
The getter goes immediately after a standalone `public:` label, or in a new
public section before the closing brace. Existing members keep their access.
Undo with `u`; nothing is saved automatically.

Policy: C++14 `auto` return deduction, **by value**, even for strings/containers.
This copies objects; it will not compile for noncopyable members. Tree-sitter
cannot determine copyability or resolve types/typedefs. Review generated code.
Only one plain member per declaration is supported. Pointers, references,
arrays, methods, storage-qualified fields and bitfields are rejected, as are
syntax errors, duplicate names and single-line classes. Macros/preprocessor
branches and unusual C++ constructs are not a semantic refactoring guarantee.

## How it works

Implementation: `lua/config/cpp/getter.lua`. No LSP request is involved.

1. `vim.treesitter.get_parser(buf, 'cpp')` gets Neovim's parser. `parser:parse()`
   refreshes its incremental syntax tree after edits.
2. `vim.treesitter.get_node()` finds the smallest syntax node under the cursor.
   Walking `node:parent()` finds the surrounding `field_declaration`, whether
   the cursor is on its type, name, or initializer.
3. `node:field('declarator')` retrieves grammar-labelled children, rather than
   splitting the line with regex. For `int count_ = 0;`, the declarator is a
   `field_identifier`. An array has an `array_declarator`, a method has a
   `function_declarator`, etc. Checking these shapes prevents bad guesses.
4. The declaration's parent is the class's `field_declaration_list`; its
   parent is a `class_specifier` or `struct_specifier`. This naturally selects
   the inner class when classes are nested.
5. `body:iter_children()` finds direct `access_specifier` children. Reading
   their text distinguishes `public`, `protected`, and `private`.
6. `node:range()` returns **zero-based** start row/column and exclusive end
   row/column. `vim.api.nvim_buf_set_lines()` also uses zero-based, exclusive
   line indices. Equal start/end inserts without replacing existing lines.
   A single buffer edit keeps undo straightforward.

Regex is only used for naming, whitespace and safe line-layout checks—not to
parse the declaration. `auto` avoids reconstructing C++ types from source.

## Exploring other Tree-sitter tricks

Start with `:InspectTree`: navigate the syntax tree and identify node kinds and
field names for real examples. Try this on declarations, calls, templates, and
comments. `:Inspect` is instead useful for highlighting captures.

Print the cursor node and its S-expression:

```vim
:lua local n = vim.treesitter.get_node(); print(n:type(), n:sexpr())
```

For a cursor-local operation, walking ancestors is usually simpler than a
query. To find many matches, use a query:

```lua
local buf = vim.api.nvim_get_current_buf()
local root = vim.treesitter.get_parser(buf, 'cpp'):parse()[1]:root()
local query = vim.treesitter.query.parse('cpp', [[
  (field_declaration declarator: (field_identifier) @member)
]])
for id, node in query:iter_captures(root, buf, 0, -1) do
    print(query.captures[id], vim.treesitter.get_node_text(node, buf))
end
```

`@member` names a capture; `declarator:` is a grammar field, not a node type.
Queries match structure, so formatting and comments generally don't matter.
For multiple edits, collect ranges first and apply them bottom-to-top so earlier
edits don't shift later positions. Don't retain nodes across asynchronous edits
without reparsing or checking the buffer changedtick. Use extmarks for positions
that must track edits.

Useful references: `:h treesitter`, `:h vim.treesitter.get_node()`,
`:h TSNode`, `:h vim.treesitter.query.parse()`, `:h nvim_buf_set_text()`.
Use `set_text` for partial-line replacements and `set_lines` for whole lines.
Tree-sitter supplies syntax; use clangd when you need symbol resolution,
references, overloads, access checking, or type semantics.

## Tests

From the repository root, with an installed parser:

```sh
nvim --headless -u NONE \
  '+set rtp+=~/.local/share/nvim/site' \
  -l dotfiles/nvim/tests/cpp/getter.lua
```

Adjust the runtimepath to the directory containing `parser/cpp.so` if necessary.
Tests cover public-section insertion, naming, initializers, nested classes,
collisions, and rejection without buffer changes.
