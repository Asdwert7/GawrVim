local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },

  mapping = cmp.mapping.preset.insert({
    ["<CR>"] = cmp.mapping.confirm({ select = true }), -- (Enter) если выбран пункт -> вставить, если ничего не выбрано -> взять первый
    -- если видно меню -> следующий пункт , если сниппет -> перейти к следующему полю , иначе -> обычный Tab
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    -- Shift-Tab делает обратное действие для TAB
    ["<S-Tab>"] = cmp.mapping(function(fallback) 
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),

  sources = cmp.config.sources({
      { name = "nvim_lsp", priority = 1000 },
      { name = "luasnip",  priority = 750 },
      { name = "buffer",   priority = 250, keyword_length = 3 },

      
  }),
  sorting = {
    priority_weight = 2,
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
})


-- nvim_lsp Источник подсказок от языкового сервера. Имена функций , методы классов , типы , сигнатуры , поля структур
-- buffer   Источник слов из текущего файла, уже написанные идентификаторы , локальные имена переменных , быстрые повторы
-- keyword_length - buffer начинает с 3 символов работать
-- luasnip для снипетов необходим так сказал чат))