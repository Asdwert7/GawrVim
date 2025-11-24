-- lua/gawrvim/plugins/cpp-dev.lua

return {
  -- DAP + отладка для C/C++
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "jay-babu/mason-nvim-dap.nvim",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- обязательная зависимость для dap-ui
    },
    config = function()
      require("mason-nvim-dap").setup({
        ensure_installed = { "codelldb" },
        automatic_installation = true,
      })

      local dap = require("dap")
      local map = vim.keymap.set
      map("n", "<F5>",  dap.continue,          { desc = "DAP Continue/Start" })
      map("n", "<F9>",  dap.toggle_breakpoint, { desc = "DAP Toggle Breakpoint" })
      map("n", "<F10>", dap.step_over,         { desc = "DAP Step Over" })
      map("n", "<F11>", dap.step_into,         { desc = "DAP Step Into" })
      map("n", "<S-F11>", dap.step_out,        { desc = "DAP Step Out" })

      local dapui = require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"]      = function() dapui.close() end

      dap.configurations.cpp = {
        {
          name = "Launch file (codelldb)",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
      dap.configurations.c = dap.configurations.cpp
    end,
  },

  -- Команда для форматирования C/C++ через clang-format
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.api.nvim_create_user_command("Asd", function()
        local ft = vim.bo.filetype
        if ft == "cpp" or ft == "c" or ft == "objc" or ft == "objcpp" then
          vim.cmd("silent! write")
          vim.cmd("silent! !clang-format -i %")
          vim.cmd("edit")
          vim.api.nvim_echo({ { "C++ formatted (clang-format) ✓", "MoreMsg" } }, false, {})
        else
          vim.api.nvim_echo({ { "Asd: not a C/C++ buffer", "WarningMsg" } }, false, {})
        end
      end, { desc = "Format C/C++ with clang-format" })
    end,
  },
}