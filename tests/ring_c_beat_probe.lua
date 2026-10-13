-- Room C ring-entry beat probe: extracts the REAL RING block from main.lua and
-- runs enter/leave against a mock world whose beginMovement completes
-- synchronously (or fails), checking the gap is never left OPEN, the busy
-- latch always releases, and a failed walk falls back to a warp.
-- usage, from the repo root: luajit tests/ring_c_beat_probe.lua [main.lua]
local f = assert(io.open(arg[1] or "main.lua", "rb")); local src = f:read("*a"); f:close()
local a = assert(src:find("    local RING = {", 1, true))
local b = assert(src:find("    function S.installMap(game)", a, true))
local body = src:sub(a, b - 1) .. "\nreturn RING\n"

local room = assert(dofile("ring_c_room.lua"))
local fails = 0
local function check(label, got, want)
  local ok = got == want
  if not ok then fails = fails + 1 end
  print(("%s %-46s got %s want %s"):format(ok and "PASS" or "FAIL", label, tostring(got), tostring(want)))
end

local function setup(px, py, opts)
  opts = opts or {}
  local log = { warps = {}, moves = {}, blocks = {} }
  local world = { player = { cellX = px, cellY = py },
    map = { width = 10, blocks = {} } }
  for i, v in ipairs(room.runtime.blocks) do world.map.blocks[i] = v end
  function world:beginMovement(id, bytes, onDone)
    log.moves[#log.moves + 1] = { id = id, n = #bytes }
    if opts.failObject == id then error("walk failed") end
    if onDone then onDone() end
  end
  local mod = {
    path = ".", options = { get = function() return nil end }, exports = {},
    read = function() local h = io.open("ring_c_room.lua", "rb"); local t = h:read("*a"); h:close(); return t end,
    world = {
      overworld = function() return world end,
      replaceBlock = function(_, bx, by, block)
        world.map.blocks[by * 10 + bx + 1] = block
        log.blocks[#log.blocks + 1] = block
        return true
      end,
      warpTo = function(_, m, x, y) log.warps[#log.warps + 1] = { m, x, y } end,
      queueScript = function(_, rows, o) if o and o.onDone then o.onDone() end end,
    },
    game = {},
  }
  function mod:read(rel) local h = io.open(rel, "rb"); local t = h:read("*a"); h:close(); return t end
  local env = setmetatable({
    mod = mod, errs = function(...) print("ERRS", string.format(...)) end,
    GameVersion = { engine = function() return "crystal" end },
    S = { MAP = "SNAG_CIANWOOD_SEWERS", spawned = { SNAG_RING_HAND = "SNAG_CIANWOOD_SEWERS_obj_7" } },
    MOVE_STANDING_DOWN = 6, MOVE_STANDING_UP = 7, MOVE_STANDING_LEFT = 8,
    ListMenu = {},
  }, { __index = _G })
  mod.options.define = function() end
  local chunk = assert(loadstring(body)); setfenv(chunk, env)
  local RING = chunk()
  return RING, world, log, mod
end

local function gap(world)
  local g = room.anchors.gap.block
  return world.map.blocks[g.y * 10 + g.x + 1]
end
local CLOSED, OPEN = room.runtime.gapClosedBlock, room.runtime.gapOpenBlock

for _, start in ipairs({ { 10, 14, 4 }, { 9, 14, 3 }, { 9, 13, 2 } }) do
  local RING, world, log = setup(start[1], start[2])
  local label = ("enter from (%d,%d)"):format(start[1], start[2])
  check(label .. ": accepted", RING.enter(), true)
  check(label .. ": gap opened first", log.blocks[1], OPEN)
  check(label .. ": gap closed after", gap(world), CLOSED)
  check(label .. ": busy released", RING.busy, false)
  check(label .. ": player steps (+end)", log.moves[1].n, start[3] + 1)
  check(label .. ": hand id = index+1", log.moves[2] and log.moves[2].id, 8)
  check(label .. ": no warp", #log.warps, 0)
end
do
  local RING, world, log = setup(5, 5)
  check("enter from elsewhere refused", RING.enter(), false)
  check("enter refused: gap untouched", #log.blocks, 0)
end
do
  local RING, world, log = setup(9, 14, { failObject = 0 })
  RING.enter()
  check("player walk fails: gap closed", gap(world), CLOSED)
  check("player walk fails: busy released", RING.busy, false)
  check("player walk fails: warped inside", log.warps[1] and log.warps[1][3], 11)
end
do
  local RING, world, log = setup(9, 14, { failObject = 8 })
  RING.enter()
  check("hand walk fails: gap closed", gap(world), CLOSED)
  check("hand walk fails: busy released", RING.busy, false)
end
for _, start in ipairs({ { 9, 11, 3 }, { 10, 11, 4 } }) do
  local RING, world, log = setup(start[1], start[2])
  local label = ("leave from (%d,%d)"):format(start[1], start[2])
  check(label .. ": accepted", RING.leave(), true)
  check(label .. ": gap closed after", gap(world), CLOSED)
  check(label .. ": busy released", RING.busy, false)
  check(label .. ": player steps (+end)", log.moves[1].n, start[3] + 1)
end
do
  local RING, world, log = setup(9, 11, { failObject = 0 })
  RING.leave()
  check("leave walk fails: gap closed", gap(world), CLOSED)
  check("leave walk fails: warped outside", log.warps[1] and log.warps[1][3], 14)
end
do
  local RING, world = setup(9, 11)
  world.map.blocks[6 * 10 + 4 + 1] = OPEN
  RING.busy = true
  RING.reapply(world)
  check("reapply on entry: gap re-closed", gap(world), CLOSED)
  check("reapply on entry: stale latch dropped", RING.busy, false)
end
do
  local RING = setup(9, 11)
  local vip = room.anchors.vip
  local onVip
  for _, o in ipairs(RING.staticObjects(room)) do
    if o.x == vip.x and o.y == vip.y then onVip = o.sprite end
  end
  check("static objects: Giovanni on the VIP sofa", onVip, "SPRITE_SNAG_GIOVANNI")
  local n = #RING.staticObjects(room)
  check("static objects: count sane (<=40)", n <= 40 and n >= 10, true)
  print("  static objects:", n)
end
do -- REQUESTS 116: the exported description
  local RING, _, _, mod = setup(9, 11)
  local ex = mod.exports.ringRoom and mod.exports.ringRoom()
  check("export: present", type(ex), "table")
  check("export: contract id", ex and ex.contract, "snag-ring-room")
  check("export: version", ex and ex.version, 1)
  check("export: no runtime", ex and ex.runtime, nil)
  check("export: cells", ex and #ex.cells, 360)
  ex.anchors.vip.x = 99
  ex.cells[1].base = "X"
  check("export: copy cannot write back (anchor)", RING.room().anchors.vip.x, room.anchors.vip.x)
  check("export: copy cannot write back (cell)", RING.room().cells[1].base, room.cells[1].base)
end
print(fails == 0 and "ALL PASS" or (fails .. " FAILED"))
os.exit(fails == 0 and 0 or 1)
