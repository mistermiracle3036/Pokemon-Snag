-- Runs transforms.lua the way engine src/mods/AssetTransform.lua does (same
-- sandbox globals, a ctx with exists/readImage/writeImage/blank) against raw
-- grey dumps of the player's cache sheets, and writes the result as raw grey.
-- usage: luajit tests/ring_c_recipe.lua <transforms.lua> <raw dir> <out file>
-- raw dir holds <sheet>.raw: first line "w h", then w*h grey bytes 0-255 as text.
local recipePath, rawDir, outPath = arg[1], arg[2], arg[3]

local function image(w, h, px)
  local img = { w = w, h = h, px = px }
  function img:getWidth() return self.w end
  function img:getHeight() return self.h end
  function img:getDimensions() return self.w, self.h end
  function img:getPixel(x, y)
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h, "getPixel out of range")
    local v = self.px[y * self.w + x + 1]
    return v, v, v, 1
  end
  function img:setPixel(x, y, r, g, b, a)
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h, "setPixel out of range")
    assert(r == g and g == b, "non-grey pixel written")
    self.px[y * self.w + x + 1] = r
  end
  return img
end

local function readRaw(name)
  local f = io.open(rawDir .. "/" .. name:gsub("%.png$", ".raw"), "r")
  if not f then return nil end
  local w, h = f:read("*n", "*n")
  local px = {}
  for i = 1, w * h do px[i] = f:read("*n") / 255 end
  f:close()
  return image(w, h, px)
end

local written
local ctx = {
  exists = function(rel) return readRaw(rel:match("[^/]+$")) ~= nil end,
  readImage = function(rel) return assert(readRaw(rel:match("[^/]+$"))) end,
  writeImage = function(img, rel) written = { img = img, rel = rel } end,
  blank = function(w, h, r)
    local px = {}
    for i = 1, w * h do px[i] = r or 0 end
    return image(w, h, px)
  end,
}

-- AssetTransform.sandboxEnv
local env = {
  math = math, string = string, table = table,
  ipairs = ipairs, pairs = pairs, next = next, select = select,
  type = type, tostring = tostring, tonumber = tonumber,
  assert = assert, error = error, pcall = pcall, unpack = unpack,
}
local f = assert(io.open(recipePath, "rb")); local src = f:read("*a"); f:close()
local chunk = assert(loadstring(src, "@transforms.lua"))
setfenv(chunk, env)
local fn = chunk()
assert(type(fn) == "function", "recipe must return function(ctx)")
fn(ctx)
assert(written, "recipe wrote nothing")
assert(written.rel == "tilesets/snag_ring_c.png", written.rel)
local out = assert(io.open(outPath, "w"))
out:write(written.img.w, " ", written.img.h, "\n")
for i = 1, written.img.w * written.img.h do
  out:write(math.floor(written.img.px[i] * 255 + 0.5), "\n")
end
out:close()
print("recipe ran: " .. written.rel)
