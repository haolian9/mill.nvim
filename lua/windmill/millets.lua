local M = {}

local buflines = require("infra.buflines")
local fn = require("infra.fn")
local jelly = require("infra.jellyfish")("windmill.modeline", "info")
local prefer = require("infra.prefer")
local strlib = require("infra.strlib")

local api = vim.api

do
  ---@param bufnr number
  ---@return string?
  local function resolve_millet_prefix(bufnr)
    local pattern = prefer.bo(bufnr, "commentstring")
    if pattern == "" then return jelly.debug("no &commentstring") end
    return string.format(pattern, "millet: ")
  end

  ---@param bufnr integer
  ---@return string?
  function M.find(bufnr)
    local prefix = resolve_millet_prefix(bufnr)
    if prefix == nil then return end

    local modelines = prefer.bo(bufnr, "modelines")
    for line in fn.slice(buflines.reversed(bufnr), 1, modelines + 1) do
      if strlib.startswith(line, prefix) then return string.sub(line, #prefix + 1) end
    end
    jelly.debug("found no millets in last %d line", modelines)
  end
end

---for example: // millet: sh %:p
---respect: 'commentstring', 'modelines'
---placeholder: %:p
---@param millet string
---@param fpath string @aka, '%:p'
---@return string[]
function M.normalize(millet, fpath)
  local parts = fn.split(millet, " ")

  do -- inject/replace fpath
    local placeholder_index
    for i = #parts, 1, -1 do
      local val = parts[i]
      -- only expect one file placeholder
      if val == "%:p" then
        placeholder_index = i
        break
      end
    end
    if placeholder_index == nil then
      table.insert(parts, fpath)
    else
      parts[placeholder_index] = fpath
    end
  end

  return parts
end

return M
