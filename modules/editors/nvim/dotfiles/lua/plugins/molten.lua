-- molten.nvim: run code through a real jupyter kernel with outputs rendered
-- inside the buffer (below each cell as virtual text).
--
-- Why: iron.nvim is a terminal REPL — great for live work, but its output is
-- ephemeral and never lands in the .ipynb. molten executes against a jupyter
-- kernel, keeps outputs per cell, and exports them into the notebook file
-- (save hook in config/autocmds.lua), which is what makes the .ipynb usable
-- by teammates / Jupyter Lab / anyone without an nvim session.
--
-- Keymaps under <space>M* (LazyVim: space is leader; capital M avoids the
-- java/gradle overseer binds on <leader>mr/mt from plugins/java.lua). Declared as lazy `keys`
-- so they exist before the plugin loads and pressing one boots molten.
--
-- Images: rendered inline under the cell via image.nvim (kitty graphics
-- protocol; Ghostty supports it). image.nvim needs the `magick` luarock on
-- nvim's LUA_PATH — see modules/editors/nvim/tui.nix (extraWrapperArgs).
-- If the rock is missing, molten keeps working with text outputs only.
-- `:MoltenImagePopup` still opens images in the system image viewer.
return {
  {
    "benlubas/molten-nvim",
    -- generates stdpath("data")/rplugin.json; re-runs on install AND update,
    -- so a stale manifest is never the failure mode
    build = ":UpdateRemotePlugins",
    event = "VeryLazy",
    keys = {
      -- kernel lifecycle
      { "<space>Mi", "<cmd>MoltenInitPair<cr>", silent = true, desc = "Molten: init kernel (pair-aware)" },
      { "<space>Md", "<cmd>MoltenDeinit<cr>", silent = true, desc = "Molten: deinit kernel" },
      { "<space>Mk", "<cmd>MoltenInterrupt<cr>", silent = true, desc = "Molten: interrupt kernel" },
      {
        "<space>MR",
        function()
          vim.g.molten_kernel_ready = false -- reboots also drop early executes
          vim.cmd("sil MoltenRestart")
        end,
        silent = true,
        desc = "Molten: restart kernel",
      },

      -- outputs
      { "<space>Mo", ":noautocmd MoltenEnterOutput<cr>", silent = true, desc = "Molten: enter output window" },
      { "<space>Mh", "<cmd>MoltenHideOutput<cr>", silent = true, desc = "Molten: hide output window" },
      { "<space>Mv", "<cmd>MoltenEvaluateVisual<cr>", mode = "v", silent = true, desc = "Molten: evaluate selection" },
      { "<space>Mp", "<cmd>MoltenImagePopup<cr>", silent = true, desc = "Molten: open image output in viewer" },
      { "<space>Mb", "<cmd>MoltenOpenInBrowser<cr>", silent = true, desc = "Molten: open HTML output in browser" },

      -- .ipynb round-trip (collaboration layer)
      { "<space>Me", "<cmd>MoltenExportOutput!<cr>", silent = true, desc = "Molten: export outputs to sibling .ipynb" },
      {
        "<space>MI",
        "<cmd>MoltenImportOutput<cr>",
        silent = true,
        desc = "Molten: import outputs from sibling .ipynb",
      },
    },
    init = function()
      -- output as pinned virtual text below each cell; the float only opens
      -- when explicitly entered via <space>Mo
      vim.g.molten_auto_open_output = false
      vim.g.molten_virt_text_output = true
      vim.g.molten_wrap_output = true
      -- inline images are placed by image.nvim (see plugins/image.lua);
      -- without that plugin loaded molten falls back to text placeholders
      vim.g.molten_image_provider = "image.nvim"
    end,
    config = function()
      -- jupyter_client writes kernel connection files under
      -- stdpath("data")/jupyter/runtime but never creates the directory
      -- itself (unlike full jupyter installs, which is why this can be
      -- missing on fresh systems); mkdir?("p") is a no-op when present.
      vim.fn.mkdir(vim.fn.stdpath("data") .. "/jupyter/runtime", "p")

      -- Kernel boot readiness gate for `run_cell`. Empirically (harness e2e):
      -- evaluating before the kernel client finishes booting SILENTLY DROPS
      -- the execution (molten sends `execute` immediately; the still-booting
      -- kernel never sees it, so no `execute_input` and no outputs ever
      -- arrive). Molten emits User events around its lifecycle — track them:
      --   MoltenInitPre     buffer attached, kernel starting   -> not ready
      --   MoltenKernelReady first kernel message processed     -> ready
      --   MoltenDeinitPost  kernel detached                    -> clear
      vim.api.nvim_create_autocmd("User", {
        pattern = "MoltenInitPre",
        callback = function()
          vim.g.molten_kernel_ready = false
          -- molten's image canvas does require("image") at init time
          -- (rplugin/python3/molten/images.py): image.nvim must be LOADED,
          -- not just installed, or MoltenInit errors instead of rendering.
          -- Only image outputs need it, so load it lazily right here.
          pcall(vim.cmd, "Lazy! load image.nvim")
        end,
        desc = "molten gates: kernel starting",
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "MoltenKernelReady",
        callback = function()
          vim.g.molten_kernel_ready = true
        end,
        desc = "molten gates: kernel ready",
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "MoltenDeinitPost",
        callback = function()
          vim.g.molten_kernel_ready = nil
        end,
        desc = "molten gates: kernel detached",
      })

      -- After a kernel init, pull in what teammates stored in the notebook so
      -- a shared .ipynb opens with their results visible (outputs attach to
      -- matching cells). Mirrors molten's own Notebook-Setup recipe.
      vim.api.nvim_create_autocmd("User", {
        pattern = "MoltenInitPost",
        callback = function()
          local sibling = vim.fn.expand("%:r") .. ".ipynb"
          if vim.fn.filereadable(sibling) == 1 then
            pcall(vim.cmd, "MoltenImportOutput")
          end
        end,
      })

      -- Pair-aware init: prefer the kernelspec recorded in the sibling
      -- .ipynb (what the notebook was authored with), falling back to the
      -- plain python3 kernel.
      --
      -- jupyter_client quirk (manager.format_kernel_cmd): a kernelspec whose
      -- argv[0] is the literal "python"/"python3" is REWRITTEN at spawn to
      -- sys.executable of the python running nvim (our nix python-withPackages
      -- host). PATH never enters the resolution, so the project venv would
      -- never be used without the below: we register a project kernelspec
      -- carrying an ABSOLUTE interpreter path (argv[0] absolute paths are not
      -- rewritten) and init molten with it instead.
      local function molten_init_pair()
        local ipynb = vim.fn.expand("%:r") .. ".ipynb"
        local kernel = "python3"
        if vim.fn.filereadable(ipynb) == 1 then
          local ok, data = pcall(function()
            local f = io.open(ipynb, "r")
            local content = f:read("a")
            f:close()
            return vim.json.decode(content)
          end)
          local ks = ok and data and data.metadata and data.metadata.kernelspec and data.metadata.kernelspec.name
          if type(ks) == "string" and ks ~= "" then
            kernel = ks
          end
        end

        -- project env: first `python` on PATH (the kernel PATH contract lives
        -- in the project's devshell; see devshells/modules/python.nix)
        local exepath = vim.fn.exepath("python")
        local env_root = exepath ~= "" and vim.fn.fnamemodify(exepath, ":h:h") or ""
        -- is the PATH python already our nvim host env? (no project packages
        -- in either case at that point — but then the fallback kernel is the
        -- right choice and no custom spec is needed)
        local host_prog = vim.g.python3_host_prog -- set in config/options.lua
        local is_host_python = host_prog ~= nil
          and vim.fn.fnamemodify(host_prog, ":h") == vim.fn.fnamemodify(exepath, ":h")

        if exepath ~= "" and not is_host_python then
          local proj_kernel = vim.fn.fnamemodify(env_root, ":t") .. "-" .. kernel
          if not vim.list_contains(vim.fn.MoltenAvailableKernels(), proj_kernel) then
            local out = vim.fn.system({
              exepath,
              "-m",
              "ipykernel",
              "install",
              "--user",
              "--name",
              proj_kernel,
              "--display-name",
              proj_kernel,
            })
            if vim.v.shell_error ~= 0 then
              vim.notify(("[molten] kernelspec install failed: %s"):format(out), vim.log.levels.WARN)
            else
              vim.notify(("[molten] registered project kernel: %s"):format(proj_kernel), vim.log.levels.INFO)
            end
          end
          if vim.list_contains(vim.fn.MoltenAvailableKernels(), proj_kernel) then
            kernel = proj_kernel
          else
            vim.notify(
              ("[molten] falling back to kernel %s (host env, no project packages)"):format(kernel),
              vim.log.levels.WARN
            )
          end
        end
        vim.cmd(("MoltenInit %s"):format(kernel))
      end

      vim.api.nvim_create_user_command("MoltenInitPair", molten_init_pair, {
        desc = "Init molten kernel matching the paired .ipynb's kernelspec",
      })
    end,
  },
}
