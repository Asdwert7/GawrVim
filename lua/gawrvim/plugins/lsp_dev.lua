return {
  "neovim/nvim-lspconfig",
  lazy = false,
  config = function()
    require("gawrvim.lsp.cpp_dev")
    require("gawrvim.gawrsettings").setup()
  end,
}
