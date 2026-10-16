-- GawrSettings: включение/выключение возможностей редактора командами.
--   :GawrOn <фича>   :GawrOff <фича>   :GawrToggle <фича>   :GawrStatus
--   С "!" (:GawrOn! lsp) состояние ещё и сохраняется как новый дефолт.
-- Дефолты — ниже в M.defaults; сохранённые переопределения — в JSON (stdpath("state")).

local features = require("gawrvim.gawrsettings.features")

local M = {}

-- Что включено при старте, пока ты не сохранил своё через "!".
M.defaults = {
  lsp = false,
  clang_tidy = false,
  diagnostics = false,
  highlight = false,
}

local state = {}
local store = vim.fn.stdpath("state") .. "/gawrsettings.json"

local function load_saved()
  local f = io.open(store, "r")
  if not f then
    return {}
  end
  local ok, data = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and type(data) == "table" and data or {}
end

local function save()
  local saved = load_saved()
  for name, v in pairs(state) do
    if v ~= M.defaults[name] or saved[name] ~= nil then
      saved[name] = v
    end
  end
  vim.fn.mkdir(vim.fn.fnamemodify(store, ":h"), "p")
  local f = assert(io.open(store, "w"))
  f:write(vim.json.encode(saved))
  f:close()
end

local ctx = {
  live = false,
  is_on = function(name)
    return state[name] == true
  end,
}

local function set(name, value, persist)
  local feat = features[name]
  if not feat or name == "order" then
    vim.notify("GawrSettings: нет фичи '" .. tostring(name) .. "'", vim.log.levels.ERROR)
    return
  end
  state[name] = value
  local ok, err = pcall(value and feat.on or feat.off, ctx)
  if not ok then
    vim.notify("GawrSettings: " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  if persist then
    save()
  end
  if ctx.live then
    vim.notify(("GawrSettings: %s → %s%s"):format(name, value and "ON" or "OFF", persist and " (сохранено)" or ""))
  end
end

local function names()
  return vim.list_extend({}, features.order)
end

local function status()
  local lines = {}
  for _, name in ipairs(features.order) do
    table.insert(lines, ("%s %-12s %s"):format(state[name] and "●" or "○", name, features[name].desc))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "GawrSettings" })
end

function M.setup()
  local saved = load_saved()
  for _, name in ipairs(features.order) do
    local v = saved[name]
    if v == nil then
      v = M.defaults[name]
    end
    set(name, v == true, false)
  end
  ctx.live = true

  local function complete()
    return names()
  end
  for cmd, value in pairs({ GawrOn = true, GawrOff = false }) do
    vim.api.nvim_create_user_command(cmd, function(o)
      set(o.args, value, o.bang)
    end, { nargs = 1, bang = true, complete = complete })
  end
  vim.api.nvim_create_user_command("GawrToggle", function(o)
    set(o.args, not state[o.args], o.bang)
  end, { nargs = 1, bang = true, complete = complete })
  vim.api.nvim_create_user_command("GawrStatus", status, {})
end

return M
