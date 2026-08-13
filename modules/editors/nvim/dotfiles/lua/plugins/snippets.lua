return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      -- require("luasnip.loaders.from_lua").load({ paths = "~/config/nvim/snippets"})
      require("luasnip.loaders.from_vscode").lazy_load()
      -- Custom snippets live in ~/.config/nvim/snippets/*.json (e.g. Forge
      -- 1.20.1 java.json — see nvim/dotfiles/snippets/).
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
      })
      require'luasnip'.filetype_extend("dart", {"flutter"})
    end,
  },
}
