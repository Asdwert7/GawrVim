-- === 🦈 Опции для GawrVim ===
-- Editor defaults. Загружается через gawrvim.core до UI/плагинов.

local o = vim.opt

o.number = true -- абсолютные номера
o.relativenumber = true -- относительные номера (отчёт от текущей строки)
o.cursorline = true -- подсветка текущей строки
o.termguicolors = true -- 24-битные цвета
o.wrap = false -- без переноса длинных строк
o.scrolloff = 10 -- минимум строк сверху/снизу от курсора при прокрутке
o.updatetime = 250
o.showmode = false -- скрыть -- INSERT -- (когда появится statusline)
o.breakindent = false
o.undofile = false -- история undo НЕ пишется на диск
o.ignorecase = false -- поиск чувствителен к регистру
o.signcolumn = "yes" -- колонка для Git/LSP signs
o.list = false -- не показывать невидимые символы

-- clipboard после старта, чтобы не тормозить UI на медленных clipboard-провайдерах
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)
