-- Форматирование. Включается флагом cmp из gawrsettings (формат при сохранении).
return {
  "stevearc/conform.nvim",
  lazy = true,
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      c = { "clang-format" },
      cpp = { "clang-format" },
      cs = { "csharpier" },
      python = { "black" },
    },
  },
}
