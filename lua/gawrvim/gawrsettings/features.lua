-- Реестр фич GawrSettings. Чтобы добавить новую — добавь запись {desc, on, off}.
-- ctx.is_on(name) — текущее состояние другой фичи.

local M = {}

local function clangd_cmd(tidy)
  local cmd = { "clangd", "--background-index" }
  if tidy then
    table.insert(cmd, "--clang-tidy")
  end
  return cmd
end

local function restart_clangd()
  vim.lsp.enable("clangd", false)
  vim.schedule(function()
    vim.lsp.enable("clangd", true)
  end)
end

M.lsp = {
  desc = "LSP: clangd (go-to-definition, hover, диагностика от сервера)",
  on = function()
    vim.lsp.enable("clangd", true)
  end,
  off = function()
    vim.lsp.enable("clangd", false) -- останавливает запущенные клиенты
  end,
}

M.clang_tidy = {
  desc = "clang-tidy внутри clangd (предупреждения о стиле/багах; тяжелее)",
  on = function(ctx)
    vim.lsp.config("clangd", { cmd = clangd_cmd(true) })
    if ctx.is_on("lsp") and ctx.live then
      restart_clangd()
    end
  end,
  off = function(ctx)
    vim.lsp.config("clangd", { cmd = clangd_cmd(false) })
    if ctx.is_on("lsp") and ctx.live then
      restart_clangd()
    end
  end,
}

M.diagnostics = {
  desc = "Показ диагностики (ошибки/предупреждения) в буферах",
  on = function()
    vim.diagnostic.enable(true)
  end,
  off = function()
    vim.diagnostic.enable(false)
  end,
}

M.highlight = {
  desc = "Подсветка синтаксиса (treesitter, если есть парсер, + :syntax)",
  on = function()
    vim.cmd("syntax enable")
    local group = vim.api.nvim_create_augroup("GawrHighlight", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      callback = function(a)
        pcall(vim.treesitter.start, a.buf)
      end,
    })
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        pcall(vim.treesitter.start, buf)
      end
    end
  end,
  off = function()
    pcall(vim.api.nvim_del_augroup_by_name, "GawrHighlight")
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      pcall(vim.treesitter.stop, buf)
    end
    vim.cmd("syntax off")
  end,
}

-- Порядок применения при старте (clang_tidy раньше lsp, чтобы clangd стартовал с нужным cmd).
M.order = { "clang_tidy", "diagnostics", "highlight", "lsp" }

return M
