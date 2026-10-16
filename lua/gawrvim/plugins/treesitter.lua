-- nvim-treesitter, ветка main (Neovim 0.12). Не поддерживает lazy-loading.
-- Парсеры ставятся из gawrsettings при включении флага lsp для языка.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
}
