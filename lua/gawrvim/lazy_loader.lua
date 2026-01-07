-- lazy_loader

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Темы
--  { "catppuccin/nvim", name = "catppuccin",lazy = false, priority = 1000 },
--  { "folke/tokyonight.nvim", name = "tokyonight",lazy = false, priority = 1000 },
--  { "sainnhe/everforest", name = "everforest",lazy = false, priority = 1000 },
--  { "EdenEast/nightfox.nvim", name = "nightfox",lazy = false, priority = 1000 },
--  { "dracula/vim", name = "dracula",lazy = false, priority = 1000 },
--  { "gruvbox-community/gruvbox", name = "gruvbox",lazy = false, priority = 1000 },
--  { "rose-pine/neovim", name = "rose-pine",lazy = false, priority = 1000 },
--  { "nordtheme/vim", name = "nord",lazy = false, priority = 1000 },

-- === LSP ===
{"neovim/nvim-lspconfig", lazy = false}, -- Я крайне не советую убирать lazy = false, тут ленивость ни к чему.

-- === CMP ===
{ "hrsh7th/nvim-cmp", event = "InsertEnter" }, -- загружать плагин, когда я в Insert mode
{ "hrsh7th/cmp-nvim-lsp" },         -- источник подсказок от LSP
{ "L3MON4D3/LuaSnip" },             -- сниппеты (без этого cmp будет полупустым)
{ "saadparwaiz1/cmp_luasnip" },     -- источник сниппетов для cmp
-- { "rafamadriz/friendly-snippets" }, -- готовые сниппеты (опционально, когда то будет bloody-cmp от asd)))) )(скоро оптимизирую)

  
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
 }) 
