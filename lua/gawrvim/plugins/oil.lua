return {
  "stevearc/oil.nvim",
  lazy = false, -- чтобы `nvim <папка>` открывал oil
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Oil: родительская папка" },
    { "<leader>e", "<cmd>Oil<cr>", desc = "Oil: файловый менеджер" },
  },
  opts = {
    default_file_explorer = true,
    view_options = { show_hidden = true },
    keymaps = { ["q"] = "actions.close" },
  },
}
