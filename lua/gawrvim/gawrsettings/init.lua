-- GawrSettings: языковые режимы командами.
--   :Gawrcpp lsp dbb cmp   включить флаги        :Gawrcpp -dbb   выключить флаг
--   :Gawrcpp all / off     всё вкл / всё выкл    :Gawrcpp        статус языка
--   :Gawrcpp! lsp          то же + запомнить (JSON) как дефолт для следующих запусков
-- Команды: Gawrcpp, Gawrcs, Gawrpy, Gawrlua (+ :GawrStatus, :GawrInstall).
-- Пользовательские команды Neovim обязаны начинаться с большой буквы, поэтому
-- вводить можно и gawrcpp — в начале командной строки оно превращается в Gawrcpp.

local langs = require("gawrvim.gawrsettings.languages")

local M = {}

local FLAGS = { "lsp", "dbb", "cmp", "tidy" }
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
local store = vim.fn.stdpath("state") .. "/gawrsettings.json"

local state = {} -- state[lang][flag] = bool
local ft_lang = {} -- filetype → lang
local dap_keys_on = false

-- ───────────────────────── helpers ─────────────────────────

local function notify(msg, level)
  vim.notify("GawrSettings: " .. msg, level or vim.log.levels.INFO)
end

local function supports(lang, flag)
  return langs[lang][flag] ~= nil and langs[lang][flag] ~= false
end

local function lazy_load(...)
  require("lazy").load({ plugins = { ... } })
end

local function read_saved()
  local f = io.open(store, "r")
  if not f then
    return {}
  end
  local ok, data = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and type(data) == "table" and data or {}
end

local function write_saved(lang)
  local saved = read_saved()
  saved[lang] = vim.deepcopy(state[lang])
  vim.fn.mkdir(vim.fn.fnamemodify(store, ":h"), "p")
  local f = assert(io.open(store, "w"))
  f:write(vim.json.encode(saved))
  f:close()
end

function M.is_on_for_buf(buf, flag)
  local lang = ft_lang[vim.bo[buf == 0 and vim.api.nvim_get_current_buf() or buf].filetype]
  return lang ~= nil and state[lang][flag] == true
end

-- ───────────────────────── подсветка (часть флага lsp) ─────────────────────────

local function ts_start(buf, lang)
  local ft = vim.bo[buf].filetype
  local ts_lang = vim.treesitter.language.get_lang(ft) or ft
  if pcall(vim.treesitter.start, buf, ts_lang) then
    vim.bo[buf].syntax = "OFF" -- treesitter работает → regex-подсветка не нужна
  else
    vim.bo[buf].syntax = ft -- парсера нет → обычный :syntax
  end
end

local function refresh_highlight(buf, lang)
  if not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  if state[lang].lsp then
    ts_start(buf, lang)
  else
    pcall(vim.treesitter.stop, buf)
    vim.bo[buf].syntax = "OFF"
  end
end

local function refresh_all_highlight(lang)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if ft_lang[vim.bo[buf].filetype] == lang then
      refresh_highlight(buf, lang)
    end
  end
end

local function has_parser(name)
  -- language.add не бросает ошибку при отсутствии парсера, а возвращает nil, err
  local ok, res = pcall(vim.treesitter.language.add, name)
  return ok and res == true
end

local function ensure_parsers(lang)
  local missing = {}
  for _, p in ipairs(langs[lang].parsers or {}) do
    if not has_parser(p) then
      table.insert(missing, p)
    end
  end
  if #missing == 0 then
    return
  end
  lazy_load("nvim-treesitter")
  local ok, ts = pcall(require, "nvim-treesitter")
  if not ok then
    return
  end
  notify("ставлю treesitter-парсеры: " .. table.concat(missing, ", "))
  ts.install(missing):await(function()
    vim.schedule(function()
      if state[lang].lsp then
        refresh_all_highlight(lang)
      end
    end)
  end)
end

-- ───────────────────────── lsp ─────────────────────────

local function lsp_config(lang)
  local def = langs[lang].lsp
  local cfg = def.config and def.config(state[lang]) or {}
  if state[lang].cmp then
    lazy_load("cmp-nvim-lsp")
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok then
      cfg.capabilities = cmp_lsp.default_capabilities()
    end
  end
  vim.lsp.config(def.server, cfg)
end

