-- Neovim 0.11+ native LSP config
local caps = require("cmp_nvim_lsp").default_capabilities() -- создаёт таблицу возможностей клиента, расширенную под cmp.


vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy" },
  capabilities = caps,
  root_markers = {
  "compile_commands.json",
  ".clangd",
  "compile_flags.txt",
  "CMakeLists.txt",
  ".git",
  },
})

vim.lsp.enable({ "clangd" })




-- compile_commands.json база команд компиляции каждого .cpp,  флаги, include-пути, стандарты, defines
-- compile_flags.txt просто список флагов: -std=c++20 -Iinclude -Wall
-- CMakeLists Маяк для CMake-проектов
-- background-index это чтобы clang все сразу индексировал, чтобы не ленился
-- clang-tidy это предупреждения они включены по умолчанию 
