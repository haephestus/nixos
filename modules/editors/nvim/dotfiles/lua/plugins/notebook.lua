-- Jupyter-notebook style editing.
--
-- Notebooks are percent-format scripts (`# %%` cells) paired with .ipynb
-- through jupytext (see config/autocmds.lua) and executed against a jupyter
-- kernel: NotebookNavigator -> molten.nvim, so outputs render inline and get
-- exported to the .ipynb on save.
--
-- iron.nvim's own keys (<space>i*) still work for ad-hoc REPL sends and the
-- iron pane; the `<space>iX`/`<space>ix` cell runs intentionally go through
-- molten's kernel instead, because only kernel runs record output into the
-- notebook.
--
-- Cell text objects: `vih` / `dih` / `yih` (via mini.ai `h` object below).
-- Native `gc` from ts-comments composes with those objects, e.g. `gch`.
return {
  {
    "GCBallesteros/NotebookNavigator.nvim",
    event = "VeryLazy",
    dependencies = {
      -- hydra powers the sticky cell-ops mode; molten runs the cells
      "anuvyklack/hydra.nvim",
      "benlubas/molten-nvim",
    },
    keys = {
      {
        "]h",
        function()
          require("notebook-navigator").move_cell("d")
        end,
        desc = "Next notebook cell",
      },
      {
        "[h",
        function()
          require("notebook-navigator").move_cell("u")
        end,
        desc = "Previous notebook cell",
      },
      {
        "<space>iX",
        function()
          require("molten.gate").run_cell("run_cell")
        end,
        desc = "Run notebook cell",
      },
      {
        "<space>ix",
        function()
          require("molten.gate").run_cell("run_and_move")
        end,
        desc = "Run notebook cell and move down",
      },
    },
    opts = {
      -- Cells run against the jupyter kernel (molten) so their output lands
      -- in the buffer and the .ipynb on save. Explicit because "auto" would
      -- pick iron first (utils.available_repls order: iron > toggleterm >
      -- molten). iron is untouched for manual sends: <space>i...
      repl_provider = "molten",
      -- Highlight `# %%` markers using the buffer's comment syntax. Avoids
      -- adding mini.hipatterns just for cell markers.
      syntax_highlight = true,
      -- Sticky cell-ops mode (add cell above/below, split, swap, merge, and
      -- run many cells quickly with `x`).
      activate_hydra_keys = "<space>ih",
      hydra_keys = {
        -- This config uses ts-comments.nvim, which NotebookNavigator can't
        -- detect (it only knows Comment.nvim / mini.comment); its no-comment
        -- fallback just nags. Cell commenting stays with native `gc`+`ih`.
        -- NOTE: "nil" is the documented value to unmap a hydra key.
        comment = "nil",
      },
    },
  },
  {
    -- Cells as a mini.ai text object `h`: `vih`, `dah`, `yih`, `gch`, ... and
    -- the hydra mode can operate on the same object.
    "nvim-mini/mini.ai",
    optional = true,
    dependencies = { "GCBallesteros/NotebookNavigator.nvim" },
    opts = function(_, opts)
      opts.custom_textobjects = opts.custom_textobjects or {}
      opts.custom_textobjects.h = require("notebook-navigator").miniai_spec
      return opts
    end,
  },
}
