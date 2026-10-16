-- lua/gawrvim/plugins/mason-tool-installer.lua
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  event = "VeryLazy",
  dependencies = { "williamboman/mason.nvim" },

  opts = {
    -- что держим установленным всегда
    ensure_installed = {
      -- LSP
      "lua-language-server",
      "pyright",
      -- форматтеры
      "stylua",
      'black',
      -- доп. по вкусу:
      -- === С++ набор ===
      "clangd",        -- LSP (+ clang-tidy если включим)
      "clang-format",  -- форматтер
      "codelldb",      -- DAP адаптер
      -- "prettier", "eslint_d", "shfmt", "black"
    },
    auto_update = false,
    run_on_start = true,
    start_delay = 3000, -- мс после старта Neovim
    debounce_hours = 6, -- не проверять обновления чаще, чем раз в 6 часов
  },

  config = function(_, opts)
    require("mason").setup()
    require("mason-tool-installer").setup(opts)
  end,
}