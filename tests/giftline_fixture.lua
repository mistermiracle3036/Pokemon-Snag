-- Test fixture: the REAL GiftLine block from main.lua, run against a fake copy
-- of the shared helper (lib/gift_jingle.lua) that only records the call.
--   local GiftLine = dofile("tests/giftline_fixture.lua")(src, mod, log)
-- `mod` needs .id and .world:queueScript; `log(itemId, line)` is called for
-- every line that would have played the jingle.
return function(src, mod, log)
  local a = assert(src:find("  local GiftLine = {}", 1, true), "GiftLine block start")
  local b = assert(src:find("  -- A quest mark is a BOUNTY", a, true), "GiftLine block end")
  local body = src:sub(a, b - 1) .. "\nreturn GiftLine\n"
  _G.__GIFTLOG = log
  mod.read = function(_, path)
    assert(path == "lib/gift_jingle.lua", path)
    return "return { say = function(m, item, line, opts) __GIFTLOG(item, line);"
      .. " if opts and opts.onDone then opts.onDone() end; return true end }"
  end
  local env = setmetatable({ mod = mod,
    require = function() return { reportError = function() end } end }, { __index = _G })
  local chunk = assert(loadstring(body, "=GiftLine")); setfenv(chunk, env)
  return chunk()
end
