-- Удобства отладчика поверх nvim-dap (работают, пока флаг dbb включён хотя бы у одного языка):
--   • клавиши F5 F9 F10 F11 F12 и <leader>d… (список в README);
--   • клик мышью по полю слева от текста (номера/знаки) — красная точка-брейкпоинт, как в VS Code;
--   • команда :Dbb <слово>  (можно набирать dbb / bdd):
--       br            поставить/снять брейкпоинт на текущей строке
--       n | next      далее (continue; без активной сессии — запуск отладки)
--       nn | nextnext шаг через (step over)
--       ni | nextinner шаг внутрь (step into)
--       out           шаг наружу (step out)
--       stop          остановить отладку
--       ui            показать/скрыть окна отладчика
-- Отладчик (dap/dapui) загружает gawrsettings при включении флага dbb.

local M = {}

local attached = false
local is_enabled = function()
  return true
end

local actions = {
  br = function(dap)
    dap.toggle_breakpoint()
  end,
  n = function(dap)
    dap.continue()
  end,
  nn = function(dap)
    dap.step_over()
  end,
  ni = function(dap)
    dap.step_into()
  end,
  out = function(dap)
    dap.step_out()
  end,
  stop = function(dap)
    dap.terminate()
  end,
  ui = function()
    require("dapui").toggle()
  end,
}
actions.next = actions.n
actions.nextnext = actions.nn
actions.nextinner = actions.ni

local function define_signs()
  vim.api.nvim_set_hl(0, "GawrBreakpoint", { fg = "#ff4d4d" })
  vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "GawrBreakpoint" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "GawrBreakpoint" })
  vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "GawrBreakpoint" })
  vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "GawrBreakpoint" })
  vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "CursorLine" })
end

-- Клик по полю слева от текста → брейкпоинт на этой строке (курсор не двигается).
local function gutter_click()
  local m = vim.fn.getmousepos()
  if m.winid == 0 or m.line == 0 then
    return "<LeftMouse>"
  end
  local info = vim.fn.getwininfo(m.winid)[1]
  local buf = vim.api.nvim_win_get_buf(m.winid)
  if not info or vim.bo[buf].buftype ~= "" or m.wincol > info.textoff then
    return "<LeftMouse>"
  end
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(m.winid) then
      return
    end
    vim.api.nvim_win_call(m.winid, function()
      local cur = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_win_set_cursor(0, { m.line, 0 })
      require("dap").toggle_breakpoint()
      vim.api.nvim_win_set_cursor(0, cur)
    end)
  end)
  return ""
end

local key_maps = {
  { "<F5>", "n", "Debug: далее" },
  { "<F9>", "br", "Debug: breakpoint" },
  { "<F10>", "nn", "Debug: шаг через" },
  { "<F11>", "ni", "Debug: шаг внутрь" },
  { "<F12>", "out", "Debug: шаг наружу" },
  { "<leader>db", "br", "Debug: breakpoint" },
  { "<leader>dc", "n", "Debug: далее" },
  { "<leader>do", "nn", "Debug: шаг через" },
  { "<leader>di", "ni", "Debug: шаг внутрь" },
  { "<leader>dO", "out", "Debug: шаг наружу" },
  { "<leader>dx", "stop", "Debug: стоп" },
  { "<leader>du", "ui", "Debug: окна" },
}

-- Вызывается из gawrsettings при включении/выключении dbb (dap к этому моменту уже загружен).
function M.attach(on)
  if on == attached then
    return
  end
  attached = on
  if on then
    define_signs()
    vim.keymap.set("n", "<LeftMouse>", gutter_click, { expr = true, silent = true, desc = "Debug: клик по полю = breakpoint" })
    for _, m in ipairs(key_maps) do
      vim.keymap.set("n", m[1], function()
        actions[m[2]](require("dap"))
      end, { desc = m[3] })
    end
  else
    pcall(vim.keymap.del, "n", "<LeftMouse>")
    for _, m in ipairs(key_maps) do
      pcall(vim.keymap.del, "n", m[1])
    end
  end
end

function M.setup_commands(enabled_fn)
  is_enabled = enabled_fn
  for _, cmd in ipairs({ "Dbb", "Bdd" }) do
    vim.api.nvim_create_user_command(cmd, function(o)
      if not is_enabled() then
        vim.notify("GawrSettings: отладчик выключен — включите флаг dbb, например :Gawrcpp dbb", vim.log.levels.WARN)
        return
      end
      local act = actions[o.args]
      if not act then
        vim.notify("GawrSettings: " .. cmd .. " br | n | nn | ni | out | stop | ui", vim.log.levels.WARN)
        return
      end
      act(require("dap"))
    end, {
      nargs = 1,
      desc = "Отладчик: br / n / nn / ni / out / stop / ui",
      complete = function(lead)
        return vim.tbl_filter(function(s)
          return s:find(lead, 1, true) == 1
        end, { "br", "n", "next", "nn", "nextnext", "ni", "nextinner", "out", "stop", "ui" })
      end,
    })
    vim.cmd(([[cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? '%s' : '%s']]):format(
      cmd:lower(), cmd:lower(), cmd, cmd:lower()
    ))
  end
end

return M
