-- Held item and MAIL on every Snag removal (0.17.26, REQUESTS 862). Pre-phone save test: these paths
-- take a POKEMON from the player and pay items, so the REAL code from main.lua runs against a mock save.
-- For the ordinary fence sale, the repeat-job settlement and the ZAPDOS ending:
--   * a held item is back in the BAG and the POKEMON is gone, paid once;
--   * a full BAG changes nothing (no pay, POKEMON kept, item still on it);
--   * MAIL is refused with the speaker's approved line and nothing changes;
--   * a party whose only other POKEMON has fainted is refused.
-- (The ROUTE 29 loan sale has the same cases in tests/loan_sale_probe.lua.)
-- usage, from the repo root: luajit tests/held_item_probe.lua [main.lua]
local f = assert(io.open(arg[1] or "main.lua", "rb")); local src = f:read("*a"); f:close()
local function section(first, last)
  local a = assert(src:find(first, 1, true), "start not found: " .. first)
  local b = assert(src:find(last, a + #first, true), "end not found: " .. last)
  return src:sub(a, b - 1)
end
local HELD = dofile("tests/held_fixture.lua")(src)

local fails, passes = 0, 0
local function check(label, got, want)
  local ok = got == want
  if ok then passes = passes + 1 else fails = fails + 1 end
  if not ok then print(("FAIL %s\n   got  %s\n   want %s"):format(label, tostring(got), tostring(want))) end
end

local function world(opts)
  opts = opts or {}
  local w = { said = {}, inv = {}, store = {}, errs = 0, releaseOk = true }
  w.target = { species = "RATTATA", snagged = true, hp = 12, item = opts.item }
  local save = { inventory = w.inv, boxes = {},
    party = opts.party or { { species = "CYNDAQUIL", hp = 20 }, w.target } }
  if opts.fainted then save.party[1].hp = 0 end
  w.save = save
  local mod = { id = "snag_quest", game = { save = save, data = {} } }
  mod.world = {
    queueScript = function(_, rows, o)
      for _, row in ipairs(rows) do w.said[#w.said + 1] = row[2] end
      if o and o.onDone then o.onDone(true) end
    end,
    overworld = function() return w.overworld end,
  }
  mod.save = {
    get = function(_, k, d) local v = w.store[k]; if v == nil then return d end; return v end,
    set = function(_, k, v) w.store[k] = v end,
  }
  local Bag = {
    add = function(s, id, n)
      if w.full == true or (type(w.full) == "table" and w.full[id]) then return false end
      s.inventory[id] = (s.inventory[id] or 0) + n; return true
    end,
    remove = function(s, id, n) s.inventory[id] = (s.inventory[id] or 0) - n end,
  }
  local env = {
    mod = mod, Bag = Bag, I = {},
    require = function(name)
      assert(name == "src.core.gen2.Mail", name)
      return { monHoldsMail = function(mon) return mon.item == "FLOWER_MAIL" end }
    end,
    Boxes = {
      releaseFromParty = function(s, index)
        if not w.releaseOk or not s.party[index] then return false end
        table.remove(s.party, index); return true
      end,
      release = function(s, box, slot)
        if not (s.boxes[box] and s.boxes[box][slot]) then return false end
        table.remove(s.boxes[box], slot); return true
      end,
    },
    battlers = function(p, excluding)
      local n = 0
      for _, mon in ipairs(p or {}) do
        if mon ~= excluding and type(mon) == "table" and mon.isEgg ~= true then n = n + 1 end
      end
      return n
    end,
    errs = function() w.errs = w.errs + 1 end,
    giveSnagBalls = function(n) return Bag.add(save, "SNAG_BALL", n) == true end,
    GiftLine = {
      named = function(_, text) w.said[#w.said + 1] = text end,
      pages = function(pages, done) for _, p in ipairs(pages) do w.said[#w.said + 1] = p end if done then done() end end,
      line = function(_, _, line) w.said[#w.said + 1] = line end,
      say = function(_, _, line, done) w.said[#w.said + 1] = line; if done then done() end end,
    },
  }
  for k, v in pairs(opts.env and opts.env(w, env) or {}) do env[k] = v end
  setmetatable(env, { __index = _G })
  w.env, w.mod = env, mod
  function w.run(body)
    local chunk = assert(loadstring(HELD .. body, "=snippet")); setfenv(chunk, env)
    return chunk()
  end
  function w.take() local s = table.concat(w.said, " / "); w.said = {}; return s end
  function w.state()
    return ("party=%d item=%s bagItem=%s balls=%s"):format(#save.party, tostring(w.target.item),
      tostring(w.inv.BERRY), tostring(w.inv.SNAG_BALL))
  end
  return w
end

------------------------------------------------------------------ helpers
do
  local w = world(); w.run("")
  local I = w.env.I
  local mon = { item = "BERRY" }
  check("takeHeld: ok", select("#", I.takeHeld(w.save, mon)) > 0 and mon.item, nil)
  check("takeHeld: in the BAG", w.inv.BERRY, 1)
  I.putHeldBack(w.save, mon, "BERRY")
  check("putHeldBack: on the POKEMON again", mon.item, "BERRY")
  check("putHeldBack: out of the BAG", w.inv.BERRY, 0)
  check("takeHeld: MAIL refused", select(2, I.takeHeld(w.save, { item = "FLOWER_MAIL" })), "mail")
  w.full = true
  check("takeHeld: full BAG refused", select(2, I.takeHeld(w.save, mon)), "bag")
  check("takeHeld: full BAG leaves the item", mon.item, "BERRY")
  check("takeHeld: nothing held is fine", I.takeHeld(w.save, {}), true)
  check("healthyBesides: a fainted one does not count", I.healthyBesides({ { hp = 0 }, mon }, mon), false)
  check("healthyBesides: an EGG does not count", I.healthyBesides({ { hp = 5, isEgg = true }, mon }, mon), false)
  check("healthyBesides: a healthy one does", I.healthyBesides({ { hp = 1 }, mon }, mon), true)
end

------------------------------------------------------------------ ordinary fence sale, all four voices
do
  local saleBody = section("    local function runFenceSale(voice)", "    -- The Route 36 fence: a professional")
  local voices = ""
  for _, name in ipairs({ "ROUTE36_VOICE", "BROKER_VOICE", "CONTACT_VOICE", "FOREMAN_VOICE" }) do
    voices = voices .. section("    local " .. name .. " = {", "\n    }\n") .. "\n    }\n"
  end
  local function fenceEnv(w)
    return {
      isDeadEnded = function() return false end,
      F = { isRescue = function() return false end, isRui = function() return false end },
      isReservedMon = function() return false end,
      ensureBountyFlag = function() end,
      snagPayoutBreakdown = function() return { total = 3, base = 3, levelBonus = 0, rarityBonus = 0, vipBonus = 0 } end,
      monName = function() return "RATTATA" end,
      SnagChoiceBox = { new = function(_, cb) return { cb = cb } end },
      fset = function() end,
    }
  end
  local body = saleBody .. voices
    .. "\nreturn runFenceSale, { FENCE = ROUTE36_VOICE, BROKER = BROKER_VOICE, CONTACT = CONTACT_VOICE, FOREMAN = FOREMAN_VOICE }\n"
  local MAIL = {
    FENCE = "FENCE: It's got\nMAIL on it.\fTake the MAIL off.\nThen we talk.",
    BROKER = "BROKER: It carries\nMAIL. Remove it.",
    CONTACT = "CONTACT: MAIL?\nTake it off first.",
    FOREMAN = "FOREMAN: No MAIL\non my cargo.",
  }
  local function sale(opts, who)
    opts.env = fenceEnv
    local w = world(opts)
    local sell, voice = w.run(body)
    w.overworld = { selectPartyMon = function(_, _, cb) cb(2, w.target) end }
    w.mod.game.stack = { push = function(_, box) box.cb(true) end }
    w.voice = voice[who or "FENCE"]
    sell(w.voice)
    return w
  end
  local w = sale({ item = "BERRY" })
  check("fence sale, held item", w.state(), "party=1 item=nil bagItem=1 balls=3")
  w = sale({})
  check("fence sale, nothing held", w.state(), "party=1 item=nil bagItem=nil balls=3")
  w = sale({ item = "BERRY" }); -- rerun with a full item pocket only
  local full = world({ item = "BERRY", env = fenceEnv })
  do
    local sell, voice = full.run(body)
    full.overworld = { selectPartyMon = function(_, _, cb) cb(2, full.target) end }
    full.mod.game.stack = { push = function(_, box) box.cb(true) end }
    full.full = { BERRY = true }
    sell(voice.FENCE)
    check("fence sale, no room for the item", full.state(), "party=2 item=BERRY bagItem=nil balls=nil")
    check("fence sale, no room for the item: line", full.take():match("[^/]+$"), " FENCE: No room for\nmy payment.\fClear some space.")
    full.full = { SNAG_BALL = true }
    sell(voice.FENCE)
    check("fence sale, no room for the pay: item put back", full.state(), "party=2 item=BERRY bagItem=0 balls=nil")
    full.full = nil
    sell(voice.FENCE)
    check("fence sale, then room: sells once", full.state(), "party=1 item=nil bagItem=1 balls=3")
  end
  for who, line in pairs(MAIL) do
    local m = sale({ item = "FLOWER_MAIL" }, who)
    check(who .. " sale, MAIL: nothing changes", m.state(), "party=2 item=FLOWER_MAIL bagItem=nil balls=nil")
    check(who .. " sale, MAIL: the approved line", m.take():match("[^/]+$"), " " .. line)
    for page in (line .. "\f"):gmatch("(.-)\f") do
      for row in (page .. "\n"):gmatch("(.-)\n") do check(who .. " MAIL row fits 18: " .. row, #row <= 18, true) end
    end
  end
  local faint = sale({ fainted = true })
  check("fence sale, only a fainted POKEMON besides it", faint.state(), "party=2 item=nil bagItem=nil balls=nil")
  check("fence sale, only a fainted POKEMON: his last-one line", faint.take():match("[^/]+$"):sub(1, 17), " FENCE: You nuts?")
end

------------------------------------------------------------------ repeat-job settlement (BROKER)
do
  local body = "local R = R\n" .. section("    function R.canRemoveJobMon()", "    function Z.resolveCarrier(name)")
  local function job(opts, terms)
    opts.env = function(w)
      return { R = { CAUGHT = 2,
        contract = function() return { termsKey = terms or "DELIVER", terms = { payout = terms == "RELEASE" and 0 or 6 } } end,
        findJobMon = function()
          for i, mon in ipairs(w.save.party) do if mon == w.target then return mon, "party", i end end
          for i, mon in ipairs(w.save.boxes[1] or {}) do if mon == w.target then return mon, "box", 1, i end end
        end,
        stage = function() return 2 end, completed = function() return w.store.done or 0 end,
        clear = function() end } }
    end
    local w = world(opts); w.run(body); return w
  end
  local w = job({ item = "BERRY" })
  check("repeat job DELIVER, held item: settles", w.env.R.finish(), true)
  check("repeat job DELIVER, held item", w.state(), "party=1 item=nil bagItem=1 balls=6")
  w = job({ item = "BERRY" }); w.full = { BERRY = true }
  check("repeat job, no room for the item: why", select(2, w.env.R.finish()), "bag")
  check("repeat job, no room for the item", w.state(), "party=2 item=BERRY bagItem=nil balls=nil")
  w.full = { SNAG_BALL = true }
  check("repeat job, no room for the pay: why", select(2, w.env.R.finish()), "bag")
  check("repeat job, no room for the pay: item put back", w.state(), "party=2 item=BERRY bagItem=0 balls=nil")
  w.full = nil
  check("repeat job, then room: settles", w.env.R.finish(), true)
  check("repeat job, then room", w.state(), "party=1 item=nil bagItem=1 balls=6")
  w = job({ item = "FLOWER_MAIL" })
  check("repeat job, MAIL: why", select(2, w.env.R.finish()), "mail")
  check("repeat job, MAIL: nothing changes", w.state(), "party=2 item=FLOWER_MAIL bagItem=nil balls=nil")
  w = job({ fainted = true })
  check("repeat job, only a fainted POKEMON besides it: why", select(2, w.env.R.finish()), "last")
  w = job({ item = "BERRY" }, "KEEP")
  check("repeat job KEEP: settles", w.env.R.finish(), true)
  check("repeat job KEEP: the POKEMON and its item stay", w.state(), "party=2 item=BERRY bagItem=nil balls=6")
  w = job({ item = "BERRY" }); w.releaseOk = false
  check("repeat job, removal fails: why", select(2, w.env.R.finish()), "remove")
  check("repeat job, removal fails: item put back", w.target.item .. ":" .. w.inv.BERRY, "BERRY:0")
  w = job({ item = "BERRY" }); table.remove(w.save.party, 2); w.save.boxes[1] = { w.target }
  check("repeat job, target in the PC with an item: settles", w.env.R.finish(), true)
  check("repeat job, target in the PC: item back, box empty", w.inv.BERRY .. ":" .. #w.save.boxes[1], "1:0")
  -- the BROKER's line for the new reason
  check("BROKER has a MAIL line for the repeat job",
    src:find('elseif why == "mail" then.-"BROKER: It carries\\nMAIL%. Remove it%."') ~= nil, true)
end

------------------------------------------------------------------ ZAPDOS ending
do
  local body = "local Z = Z\n" .. section("    function Z.canRemoveJobMon()", "    function S.stage()")
    .. section("    Z.MAIL_LINE = ", "    function Z.openOutcome()")
  local function zap(opts)
    opts.env = function(w)
      return { Z = { setResolved = function(v) w.resolved = v end,
        findJobMon = function()
          for i, mon in ipairs(w.save.party) do if mon == w.target then return mon, "party", i end end
        end } }
    end
    local w = world(opts); w.run(body); return w
  end
  local w = zap({ item = "BERRY" })
  check("ZAPDOS sell, held item: completes", w.env.Z.finishSell(), true)
  check("ZAPDOS sell, held item", w.state(), "party=1 item=nil bagItem=1 balls=20")
  w = zap({ item = "BERRY" }); w.full = { BERRY = true }
  check("ZAPDOS sell, no room for the item: stalls", w.env.Z.finishSell(), false)
  check("ZAPDOS sell, no room for the item: bird kept with its item", #w.save.party .. ":" .. w.target.item, "2:BERRY")
  check("ZAPDOS sell, no room for the item: line", w.take(), "No room in BAG.\nClear some space.")
  w.full = nil
  check("ZAPDOS sell, then room: completes", w.env.Z.finishSell(), true)
  check("ZAPDOS sell, then room: paid once", w.state(), "party=1 item=nil bagItem=1 balls=20")
  w = zap({ item = "FLOWER_MAIL" })
  check("ZAPDOS sell, MAIL: refused", w.env.Z.finishSell(), false)
  check("ZAPDOS sell, MAIL: nothing changes", w.state(), "party=2 item=FLOWER_MAIL bagItem=nil balls=nil")
  check("ZAPDOS sell, MAIL: line", w.take(), "It carries MAIL.\nTake it off first.")
  w = zap({ item = "FLOWER_MAIL" })
  check("ZAPDOS release, MAIL: refused", w.env.Z.finishRelease(), false)
  check("ZAPDOS release, MAIL: no tape, bird kept", tostring(w.inv.OPEN_WATER_TAPE) .. ":" .. #w.save.party, "nil:2")
  w = zap({ item = "BERRY" })
  check("ZAPDOS release, held item: completes", w.env.Z.finishRelease(), true)
  check("ZAPDOS release, held item: back in the BAG", w.inv.BERRY .. ":" .. #w.save.party, "1:1")
  w = zap({ fainted = true })
  check("ZAPDOS sell, only a fainted POKEMON besides it: refused", w.env.Z.finishSell(), false)
  check("ZAPDOS sell, only a fainted POKEMON: line", w.take(), "Keep one partner.\nThen decide.")
  w = zap({ item = "BERRY" }); w.releaseOk = false
  check("ZAPDOS sell, removal fails: refused", w.env.Z.finishSell(), false)
  check("ZAPDOS sell, removal fails: item put back", w.target.item .. ":" .. w.inv.BERRY, "BERRY:0")
  for _, line in ipairs({ "It carries MAIL.\nTake it off first.", "No room in BAG.\nClear some space." }) do
    for row in (line .. "\n"):gmatch("(.-)\n") do check("row fits 18: " .. row, #row <= 18, true) end
  end
end

print(("%d passed, %d failed"):format(passes, fails))
print(fails == 0 and "ALL PASS" or "FAILED")
os.exit(fails == 0 and 0 or 1)
