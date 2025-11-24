-- 🌊 GawrVim init.lua

print("GawrVim!!!")


-- Теперт проект перераспределен по разделам -- 
-- === База GawrVim === 


-- === Плагины GawrVim === 
require('gawrvim.core.lazy_loader')







-- === 🦈 Опции для GawrVim ===
local o = vim.opt -- переменная 
require('gawrvim.plugins.options')
require('gawrvim.plugins.themes')



-- === 🦈 Апи для GawrVim ===
local a = vim.api



-- === Мапинги для GawrVim ===



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