-- GawrSettings: языковые режимы командами (подробности — README.md, раздел GawrSettings).
--   :Gawrcpp lsp dbb cmp      включить флаги            :Gawrcpp -dbb     выключить флаг
--   :Gawrcpp all | off        все флаги вкл / выкл       :Gawrcpp          статус
--   :Gawrcpp set default lsp  включить и запомнить как дефолт этого языка
--   :Gawrcpp reset default    всё выключить и забыть сохранённые дефолты
--   :Gawrall <то же самое>    применить ко всем языкам; неподдерживаемые флаги пропускаются
-- Команды: Gawrcpp, Gawrcs, Gawrpy, Gawrlua, Gawrall, GawrStatus, GawrInstall, Dbb.
-- Команды Neovim начинаются с большой буквы, поэтому gawrcpp в начале командной строки
-- автоматически превращается в Gawrcpp.

local langs = require("gawrvim.gawrsettings.languages")
local debugger = require("gawrvim.gawrsettings.debugger")

local M = {}

local FLAGS = { "lsp", "dbb", "cmp", "tidy" }
local APPLY_ORDER = { "tidy", "cmp", "dbb", "lsp" } -- tidy/cmp до lsp: сервер стартует сразу с нужными опциями
local KNOWN = { lsp = true, dbb = true, cmp = true, tidy = true }
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
local store = vim.fn.stdpath("state") .. "/gawrsettings.json"

local state = {} -- state[lang][flag] = bool
local ft_lang = {} -- filetype → lang

-- ───────────────────────── helpers ─────────────────────────

local function notify(msg, level)
  vim.notify("GawrSettings: " .. msg, level or vim.log.levels.INFO)
end

local function supports(lang, flag)
  return langs[lang][flag] ~= nil and langs[lang][flag] ~= false
end

local function supported_flags(lang)
  return vim.tbl_filter(function(f)
    return supports(lang, f)
  end, FLAGS)
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

local function write_saved(lang, flags) -- flags == nil → забыть сохранённое для языка
  local saved = read_saved()
  saved[lang] = flags and vim.deepcopy(flags) or nil
  vim.fn.mkdir(vim.fn.fnamemodify(store, ":h"), "p")
  local f = assert(io.open(store, "w"))
  f:write(vim.json.encode(saved))
  f:close()
end

function M.is_on_for_buf(buf, flag)
  local lang = ft_lang[vim.bo[buf == 0 and vim.api.nvim_get_current_buf() or buf].filetype]
  return lang ~= nil and state[lang][flag] == true
end

-- ───────────────────────── пояснения пользователю (одно сообщение на команду) ─────────────────────────

local notes = { unsupported = {}, unknown = {} } -- unsupported[lang] = { flag, ... }

local function note_unsupported(lang, flag)
  notes.unsupported[lang] = notes.unsupported[lang] or {}
  table.insert(notes.unsupported[lang], flag)
end

local function note_unknown(flag)
  notes.unknown[flag] = true
end

-- Собирает все накопленные пояснения в одно сообщение и сбрасывает сборщик.
local function flush_notes()
  local lines = {}
  if next(notes.unsupported) then
    local all, details = {}, {}
    for _, lang in ipairs(langs.order) do
      local fl = notes.unsupported[lang]
      if fl then
        table.insert(details, ("  %s: %s"):format(lang, table.concat(fl, ", ")))
        for _, f in ipairs(fl) do
          all[f] = true
        end
      end
    end
    local names = vim.tbl_filter(function(f)
      return all[f]
    end, FLAGS)
    table.insert(lines, ("Некоторые языки не поддерживают флаги [%s], за справкой смотрите README.md"):format(table.concat(names, ", ")))
    vim.list_extend(lines, details)
  end
  if next(notes.unknown) then
    table.insert(lines, "Неизвестные флаги: " .. table.concat(vim.tbl_keys(notes.unknown), ", ") .. " (есть: lsp, dbb, cmp, tidy)")
  end
  notes = { unsupported = {}, unknown = {} }
  if #lines > 0 then
    notify(table.concat(lines, "\n"), vim.log.levels.WARN)
  end
end

-- ───────────────────────── подсветка (часть флага lsp) ─────────────────────────

local function ts_start(buf)
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
    ts_start(buf)
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

local function any_dbb()
  for _, name in ipairs(langs.order) do
    if state[name] and state[name].dbb then
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
  debugger.attach(any_dbb()) -- клик по полю, знаки, :Dbb, <leader>d…
end

-- ───────────────────────── cmp (автодополнение + автоформат) ─────────────────────────

local function apply_cmp(lang, on)
  if on then
    lazy_load("nvim-cmp") -- сам cmp сверяется с флагом в enabled()
    restart_lsp(lang) -- чтобы сервер получил capabilities cmp
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
  if state[lang][flag] == on then
    return
  end
  state[lang][flag] = on
  local ok, err = pcall(appliers[flag], lang, on)
  if not ok then
    state[lang][flag] = not on
    notify(("%s %s: %s"):format(lang, flag, tostring(err)), vim.log.levels.ERROR)
  end
end

local function apply_changes(lang, changes)
  for _, f in ipairs(APPLY_ORDER) do
    if changes[f] ~= nil then
      set_flag(lang, f, changes[f])
    end
  end
end

local function status_line(lang)
  local parts = {}
  for _, f in ipairs(supported_flags(lang)) do
    table.insert(parts, (state[lang][f] and "●" or "○") .. f)
  end
  return ("%-4s %s"):format(lang, table.concat(parts, "  "))
end

-- ───────────────────────── разбор команд ─────────────────────────

