-- 0.17.8: every Snag choice as a Trainer Journey style response. Extracts the
-- REAL ListMenu / ChoiceBox shims from main.lua and runs them against a fake
-- Trainer Journey (and none), checking value round-trips, the safe answer
-- first for defaultNo, B = no, and the untouched fallback screens.
-- usage, from the repo root: luajit tests/choice_shim_probe.lua [main.lua]
local f = assert(io.open(arg[1] or "main.lua", "rb")); local src = f:read("*a"); f:close()
local a = assert(src:find("    local RawListMenu = require", 1, true))
local b = assert(src:find("    local MAP = \"ROUTE_29\"", a, true))
local body = src:sub(a, b - 1) .. "\nreturn ListMenu, SnagChoiceBox\n"

local fails = 0
local function check(label, got, want)
  local ok = got == want
  if not ok then fails = fails + 1 end
  print(("%s %-50s got %s want %s"):format(ok and "PASS" or "FAIL", label, tostring(got), tostring(want)))
end

local function setup(tj)
  local made = {}
  local raw = { list = {}, choice = {} }
  local api = tj and {
    dialogue_ui_version = tj.version or 3,
    makeCheckMenu = function(game, opts)
      if tj.fail then error("boom") end
      made[#made + 1] = opts
      return { tj = true, opts = opts }
    end,
  }
  local env = setmetatable({
    mod = { find = function(id) if id == "trainer_journey" and api then return { exports = { trainer_journey = api } } end end },
    require = function(name)
      if name == "src.ui.ListMenu" then
        return { new = function(g, title, items, opts) raw.list[#raw.list + 1] = { title = title, items = items, opts = opts }; return { raw = true } end }
      elseif name == "src.ui.ChoiceBox" then
        return { new = function(g, fn, opts) raw.choice[#raw.choice + 1] = { fn = fn, opts = opts }; return { raw = true } end }
      end
      error(name)
    end,
  }, { __index = _G })
  local chunk = assert(loadstring(body)); setfenv(chunk, env)
  local LM, CB = chunk()
  return LM, CB, made, raw
end

do -- with Trainer Journey
  local LM, CB, made, raw = setup({})
  local chosen, list
  local m = LM.new({}, "THE RING", {
    { label = "STEP IN", value = "IN", reply = "Hold it open." },
    { label = "NOT YET", value = "NO" },
  }, { onChoose = function(item, l) chosen, list = item and item.value, l end })
  check("TJ: check menu returned", m.tj, true)
  check("TJ: no raw list", #raw.list, 0)
  local rows = made[1].rows
  check("TJ: reply carried", rows[1].reply, "Hold it open.")
  check("TJ: no reply -> label shown by TJ", rows[2].reply, nil)
  check("TJ: no stat on any row", rows[1].stat == nil and rows[2].stat == nil, true)
  made[1].onChoose(rows[1])
  check("TJ: value round-trips", chosen, "IN")
  check("TJ: list:close() is safe", pcall(list.close, list), true)
  local cancelled = false
  local m2 = LM.new({}, "X", { { label = "A", value = 1 } }, { onCancel = function() cancelled = true end })
  made[2].onCancel()
  check("TJ: cancel reaches onCancel", cancelled, true)

  local answer
  CB.new({}, function(yes) answer = yes end, { defaultNo = true, yesReply = "Deal.", noReply = "No." })
  local yn = made[3].rows
  check("YES/NO defaultNo: safe answer first", yn[1].value, false)
  check("YES/NO: replies carried", yn[2].reply, "Deal.")
  made[3].onChoose(yn[2]); check("YES/NO: yes -> true", answer, true)
  made[3].onChoose(yn[1]); check("YES/NO: no -> false", answer, false)
  answer = nil; made[3].onCancel(); check("YES/NO: B -> false", answer, false)
  CB.new({}, function() end, {})
  check("YES/NO without defaultNo: yes first", made[4].rows[1].value, true)
  check("YES/NO default replies", made[4].rows[1].reply .. made[4].rows[2].reply, "Yes.No.")
end

do -- without Trainer Journey: original screens, unchanged arguments
  local LM, CB, made, raw = setup(nil)
  local items = { { label = "ENTER", value = "ENTER", reply = "Put me on." } }
  local opts = { kind = "snag.sewer_entry" }
  local m = LM.new({}, "SEWER CIRCUIT", items, opts)
  check("no TJ: raw ListMenu", m.raw, true)
  check("no TJ: same items table", raw.list[1].items, items)
  check("no TJ: same opts table", raw.list[1].opts, opts)
  local fn = function() end
  local co = { defaultNo = true }
  CB.new({}, fn, co)
  check("no TJ: raw ChoiceBox, same callback", raw.choice[1].fn, fn)
  check("no TJ: raw ChoiceBox, same opts", raw.choice[1].opts, co)
end

do -- old Trainer Journey, or one whose menu errors: fall back
  local LM, _, _, raw = setup({ version = 2 })
  LM.new({}, "T", { { label = "A", value = 1 } }, {})
  check("TJ dialogue_ui_version 2: fallback", #raw.list, 1)
  local LM2, CB2, _, raw2 = setup({ fail = true })
  LM2.new({}, "T", { { label = "A", value = 1 } }, {})
  CB2.new({}, function() end, {})
  check("TJ makeCheckMenu errors: list fallback", #raw2.list, 1)
  check("TJ makeCheckMenu errors: yes/no fallback", #raw2.choice, 1)
end

print(fails == 0 and "ALL PASS" or (fails .. " FAILED"))
os.exit(fails == 0 and 0 or 1)
