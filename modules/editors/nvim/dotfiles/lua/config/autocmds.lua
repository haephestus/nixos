-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- ── Jupyter notebooks via jupytext ─────────────────────────────────────────
-- Notebooks are edited as percent-format scripts (`# %%` cells, see
-- plugins/notebook.lua) paired with .ipynb files through the jupytext CLI.
--
-- Workflow:
--   - `:NewNotebook <path>`   create a valid .ipynb and open its .py pair
--   - `:MoltenInitPair`       start the kernel matching the pair's .ipynb
--                             (molten keymaps: <space>M* in plugins/molten.lua)
--   - `:JupytextPair`         pair the current .py/.ipynb once (metadata is
--                             stored in the files, so run this just once)
--   - `:JupytextSync`         sync manually (saving an already-paired .py
--                             below already syncs, outputs untouched)
--
-- The binary is provided by the nvim wrapper (programs.lazyvim.extraPackages)
-- and by the project devshells; see tui.nix / devshells/modules/python.nix.
local function jupytext(args)
  local out = vim.fn.system(vim.list_extend({ "jupytext" }, args))
  if vim.v.shell_error ~= 0 then
    vim.notify(("[jupytext] %s"):format(out), vim.log.levels.ERROR)
    return false
  end
  return true
end

local function checktime()
  -- Reload buffers changed on disk by jupytext (the .ipynb partner may be
  -- open in another buffer).
  vim.schedule(function() vim.cmd("checktime") end)
end

-- True when molten has a running kernel for the current buffer
-- (molten.status is only present once the plugin has loaded).
local function molten_initialized()
  local ok, status = pcall(require, "molten.status")
  if not ok then
    return false
  end
  return status.initialized() == "Molten"
end

vim.api.nvim_create_user_command("JupytextPair", function(e)
  if jupytext({ "--set-formats", "ipynb,py:percent", e.file }) then
    checktime()
    vim.notify("[jupytext] paired " .. e.file)
  end
end, { desc = "Pair current file as jupytext ipynb<->py:percent" })

vim.api.nvim_create_user_command("JupytextSync", function(e)
  if jupytext({ "--sync", e.file }) then
    checktime()
  end
end, { desc = "Sync jupytext notebook pair" })

-- Create a fresh (empty but valid) notebook and open the percent-script side.
local new_notebook_template = [[
{
  "cells": [
    {
      "cell_type": "markdown",
      "metadata": {},
      "source": [""]
    }
  ],
  "metadata": {
    "kernelspec": {
      "display_name": "Python 3",
      "language": "python",
      "name": "python3"
    },
    "language_info": { "name": "python" }
  },
  "nbformat": 4,
  "nbformat_minor": 5
}
]]

vim.api.nvim_create_user_command("NewNotebook", function(e)
  local ipynb = vim.fn.fnamemodify(e.args, ":p")
  if not ipynb:match("%.ipynb$") then
    ipynb = ipynb .. ".ipynb"
  end
  if vim.fn.filereadable(ipynb) == 1 then
    vim.notify("[jupytext] file exists: " .. ipynb, vim.log.levels.ERROR)
    return
  end
  local dir = vim.fn.fnamemodify(ipynb, ":h")
  if dir ~= "" and vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  vim.fn.writefile(vim.split(new_notebook_template, "\n"), ipynb)
  if jupytext({ "--set-formats", "ipynb,py:percent", ipynb }) then
    checktime()
    local py = (ipynb:gsub("%.ipynb$", ".py"))
    vim.cmd("edit " .. vim.fn.fnameescape(py))
  end
end, { nargs = 1, complete = "file", desc = "Create a notebook and open its percent-script pair" })

-- Sync on save. Only fires for .py files that carry the `# jupyter:` header
-- jupytext writes into percent scripts, so plain .py files never get a
-- surprise .ipynb sibling.
--
-- Collaboration layer (molten.nvim): keep the text pair and the kernel
-- outputs in sync on save. Order matters and was verified empirically:
-- jupytext --sync FIRST (regenerates the .ipynb from this .py, preserving
-- outputs of cells that did not change), THEN MoltenExportOutput! LAST so
-- the outputs executed in this session are stamped into the notebook after
-- jupytext is done with it (exporting before syncing makes jupytext
-- regenerate the ipynb and drop the outputs entirely).
local sync_group = vim.api.nvim_create_augroup("jupytext_sync", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = sync_group,
  pattern = "*.py",
  callback = function(e)
    local is_notebook = false
    for i = 1, 3 do
      local line = vim.api.nvim_buf_get_lines(e.buf, i - 1, i, false)[1]
      if line and line:find("jupyter:", 1, true) then
        is_notebook = true
        break
      end
    end
    if not is_notebook then
      return
    end
    if jupytext({ "--sync", e.file }) then
      checktime()
    end
    if molten_initialized() then
      -- `!` = overwrite outputs of matching cells (never the code); no arg =
      -- export to the sibling .ipynb. A failure here must not block anything.
      local ok, err = pcall(vim.cmd, "MoltenExportOutput!")
      if not ok then
        vim.notify(("[molten] export failed: %s"):format(err), vim.log.levels.WARN)
      end
    end
  end,
})

