-- Mason ставит бинарники (LSP, DAP, форматтеры). Архитектурой LSP не управляет.
-- bin-папка добавляется в PATH из gawrsettings, поэтому плагин можно грузить лениво.
return {
  "williamboman/mason.nvim",
  cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
  opts = {
    ui = {
      icons = {
        package_installed = "✓",
        package_uninstalled = "✗",
        package_pending = "⟳",
      },
    },
  },
}
