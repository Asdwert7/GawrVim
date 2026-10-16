-- Отладчик. Грузится только когда включён флаг dbb (см. gawrsettings).
return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" },
  },
  { "rcarriga/nvim-dap-ui", lazy = true, dependencies = { "nvim-neotest/nvim-nio" } },
  { "nvim-neotest/nvim-nio", lazy = true },
}
