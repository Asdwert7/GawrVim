-- Описание языков для GawrSettings. Команда = :Gawr<lang> (см. init.lua).
-- Флаги:
--   lsp  — LSP-сервер + подсветка (treesitter, фолбэк на :syntax)
--   dbb  — отладчик (nvim-dap + dap-ui)
--   cmp  — автодополнение (nvim-cmp) + автоформат при сохранении (conform)
--   tidy — только для cpp: clang-tidy внутри clangd
-- Язык, у которого нет блока lsp/dbb/cmp, этот флаг не поддерживает.
-- Новый язык: добавь запись сюда (+ formatters_by_ft в plugins/conform.lua).

local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"
local mason_pkgs = vim.fn.stdpath("data") .. "/mason/packages/"

local function input_path(prompt, default)
  return function()
    return vim.fn.input(prompt, vim.fn.getcwd() .. default, "file")
  end
end

local M = {}

M.cpp = {
  fts = { "c", "cpp" },
  parsers = { "c", "cpp" },
  mason = { "clangd", "clang-format", "codelldb" },
  lsp = {
    server = "clangd",
    config = function(flags)
      local cmd = { "clangd", "--background-index" }
      if flags.tidy then
        table.insert(cmd, "--clang-tidy")
      end
      return { cmd = cmd }
    end,
  },
  tidy = true,
  cmp = true, -- автоформат: clang-format (plugins/conform.lua)
  dbb = {
    setup = function(dap)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = { command = mason_bin .. "codelldb", args = { "--port", "${port}" } },
      }
      local cfg = {
        {
          name = "Launch executable",
          type = "codelldb",
          request = "launch",
          program = input_path("Executable: ", "/"),
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = cfg
      dap.configurations.cpp = cfg
    end,
  },
}

M.cs = {
  fts = { "cs" },
  parsers = { "c_sharp" },
  mason = { "csharp-language-server", "csharpier", "netcoredbg" },
  lsp = { server = "csharp_ls" },
  cmp = true, -- автоформат: csharpier
  dbb = {
    setup = function(dap)
      dap.adapters.coreclr = {
        type = "executable",
        command = mason_bin .. "netcoredbg",
        args = { "--interpreter=vscode" },
      }
      dap.configurations.cs = {
        {
          name = "Launch dll",
          type = "coreclr",
          request = "launch",
          program = input_path("Path to dll: ", "/bin/Debug/"),
        },
      }
    end,
  },
}

M.py = {
  fts = { "python" },
  parsers = { "python" },
  mason = { "pyright", "black", "debugpy" },
  lsp = { server = "pyright" },
  cmp = true, -- автоформат: black
  dbb = {
    setup = function(dap)
      dap.adapters.python = {
        type = "executable",
        command = mason_pkgs .. "debugpy/venv/bin/python",
        args = { "-m", "debugpy.adapter" },
      }
      dap.configurations.python = {
        {
          name = "Launch file",
          type = "python",
          request = "launch",
          program = "${file}",
          pythonPath = function()
            local venv = os.getenv("VIRTUAL_ENV")
            return venv and (venv .. "/bin/python") or "python3"
          end,
        },
      }
    end,
  },
}

M.lua = {
  fts = { "lua" },
  parsers = { "lua" }, -- парсер lua встроен в Neovim
  mason = { "lua-language-server" },
  lsp = {
    server = "lua_ls",
    config = function()
      return {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      }
    end,
  },
  -- без dbb и cmp (по задумке)
}

-- Порядок команд в :GawrStatus
M.order = { "cpp", "cs", "py", "lua" }

return M
