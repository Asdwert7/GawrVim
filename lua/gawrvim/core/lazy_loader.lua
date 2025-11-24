-- lazy_loader

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- === DashBoard ===
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      local opts = require('gawrvim.plugins.dashboard')
      require('dashboard').setup(opts)
    end,
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },
  

  -- === Mason (ядро) ===
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "⟳",
            package_uninstalled = "✗",
          },
          border = "rounded",
        },
      })
    end,
  },
  -- === Mason + LSPConfig (без cmp, только LSP) ===
{
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "neovim/nvim-lspconfig" },
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = { "clangd" },
    })

    local on_attach = function(client, bufnr)
      local opts = { buffer = bufnr, silent = true }

      -- Диагностика
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

      -- LSP-действия
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end

    -- Настройка серверов без cmp
    require("mason-lspconfig").setup_handlers({
      function(server_name)
        require("lspconfig")[server_name].setup({
          on_attach = on_attach,
          capabilities = vim.lsp.protocol.make_client_capabilities(),
        })
      end,
    })
  end,
},
-- Темы
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  { "folke/tokyonight.nvim", name = "tokyonight", priority = 1000 },
  { "sainnhe/everforest", name = "everforest", priority = 1000 },
  { "EdenEast/nightfox.nvim", name = "nightfox", priority = 1000 },
  { "dracula/vim", name = "dracula", priority = 1000 },
  { "gruvbox-community/gruvbox", name = "gruvbox", priority = 1000 },
  { "rose-pine/neovim", name = "rose-pine", priority = 1000 },
  { "nordtheme/vim", name = "nord", priority = 1000 },
  
 -- Напоминание: Сюда добавляй все плагины, соблюдай прикол!!!

  { "WhoIsSethDaniel/mason-tool-installer.nvim", commit = "517ef5994ef9d6b738322664d5fdd948f0fdeb46", optional = true },
  { "jay-babu/mason-null-ls.nvim", version = "^2", optional = true },
  { "jay-babu/mason-nvim-dap.nvim", version = "^2", optional = true },
  { "williamboman/mason-lspconfig.nvim", version = "^1", optional = true },
  { "williamboman/mason.nvim", version = "^2", optional = true },

})