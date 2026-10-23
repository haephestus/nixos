-- Treesitter comment stripper for the molten.nvim integration.
--
-- This SHADOWS molten-nvim's own lua/remove_comments.lua (user lua/ precedes
-- plugin paths on the runtimepath, and molten's python side does
-- `require("remove_comments")` when exporting). Upstream's version is broken
-- on Neovim 0.11+: the `#offset!` treesitter directive now produces
-- `metadata[1].offset` (strings) instead of the `region`/`range` the plugin
-- reads, so no comments were ever removed -> MoltenExportOutput's cell
-- matching failed with "No cell matching cell in notebook ... Bailing"
-- whenever the notebook cell text differed from the executed range by even a
-- marker comment. This rewrite reads the comment node's real span via
-- node:start() and truncates from there, which is what upstream intended.
--
-- Same semantics as upstream: match the notebook and the executed buffer cell
-- by their code text with comments removed.
local M = {}

M.remove_comments = function(str, lang)
  local ok_parser, parser = pcall(vim.treesitter.get_string_parser, str, lang)
  if not ok_parser or not parser then
    return str
  end
  local tree = parser:parse()
  if not tree or not tree[1] then
    return str
  end
  local root = tree[1]:root()
  -- `comment` is the node type used by the python grammar (and many others);
  -- if a grammar does not have it, keep the source untouched like upstream do.
  local ok_query, query = pcall(vim.treesitter.query.parse, lang, "((comment) @c)")
  if not ok_query or not query then
    return str
  end

  local lines = vim.split(str, "\n")
  for _, node in query:iter_captures(root, str) do
    local srow, scol = node:start()
    if type(srow) == "number" and lines[srow + 1] then
      lines[srow + 1] = string.sub(lines[srow + 1], 1, scol)
    end
  end

  lines = vim.tbl_filter(function(line)
    return line ~= ""
  end, lines)
  return table.concat(lines, "\n")
end

return M