-- Токены → { {name=, value=}, ... }
local function tokenize(words)
  local out = {}
  for _, w in ipairs(words) do
    if w:sub(1, 1) == "-" then
      table.insert(out, { name = w:sub(2), value = false })
    else
      table.insert(out, { name = w, value = true })
    end
  end
  return out
end

-- Токены → изменения для конкретного языка; неподдерживаемое пропускает и копит пояснения.
local function resolve(lang, tokens)
  local changes = {}
  for _, t in ipairs(tokens) do
    if t.name == "all" then
      for _, f in ipairs(supported_flags(lang)) do
        if f ~= "tidy" then
          changes[f] = t.value
        end
      end
    elseif t.name == "off" then
      for _, f in ipairs(supported_flags(lang)) do
        changes[f] = false
      end
    elseif not KNOWN[t.name] then
      note_unknown(t.name)
    elseif not supports(lang, t.name) then
      note_unsupported(lang, t.name)
    else
      changes[t.name] = t.value
    end
  end
  return changes
end

-- Общий исполнитель для :Gawr<lang> и :Gawrall.
local function run(lang_list, words)
  local first, second = words[1], words[2]
  local summary = {}

  if #words == 0 or first == "status" then
    -- только статус
  elseif first == "reset" and second == "default" then
    for _, lang in ipairs(lang_list) do
      local off = {}
      for _, f in ipairs(supported_flags(lang)) do
        off[f] = false
      end
      apply_changes(lang, off)
      write_saved(lang, nil)
    end
    table.insert(summary, "дефолты сброшены, всё выключено")
  elseif first == "set" and second == "default" then
    local tokens = tokenize(vim.list_slice(words, 3))
    for _, lang in ipairs(lang_list) do
      local want = resolve(lang, tokens)
      local desired = {}
      for _, f in ipairs(supported_flags(lang)) do
        desired[f] = want[f] == true
      end
      apply_changes(lang, desired)
      write_saved(lang, desired)
    end
    table.insert(summary, "сохранено как дефолт")
  elseif first == "set" or first == "reset" then
    notify(("после '%s' нужно слово default, например: %s default lsp"):format(first, first), vim.log.levels.WARN)
    return
  else
    local tokens = tokenize(words)
    for _, lang in ipairs(lang_list) do
      apply_changes(lang, resolve(lang, tokens))
    end
  end

  flush_notes()
  local lines = {}
  for _, lang in ipairs(lang_list) do
    table.insert(lines, status_line(lang))
  end
  local tail = #summary > 0 and ("  (" .. summary[1] .. ")") or ""
  if #lang_list == 1 then
    notify(lines[1] .. tail)
  else
    notify((tail ~= "" and tail:gsub("^%s+", "") .. "\n" or "\n") .. table.concat(lines, "\n"))
  end
end

local function completion(supported_fn)
  return function(lead, cmdline)
    local words = vim.split(vim.trim(cmdline), "%s+")
    table.remove(words, 1) -- имя команды
    if cmdline:match("%s$") == nil and #words > 0 then
      table.remove(words) -- слово, которое сейчас набирается
    end
    local items
    if words[1] == "reset" or (words[1] == "set" and #words == 1) then
      items = { "default" }
    elseif #words == 0 then
      items = { "status", "off", "all", "set", "reset" }
      vim.list_extend(items, supported_fn())
      vim.list_extend(items, vim.tbl_map(function(f)
        return "-" .. f
      end, supported_fn()))
    else
      items = { "off", "all" }
      vim.list_extend(items, supported_fn())
      vim.list_extend(items, vim.tbl_map(function(f)
        return "-" .. f
      end, supported_fn()))
    end
    return vim.tbl_filter(function(s)
      return s:find(lead, 1, true) == 1
    end, items)
  end
end

local function abbrev(cmd)
  vim.cmd(([[cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? '%s' : '%s']]):format(
    cmd:lower(), cmd:lower(), cmd, cmd:lower()
  ))
end

-- ───────────────────────── setup ─────────────────────────

function M.setup()
  -- Mason-бинарники доступны сразу, без ленивой загрузки mason.nvim
  if not vim.env.PATH:find(mason_bin, 1, true) then
    vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
  end

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
      run({ lang }, o.fargs)
    end, {
      nargs = "*",
      desc = "GawrSettings: " .. lang,
      complete = completion(function()
        return supported_flags(lang)
      end),
    })
    abbrev(cmd)
  end

  vim.api.nvim_create_user_command("Gawrall", function(o)
    run(langs.order, o.fargs)
  end, {
    nargs = "*",
    desc = "GawrSettings: все языки",
    complete = completion(function()
      return { "lsp", "dbb", "cmp", "tidy" }
    end),
  })
  abbrev("Gawrall")

  vim.api.nvim_create_user_command("GawrStatus", function()
    run(langs.order, {})
  end, {})

  vim.api.nvim_create_user_command("GawrInstall", function()
    local pkgs = {}
    for _, lang in ipairs(langs.order) do
      vim.list_extend(pkgs, langs[lang].mason or {})
    end
    vim.list_extend(pkgs, { "tree-sitter-cli" })
    vim.cmd("MasonInstall " .. table.concat(pkgs, " "))
  end, { desc = "Установить все серверы/отладчики/форматтеры через Mason" })

  debugger.setup_commands(any_dbb)

  -- Применяем сохранённые дефолты (set default). Без них всё выключено.
  local saved = read_saved()
  for _, lang in ipairs(langs.order) do
    local changes = {}
    for _, f in ipairs(supported_flags(lang)) do
      if (saved[lang] or {})[f] == true then
        changes[f] = true
      end
    end
    apply_changes(lang, changes)
  end
end

return M
