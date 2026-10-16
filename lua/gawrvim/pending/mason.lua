-- lua/gawrvim/plugins/mason.lua
return {
  "williamboman/mason.nvim",
  cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
  build = ":MasonUpdate",
  opts = function(_, opts)
    opts = opts or {}
    opts.ui = opts.ui or {}
    opts.ui.icons = {
      package_installed = "✓",
      package_uninstalled = "✗",
      package_pending = "⟳",
    }
    return opts
  end,
}