-- LARRY's lent POKEMON, sold to the ROUTE 29 sailor (0.17.21, REQUESTS 806;
-- contract adoption-loan-sale). Pre-phone save test: the sale moves a POKEMON
-- out of the party and pays money, so the REAL block from main.lua is run
-- against a mock save, and the sale record is pushed through a save
-- round trip (serialise, reload).
-- usage, from the repo root: luajit tests/loan_sale_probe.lua [main.lua]
local f = assert(io.open(arg[1] or "main.lua", "rb")); local src = f:read("*a"); f:close()
local function section(first, last)
  local a = assert(src:find(first, 1, true), "start not found: " .. first)
  local b = assert(src:find(last, a + #first, true), "end not found: " .. last)
  return src:sub(a, b - 1)
end
local body = "local F = {}\n"
  .. section("    -- (fields on F, not locals: this function is at Lua's 200-local limit)",
    "    -- THE OFFICER IN ELM'S LAB")
  .. "\nreturn F\n"
local reserved = "local F, Z, R = ...\n" .. section("    local function isReservedMon(mon)",
  "    -- \"Sellable\" must mean") .. "\nreturn isReservedMon\n"

local fails, passes = 0, 0
local function check(label, got, want)
  local ok = got == want
  if ok then passes = passes + 1 else fails = fails + 1 end
  if not ok then print(("FAIL %s\n   got  %s\n   want %s"):format(label, tostring(got), tostring(want))) end
end

-- a plain-data serialiser standing in for the save file
local function dump(v)
  if type(v) == "table" then
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local out = {}
    for _, k in ipairs(keys) do
      out[#out + 1] = "[" .. (type(k) == "string" and ("%q"):format(k) or tostring(k)) .. "]=" .. dump(v[k])
    end
    return "{" .. table.concat(out, ",") .. "}"
  end
  assert(type(v) ~= "function" and type(v) ~= "userdata", "unserialisable value in the save")
  return type(v) == "string" and ("%q"):format(v) or tostring(v)
end

local function setup(opts)
  opts = opts or {}
  local t = { said = {}, menus = {}, listeners = {}, store = {}, errs = 0, faced = nil, releaseOk = true }
  local larry = { species = opts.species or "SLAKOTH", onLoanFrom = "larry", level = 12,
    nickname = opts.nickname, dvs = { atk = 7, def = 3 }, moves = { "SCRATCH", "YAWN" },
    jqpLentFor = "bianca", junk = function() end }
  t.larry = larry
  local party = opts.party or { { species = "CYNDAQUIL" }, larry, { species = "PIDGEY" } }
  local save = { party = party, player = { money = opts.money or 3000 }, inventory = {} }
  t.save = save
  local mod = {
    id = "snag_quest", exports = { snag_quest = {} },
    game = { save = save, data = { pokemon = { SLAKOTH = { name = "SLAKOTH" }, SKITTY = { name = "SKITTY" } } },
      stack = { push = function(_, menu) t.menus[#t.menus + 1] = menu end } },
    save = {
      get = function(_, k, d) local v = t.store[k]; if v == nil then return d end; return v end,
      set = function(_, k, v) t.store[k] = v end,
    },
    events = { on = function(_, name, fn) t.listeners[name] = fn end },
  }
  mod.world = {
    overworld = function() return { maps = { ROUTE_29 = { objects = { t.sailor } } } } end,
    npc = function() return { face = function(_, dir) t.faced = dir end } end,
  }
  t.sailor = { name = "SNAG_INTRO_SAILOR", x = 40, y = 11 }
  local env = setmetatable({
    mod = mod, MAP = "ROUTE_29", SAILOR_NAME = "SNAG_INTRO_SAILOR",
    battlers = function(p, excluding)
      local n = 0
      for _, mon in ipairs(p or {}) do
        if mon ~= excluding and type(mon) == "table" and mon.isEgg ~= true then n = n + 1 end
      end
      return n
    end,
    Boxes = { releaseFromParty = function(s, index)
      if not t.releaseOk or not s.party[index] then return false end
      table.remove(s.party, index); return true
    end },
    errs = function() t.errs = t.errs + 1 end,
    monName = function(mon) return mon.nickname or mon.species end,
    objectNamed = function(world, mapId, name)
      for _, o in ipairs(world.maps[mapId].objects) do if o.name == name then return o end end
    end,
    I = { say = function(pages, done)
      for _, p in ipairs(pages) do t.said[#t.said + 1] = p end
      if done then done() end
    end },
    ListMenu = { new = function(_, title, items, o)
      return { title = title, items = items, o = o, close = function() end } end },
  }, { __index = _G })
  local chunk = assert(loadstring(body, "=loan")); setfenv(chunk, env)
  t.F, t.mod, t.env = chunk(), mod, env
  function t.choose(value)
    local menu = assert(table.remove(t.menus), "no menu open")
    for _, item in ipairs(menu.items) do
      if item.value == value then menu.o.onChoose(item, menu); return end
    end
    error("no item " .. value)
  end
  function t.cancel() assert(table.remove(t.menus), "no menu open").o.onCancel() end
  function t.take() local s = table.concat(t.said, " / "); t.said = {}; return s end
  function t.sales() return t.mod.exports.snag_quest.getFenceSales() end
  return t
end

local OFFER = "That's one of the\nADOPTION ones? / Special, those.\nNot from here. / I tried to get in.\nGot thrown out."
  .. " / They caught me\npricing the lot. / Got a home? Sure.\nHomes are free. / I pay cash. More\nfor the SLAKOTH."

do -- every page fits the box
  -- menu replies are wrapped by the menu itself, not by the text box
  for line in (body:gsub('reply = "[^"]*"', "")):gmatch('"([^"]-)"') do
    if line:find("\\n", 1, true) or #line > 12 then
      local segs = 0
      for seg in (line .. "\\n"):gmatch("(.-)\\n") do
        segs = segs + 1
        if #seg > 18 then check("width <= 18: " .. seg, #seg, 18) end
      end
      if segs > 2 then check("<= 2 lines: " .. line, segs, 2) end
    end
  end
end

do -- the whole sale, SLAKOTH
  local t = setup()
  check("offer opens", t.F.loanOffer(), true)
  check("offer pages", t.take(), OFFER)
  check("first menu rows", t.menus[1].items[1].action .. "|" .. t.menus[1].items[2].action, "HOW MUCH|NOT MINE")
  t.choose("price")
  check("quote", t.take(), "1200, the SLAKOTH.")
  check("NO DEAL is the first row", t.menus[1].items[1].value, "leave")
  check("nothing paid before SELL IT", t.save.player.money, 3000)
  check("nothing removed before SELL IT", #t.save.party, 3)
  t.choose("sell")
  check("sold lines", t.take(), "Pleasure.\nYou never saw me. / I never saw it.\nIt never saw us.")
  check("paid 1200", t.save.player.money, 4200)
  check("party is two", #t.save.party, 2)
  check("the others kept, in order", t.save.party[1].species .. "," .. t.save.party[2].species, "CYNDAQUIL,PIDGEY")
  local sales = t.sales()
  check("one sale recorded", #sales, 1)
  check("key", sales[1].key, "larry:SLAKOTH")
  check("species", sales[1].species, "SLAKOTH")
  check("day is a whole number", sales[1].day, math.floor(sales[1].day))
  check("mon is a copy, not the live table", sales[1].mon ~= t.larry, true)
  check("copy keeps its moves", table.concat(sales[1].mon.moves, ","), "SCRATCH,YAWN")
  check("copy keeps its DVs", sales[1].mon.dvs.atk, 7)
  check("copy keeps the lender mark", sales[1].mon.onLoanFrom, "larry")
  check("copy drops functions", sales[1].mon.junk, nil)
  sales[1].mon.level = 99; sales[1].key = "x"
  check("a reader cannot change the record", t.sales()[1].mon.level .. t.sales()[1].key, "12larry:SLAKOTH")
  check("no second offer once it is gone", t.F.loanOffer(), false)
  check("money unchanged afterwards", t.save.player.money, 4200)
  -- save round trip: the record is plain data and reloads identical
  local text = dump(t.store)
  local reloaded = assert(loadstring("return " .. text))()
  check("save round trip", dump(reloaded), text)
  check("reloaded record", reloaded.g2_fence_loans[1].mon.moves[2], "YAWN")
end

do -- SKITTY price; a second sale appends, never rewrites
  local t = setup({ species = "SKITTY", nickname = "MITTENS" })
  t.F.loanOffer(); t.take()
  check("menu title is the POKEMON's name", t.menus[1].title, "MITTENS")
  t.choose("price")
  check("quote 800", t.take(), "800 for that one.")
  t.choose("sell")
  check("paid 800", t.save.player.money, 3800)
  local zig = { species = "ZIGZAGOON", onLoanFrom = "larry" }
  t.save.party[#t.save.party + 1] = zig
  t.F.loanOffer(); t.choose("price"); t.choose("sell")
  check("second sale paid", t.save.player.money, 4600)
  check("two records", #t.sales(), 2)
  check("first record untouched", t.sales()[1].key, "larry:SKITTY")
  check("second record", t.sales()[2].key, "larry:ZIGZAGOON")
end

do -- every way of saying no changes nothing
  for _, way in ipairs({ "notmine", "nodeal", "cancel1", "cancel2" }) do
    local t = setup()
    t.F.loanOffer(); t.take()
    if way == "notmine" then t.choose("leave")
    elseif way == "cancel1" then t.cancel()
    else
      t.choose("price"); t.take()
      if way == "nodeal" then t.choose("leave") else t.cancel() end
    end
    local said = t.take()
    check(way .. ": line", said, (way == "notmine" or way == "nodeal") and "No deal? Fine.\nKeep walking." or "")
    check(way .. ": money", t.save.player.money, 3000)
    check(way .. ": party", #t.save.party, 3)
    check(way .. ": no record", #t.sales(), 0)
    check(way .. ": still lent", t.larry.onLoanFrom, "larry")
  end
end

do -- guards
  local t = setup({ party = nil })
  t.save.party = { t.larry }
  check("last POKEMON: no offer", t.F.loanOffer(), false)
  check("last POKEMON: sell refused", select(2, t.F.loanSell(t.larry, 1)), "last")
  local egg = setup(); egg.save.party = { egg.larry, { species = "TOGEPI", isEgg = true } }
  check("only an EGG besides it: no offer", egg.F.loanOffer(), false)
  local rui = setup(); rui.save.party = { { species = "CYNDAQUIL" }, { species = "MEOWTH", onLoanFrom = "rui" } }
  check("RUI's lent MEOWTH: no offer", rui.F.loanOffer(), false)
  check("RUI's lent MEOWTH: sell refused", select(2, rui.F.loanSell(rui.save.party[2], 2)), "changed")
  check("RUI's lent MEOWTH: untouched", #rui.save.party .. ":" .. rui.save.player.money, "2:3000")
  local none = setup(); none.save.party = { { species = "CYNDAQUIL" }, { species = "PIDGEY" } }
  check("nothing lent: no offer", none.F.loanOffer(), false)
  local moved = setup()
  moved.F.loanOffer(); moved.choose("price")
  table.remove(moved.save.party, 2) -- gone while the menu was open
  moved.choose("sell")
  check("gone mid-menu: nothing paid", moved.save.player.money, 3000)
  check("gone mid-menu: no record", #moved.sales(), 0)
  local fail = setup(); fail.releaseOk = false
  fail.F.loanOffer(); fail.choose("price"); fail.take(); fail.choose("sell")
  check("release fails: money taken back", fail.save.player.money, 3000)
  check("release fails: POKEMON kept", #fail.save.party, 3)
  check("release fails: no record", #fail.sales(), 0)
  check("release fails: reported", fail.errs, 1)
  check("release fails: line", fail.take(), "No deal? Fine.\nKeep walking.")
  local rich = setup({ money = 999500 })
  rich.F.loanOffer(); rich.choose("price"); rich.choose("sell")
  check("money caps at 999999", rich.save.player.money, 999999)
  check("capped sale still completes", #rich.save.party, 2)
end

do -- walking past: beside him, once a visit
  local t = setup()
  local step, enter = t.listeners["world.stepped"], t.listeners["map.entered"]
  step({ mapId = "ROUTE_29", x = 38, y = 11 })
  check("two cells away: nothing", #t.menus, 0)
  step({ mapId = "ROUTE_29", x = 41, y = 12 })
  check("diagonal: nothing", #t.menus, 0)
  step({ mapId = "CHERRYGROVE_CITY", x = 41, y = 11 })
  check("other map: nothing", #t.menus, 0)
  step({ mapId = "ROUTE_29", x = 41, y = 11 })
  check("beside him: the offer", #t.menus, 1)
  check("he turns to you", t.faced, "right")
  t.cancel(); t.take()
  step({ mapId = "ROUTE_29", x = 39, y = 11 })
  check("same visit: not again", #t.menus, 0)
  enter({ mapId = "ROUTE_29" })
  step({ mapId = "ROUTE_29", x = 40, y = 10 })
  check("next visit: offered again", #t.menus, 1)
  check("he turns up", t.faced, "up")
  local none = setup(); none.save.party = { { species = "CYNDAQUIL" } }
  none.listeners["world.stepped"]({ mapId = "ROUTE_29", x = 41, y = 11 })
  check("nothing lent: walking past is silent", #none.menus + #none.said, 0)
end

do -- every other fence still refuses LARRY's POKEMON
  local chunk = assert(loadstring(reserved, "=reserved"))
  local isReserved = chunk({ isRescue = function() return false end },
    { stage = function() return 0 end, RESOLVED = 9 },
    { jobId = function() return 0 end, stage = function() return 0 end, NONE = 0 })
  check("isReservedMon: larry", isReserved({ species = "SLAKOTH", onLoanFrom = "larry", snagged = true }), true)
  check("isReservedMon: rui", isReserved({ species = "MEOWTH", onLoanFrom = "rui" }), true)
  check("isReservedMon: an ordinary stolen POKEMON", isReserved({ species = "RATTATA", snagged = true }), false)
end

print(("%d passed, %d failed"):format(passes, fails))
print(fails == 0 and "ALL PASS" or "FAILED")
os.exit(fails == 0 and 0 or 1)
