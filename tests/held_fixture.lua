-- Test fixture: the source of main.lua's REAL "HELD PROPERTY" helpers (I.healthyBesides, I.holdsMail,
-- I.takeHeld, I.putHeldBack), to run inside a probe's env. The env needs: I (a table), Bag (add, remove),
-- mod (.game.data) and a `require` that answers "src.core.gen2.Mail".
--   local held = dofile("tests/held_fixture.lua")(src)   -- then: loadstring(held .. your snippet)
return function(src)
  local a = assert(src:find("    function I.healthyBesides(party, mon)", 1, true), "held block start")
  local b = assert(src:find("    local FENCE_MAP", a, true), "held block end")
  return src:sub(a, b - 1) .. "\n"
end
