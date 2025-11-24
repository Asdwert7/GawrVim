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