local function apply_lsp(lang, on)
  local def = langs[lang].lsp
  if on then
    lsp_config(lang)
    vim.lsp.enable(def.server, true)
    ensure_parsers(lang)
  else
    vim.lsp.enable(def.server, false) -- останавливает запущенные клиенты
  end
  refresh_all_highlight(lang)
end

local function restart_lsp(lang)
  if state[lang].lsp then
    vim.lsp.enable(langs[lang].lsp.server, false)
    lsp_config(lang)
    vim.schedule(function()
      vim.lsp.enable(langs[lang].lsp.server, true)
    end)
  end
end

-- ───────────────────────── dbb ─────────────────────────

local dap_maps = {
  { "<F5>", "continue", "Debug: continue" },
  { "<F9>", "toggle_breakpoint", "Debug: breakpoint" },
  { "<F10>", "step_over", "Debug: step over" },
  { "<F11>", "step_into", "Debug: step into" },
  { "<F12>", "step_out", "Debug: step out" },
  { "<leader>dc", "continue", "Debug: continue" },
  { "<leader>db", "toggle_breakpoint", "Debug: breakpoint" },
  { "<leader>do", "step_over", "Debug: step over" },
  { "<leader>di", "step_into", "Debug: step into" },
  { "<leader>dO", "step_out", "Debug: step out" },
  { "<leader>dx", "terminate", "Debug: terminate" },
}

local function set_dap_keys(on)
  if on == dap_keys_on then
    return
  end
  dap_keys_on = on
  for _, m in ipairs(dap_maps) do
    if on then
      vim.keymap.set("n", m[1], function()
        require("dap")[m[2]]()
      end, { desc = m[3] })
    else
      pcall(vim.keymap.del, "n", m[1])
    end
  end
  if on then
    vim.keymap.set("n", "<leader>du", function()
      require("dapui").toggle()
    end, { desc = "Debug: UI" })
  else
    pcall(vim.keymap.del, "n", "<leader>du")
  end
end

local function any_dbb()
  for name in pairs(langs) do
    if name ~= "order" and state[name].dbb then
      return true
    end
  end
  return false
end

local ui_ready = false

local function apply_dbb(lang, on)
  local def = langs[lang].dbb
  if on then
    lazy_load("nvim-dap", "nvim-dap-ui", "nvim-nio")
    local dap = require("dap")
    def.setup(dap)
    if not ui_ready then
      ui_ready = true
      local dapui = require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["gawr"] = dapui.open
      dap.listeners.before.event_terminated["gawr"] = dapui.close
      dap.listeners.before.event_exited["gawr"] = dapui.close
    end
  elseif package.loaded["dap"] then
    for _, ft in ipairs(langs[lang].fts) do
      require("dap").configurations[ft] = nil
    end
  end
  set_dap_keys(any_dbb())
end

-- ───────────────────────── cmp (автодополнение + автоформат) ─────────────────────────

local function apply_cmp(lang, on)
  if on then
    lazy_load("nvim-cmp") -- сам cmp сверяется с флагом в enabled()
    if state[lang].lsp then
      restart_lsp(lang) -- чтобы сервер получил capabilities cmp
    end
  end
end

-- ───────────────────────── применение флагов ─────────────────────────

local appliers = {
  lsp = apply_lsp,
  dbb = apply_dbb,
  cmp = apply_cmp,
  tidy = function(lang)
    restart_lsp(lang)
  end,
}

local function set_flag(lang, flag, on)
  if not supports(lang, flag) then
    notify(("для %s нет флага '%s'"):format(lang, flag), vim.log.levels.WARN)
    return false
  end
  if state[lang][flag] == on then
    return true
  end
  state[lang][flag] = on
  local ok, err = pcall(appliers[flag], lang, on)
  if not ok then
    state[lang][flag] = not on
    notify(("%s %s: %s"):format(lang, flag, tostring(err)), vim.log.levels.ERROR)
    return false
  end
  return true
end

local function supported_flags(lang)
  return vim.tbl_filter(function(f)
    return supports(lang, f)
  end, FLAGS)
end

local function status_line(lang)
  local parts = {}
  for _, f in ipairs(supported_flags(lang)) do
    table.insert(parts, (state[lang][f] and "●" or "○") .. f)
  end
  return ("%-4s %s"):format(lang, table.concat(parts, "  "))
end

