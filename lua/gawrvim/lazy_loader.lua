-- L0 Bootstrap: lazy.nvim installer + plugin spec import.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local result = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "GawrVim: не удалось клонировать lazy.nvim\n", "ErrorMsg" },
      { vim.trim(result), "Comment" },
    }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "gawrvim.plugins" },
}, {
  checker = { enabled = false },
  change_detection = { notify = false },
})
