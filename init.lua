-- 🌊 GawrVim

-- ===== Bootstrap lazy.nvim =====
-- Загрузчик плагинов --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git","clone","--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- ===== Опции =====
local o = vim.opt
o.number = true             -- абсолютные номера
o.relativenumber = false    -- относительные номера (Отчет идет от теккущей строки)
o.cursorline = true         -- подсветка текущей строки
o.signcolumn = "yes"        -- колонка для иконок (ошибки, брейкпоинты и т.п.)
o.termguicolors = true      -- включаем поддержку 24-битных цветов
o.signcolumn = "yes"            -- колонка знаков (LSP/гит)
o.wrap = false             -- отключаем перенос длинных строк
o.scrolloff = 4             -- отступ сверху/снизу при прокрутке
o.clipboard = "unnamedplus" -- общий буфер-обмена с macOS
o.updatetime = 200




-- ===== Плагины =====
-- Темы
require("lazy").setup({
{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
{ "folke/tokyonight.nvim", name = "tokyonight", priority = 1000 },
{ "sainnhe/everforest", name = "everforest", priority = 1000 },
{ "EdenEast/nightfox.nvim", name = "nightfox", priority = 1000 },
{ "dracula/vim", name = "dracula", priority = 1000 },
{ "gruvbox-community/gruvbox", name = "gruvbox", priority = 1000 },
{ "rose-pine/neovim", name = "rose-pine", priority = 1000 },
{ "nordtheme/vim", name = "nord", priority = 1000 },
})
-- === 🎨 Быстрый выбор темы ===
local themes = {
  "catppuccin",
  "tokyonight",
  "everforest",
  "nightfox",
  "dracula",
  "gruvbox",
  "rose-pine",
  "nord",
  "default",
}

-- Запоминаем активную тему при любом переключении
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function(args)
    vim.g.current_theme = args.match or "unknown"
  end,
})

-- Хелпер: применить тему и сохранить имя
local function apply_colorscheme(name)
  local ok = pcall(vim.cmd.colorscheme, name)
  if ok then
    vim.g.current_theme = name
    vim.api.nvim_echo({ { "✓ Тема: " .. name, "MoreMsg" } }, false, {})
  else
    vim.api.nvim_echo({ { "⚠ Не удалось загрузить тему: " .. name, "ErrorMsg" } }, false, {})
  end
end

-- Команда с заглавной (требование Neovim)
vim.api.nvim_create_user_command("Asd", function()
  vim.ui.select(themes, { prompt = "Выбери тему:" }, function(choice)
    if choice then apply_colorscheme(choice) end
  end)
end, {})

-- Короткий алиас: можно писать :asd
vim.cmd([[
  cnoreabbrev <expr> asd (getcmdtype() == ':' && getcmdline() ==# 'asd') ? 'Asd' : 'asd'
]])

-- Показать текущую тему в любой момент
vim.api.nvim_create_user_command("ThemeName", function()
  local name = vim.g.current_theme or "default"
  vim.api.nvim_echo({ { "Текущая тема: " .. name, "MoreMsg" } }, false, {})
end, {})

vim.o.laststatus = 3
vim.o.statusline = vim.o.statusline .. " %= %{get(g:,'current_theme','default')} "

-- Сообщение при загрузке ErrorMsg WarningMsg ModeMsg MoreMsg
-- Красное типа - желто-оранжевое - зелёное - голубое
vim.api.nvim_echo({{"GawrVim loaded ✓", "MoreMsg"}}, false, {})
