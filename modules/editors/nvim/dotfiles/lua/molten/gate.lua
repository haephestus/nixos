-- Readiness gate for notebook cell runs (see plugins/molten.lua for the
-- rationale: executions issued before the kernel client finishes booting are
-- silently dropped by molten — no `execute_input`, no outputs, nothing).
--
-- `vim.g.molten_kernel_ready` is maintained by User autocmds in molten.lua
-- (MoltenInitPre / MoltenKernelReady / MoltenDeinitPost), so both modules can
-- share one source of truth.
local M = {}

-- Send a cell only once the kernel has booted. While it is still starting,
-- hold the run until the first MoltenKernelReady (after a genuine kernel
-- init; on the plain "no molten at all" path nothing is gated).
---@param what string NN method: "run_cell" or "run_and_move"
M.run_cell = function(what)
  local nn = require("notebook-navigator")

  local okmol, ms = pcall(require, "molten.status")
  if not (okmol and ms.initialized() == "Molten") then
    -- no kernel yet: the molten init prompt takes care of itself via NN's
    -- knowledge — only run for real kernels (molten is attached)
    nn[what]()
    return
  end

  if vim.g.molten_kernel_ready == false then
    -- Kernel is booting: defer until MoltenKernelReady, once.
    vim.notify("[molten] kernel starting — running cell when ready", vim.log.levels.INFO)
    vim.api.nvim_create_autocmd("User", {
      pattern = "MoltenKernelReady",
      once = true,
      callback = function()
        vim.notify("[molten] kernel ready", vim.log.levels.INFO)
        nn[what]()
      end,
    })
    return
  end

  nn[what]()
end

return M
