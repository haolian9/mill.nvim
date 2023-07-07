local M = {}

local fn = require("infra.fn")
local jelly = require("infra.jellyfish")("windmill")
local prefer = require("infra.prefer")

local engine = require("windmill.engine")
local find_modeline = require("windmill.find_modeline")

local api = vim.api

local filetype_runners = {
  python = { "python" },
  zig = { "zig", "run" },
  sh = { "sh" },
  bash = { "bash" },
  lua = { "luajit" },
  c = { "ccrun" },
  fennel = { "fennel" },
  go = { "go", "run" },
  nim = { "nim", "compile", "--hints:off", "--run" },
  rust = { "cargo", "run", "--quiet" },
  php = { "php" },
}

function M.autorun()
  local bufnr = api.nvim_get_current_buf()

  -- try modeline first
  do
    local cmd = find_modeline(bufnr)
    if cmd ~= nil then return engine.run(cmd) end
  end

  -- then ft
  do
    local runner = filetype_runners[prefer.bo(bufnr, "filetype")]
    if runner ~= nil then
      local fpath = vim.fn.fnamemodify(api.nvim_buf_get_name(bufnr), "%:p")
      local cmd = fn.concrete(fn.chained(runner, { fpath }))
      return engine.run(cmd)
    end
  end

  jelly.info("no runner available for this buf#%d", bufnr)
end

M.run = engine.run

return M
