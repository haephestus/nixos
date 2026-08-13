return {
  "nickjvandyke/opencode.nvim",
  version = "*", -- Latest stable release
  config = function()
    ---@type opencode.Opts
    --
    -- ══════════════════════════════════════════════════════════════════════
    --  ALL opencode.nvim OPTIONS (documentation reference)
    --  ──────────────────────────────────────────────────────────────────────
    --  Plugin config lives in `vim.g.opencode_opts`, defined by `opencode.Opts`.
    --  Source of truth: https://github.com/nickjvandyke/opencode.nvim
    --  * defaults → lua/opencode/config.lua
    --  * go-to-definition on `opencode.Opts` in nvim shows every field
    --
    --  Every field is shown below with its DEFAULT value, commented out.
    --  Uncomment (and edit) only what you need — nothing active below except
    --  the empty table, so this matches the default behaviour exactly.
    -- ══════════════════════════════════════════════════════════════════════
    vim.g.opencode_opts = {
      -- ── server ──────────────────────────────────────────────────────────
      -- OpenCode server connection options.
      -- server = {
      --   url = nil,              -- string or fun(callback): "http://localhost:4096"
      --                           -- Bypasses discovery; server MUST run `opencode --port`
      --   connect = true,         -- connect + listen for events before interacting
      --   username = vim.env.OPENCODE_SERVER_USERNAME or "opencode",
      --   password = vim.env.OPENCODE_SERVER_PASSWORD,  -- basic auth password
      --   start = function()      -- fun() | false; start server when none found
      --     vim.cmd("vsplit term://opencode --port | wincmd p")
      --   end,
      -- },

      -- ── contexts ────────────────────────────────────────────────────────
      -- Context placeholders and their builders (table<string, fun>).
      -- Built-in placeholders you can use in prompts:
      --   @this        range/selection, else cursor position
      --   @buffer      current buffer
      --   @buffers     open buffers
      --   @diagnostics diagnostics in range, else current buffer
      --   @marks       global marks
      --   @quickfix    quickfix list
      --   @visible     visible text
      -- contexts = {
      --   ["@this"] = require("opencode.context.builtins").this,
      --   ["@buffer"] = require("opencode.context.builtins").buffer,
      --   ["@buffers"] = require("opencode.context.builtins").buffers,
      --   ["@diagnostics"] = require("opencode.context.builtins").diagnostics,
      --   ["@marks"] = require("opencode.context.builtins").marks,
      --   ["@quickfix"] = require("opencode.context.builtins").quickfix,
      --   ["@visible"] = require("opencode.context.builtins").visible_text,
      -- },

      -- ── ask ─────────────────────────────────────────────────────────────
      -- Options for ask(). Supports snacks.input when enabled.
      -- ask = {
      --   prompt = "Ask OpenCode: ",
      --   completion = "customlist,v:lua.opencode_completion",
      --   snacks = {            -- snacks.input.Opts, e.g.:
      --     icon = "󰚩 ",
      --     win = {
      --       title_pos = "left",
      --       relative = "cursor",
      --       row = -3,         -- row above the cursor
      --       col = 0,          -- align with the cursor
      --       keys = { i_cr = { desc = "submit" } },
      --       b = { completion = true },
      --       bo = { filetype = "opencode_ask" },
      --       on_buf = function(win)
      --         vim.lsp.start(require("opencode.ui.ask.cmp"), { bufnr = win.buf })
      --       end,
      --     },
      --   },
      -- },

      -- ── select ──────────────────────────────────────────────────────────
      -- Options and items for select(). Supports snacks.picker when enabled.
      -- select = {
      --   prompt = "OpenCode: ",
      --   prompts = {                       -- selectable canned prompts
      --     ask = "...",
      --     diagnostics = "Explain @diagnostics",
      --     document = "Add comments documenting @this",
      --     explain = "Explain @this and its context",
      --     fix = "Fix @diagnostics",
      --     implement = "Implement @this",
      --     optimize = "Optimize @this for performance and readability",
      --     review = "Review @this for correctness and readability",
      --     test = "Add tests for @this",
      --   },
      --   commands = {                      -- TUI commands (also usable via require("opencode").command)
      --     ["agent.cycle"] = "Cycle selected agent",
      --     ["prompt.clear"] = "Clear current prompt",
      --     ["prompt.submit"] = "Submit current prompt",
      --     ["session.compact"] = "Compact current session",
      --     ["session.interrupt"] = "Interrupt current session",
      --     ["session.new"] = "Start new session",
      --     ["session.redo"] = "Redo last undone action in current session",
      --     ["session.select"] = "Select session",
      --     ["session.undo"] = "Undo last action in current session",
      --   },
      --   server = {
      --     ["server.start"] = "Start configured server",
      --     ["server.connect"] = "Connect to a server",
      --     ["server.disconnect"] = "Disconnect from connected server",
      --   },
      --   snacks = {            -- snacks.picker.Opts
      --     preview = "preview",
      --     layout = { preset = "vscode", hidden = {} },
      --   },
      -- },

      -- ── events ──────────────────────────────────────────────────────────
      -- Handling of OpenCode SSE events (dispatched as `OpencodeEvent:*` autocmds).
      -- events = {
      --   enabled = true,
      --   reload = { enabled = true },      -- reload buffers edited by OpenCode (sets vim.o.autoread)
      --   permissions = {
      --     enabled = true,
      --     edits = { enabled = true },     -- show :diffpatch tab for edit requests
      --   },
      -- },
    }

    -- Recommended/example keymaps
    vim.keymap.set({ "n", "x" }, "<C-a>", function()
      require("opencode").ask("@this: ")
    end, { desc = "Ask OpenCode…" })
    vim.keymap.set({ "n", "x" }, "<C-x>", function()
      require("opencode").select()
    end, { desc = "Select OpenCode…" })
    vim.keymap.set({ "n", "x" }, "go", function()
      return require("opencode").operator("@this ")
    end, { desc = "Append range to OpenCode", expr = true })
    vim.keymap.set({ "n" }, "goo", function()
      return require("opencode").operator("@this ") .. "_"
    end, { desc = "Append line to OpenCode", expr = true })
    vim.keymap.set({ "n" }, "<S-C-u>", function()
      require("opencode").command("session.half.page.up")
    end, { desc = "Scroll OpenCode up" })
    vim.keymap.set({ "n" }, "<S-C-d>", function()
      require("opencode").command("session.half.page.down")
    end, { desc = "Scroll OpenCode down" })
  end,
}
