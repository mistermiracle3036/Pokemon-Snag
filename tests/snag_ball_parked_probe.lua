-- Snag parked-ball probe. Extracts the REAL advanceQueue wrap from main.lua
-- and runs its snag-replace arm against a stub BattleState holding the
-- engine's parked ball throw (a finished keepSprites ANIM_THROW_POKE_BALL,
-- engine src/ui/gen2/BattleState.lua stepAnim, v0.3.96).
-- REQUESTS 328 regression test: the parked ball is dropped before the
-- faint/EXP/move-learn screens; anything else in self.anim is left alone.
-- usage, from the repo root: luajit tests/snag_ball_parked_probe.lua [main.lua]
local mainPath = arg[1] or "main.lua"
local f = assert(io.open(mainPath, "rb")); local src = f:read("*a"); f:close()

local function section(first, last)
  local a = assert(src:find(first, 1, true), first)
  local b = assert(src:find(last, a + #first, true), last)
  return src:sub(a, b - 1)
end

local wrap = section("      BattleState.advanceQueue = function(self)",
  "      BattleState.throwBallAtTrainer = function(self, itemId)")
local fails = 0
local function check(label, got, want)
  if got ~= want then
    fails = fails + 1
    print(("FAIL %s: got %s, want %s"):format(label, tostring(got), tostring(want)))
  else
    print("ok   " .. label)
  end
end

local function anim(id, keep, done)
  return { animId = id, keepSprites = keep, done = function() return done end }
end

local function runArm(parked)
  local BattleState = {}
  local env = setmetatable({
    BattleState = BattleState,
    originals = { advanceQueue = function() return "orig" end },
  }, { __index = _G })
  local fn = assert(loadstring(wrap)); setfenv(fn, env); fn()
  local caught = { hp = 12 }
  local self = {
    anim = parked,
    queue = { { kind = "snag-replace" } },
    battle = {
      enemy = caught, enemyParty = { caught }, enemyIndex = 1,
      resolveFaints = function() end, takeEvents = function() return {} end,
    },
    pushAll = function() end,
  }
  setmetatable(self, { __index = BattleState })
  BattleState.advanceQueue(self)
  return self
end

local throw = anim("ANIM_THROW_POKE_BALL", true, true)
check("parked caught ball is dropped", runArm(throw).anim, nil)
local running = anim("ANIM_THROW_POKE_BALL", true, false)
check("a throw still running is kept", runArm(running).anim, running)
local other = anim("TACKLE", true, true)
check("another parked anim is kept", runArm(other).anim, other)
check("no anim stays nil", runArm(nil).anim, nil)
local s = runArm(anim("ANIM_THROW_POKE_BALL", true, true))
check("arm still replaces the enemy with a 0-HP ghost", s.battle.enemy.hp, 0)

if fails > 0 then print(fails .. " FAILED"); os.exit(1) end
print("ALL PASS")
