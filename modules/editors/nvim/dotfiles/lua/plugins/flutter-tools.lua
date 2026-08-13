-- flutter.lua
-- Plugin config for Flutter development in LazyVim using flutter-tools.nvim

return {
  {
    "akinsho/flutter-tools.nvim",
    ft = { "dart" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("flutter-tools").setup({
        -- Optional: Flutter tools config options
        debugger = {
          enabled = true,
          run_via_dap = true,
        },
        widget_guides = {
          enabled = true,
        },
        dev_tools = {
          autostart = true,
          auto_open_browser = false,
        },
        lsp = {
          color = { enabled = true, virtual_text = true, virtual_text_str = "■" },
          on_attach = function(client, bufnr)
            -- You can add custom keymaps here
            local opts = { noremap = true, silent = true, buffer = bufnr }
            vim.keymap.set("n", "<leader>fr", "<cmd>FlutterRun<cr>", opts)
            vim.keymap.set("n", "<leader>fd", "<cmd>FlutterDevices<cr>", opts)
            vim.keymap.set("n", "<leader>fq", "<cmd>FlutterQuit<cr>", opts)
            vim.keymap.set("n", "<leader>fl", "<cmd>FlutterReload<cr>", opts)
            vim.keymap.set("n", "<leader>fp", "<cmd>FlutterOutlineToggle<cr>", opts)
          end,
          settings = {
            dart = {
              completeFunctionCalls = true,
            },
          },
        },
      })
    end,
  },
}
