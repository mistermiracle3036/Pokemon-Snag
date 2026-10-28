-- Shadow opening, Snag side (REQUESTS 251; contract shadow-opening): extracts
-- the REAL fence code from main.lua and runs every branch against a mock save,
-- counting SNAG BALLs. Pre-phone test required because the proof pays items.
-- usage, from the repo root: luajit tests/shadow_fence_probe.lua [main.lua]
local f = assert(io.open(arg[1] or "main.lua", "rb")); local src = f:read("*a"); f:close()
local function section(first, last)
  local a = assert(src:find(first, 1, true), first)
  local b = assert(src:find(last, a + #first, true), last)
  return src:sub(a, b - 1)
end
local core = section("    local RUI_STORY =", "    -- \"Sellable\" must mean")
local talk = section("    function F.accept()", "    mod.events:on(\"game.ready\"")
local body = core .. talk .. "\nreturn F, isReservedMon\n"

local fails = 0
local function check(label, got, want)
  local ok = got == want
  if not ok then fails = fails + 1 end
  print(("%s %-52s got %s want %s"):format(ok and "PASS" or "FAIL", label, tostring(got), tostring(want)))
end

local RUI = "shadow_pokemon:rui_meowth"
local function setup(opts)
  opts = opts or {}
  local store = {}
  local st = { stage = 0, rewarded = false, menus = {}, said = {}, after = 0, errs = 0 }
  local save = { party = opts.party or { { species = "CYNDAQUIL" } },
    boxes = opts.boxes or {}, inventory = { SNAG_BALL = opts.balls or 0 } }
  local mod = {
    exports = {},
    find = function(_, id) if id == "shadow_pokemon" and opts.shadow ~= false then return {} end end,
    save = {
      get = function(_, k, d) local v = store[k]; if v == nil then return d end; return v end,
      set = function(_, k, v) store[k] = v end,
    },
    game = { save = save, stack = { push = function(_, menu) st.menus[#st.menus + 1] = menu end } },
  }
  mod.find = function(id) if id == "shadow_pokemon" and opts.shadow ~= false then return {} end end
  local env = setmetatable({
    mod = mod,
    Boxes = { NUM_BOXES = 14 },
    STAGE_NEW = 0, STAGE_ARMED = 1, STAGE_DONE = 2,
    stage = function() return st.stage end,
    setStage = function(v) st.stage = v end,
    rewardClaimed = function() return st.rewarded end,
    setRewardClaimed = function(v) st.rewarded = v end,
    giveOneSnagBall = function()
      if opts.bagFull then return false end
      save.inventory.SNAG_BALL = save.inventory.SNAG_BALL + 1; return true
    end,
    giveRewardSnagBalls = function()
      if st.bagFull then return false end
      save.inventory.SNAG_BALL = save.inventory.SNAG_BALL + 5; return true
    end,
    errs = function() st.errs = st.errs + 1 end,
    I = {
      say = function(pages, done)
        for _, p in ipairs(pages) do st.said[#st.said + 1] = p end
        if done then done() end
      end,
      afterMenu = function() st.after = st.after + 1 end,
      syncCareer = function() end,
    },
    ListMenu = { new = function(_, title, items, o) return { title = title, items = items, o = o,
      close = function() end } end },
    Z = { stage = function() return 0 end, RESOLVED = 9 },
    R = { jobId = function() return 0 end, stage = function() return 0 end, NONE = 0 },
  }, { __index = _G })
  local chunk = assert(loadstring(body)); setfenv(chunk, env)
  local F, isReserved = chunk()
  st.F, st.save, st.mod, st.store, st.isReserved = F, save, mod, store, isReserved
  function st.choose(value)
    local menu = table.remove(st.menus)
    assert(menu, "no menu open")
    for _, item in ipairs(menu.items) do
      if item.value == value then menu.o.onChoose(item, menu); return end
    end
    error("no item " .. value)
  end
  function st.cancel() local menu = table.remove(st.menus); menu.o.onCancel() end
  return st
end
local function balls(t) return t.save.inventory.SNAG_BALL end

-- dialogue limits on every page the fence can say
do
  local t = setup()
  for line in talk:gmatch('"([^"]-)"') do
    if line:find("\\n", 1, true) or #line > 10 then
      local segs = 0
      for seg in (line .. "\\n"):gmatch("(.-)\\n") do
        segs = segs + 1
        if #seg > 18 then check("dialogue width <= 18: " .. seg, #seg, 18) end
      end
      if segs > 2 then check("dialogue <= 2 lines: " .. line, segs, 2) end
    end
  end
end

do -- REQUESTS 278: the fence never says her name; the player learns it from Rui
  local named = 0
  for line in talk:gmatch('"([^"]-)"') do
    if line:find("RUI", 1, true) then
      named = named + 1
      check("fence line names RUI: " .. line, false, true)
    end
  end
  check("no fence line names RUI", named, 0)
end

do -- refuse: nothing granted, revisit offers again
  local t = setup()
  t.F.talk()
  check("fresh talk opens the offer menu", #t.menus, 1)
  t.choose("leave")
  check("NO DEAL: refused", t.F.facts().refused, true)
  check("NO DEAL: not accepted", t.F.facts().accepted, false)
  check("NO DEAL: no Balls", balls(t), 0)
  check("NO DEAL: not a Rui job", t.F.ruiJob(), false)
  t.F.talk()
  check("revisit offers again", #t.menus, 1)
  t.choose("why")
  check("WHY ME? returns to the menu", #t.menus, 1)
  t.cancel()
  check("cancel: still not accepted", t.F.facts().accepted, false)
  check("cancel: no Balls", balls(t), 0)
  t.F.talk(); t.choose("accept")
  check("accept after refusing: accepted", t.F.facts().accepted, true)
  check("accept after refusing: refused stays (never cleared)", t.F.facts().refused, true)
  check("accept after refusing: 1 tutorial Ball", balls(t), 1)
end

do -- honest route: loan shown, paid once, kept by the player
  local loan = { species = "MEOWTH", storyId = RUI, onLoanFrom = "rui" }
  local t = setup()
  t.F.talk(); t.choose("accept")
  check("accept: Rui job", t.F.ruiJob(), true)
  check("accept: stage ARMED", t.stage, 1)
  check("accept: 1 Ball", balls(t), 1)
  t.F.talk()
  check("armed, no Meowth: no pay", balls(t), 1)
  check("armed, no Meowth: no proof", t.F.facts().proofShown, false)
  t.save.party[2] = loan
  t.F.talk()
  check("loan shown: proofShown", t.F.facts().proofShown, true)
  check("loan shown: proofWith loan", t.F.facts().proofWith, "loan")
  check("loan shown: paid 5 once", balls(t), 6)
  check("loan shown: proofPaid", t.F.facts().proofPaid, true)
  check("loan shown: stage DONE", t.stage, 2)
  check("loan shown: chain open (rewardClaimed)", t.rewarded, true)
  check("loan shown: Meowth still with the player", t.save.party[2], loan)
  local heard = false
  for _, p in ipairs(t.said) do if p:find("My buyer", 1, true) then heard = true end end
  check("paid: fence lets slip his buyer (proofPaid = knows buyer)", heard, true)
  t.F.talk(); t.F.talk()
  check("talk again twice: still 6 Balls", balls(t), 6)
  check("talk again: after-menu", t.after >= 2, true)
  check("loan is reserved from every fence", t.isReserved(loan), true)
end

do -- pay pending while the Bag is full
  local t = setup({ party = { { species = "CYNDAQUIL" },
    { species = "MEOWTH", storyId = RUI, snagged = true } } })
  t.F.talk(); t.choose("accept")
  t.bagFull = true
  t.F.talk()
  check("bag full: proof recorded", t.F.facts().proofShown, true)
  check("bag full: proofWith snagged", t.F.facts().proofWith, "snagged")
  check("bag full: not paid", t.F.facts().proofPaid, false)
  check("bag full: stage not advanced", t.stage, 1)
  check("bag full: Balls unchanged", balls(t), 1)
  local early = false
  for _, p in ipairs(t.said) do if p:find("My buyer", 1, true) then early = true end end
  check("bag full: buyer not mentioned before payment", early, false)
  t.bagFull = false
  t.save.party[2] = nil
  t.F.talk()
  check("room again: pays without re-showing", balls(t), 6)
  check("room again: proofPaid", t.F.facts().proofPaid, true)
end

do -- thief: stolen (stage DONE by capture), then sold/released before showing
  local t = setup()
  t.F.talk(); t.choose("accept")
  t.stage = 2                                   -- the capture hook's effect
  t.F.talk()
  check("stolen and gone: job closed", t.rewarded, true)
  check("stolen and gone: no fee", balls(t), 1)
  check("stolen and gone: proofPaid false", t.F.facts().proofPaid, false)
end

do -- Meowth in a PC box is not shown
  local t = setup({ boxes = { { { species = "MEOWTH", storyId = RUI, snagged = true } } } })
  t.F.talk(); t.choose("accept")
  t.F.talk()
  check("boxed Meowth: no proof", t.F.facts().proofShown, false)
  check("boxed Meowth: no pay", balls(t), 1)
end

do -- tool: one at accept, one re-issue only when spent, none on top
  local t = setup({ balls = 3 })
  t.F.talk(); t.choose("accept")
  check("holding Balls: no extra tool", balls(t), 3)
  t.save.inventory.SNAG_BALL = 0
  t.F.talk()
  check("spent: one re-issued", balls(t), 1)
  t.F.talk()
  check("not spent: none on top", balls(t), 1)
end

do -- full pocket at accept: job not taken
  local t = setup({ bagFull = true })
  t.F.talk(); t.choose("accept")
  check("pocket full at accept: not accepted", t.F.facts().accepted, false)
  check("pocket full at accept: stage NEW", t.stage, 0)
end

do -- contract read side + absent Shadow
  local t = setup()
  check("export getFenceJob", type(t.mod.exports.getFenceJob), "function")
  check("export snag_quest.getFenceJob", t.mod.exports.snag_quest.getFenceJob, t.mod.exports.getFenceJob)
  local facts = t.mod.exports.getFenceJob()
  for _, k in ipairs({ "accepted", "refused", "proofShown", "proofPaid", "soldRuiMeowth" }) do
    check("fact " .. k .. " is boolean", type(facts[k]), "boolean")
  end
  check("shadowActive with Shadow", t.F.shadowActive(), true)
  local t2 = setup({ shadow = false })
  check("shadowActive without Shadow", t2.F.shadowActive(), false)
  check("ordinary snagged mon not reserved", t.isReserved({ snagged = true }), false)
  -- chunk B: a rescued Shadow is never fence stock, before or after purify
  check("rescue (shadow) reserved", t.isReserved({ snagged = true, shadow = true }), true)
  check("rescue (purified) reserved", t.isReserved({ snagged = true, purified = true }), true)
  check("rescue (shadowFrom) reserved", t.isReserved({ snagged = true, shadowFrom = "cipher:naps" }), true)
  check("isRescue false for an ordinary theft", t.F.isRescue({ snagged = true }), false)
end

do -- 0.17.6: a rescue gets its own refusal from every fence voice (WHAT_TO_CHECK 886)
  local sale = section("    local function runFenceSale(voice)", "    I.sell = function()")
  local r, n = sale:find("if F.isRescue(picked) then", 1, true), sale:find("if picked.snagged ~= true then", 1, true)
  check("sale: rescue refusal before the not-stolen line", r ~= nil and n ~= nil and r < n, true)
  for _, v in ipairs({ "ROUTE36_VOICE", "BROKER_VOICE", "CONTACT_VOICE", "FOREMAN_VOICE" }) do
    local body = section("    local " .. v .. " = {", "\n    }")
    check(v .. " has its rescued line", body:find("rescued = {", 1, true) ~= nil, true)
    for line in (body:match("rescued = (%b{})") or ""):gmatch('"([^"]*)"') do
      for seg in (line .. "\\n"):gmatch("(.-)\\n") do
        if #seg > 18 then check(v .. " rescued width: " .. seg, #seg, 18) end
      end
    end
  end
end

do -- chunk B: the capture handler returns before any bounty/job for a rescue
  local h = section("    mod.events:on(\"pokemon.caught\", function(payload)",
    "      if introBattleActive and mon.species == \"MEOWTH\"")
  check("capture: rescue returns before bounty/job stamps",
    h:find("if F.isRescue(mon) then return end", 1, true) ~= nil, true)
  check("capture: origin stamped before that return",
    h:find("mon.snagged = true", 1, true) < h:find("if F.isRescue(mon) then return end", 1, true), true)
end

print(fails == 0 and "ALL PASS" or (fails .. " FAILED"))
os.exit(fails == 0 and 0 or 1)
