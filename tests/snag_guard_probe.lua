-- Snag guard refund probe. Extracts the two REAL wrap bodies from main.lua,
-- runs them against the engine's real src.inventory.Bag, with the vanilla
-- block path stubbed to do exactly what the engine's does to the bag.
-- REQUESTS 108 regression test: a guarded target refunds exactly one ball.
-- usage, from the repo root: luajit tests/snag_guard_probe.lua [main.lua] [engine dir]
local mainPath, engineDir = arg[1] or "main.lua", arg[2] or "../engine"
package.path = engineDir .. "/?.lua;" .. package.path
local Bag = require("src.inventory.Bag")
local f = assert(io.open(mainPath, "rb")); local src = f:read("*a"); f:close()

local function section(first, last)
  local a = assert(src:find(first, 1, true), first)
  local b = assert(src:find(last, a + #first, true), last)
  return src:sub(a, b - 1)
end
local function run(text, env)
  setmetatable(env, { __index = _G })
  local fn = assert(loadstring(text)); setfenv(fn, env); return fn()
end

local data = { items = {
  SNAG_BALL = { pocket = "BALL" }, HEIST_BALL = { pocket = "BALL" },
  KINGPIN_BALL = { pocket = "BALL" }, POKE_BALL = { pocket = "BALL" } } }
local fails = 0
local function check(label, got, want)
  local ok = got == want
  if not ok then fails = fails + 1 end
  print(("%s %-52s got %s want %s"):format(ok and "PASS" or "FAIL", label,
    tostring(got), tostring(want)))
end

---------------------------------------------------------------- Gold arm
do
  local body = section("      BattleState.throwBallAtTrainer = function(self, itemId)",
    "\n    end\n\n    mod.events:on(\"pokemon.caught\"")
  local calls
  local function newEnv()
    calls = { block = 0, useItem = 0 }
    local BattleState = {}
    local env = {
      BattleState = BattleState, Bag = Bag, mod = { game = { data = data } },
      SNAG_BALL_TIERS = { SNAG_BALL = {}, HEIST_BALL = {}, KINGPIN_BALL = {} },
      originals = {
        -- engine src/ui/gen2/BattleState.lua throwBallAtTrainer -> consumeItem
        throwBallAtTrainer = function(self, itemId)
          calls.block = calls.block + 1
          local save = self.save
          save.inventory[itemId] = math.max(0, (save.inventory[itemId] or 1) - 1)
          if save.inventory[itemId] == 0 then save.inventory[itemId] = nil end
        end,
        useItem = function() calls.useItem = calls.useItem + 1 end,
      },
    }
    run(body, env)
    return BattleState
  end
  for _, ball in ipairs({ "SNAG_BALL", "HEIST_BALL", "KINGPIN_BALL" }) do
    for _, start in ipairs({ 1, 5 }) do
      local BS = newEnv()
      local self = { save = { inventory = { [ball] = start } },
        battle = { trainer = {}, enemy = { species = "GARCHOMP", snagGuard = "ipc" } },
        queue = {} }
      BS.throwBallAtTrainer(self, ball)
      check(("gold guarded %s x%d: count after"):format(ball, start),
        self.save.inventory[ball], start)
      check(("gold guarded %s x%d: block path ran"):format(ball, start), calls.block, 1)
      check(("gold guarded %s x%d: no catch attempt"):format(ball, start), calls.useItem, 0)
      check(("gold guarded %s x%d: wild untouched"):format(ball, start),
        self.battle.wild, nil)
    end
  end
  -- unguarded target: snag path, no refund, block not taken
  local BS = newEnv()
  local self = { save = { inventory = { SNAG_BALL = 3 } },
    battle = { trainer = {}, enemy = { species = "RATTATA" } }, queue = {} }
  BS.throwBallAtTrainer(self, "SNAG_BALL")
  check("gold unguarded: catch attempted", calls.useItem, 1)
  check("gold unguarded: no block", calls.block, 0)
  check("gold unguarded: count untouched by wrap", self.save.inventory.SNAG_BALL, 3)
  -- ordinary ball at a guarded mon: vanilla block, ball spent, no refund
  BS = newEnv()
  self = { save = { inventory = { POKE_BALL = 2 } },
    battle = { trainer = {}, enemy = { snagGuard = "ipc" } }, queue = {} }
  BS.throwBallAtTrainer(self, "POKE_BALL")
  check("gold POKE_BALL at guarded: spent, not refunded", self.save.inventory.POKE_BALL, 1)
end

---------------------------------------------------------------- Gen 1 arm
do
  local body = section("    local vanillaThrowBall = originals.throwBall",
    "      -- verbatim copy of BattleState:throwBall's wild-catch body")
  body = body .. "  return 'SNAG_BODY_REACHED'\n    end\n"
  local vanilla
  local function newEnv()
    vanilla = 0
    local BattleState = {}
    run(body, { BattleState = BattleState,
      originals = { throwBall = function() vanilla = vanilla + 1 end } })
    return BattleState
  end
  for _, start in ipairs({ 1, 5 }) do
    local BS = newEnv()
    local save = { inventory = { SNAG_BALL = start } }
    Bag.remove(save, "SNAG_BALL", 1) -- BagMenu consume() before throwBall
    local self = { kind = "trainer", game = { save = save }, data = data,
      enemy = { mon = { species = "MEWTWO", snagGuard = "ipc" } } }
    local r = BS.throwBall(self, "SNAG_BALL")
    check(("gen1 guarded x%d: count after"):format(start), save.inventory.SNAG_BALL, start)
    check(("gen1 guarded x%d: vanilla block ran"):format(start), vanilla, 1)
    check(("gen1 guarded x%d: snag body skipped"):format(start), r, nil)
  end
  local BS = newEnv()
  local self = { kind = "trainer", game = { save = { inventory = {} } }, data = data,
    enemy = { mon = { species = "RATTATA" } } }
  check("gen1 unguarded: snag body reached", BS.throwBall(self, "SNAG_BALL"), "SNAG_BODY_REACHED")
  check("gen1 unguarded: vanilla not called", vanilla, 0)
end

print(fails == 0 and "ALL PASS" or (fails .. " FAILED"))
os.exit(fails == 0 and 0 or 1)
