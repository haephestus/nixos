-- In lua/plugins/todo-md.lua or your plugin configuration
return {
  {
    "zaffron/todo-md.nvim",
    opts = {
      todo_file_path = vim.fn.expand("~/todo.md"), -- Customize your todo file location
      auto_sort = true, -- Auto-sort todos by completion status
      floating_width = 80, -- Custom width for floating window (in columns)
      keybindings = {
        open_todo_floating = "<leader>to",
        open_todo_buffer = "<leader>tO",
        add_todo = "<leader>ta",
        toggle_todo = "<leader>tt",
        delete_todo = "<leader>td",
        sort_todos = "<leader>ts",
        clear_todos = "<leader>tc",
        mark_all_done = "<leader>tD",
        mark_all_undone = "<leader>tU",
        insert_today = "<leader>tdt",
        insert_tomorrow = "<leader>tdm",
        insert_full_date = "<leader>tdf",
      },
    },
    config = function(_, opts)
      require("zaffron.todo-md").setup(opts)
    end,
    keys = {
      { "<leader>to", desc = "Open Todo (Floating)" },
      { "<leader>tO", desc = "Open Todo (Buffer)" },
      { "<leader>ta", desc = "Add Todo Item" },
      { "<leader>tt", desc = "Toggle Todo Item" },
      { "<leader>td", desc = "Delete Todo Item" },
      { "<leader>ts", desc = "Sort Todos" },
      { "<leader>tc", desc = "Clear Todos" },
      { "<leader>tD", desc = "Mark All Done" },
      { "<leader>tU", desc = "Mark All Undone" },
      { "<leader>tdt", desc = "Insert Today's Date" },
      { "<leader>tdm", desc = "Insert Tomorrow's Date" },
      { "<leader>tdf", desc = "Insert Full Date" },
    },
  },
}
