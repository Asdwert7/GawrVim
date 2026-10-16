-- Neovim 0.11+ native LSP config
-- cmp временно отключён → без cmp_nvim_lsp; вернём, когда включим cmp обратно.
local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
local caps = ok and cmp_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()


vim.lsp.config("clangd", {
  -- cmd и enable управляются модулем gawrsettings (:GawrOn lsp / :GawrOn clang_tidy)
  capabilities = caps,
  root_markers = {
  "compile_commands.json",
  ".clangd",
  "compile_flags.txt",
  "CMakeLists.txt",
  ".git",
  },
})





-- compile_commands.json база команд компиляции каждого .cpp,  флаги, include-пути, стандарты, defines
-- compile_flags.txt просто список флагов: -std=c++20 -Iinclude -Wall
-- CMakeLists Маяк для CMake-проектов
-- background-index это чтобы clang все сразу индексировал, чтобы не ленился
-- clang-tidy это предупреждения они включены по умолчанию 
