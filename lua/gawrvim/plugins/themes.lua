-- lua/gawrvim/plugins/themes.lua

-- === 🎨 Настройка Catppuccin (обязательно!) ===
local ok, catppuccin = pcall(require, "catppuccin")
if ok then
  catppuccin.setup({
    flavour = "mocha", -- "latte", "frappe", "macchiato", "mocha"
    background = { -- :h background
      light = "latte",
      dark = "mocha",
    },
    transparent_background = false, -- true если хочешь прозрачный фон
    show_end_of_buffer = false,     -- показывать пустые строки в конце
    term_colors = true,
    dim_inactive = {
      enabled = false,
      shade = "dark",
      percentage = 0.15,
    },
    no_italic = false, -- если хочешь убрать курсив
    no_bold = false,   -- если хочешь убрать жирный шрифт
    styles = {
      comments = { "italic" },
      conditionals = { "italic" },
      loops = {},
      functions = {},
      keywords = {},
      strings = {},
      variables = {},
      numbers = {},
      booleans = {},
      properties = {},
      types = {},
    },
    integrations = {
      cmp = true,
      gitsigns = true,
      nvimtree = true,
      telescope = true,
      notify = true,
      mini = false,
      -- другие интеграции...
    },
  })
end

-- Список тем для выбора
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

-- Запоминаем текущую тему
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function(args)
    vim.g.current_theme = args.match or "unknown"
  end,
})

-- Применить тему
local function apply_colorscheme(name)
  if name == "default" then
    vim.cmd("colorscheme default")
    vim.g.current_theme = "default"
    return
  end

  local ok, err = pcall(vim.cmd.colorscheme, name)
  if ok then
    vim.g.current_theme = name
    vim.notify("✓ Тема: " .. name, vim.log.levels.INFO)
  else
    vim.notify("⚠ Не удалось загрузить тему: " .. name .. "\n" .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Команда выбора темы
vim.api.nvim_create_user_command("Asd", function()
  vim.ui.select(themes, { prompt = "Выбери тему:" }, function(choice)
    if choice then apply_colorscheme(choice) end
  end)
end, {})

-- Алиас :asd → :Asd
vim.cmd([[
  cnoreabbrev <expr> asd (getcmdtype() == ':' && getcmdline() ==# 'asd') ? 'Asd' : 'asd'
]])

-- Показать текущую тему
vim.api.nvim_create_user_command("ThemeName", function()
  local name = vim.g.current_theme or "default"
  vim.notify("Текущая тема: " .. name, vim.log.levels.INFO)
end, {})

-- === Активация стартовой темы ===
apply_colorscheme("catppuccin")