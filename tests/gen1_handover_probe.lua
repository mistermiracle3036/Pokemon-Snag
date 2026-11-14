-- Gen 1 (Red) hand-overs, 0.17.28 (REQUESTS 931). Pre-phone save test: both commands take a POKEMON
-- from the party, so the REAL command functions from main.lua run against a mock save.
--   snag_quest:turn_in_meowth  the ROUTE 24 recruiter takes the MEOWTH; the reward is a later script row
--   snag_quest:sell_snagged    a Kanto fence buys a stolen POKEMON
-- usage, from the repo root: luajit tests/gen1_handover_probe.lua [main.lua]
local f = assert(io.open(arg[1] or "main.lua", "rb")); local src = f:read("*a"); f:close()
local function section(first, last)
  local a = assert(src:find(first, 1, true), "start not found: " .. first)
  local b = assert(src:find(last, a + #first, true), "end not found: " .. last)
  return src:sub(a, b - 1)
end
local body = section("  mod.exports._healthyBesidesGen1 = function(party, mon)", "  -- The merchant system.")
  :gsub("%-%-%-%-%-+%s*$", "")
  .. section('  mod.content.commands:register("snag_quest:turn_in_meowth", {',
    '  mod.content.commands:register("snag_quest:complete"')

local fails, passes = 0, 0
local function check(label, got, want)
  local ok = got == want
  if ok then passes = passes + 1 else fails = fails + 1 end
  if not ok then print(("FAIL %s\n   got  %s\n   want %s"):format(label, tostring(got), tostring(want))) end
end

local function setup(opts)
  opts = opts or {}
  local t = { said = {}, cmds = {}, pick = opts.pick }
  local meowth = { species = "MEOWTH", hp = 12, snagged = true }
  t.meowth = meowth
  local save = { party = opts.party or { { species = "CHARMANDER", hp = opts.reserveHp or 20 }, meowth },
    inventory = { SNAG_BALL = opts.balls } }
  t.save = save
  local Bag = {
    add = function(s, id, n)
      if t.full then return false end
      s.inventory[id] = (s.inventory[id] or 0) + n; return true
    end,
    remove = function(s, id, n)
      s.inventory[id] = (s.inventory[id] or 0) - n
      if s.inventory[id] <= 0 then s.inventory[id] = nil end
    end,
  }
  local Commands = {
    show_text = function(_, text) t.said[#t.said + 1] = text end,
    ask = function(ctx) ctx.lastCheck = opts.answer ~= false end,
    give_item = function(ctx, id, n)
      if not Bag.add(ctx.save, id, n) then t.said[#t.said + 1] = "BAGFULL"; return math.huge end
    end,
  }
  local pending
  local mod = { exports = {}, content = { commands = { register = function(_, name, def)
    t.cmds[name] = type(def) == "table" and def.fn or def
  end } } }
  local env = setmetatable({
    mod = mod, QUEST_REWARD_BALLS = 5,
    snagPayout = function() return 2 end,
    require = function(name)
      if name == "src.inventory.Bag" then return Bag end
      if name == "src.script.Commands" then return Commands end
      if name == "src.ui.Screens" then
        return { push = function(_, _, o) pending = o end }
      end
      error("unexpected require " .. name)
    end,
  }, { __index = _G })
  local chunk = assert(loadstring(body, "=gen1")); setfenv(chunk, env); chunk()
  t.ctx = { save = save, lastCheck = nil,
    game = { data = { text = { _BagFullText = "ENGINE BAG FULL" }, pokemon = { MEOWTH = { name = "MEOWTH" } } } },
    runner = { resume = function() end, yield = function()
      local o = pending; pending = nil
      t.asked = true
      if t.pick == nil then o.onCancel() else o.onSwitch(t.pick == "meowth" and meowth or save.party[1]) end
    end } }
  function t.run(name) t.asked = false; return t.cmds["snag_quest:" .. name](t.ctx) end
  function t.state()
    return ("party=%d balls=%s check=%s"):format(#save.party, tostring(save.inventory.SNAG_BALL), tostring(t.ctx.lastCheck))
  end
  return t
end

------------------------------------------------------------------ the MEOWTH hand-over
do
  local t = setup({ pick = "meowth" })
  check("turn-in: continues to the next row", t.run("turn_in_meowth"), nil)
  check("turn-in: MEOWTH taken, success, room check left no Balls behind", t.state(), "party=1 balls=nil check=true")
  -- the script's own reward row then runs
  check("turn-in: the reward row still has room", t.save.inventory.SNAG_BALL, nil)

  t = setup({ pick = "meowth", balls = 3 })
  t.run("turn_in_meowth")
  check("turn-in with Balls in hand: stack untouched by the room check", t.state(), "party=1 balls=3 check=true")

  t = setup({ pick = "meowth" }); t.full = true
  check("turn-in, full bag: the script ends", t.run("turn_in_meowth"), "end")
  check("turn-in, full bag: MEOWTH kept", t.state(), "party=2 balls=nil check=nil")
  check("turn-in, full bag: the engine's bag-full text", t.said[1], "ENGINE BAG FULL")
  check("turn-in, full bag: the picker never opened", t.asked, false)
  t.full = false
  t.run("turn_in_meowth")
  check("turn-in, then room: taken once", t.state(), "party=1 balls=nil check=true")

  t = setup({ pick = "meowth", reserveHp = 0 })
  t.run("turn_in_meowth")
  check("turn-in, only a fainted POKEMON besides it: refused", t.state(), "party=2 balls=nil check=false")

  t = setup({ pick = "other" })
  t.run("turn_in_meowth")
  check("turn-in, wrong POKEMON picked: refused", t.state(), "party=2 balls=nil check=false")
  t = setup({})
  t.run("turn_in_meowth")
  check("turn-in, cancelled: refused", t.state(), "party=2 balls=nil check=false")
  t = setup({ pick = "meowth" }); t.save.party = { t.meowth }
  t.run("turn_in_meowth")
  check("turn-in, MEOWTH is the only POKEMON: refused, picker not opened", t.state() .. ":" .. tostring(t.asked), "party=1 balls=nil check=false:false")
end

------------------------------------------------------------------ the Kanto fence
do
  local t = setup({ pick = "meowth" })
  t.run("sell_snagged")
  check("fence: sold, paid 2", t.state(), "party=1 balls=2 check=true")
  t = setup({ pick = "meowth", reserveHp = 0 })
  t.run("sell_snagged")
  check("fence, only a fainted POKEMON besides it: refused, nothing paid", t.state(), "party=2 balls=nil check=false")
  t = setup({ pick = "meowth" }); t.full = true
  t.run("sell_snagged")
  check("fence, full bag: POKEMON kept, nothing paid", t.state(), "party=2 balls=nil check=false")
  t = setup({ pick = "meowth", answer = false })
  t.run("sell_snagged")
  check("fence, player says no: nothing changes", t.state(), "party=2 balls=nil check=false")
  t = setup({ pick = "other" })
  t.run("sell_snagged")
  check("fence, a POKEMON that is not stolen: refused", t.state(), "party=2 balls=nil check=false")
end

print(("%d passed, %d failed"):format(passes, fails))
print(fails == 0 and "ALL PASS" or "FAILED")
os.exit(fails == 0 and 0 or 1)
