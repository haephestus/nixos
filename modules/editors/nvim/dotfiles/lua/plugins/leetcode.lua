return {
  {
    "kawre/leetcode.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      local leetcode = require("leetcode")

      leetcode.setup({
        default_lang = "python3", -- Default language
        show_difficulty = true, -- Show difficulty in list
        use_telescope = false, -- Disable Telescope entirely
      })

      local opts = { noremap = true, silent = true }

      -- Open problem list in a split
      vim.keymap.set("n", "<leader>kc", function()
        vim.cmd("vsplit") -- Open vertical split
        vim.cmd("LeetCodeList") -- Show list of problems
      end, opts)

      -- Run tests for current problem
      vim.keymap.set("n", "<leader>kt", ":LeetCodeTest<CR>", opts)

      -- Submit current problem
      vim.keymap.set("n", "<leader>ks", ":LeetCodeSubmit<CR>", opts)

      -- Show problem description
      vim.keymap.set("n", "<leader>kd", ":LeetCodeDescribe<CR>", opts)
    end,
  },
}
