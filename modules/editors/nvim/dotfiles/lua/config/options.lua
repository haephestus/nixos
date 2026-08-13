-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.textwidth = 80
vim.o.termguicolors = true
vim.opt.formatoptions:append("t")
vim.opt.breakindent = true -- indent wrapped lines
vim.opt.showbreak = "↳ " -- visual cue for wrapped lines (optional, pick a glyph or space)

-- Add any additional options here
if vim.g.neovide then
  vim.g.neovide_cursor_vfx_mode = "pixiedust"
  vim.g.neovide_cursor_vfx_opacity = 200.0
  vim.g.neovide_cursor_vfx_particle_lifetime = 1.2
  vim.g.neovide_cursor_vfx_particle_density = 14.0
  vim.g.neovide_cursor_vfx_particle_speed = 20.0
  vim.g.neovide_cursor_animation_length = 0.13
  vim.g.neovide_cursor_trail_size = 0.8
end
