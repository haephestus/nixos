-- image.nvim: renders images in the terminal via the kitty graphics
-- protocol (Ghostty speaks it). molten.nvim calls its API to place image
-- outputs (matplotlib plots, etc.) inline under the cell instead of the
-- text placeholder.
--
-- Requires the `magick` luarock visible to nvim's embedded LuaJIT — see the
-- programs.neovim.extraWrapperArgs block in modules/editors/nvim/tui.nix
-- (LUA_PATH suffix). Without it this plugin fails to load
-- (require("magick") errors) and molten keeps text-only output rendering.
-- Keep lazy.nvim away from luarocks entirely: image.nvim ships a
-- .rockspec with a magick dependency, so lazy's pkg "rockspec" source
-- tries to luarocks-install it on every startup. Without a system
-- luarocks it falls back to hererocks, which builds Lua 5.1 from source
-- and fails on nix (no readline headers). magick is provided nix-side
-- via the nvim wrapper's LUA_PATH (see tui.nix extraWrapperArgs), so
-- nothing needs installing at runtime.
--
-- This must be plain top-level code, not a plugin `init` or `opts`:
-- spec files are required during lazy.setup's spec parse, which happens
-- BEFORE lazy's pkg state update, whereas `init` functions and the
-- lazy.nvim spec `opts` run too late to disable it (rocks stayed enabled
-- through both in the e2e harness).
--
-- Mutate only the flag: replacing the whole `rocks` table (e.g.
-- `rocks = { enabled = false }`) nils out `rocks.root`/`rocks.server`,
-- and lazy's update_rocks_state then crashes with fs_scandir(nil) if the
-- lazy-rocks directory was removed from disk.
do
  local rocks = require("lazy.core.config").options.rocks
  if rocks then
    rocks.enabled = false
    -- the pkg cache from before this change still assigns image.nvim the
    -- rockspec source (and a build task); drop it so the next recompute —
    -- on the following `Lazy sync`/`Lazy update` — starts clean with
    -- rockspec excluded from the source list.
    vim.uv.fs_unlink(require("lazy.core.config").options.pkg.cache)
  end
end

return {
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty",
      -- this config does not use image.nvim for file previews; molten is the
      -- only consumer, driven through its own API hooks
      integrations = {
        markdown = { enabled = false },
      },
      -- don't render image past the lower window edge; leave scroll room
      max_height_window_percentage = 40,
      -- clear images under other floating windows/overlaps so scrolling
      -- through cells doesn't leave ghosts
      window_overlap_clear_enabled = true,
    },
  },
}
