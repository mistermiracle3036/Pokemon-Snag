-- Gift jingle, 0.17.20 (REQUESTS 667). Pre-phone reward test: this build moves
-- WHEN several rewards are paid (just before the page that names them), so
-- every paying path is run from the REAL main.lua code against a mock bag:
--   * pays exactly once, and a second talk pays nothing more;
--   * a full bag pays nothing, sets no paid flag, plays no jingle, and the
--     retry after making room pays once;
--   * the pages come out in the same order and wording as 0.17.19, with the
--     jingle on the page that names the item.
-- usage, from the repo root: luajit tests/gift_jingle_probe.lua [main.lua]
local f = assert(io.open(arg[1] or "main.lua", "rb")); local src = f:read("*a"); f:close()
local function section(first, last)
  local a = assert(src:find(first, 1, true), "start not found: " .. first)
  local b = assert(src:find(last, a + #first, true), "end not found: " .. last)
  return src:sub(a, b - 1)
end

local fails, passes = 0, 0
local function check(label, got, want)
  local ok = got == want
  if ok then passes = passes + 1 else fails = fails + 1 end
  if not ok then
    print(("FAIL %s\n   got  %s\n   want %s"):format(label, tostring(got), tostring(want)))
  end
end

-- One world per case: a bag, an event log, and the env the snippet runs in.
local function world(extra)
  local w = { ev = {}, inv = {}, full = {}, flags = {}, store = {} }
  local function log(s) w.ev[#w.ev + 1] = s end
  local save = { inventory = w.inv, party = {} }
  local data = {}
  local mod = { id = "snag_quest", game = { save = save, data = data } }
  mod.world = {
    queueScript = function(_, rows, o)
      for _, row in ipairs(rows) do log("T:" .. row[2]) end
      if o and o.onDone then o.onDone(true) end
      return true
    end,
    overworld = function() return w.overworld end,
  }
  mod.save = {
    get = function(_, k, d) local v = w.store[k]; if v == nil then return d end; return v end,
    set = function(_, k, v) w.store[k] = v end,
  }
  local Bag = { add = function(s, item, n)
    assert(s == save, "Bag.add: wrong save")
    if w.full.ALL or w.full[item] then return false end
    w.inv[item] = (w.inv[item] or 0) + n
    return true
  end }
  local GiftLine = dofile("tests/giftline_fixture.lua")(src, mod, function(item, line)
    log("G:" .. item .. ":" .. line)
  end)
  local function give(item) return function(n) return Bag.add(save, item, n or 1, data) == true end end
  local function flag(name)
    return function() return w.flags[name] == true end, function(v) w.flags[name] = v end
  end
  local env = {
    mod = mod, Bag = Bag, GiftLine = GiftLine, save = save, data = data,
    giveSnagBalls = give("SNAG_BALL"), giveHeistBalls = give("HEIST_BALL"),
    giveOneSnagBall = function() return Bag.add(save, "SNAG_BALL", 1, data) == true end,
    giveRewardSnagBalls = function() return Bag.add(save, "SNAG_BALL", 5, data) == true end,
    CONTRACT_REWARD_BALLS = 5,
    errs = function(fmt) log("ERRS:" .. tostring(fmt):gsub("\n", " ")) end,
  }
  env.I = {
    say = function(pages, done)
      for _, p in ipairs(pages) do log("T:" .. p) end
      if done then done() end
    end,
    afterMenu = function() log("MENU") end,
  }
  for k, v in pairs(extra and extra(w, env, flag) or {}) do env[k] = v end
  setmetatable(env, { __index = _G })
  w.env, w.save, w.mod = env, save, mod
  function w.run(body)
    local chunk = assert(loadstring(body, "=snippet")); setfenv(chunk, env)
    return chunk()
  end
  function w.take() local s = table.concat(w.ev, " / "); w.ev = {}; return s end
  function w.n(item) return w.inv[item] or 0 end
  return w
end

-- pay, pay again, and the full-bag round trip, for a snippet that is one talk
local function payOnce(label, body, extra, item, count, paidFlags)
  local w = world(extra)
  w.run(body)
  check(label .. ": paid", w.n(item), count)
  for _, name in ipairs(paidFlags) do check(label .. ": flag " .. name, w.flags[name], true) end
  w.run(body)
  check(label .. ": second talk pays nothing", w.n(item), count)
  local full = world(extra)
  full.full.ALL = true
  full.run(body)
  check(label .. ": full bag pays nothing", full.n(item), 0)
  for _, name in ipairs(paidFlags) do check(label .. ": full bag leaves " .. name, full.flags[name], nil) end
  check(label .. ": full bag plays no jingle", full.take():find("G:", 1, true), nil)
  full.full.ALL = nil
  full.run(body)
  check(label .. ": retry after making room pays once", full.n(item), count)
  return w
end

------------------------------------------------------------------ helper
do
  local w = world()
  w.env.GiftLine.named("SNAG_BALL", "A\fOne SNAG\nBALL.\fTail one\fTail two", "SNAG",
    function() w.ev[#w.ev + 1] = "DONE" end)
  check("named: jingle on the naming page, tail plain",
    w.take(), "G:SNAG_BALL:A\fOne SNAG\nBALL. / T:Tail one / T:Tail two / DONE")
  w.env.GiftLine.line(false, "SNAG_BALL", "plain", function() w.ev[#w.ev + 1] = "DONE" end)
  check("line(false): no jingle", w.take(), "T:plain / DONE")
  w.env.GiftLine.pages({}, function() w.ev[#w.ev + 1] = "DONE" end)
  check("pages({}): done at once", w.take(), "DONE")
  w.env.GiftLine.lib = nil
  w.env.GiftLine.say(nil, "SNAG_BALL", "no helper", function() w.ev[#w.ev + 1] = "DONE" end)
  check("helper missing: the line still shows", w.take(), "T:no helper / DONE")
end

------------------------------------------------------------------ intro (lass job)
do
  local body = section("    function I.accept()", "    function I.offerMenu()") .. "\nI.accept()\n"
  local function extra(w)
    w.stage = 0
    return { STAGE_NEW = 0, STAGE_ARMED = 1, girlClassIx = 1, MAP = "M", GIRL_NAME = "G",
      stage = function() return w.stage end, setStage = function(v) w.stage = v end,
      spawnGirlForAmbush = function() return true end, removeNamed = function() end }
  end
  local w = world(extra); w.overworld = {}
  w.run(body)
  check("intro: one Ball", w.n("SNAG_BALL"), 1)
  check("intro: pages", w.take(), "G:SNAG_BALL:The job is yours.\nOne SNAG BALL. / T:Collector's east.\nTalk to the lass."
    .. " / T:Target: MEOWTH.\nShe has only one. / T:This first catch\nis guaranteed."
    .. " / T:Later marks: lower\nHP, then throw. / T:Bring proof back.\nYour fee: 5 BALLs.")
  w.run(body)
  check("intro: armed, no second Ball", w.n("SNAG_BALL"), 1)
  local has = world(extra); has.overworld = {}; has.inv.SNAG_BALL = 2
  has.run(body)
  check("intro with a Ball already: none added", has.n("SNAG_BALL"), 2)
  check("intro with a Ball already: no jingle", has.take():sub(1, 2), "T:")
  local full = world(extra); full.overworld = {}; full.full.ALL = true
  full.run(body)
  check("intro full bag: stays NEW", full.stage, 0)
  check("intro full bag: line", full.take(), "T:BALL pocket full.\nMake space first.")
end

------------------------------------------------------------------ sailor reward
do
  local body = section("          -- 0.17.20: the Balls land just before the page that names them",
    "          return\n        end\n\n        if isSailor then")
  local function extra(w, _, flag)
    local get, set = flag("rewardClaimed")
    return { rewardClaimed = get, setRewardClaimed = set, pcall = pcall }
  end
  local w = payOnce("sailor reward", body, extra, "SNAG_BALL", 5, { "rewardClaimed" })
  w = world(extra); w.run(body)
  check("sailor reward: pages", w.take(), "T:She says she paid?\nThat's her story."
    .. " / G:SNAG_BALL:You did the job.\nFive SNAG BALLs. / T:MEOWTH is yours.\nSelling is extra. / MENU")
end

------------------------------------------------------------------ fence sale + valve
do
  local body = section("    local function runFenceSale(voice)", "    -- The Route 36 fence: a professional")
    .. section("    local ROUTE36_VOICE = {", "    -- The opening teaches")
    .. "\nreturn runFenceSale, ROUTE36_VOICE\n"
  local function extra(w)
    w.dead, w.released = false, 0
    return {
      isDeadEnded = function() return w.dead end,
      battlers = function(party) return #party end,
      F = { isRescue = function() return false end, isRui = function() return false end },
      isReservedMon = function() return false end,
      ensureBountyFlag = function() end,
      snagPayoutBreakdown = function() return { total = 3, base = 3, levelBonus = 0, rarityBonus = 0, vipBonus = 0 } end,
      monName = function() return "RATTATA" end,
      SnagChoiceBox = { new = function(_, cb) return { cb = cb } end },
      Boxes = { releaseFromParty = function(save, index)
        table.remove(save.party, index); w.released = w.released + 1; return true end },
      fset = function() end,
    }
  end
  local function sale(w)
    local sell, voice = w.run(body)
    local mon = { snagged = true }
    w.save.party = { { species = "A" }, mon }
    w.overworld = { selectPartyMon = function(_, _, cb) cb(2, mon) end }
    w.mod.game.stack = { push = function(_, box) box.cb(true) end }
    sell(voice)
  end
  local w = world(extra); sale(w)
  check("fence sale: 3 Balls", w.n("SNAG_BALL"), 3)
  check("fence sale: Pokemon gone", #w.save.party, 1)
  local ev = w.take()
  check("fence sale: ends on the jingle line", ev:match("[^/]+$"),
    " G:SNAG_BALL:FENCE: Done.\f3 SNAG BALLs.\nForget we met.")
  local full = world(extra); full.full.ALL = true; sale(full)
  check("fence sale full bag: no Balls", full.n("SNAG_BALL"), 0)
  check("fence sale full bag: Pokemon kept", #full.save.party, 2)
  check("fence sale full bag: no jingle", full.take():find("G:", 1, true), nil)
  local v = world(extra); v.dead = true
  local sell, voice = v.run(body); sell(voice)
  check("valve: one Ball", v.n("SNAG_BALL"), 1)
  check("valve: jingle on the credit page", v.take(),
    "G:SNAG_BALL:FENCE: No BALLs,\nno goods.\fYou're no use to\nme like that.\fHere. One SNAG\nBALL. On credit."
    .. " / T:Don't waste it.")
  local vf = world(extra); vf.dead = true; vf.full.ALL = true
  sell, voice = vf.run(body); sell(voice)
  check("valve full bag: nothing", vf.n("SNAG_BALL"), 0)
  check("valve full bag: line", vf.take(), "T:FENCE: Your BAG's\nfull. Clear space.")
  -- every voice's valve line names the Ball on a page containing SNAG
  for _, name in ipairs({ "ROUTE36_VOICE", "BROKER_VOICE", "CONTACT_VOICE", "FOREMAN_VOICE" }) do
    local t = section("    local " .. name .. " = {", "\n    }")
    check(name .. ": done line names SNAG on its last page", t:match('done = "[^"]*\\f[^"\\]*SNAG[^"]*"') ~= nil, true)
  end
end

------------------------------------------------------------------ repeat job settle line
do
  local body = section('              if c.termsKey == "RELEASE" then\n                mod.world:queueScript({',
    "            elseif why == \"last\" then")
  local function run(key, payout)
    local w = world(function() return { c = { termsKey = key, terms = { payout = payout } }, result = "RESULT" } end)
    w.run(body); return w.take()
  end
  check("repeat DELIVER", run("DELIVER", 6), "T:RESULT / G:SNAG_BALL:PAY: 6 SNAG BALLs")
  check("repeat KEEP", run("KEEP", 3), "T:RESULT / G:SNAG_BALL:PAY: 3 SNAG BALLs")
  check("repeat RELEASE: no jingle", run("RELEASE", 0), "T:RESULT / T:PAY: NO BALLS / T:REWARD: NONE")
end

------------------------------------------------------------------ sewer champion
do
  local body = section("        local doubled = tonumber(mod.save:get(\"g2_sewer_double\", 0)) == 1",
    "      end\n      return false\n    end\n\n    -- Double or nothing.")
  local function extra(w)
    w.wins = 0
    return { S = { IDLE = 0, wins = function() return w.store.g2_sewer_wins or 0 end,
      setStage = function(v) w.sstage = v end, setDraw = function() end, setAfterBattle = function() end } }
  end
  local w = world(extra); w.run(body)
  check("sewer: one HEIST BALL", w.n("HEIST_BALL"), 1)
  check("sewer: win counted", w.store.g2_sewer_wins, 1)
  check("sewer: pages", w.take(), "G:HEIST_BALL:PETREL: Champion.\nOne HEIST BALL. / T:House keeps quiet.\nPurse is yours.")
  local d = world(extra); d.store.g2_sewer_double = 1; d.run(body)
  check("sewer doubled: two", d.n("HEIST_BALL"), 2)
  check("sewer doubled: pages", d.take(), "G:HEIST_BALL:PETREL: You beat\nthe house. Two. / T:House keeps quiet.\nPurse is yours.")
  local full = world(extra); full.full.ALL = true; full.run(body)
  check("sewer full bag: nothing", full.n("HEIST_BALL"), 0)
  check("sewer full bag: win not counted", full.store.g2_sewer_wins, nil)
  check("sewer full bag: line", full.take(), "T:PETREL: BALL bag\nneeds room.")
end

------------------------------------------------------------------ KINGPIN BALL
do
  local body = section('        mod.world:queueScript({\n          { "text", "FOREMAN: Old crew.\\nMAHOGANY base." },',
    "        return true\n      elseif s == Z.GRUNT_M then")
  local function extra(w, _, flag)
    local get, set = flag("kingpinIssued")
    w.z = 0
    return { Z = { NONE = 0, GRUNT_M = 1, kingpinIssued = get, setKingpinIssued = set,
      stage = function() return w.z end, setStage = function(v) w.z = v end,
      giveKingpinBall = function() return w.env.Bag.add(w.save, "KINGPIN_BALL", 1) == true end } }
  end
  local w = payOnce("kingpin", body, extra, "KINGPIN_BALL", 1, { "kingpinIssued" })
  w = world(extra); w.run(body)
  check("kingpin: pages", w.take(), "T:FOREMAN: Old crew.\nMAHOGANY base. / T:They boxed thunder\nBuyer pays tonight"
    .. " / G:KINGPIN_BALL:One KINGPIN BALL.\nIt does not miss.")
  check("kingpin: stage moved", w.z, 1)
  w.z = 0; w.run(body)
  check("kingpin already issued: same pages, no jingle", w.take(),
    "T:FOREMAN: Old crew.\nMAHOGANY base. / T:They boxed thunder\nBuyer pays tonight / T:One KINGPIN BALL.\nIt does not miss.")
  check("kingpin already issued: stage moved", w.z, 1)
end

------------------------------------------------------------------ Goldenrod broker fee
do
  local body = section('          mod.world:queueScript({\n            { "text", "BROKER: Good work.\\nYour call now." },',
    "        else\n          if R.eligible() then R.openBroker()")
  local function extra(_, _, flag)
    local get, set = flag("contractRewarded")
    return { contractRewarded = get, setContractRewarded = set }
  end
  payOnce("broker fee", body, extra, "SNAG_BALL", 5, { "contractRewarded" })
  local w = world(extra); w.run(body)
  check("broker fee: pages", w.take(), "T:BROKER: Good work.\nYour call now. / T:Keep it, or bring\nit back to me."
    .. " / G:SNAG_BALL:Five SNAG BALLs.\nYou earned them.")
end

------------------------------------------------------------------ Ecruteak (two halves)
do
  local body = section("          local function heistHalf()\n            if ecruteakHeistPaid() then return end",
    "        else\n          runFenceSale(CONTACT_VOICE)")
  local function extra(_, _, flag)
    local a, b = flag("fee"); local c, d = flag("heist")
    return { ecruteakFeePaid = a, setEcruteakFeePaid = b, ecruteakHeistPaid = c, setEcruteakHeistPaid = d }
  end
  local w = world(extra); w.run(body)
  check("ecruteak: 5 SNAG", w.n("SNAG_BALL"), 5); check("ecruteak: 1 HEIST", w.n("HEIST_BALL"), 1)
  check("ecruteak: pages", w.take(), "T:CONTACT: Nice.\nYou are moving up. / G:SNAG_BALL:Five SNAG BALLs\nfor the job."
    .. " / G:HEIST_BALL:One more thing.\nHEIST BALL. / T:Better odds.\nSave it for later.")
  local h = world(extra); h.full.HEIST_BALL = true; h.run(body)
  check("ecruteak heist pocket full: fee paid", h.n("SNAG_BALL"), 5)
  check("ecruteak heist pocket full: heist owed", h.flags.heist, nil)
  check("ecruteak heist pocket full: pages", h.take(), "T:CONTACT: Nice.\nYou are moving up."
    .. " / G:SNAG_BALL:Five SNAG BALLs\nfor the job. / T:CONTACT: No room\nfor a HEIST BALL.")
  h.full.HEIST_BALL = nil; h.run(body)
  check("ecruteak retry: fee not paid twice", h.n("SNAG_BALL"), 5)
  check("ecruteak retry: heist paid", h.n("HEIST_BALL"), 1)
  check("ecruteak retry: pages", h.take(), "T:CONTACT: Nice.\nYou are moving up."
    .. " / G:HEIST_BALL:One more thing.\nHEIST BALL. / T:Better odds.\nSave it for later.")
  local full = world(extra); full.full.ALL = true; full.run(body)
  check("ecruteak full bag: nothing", full.n("SNAG_BALL") + full.n("HEIST_BALL"), 0)
  check("ecruteak full bag: nothing flagged", full.flags.fee or full.flags.heist, nil)
  check("ecruteak full bag: pages", full.take(), "T:CONTACT: Nice.\nYou are moving up. / T:CONTACT: No room.\nClear your BAG.")
end

------------------------------------------------------------------ Olivine (two halves)
do
  local body = section("          local function tail()", "        else\n          runFenceSale(FOREMAN_VOICE)")
  local function extra(_, _, flag)
    local a, b = flag("fee"); local c, d = flag("heist")
    return { olivineRewarded = a, setOlivineRewarded = b, olivineHeistPaid = c, setOlivineHeistPaid = d }
  end
  local w = world(extra); w.run(body)
  check("olivine: 5 SNAG", w.n("SNAG_BALL"), 5); check("olivine: 3 HEIST", w.n("HEIST_BALL"), 3)
  check("olivine: pages", w.take(), "T:FOREMAN: Clean.\nRoute's clear. / G:SNAG_BALL:Five SNAG BALLs.\nDock rate."
    .. " / G:HEIST_BALL:Three HEIST BALLs.\nHazard pay. / T:Bring future cargo\nback to me.")
  local up = world(extra); up.flags.fee = true; up.run(body)
  check("olivine upgraded save: only the HEIST BALLs", up.n("SNAG_BALL") * 10 + up.n("HEIST_BALL"), 3)
  check("olivine upgraded save: pages", up.take(), "T:FOREMAN: Clean.\nRoute's clear."
    .. " / G:HEIST_BALL:Three HEIST BALLs.\nHazard pay. / T:Bring future cargo\nback to me.")
  local h = world(extra); h.full.HEIST_BALL = true; h.run(body)
  check("olivine heist pocket full: heist owed", h.flags.heist, nil)
  h.full.HEIST_BALL = nil; h.run(body)
  check("olivine retry: fee once", h.n("SNAG_BALL"), 5); check("olivine retry: heist once", h.n("HEIST_BALL"), 3)
  local full = world(extra); full.full.ALL = true; full.run(body)
  check("olivine full bag: nothing", full.n("SNAG_BALL") + full.n("HEIST_BALL"), 0)
  check("olivine full bag: pages", full.take(), "T:FOREMAN: Clean.\nRoute's clear. / T:FOREMAN: BAG full.\nClear deck space.")
end

------------------------------------------------------------------ Zapdos settlements
do
  local body = "local Z = Z\n" .. section("    function Z.finishSell()", "    function Z.openOutcome()")
  local function extra(w)
    w.bird = true
    return { Z = { findJobMon = function() return w.bird and {} or nil end,
      canRemoveJobMon = function() return true end,
      removeJobMon = function() if not w.bird then return false end w.bird = false; return true end,
      setResolved = function(v) w.resolved = v end } }
  end
  local w = world(extra); w.run(body)
  check("zapdos sell: returns true", w.env.Z.finishSell(), true)
  check("zapdos sell: 20 SNAG", w.n("SNAG_BALL"), 20); check("zapdos sell: 10 HEIST", w.n("HEIST_BALL"), 10)
  check("zapdos sell: bird gone", w.bird, false)
  check("zapdos sell: pages", w.take(), "T:One call. No names\nThe bird is gone. / G:SNAG_BALL:Twenty SNAG BALLs.\nTen HEIST BALLs.")
  check("zapdos sell again: refused", w.env.Z.finishSell(), false)
  check("zapdos sell again: nothing more", w.n("SNAG_BALL") + w.n("HEIST_BALL"), 30)
  local h = world(extra); h.run(body); h.full.HEIST_BALL = true
  check("zapdos sell, heist pocket full: stalls", h.env.Z.finishSell(), false)
  check("zapdos sell, heist pocket full: bird kept", h.bird, true)
  h.take(); h.full.HEIST_BALL = nil
  check("zapdos sell retry: completes", h.env.Z.finishSell(), true)
  check("zapdos sell retry: 20 SNAG once", h.n("SNAG_BALL"), 20); check("zapdos sell retry: 10 HEIST", h.n("HEIST_BALL"), 10)
  local r = world(extra); r.run(body)
  check("zapdos release: returns true", r.env.Z.finishRelease(), true)
  check("zapdos release: tape", r.n("OPEN_WATER_TAPE"), 1)
  check("zapdos release: pages", r.take(), "T:The crate opens.\nZAPDOS takes wing. / T:The storm breaks.\nThe sea goes still"
    .. " / G:OPEN_WATER_TAPE:SEA SONG TAPE.\nNo station airs it")
  local held = world(extra); held.run(body); held.inv.OPEN_WATER_TAPE = 1
  held.env.Z.finishRelease()
  check("zapdos release, tape already held: still one", held.n("OPEN_WATER_TAPE"), 1)
  check("zapdos release, tape already held: no jingle", held.take():find("G:", 1, true), nil)
  local full = world(extra); full.run(body); full.full.ALL = true
  check("zapdos release full bag: stalls", full.env.Z.finishRelease(), false)
  check("zapdos release full bag: bird kept", full.bird, true)
end

print(("%d passed, %d failed"):format(passes, fails))
print(fails == 0 and "ALL PASS" or "FAILED")
os.exit(fails == 0 and 0 or 1)
