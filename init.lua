-- 🌊 GawrVim init.lua

print("GawrVim!!!")

-- Теперт проект перераспределен по разделам -- 
-- === CORE GawrVim === 
require('gawrvim.lazy_loader')

-- === Plugins GawrVim === 
require('gawrvim.plugins.lsp_dev') -- Подсветка синтаксиса лсп сервер
require('gawrvim.plugins.cmp')     -- Автодополнение и подсказки работают вместе с лсп
--require('plugins.mason')      	   -- Менеджер инструментов
--require('plugins.colorizer')       -- Кастомная подсветка в коде
--require('plugins.lualine')         -- Красивый(в теории) статус бар 
--require('plugins.comment')         -- Ставит коментарий для любого языка по кнопке типа /* */ // -- # и тд
--require('plugins.trouble')         -- Подсветка для ошибок работает в интеграции с lsp
-- require('plugins.whichkey')        -- Подсказка горячих клавиш

-- === 🦈 Опции для GawrVim ===
-- require('gawrvim.plugins.themes')
-- require('gawrvim.plugins.options')

-- === 🦈 Апи для GawrVim ===
local a = vim.api

-- === Приветствие (пока что) ===
-- a.nvim_echo({{"GawrVim loaded ✓", "MoreMsg"}}, false, {})

-- включать dashboard только если запущен без файла
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 then
      vim.schedule(function()
        vim.cmd("Dashboard")
      end)
    else
      a.nvim_echo({{"GawrVim loaded ✓", "DiffText"}}, false, {})
    end
  end,
})

-- показать сообщение когда dashboard уже полностью нарисован
vim.api.nvim_create_autocmd("User", {
  pattern = "DashboardLoaded",
  callback = function()
    vim.defer_fn(function()
      a.nvim_echo({{"GawrVimDashboard loaded ✓", "MoreMsg"}}, false, {})
    end, 10)
  end,
})