local function run_command(lang, o)
  local args = o.fargs
  if #args == 0 or args[1] == "status" then
    notify(status_line(lang))
    return
  end
  local changes = {}
  for _, a in ipairs(args) do
    if a == "all" then
      for _, f in ipairs(supported_flags(lang)) do
        if f ~= "tidy" then
          changes[f] = true
        end
      end
    elseif a == "off" then
      for _, f in ipairs(supported_flags(lang)) do
        changes[f] = false
      end
    elseif a:sub(1, 1) == "-" then
      changes[a:sub(2)] = false
    else
      changes[a] = true
    end
  end
  -- порядок: tidy и cmp до lsp, чтобы сервер стартовал сразу с нужными опциями
  for _, f in ipairs({ "tidy", "cmp", "dbb", "lsp" }) do
    if changes[f] ~= nil then
      set_flag(lang, f, changes[f])
    end
    changes[f] = nil
  end
  for unknown in pairs(changes) do
    notify(("неизвестный флаг '%s' (есть: %s)"):format(unknown, table.concat(supported_flags(lang), ", ")), vim.log.levels.WARN)
  end
  if o.bang then
    write_saved(lang)
  end
  notify(status_line(lang) .. (o.bang and "  (сохранено)" or ""))
end

-- ───────────────────────── setup ─────────────────────────

function M.setup()
  -- Mason-бинарники доступны сразу, без ленивой загрузки mason.nvim
  if not vim.env.PATH:find(mason_bin, 1, true) then
    vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
  end

  local saved = read_saved()
  for _, lang in ipairs(langs.order) do
    state[lang] = {}
    for _, ft in ipairs(langs[lang].fts) do
      ft_lang[ft] = lang
    end
  end

  -- Подсветка: решаем на каждом FileType по текущему флагу lsp языка.
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("GawrHighlight", { clear = true }),
    pattern = vim.tbl_keys(ft_lang),
    callback = function(a)
      local lang = ft_lang[a.match]
      if lang then
        -- schedule: после ftplugin'ов (lua сам стартует treesitter)
        vim.schedule(function()
          refresh_highlight(a.buf, lang)
        end)
      end
    end,
  })

  -- Автоформат при сохранении (флаг cmp)
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("GawrFormat", { clear = true }),
    callback = function(a)
      if M.is_on_for_buf(a.buf, "cmp") then
        lazy_load("conform.nvim")
        require("conform").format({ bufnr = a.buf, timeout_ms = 3000, lsp_format = "fallback" })
      end
    end,
  })

  for _, lang in ipairs(langs.order) do
    local cmd = "Gawr" .. lang
    vim.api.nvim_create_user_command(cmd, function(o)
      run_command(lang, o)
    end, {
      nargs = "*",
      bang = true,
      desc = "GawrSettings: " .. lang,
      complete = function()
        local items = { "status", "off" }
        if #supported_flags(lang) > 1 then
          table.insert(items, "all")
        end
        for _, f in ipairs(supported_flags(lang)) do
          table.insert(items, f)
          table.insert(items, "-" .. f)
        end
        return items
      end,
    })
    -- gawrcpp → Gawrcpp в начале командной строки
    vim.cmd(([[cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? '%s' : '%s']]):format(
      cmd:lower(), cmd:lower(), cmd, cmd:lower()
    ))
  end

  vim.api.nvim_create_user_command("GawrStatus", function()
    local lines = {}
    for _, lang in ipairs(langs.order) do
      table.insert(lines, status_line(lang))
    end
    notify("\n" .. table.concat(lines, "\n"))
  end, {})

  vim.api.nvim_create_user_command("GawrInstall", function()
    local pkgs = {}
    for _, lang in ipairs(langs.order) do
      vim.list_extend(pkgs, langs[lang].mason or {})
    end
    vim.list_extend(pkgs, { "tree-sitter-cli" })
    vim.cmd("MasonInstall " .. table.concat(pkgs, " "))
  end, { desc = "Установить все серверы/отладчики/форматтеры через Mason" })

  -- Применяем дефолты/сохранённое (по умолчанию всё выключено)
  for _, lang in ipairs(langs.order) do
    for _, f in ipairs({ "tidy", "cmp", "dbb", "lsp" }) do
      local want = (saved[lang] or {})[f]
      if want == true and supports(lang, f) then
        set_flag(lang, f, true)
      end
    end
  end
end

return M
