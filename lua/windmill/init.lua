local M = {}

local bufpath = require("infra.bufpath")
local ex = require("infra.ex")
local fn = require("infra.fn")
local jelly = require("infra.jellyfish")("windmill", "info")
local prefer = require("infra.prefer")
local strlib = require("infra.strlib")

local engine = require("windmill.engine")
local millets = require("windmill.millets")

local api = vim.api

local filetype_runners = {
  python = { "python" },
  zig = { "zig", "run" },
  sh = { "sh" },
  bash = { "bash" },
  lua = { "luajit" },
  c = { "ccrun" },
  go = { "go", "run" },
  nim = { "nim", "compile", "--hints:off", "--run" },
  php = { "php" },
}

function M.run()
  local bufnr = api.nvim_get_current_buf()

  local millet = millets.find(bufnr)
  jelly.debug("millet='%s'", millet)
  --to support: `source`, `source a.lua`, `source a.vim`
  if millet and strlib.startswith(millet, "source") then
    return engine.source(millet)
  end

  local fpath = bufpath.file(bufnr)
  if fpath == nil then return jelly.warn("not exists on disk") end

  if millet then -- try modeline first
    local cmd = millets.normalize(millet, fpath)
    assert(cmd[1] ~= "source")
    return engine.spawn(cmd)
  end

  do -- then ft
    local runner = filetype_runners[prefer.bo(bufnr, "filetype")]
    if runner ~= nil then
      local cmd = fn.tolist(fn.chained(runner, { fpath }))
      return engine.spawn(cmd)
    end
  end

  jelly.warn("no available runner")
end

return M
