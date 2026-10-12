"""Build boxing room C (A-0082 stage 2) from layered native pieces.

usage: python build_ring_c.py <dumped-data-dir> <repo-root>

<dumped-data-dir> holds tilesets.json / maps.json / palettes.json made from the
Crystal cache with the room package's tools/dump.lua. Writes, under <repo-root>:
  transforms.lua      the assets_transforms recipe: copies each composite tile out
                      of the player's OWN cache sheets (no ROM pixels ship) and
                      draws the new rope/edge art from the masks below
  ring_c_room.lua     the shared room description + the runtime tileset/map data
  docs/ring_c/*.png   offline previews (engine rules, NOT engine renders)

Layout = the package's tools/boards.py native_shell + native_stands +
native_ring + option_c, layered cell by cell (never layout_C.json alone: it keeps
only the last piece per cell). Coordinates are zero-based 16 px cells.
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ringlib as R
from PIL import Image, ImageDraw

DATA, REPO = sys.argv[1], sys.argv[2]
OUT_DOCS = os.path.join(REPO, "docs", "ring_c")
W, H = 20, 18
RING = (6, 6, 8, 8)
DOOR = (9, 10)
GIO = (9, 3)
GAP = (9, 12)
COLL_FLOOR, COLL_WALL = 0x00, 0x07

src = R.Src(DATA)
P = R.native_pieces(src)

# ---------------------------------------------------------------- new art
# 16x16 shade masks (None = keep the piece underneath). Original art for this
# mod, drawn in the platform's own palette (slot 1, the canvas/band palette):
# shade 3 outline, braid alternating shades 1/2 every 2 px, after the package's
# H-ROPE previews (boards.py rope_pieces).
def blank():
    return [[None] * 16 for _ in range(16)]

def rope_h():
    m = blank()
    for a, mid, b in ((7, 8, 9), (12, 13, 14)):
        for t in range(16):
            m[a][t] = 3; m[b][t] = 3
            m[mid][t] = 1 if (t // 2) % 2 == 0 else 2
    return m

def rope_v():
    m = blank()
    for a, mid, b in ((3, 4, 5), (8, 9, 10)):
        for t in range(16):
            m[t][a] = 3; m[t][b] = 3
            m[t][mid] = 1 if (t // 2) % 2 == 0 else 2
    return m

def join(side):
    """Rope stub from the post's edge to the cell edge (art gap 3): the post fills
    the west half of N-POST-W and the east half of N-POST-E (measured, cols 0-7 /
    8-15), so the stub runs over the other half."""
    full, m = rope_h(), blank()
    cols = range(8, 16) if side == "W" else range(0, 8)
    for y in range(16):
        for x in cols:
            m[y][x] = full[y][x]
    return m

def edge(side):
    """Ring-facing stand edge (art gap 5): a 4 px strip of the E4 slab face turned
    90 degrees, as the package's H-EDGE-E preview; west stand faces east."""
    face = R.cell_shades(src, P["N-SLAB-FACE"][0])
    rot = [[face[15 - x][y] for x in range(16)] for y in range(16)]   # clockwise
    m = blank()
    for y in range(16):
        for x in range(12, 16):
            m[y][x] = rot[y][x]
    if side == "W":
        m = [row[::-1] for row in m]
    return m

NEW = {"H-ROPE-H": rope_h(), "H-ROPE-V": rope_v(), "H-JOIN-W": join("W"),
       "H-JOIN-E": join("E"), "H-EDGE-E": edge("E"), "H-EDGE-W": edge("W")}

# ---------------------------------------------------------------- layering
class Cell:
    def __init__(self):
        self.base = None; self.over = []; self.surface = "flat"; self.solid = False
        self.priority = False   # BG priority on the cell's BOTTOM tiles (near rope)

cells = {(x, y): Cell() for x in range(W) for y in range(H)}

def put(x, y, pid, surface="flat", solid=False):
    c = cells[(x, y)]
    c.base, c.over, c.surface, c.solid, c.priority = pid, [], surface, solid, False

def overlay(x, y, pid, surface, solid=False, priority=False):
    c = cells[(x, y)]
    c.over.append(pid); c.surface = surface; c.solid = solid; c.priority = priority

def fill(x0, y0, x1, y1, pid, **kw):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, pid, **kw)

# native_shell
fill(0, 0, W - 1, 0, "N-UWALL-T", surface="up", solid=True)
fill(0, 1, W - 1, 1, "N-UWALL-B", surface="up", solid=True)
fill(0, 2, 0, H - 1, "N-UDARK", surface="up", solid=True)
fill(W - 1, 2, W - 1, H - 1, "N-UDARK", surface="up", solid=True)
fill(1, H - 1, W - 2, H - 1, "N-UDARK", surface="up", solid=True)
fill(1, 2, W - 2, H - 2, "N-UFLOOR")
put(DOOR[0], H - 1, "N-MAT"); put(DOOR[1], H - 1, "N-MAT")

# native_stands (boards.py stands(): the package's seat-list KEYS are swapped
# against their positions -- "E" holds x 2-4, the WEST stand -- so positions,
# not names, are what is copied here)
seats_north = [(x, y) for y in (2, 3) for x in range(1, 19) if not (x in (GIO[0], GIO[0] + 1) and y == 3)]
seats_west = [(x, y) for x in (2, 3, 4) for y in list(range(5, 9)) + list(range(10, 14))]
seats_east = [(x, y) for x in (15, 16, 17) for y in list(range(5, 9)) + list(range(10, 14))]
seats_south = [(x, y) for y in (15, 16) for x in list(range(1, 8)) + list(range(12, 19))]
reserved = {(x, y) for x in range(GIO[0] - 1, GIO[0] + 3) for y in (2, 3)}
fill(1, 2, 18, 3, "N-STANDFLOOR")
for (x, y) in seats_north:
    put(x, y, "N-SEAT", surface="up")
put(GIO[0], GIO[1], "N-SOFA-L", surface="up"); put(GIO[0] + 1, GIO[1], "N-SOFA-R", surface="up")
for x in range(1, 19):
    if x not in (5, 14):
        put(x, 4, "N-SLAB-FACE", surface="up", solid=True)
for (x, y) in seats_west + seats_east + seats_south:
    put(x, y, "N-STOOL", surface="up")       # stool cell carries its own floor

# native_ring
rx, ry, rw, rh = RING
for y in range(ry + 1, ry + rh - 1):
    for x in range(rx + 1, rx + rw - 1):
        put(x, y, "N-CANVAS")
for x in range(rx + 1, rx + rw - 1):
    put(x, ry, "N-BAND-N", solid=True)
    put(x, ry + rh - 1, "N-BAND-S", surface="up", solid=True)
for y in range(ry + 1, ry + rh - 1):
    put(rx, y, "N-BAND-W", solid=True)
    put(rx + rw - 1, y, "N-BAND-E", solid=True)
put(rx, ry, "N-CORNER-NW", solid=True); put(rx + rw - 1, ry, "N-CORNER-NE", solid=True)
put(rx, ry + rh - 1, "N-CORNER-SW", surface="up", solid=True)
put(rx + rw - 1, ry + rh - 1, "N-CORNER-SE", surface="up", solid=True)
put(DOOR[0], ry + rh - 1, "N-STAIR-L", surface="up"); put(DOOR[1], ry + rh - 1, "N-STAIR-R", surface="up")
for (x, y, pid) in ((rx + 1, ry + 1, "N-POST-W"), (rx + rw - 2, ry + 1, "N-POST-E"),
                    (rx + 1, ry + rh - 2, "N-POST-W"), (rx + rw - 2, ry + rh - 2, "N-POST-E")):
    put(x, y, pid, surface="up", solid=True)

# option_c (closed)
for y in list(range(5, 9)) + list(range(10, 14)):
    overlay(4, y, "H-EDGE-E", "up"); overlay(15, y, "H-EDGE-W", "up")
for x in range(rx + 2, rx + rw - 2):
    overlay(x, ry + 1, "H-ROPE-H", "mount")                       # far rope: no priority
    overlay(x, ry + rh - 2, "H-ROPE-H", "mount", solid=x in DOOR, priority=True)
for y in range(ry + 2, ry + rh - 2):
    overlay(rx + 1, y, "H-ROPE-V", "mount"); overlay(rx + rw - 2, y, "H-ROPE-V", "mount")
for y in (ry + 1, ry + rh - 2):
    overlay(rx + 1, y, "H-JOIN-W", "up", solid=True); overlay(rx + rw - 2, y, "H-JOIN-E", "up", solid=True)

# ---------------------------------------------------------------- tiles
def cell_tiles(c, open_gap=False):
    tiles = [dict(t) for t in P[c.base][0]]
    overs = [] if open_gap else c.over
    for pid in overs:
        m = NEW[pid]
        for i, t in enumerate(tiles):
            ox, oy = (i % 2) * 8, (i // 2) * 8
            sub = [[m[oy + y][ox + x] for x in range(8)] for y in range(8)]
            if any(v is not None for row in sub for v in row):
                prev = t["ov"]
                if prev:
                    sub = [[sub[y][x] if sub[y][x] is not None else prev[y][x] for x in range(8)] for y in range(8)]
                t["ov"] = sub
    if c.priority and not open_gap:
        for t in tiles[2:]:               # bottom tiles only: see header note in ring_c_room.lua
            t["prio"] = True
    return tiles

def tkey(t):
    ov = None if not t["ov"] else tuple(tuple(-1 if v is None else v for v in row) for row in t["ov"])
    return (t["image"], t["sid"], t["fx"], t["fy"], t["pal"], ov, bool(t.get("prio")))

slots, slot_of = [], {}
def slot(t):
    k = tkey(t)
    if k not in slot_of:
        n = len(slots)
        # 0x00-0x5F then 0x80-0xDF: the two 96-tile banks Crystal tilesets use
        slot_of[k] = n if n < 0x60 else 0x80 + (n - 0x60)
        slots.append((slot_of[k], t))
    return slot_of[k]

def coll(c, open_gap=False):
    return COLL_FLOOR if (open_gap or not c.solid) else COLL_WALL

# blocks: 2x2 cells. Index 0 is the VOID (map border, BorderFill.blockFor), never
# used inside the grid; real blocks start at 1.
blocks, collision, block_of = [], [], {}
void = cells[(0, H - 1)]                      # dark fill
def add_block(quads):
    tile_ids = [0] * 16
    for qi, (tiles, _) in enumerate(quads):
        qx, qy = (qi % 2) * 2, (qi // 2) * 2
        for i, t in enumerate(tiles):
            tile_ids[(qy + i // 2) * 4 + qx + i % 2] = slot(t)
    key = (tuple(tile_ids), tuple(cv for _, cv in quads))
    if key not in block_of:
        block_of[key] = len(blocks)
        blocks.append(tile_ids); collision.append([cv for _, cv in quads])
    return block_of[key]

vt = cell_tiles(void)
add_block([(vt, COLL_WALL)] * 4)            # block 0 = void
grid = []
for by in range(H // 2):
    for bx in range(W // 2):
        quads = []
        for (dx, dy) in ((0, 0), (1, 0), (0, 1), (1, 1)):
            c = cells[(bx * 2 + dx, by * 2 + dy)]
            quads.append((cell_tiles(c), coll(c)))
        b = add_block(quads)
        if b == 0:                           # a wall block identical to the void: give it its own id
            blocks.append(list(blocks[0])); collision.append(list(collision[0]))
            b = len(blocks) - 1
            block_of[(tuple(blocks[0]), tuple(collision[0]), "grid")] = b
        grid.append(b)
gbx, gby = GAP[0] // 2, GAP[1] // 2
closed_block = grid[gby * (W // 2) + gbx]
quads = []
for (dx, dy) in ((0, 0), (1, 0), (0, 1), (1, 1)):
    xy = (gbx * 2 + dx, gby * 2 + dy)
    og = xy == GAP
    quads.append((cell_tiles(cells[xy], open_gap=og), coll(cells[xy], open_gap=og)))
open_block = add_block(quads)
assert 0 not in grid, "block 0 is the void"
assert len(slots) <= 192, len(slots)

# ---------------------------------------------------------------- outputs
def lua(v, ind=""):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, list):
        if all(isinstance(x, (int, float)) for x in v):
            return "{ " + ", ".join(lua(x) for x in v) + " }"
        return "{\n" + "".join(ind + "  " + lua(x, ind + "  ") + ",\n" for x in v) + ind + "}"
    if isinstance(v, dict):
        items = []
        for k in v:
            kk = k if isinstance(k, str) and k.isidentifier() else "[" + lua(k) + "]"
            items.append(ind + "  " + kk + " = " + lua(v[k], ind + "  ") + ",\n")
        return "{\n" + "".join(items) + ind + "}"
    raise TypeError(type(v))

tile_pals = {}
tile_attrs = {}
for sid, t in slots:
    tile_pals[sid + 1] = t["pal"]
    if t.get("prio"):
        tile_attrs[sid + 1] = {"palette": t["pal"], "vramBank": 1 if sid >= 0x80 else 0,
                               "priority": True, "xFlip": False, "yFlip": False}
pal_list = [tile_pals.get(i, 1) for i in range(1, 0xE0 + 1)]

def cell_record(x, y):
    c = cells[(x, y)]
    r = {"x": x, "y": y, "base": c.base, "surface": c.surface, "solid": c.solid}
    if c.over:
        r["over"] = list(c.over)
    if c.priority:
        r["bgPriority"] = True
    return r

room = {
    "contract": "snag-ring-room",
    "version": 1,
    "id": "SNAG_RING_C",
    "cellSize": 16, "cellsW": W, "cellsH": H, "blocksW": W // 2, "blocksH": H // 2,
    "anchors": {
        "ringOuter": {"x": 6, "y": 6, "w": 8, "h": 8},
        "canvas": {"x": 7, "y": 7, "w": 6, "h": 6},
        "door": [{"x": 9, "y": 17}, {"x": 10, "y": 17}],
        "arrival": {"x": 9, "y": 16, "facing": "up"},
        "stair": [{"x": 9, "y": 13}, {"x": 10, "y": 13}],
        "gap": {"x": GAP[0], "y": GAP[1], "block": {"x": gbx, "y": gby}},
        "ringHand": {"x": 10, "y": 13, "facing": "left"},
        "ringHandBack": {"x": 10, "y": 14},
        "entryPath": [{"x": 9, "y": 14}, {"x": 9, "y": 13}, {"x": 9, "y": 12}, {"x": 9, "y": 11}],
        "vip": {"x": GIO[0], "y": GIO[1], "facing": "down"},
        "fighterWest": {"x": 8, "y": 9, "facing": "right"},
        "fighterEast": {"x": 11, "y": 9, "facing": "left"},
        "nearRope": {"x": 8, "y": 12},
    },
    "crowdSlots": {
        "north": [{"x": x, "y": y, "facing": "down"} for (x, y) in seats_north if (x, y) not in reserved],
        "west": [{"x": x, "y": y, "facing": "right"} for (x, y) in seats_west],
        "east": [{"x": x, "y": y, "facing": "left"} for (x, y) in seats_east],
        "south": [{"x": x, "y": y, "facing": "up"} for (x, y) in seats_south],
    },
    "smoke": {
        "koffing": [{"x": 3, "y": 7}, {"x": 15, "y": 2}, {"x": 16, "y": 11}, {"x": 5, "y": 15}],
        "weezing": [{"x": 2, "y": 12}, {"x": 17, "y": 6}, {"x": 13, "y": 16}],
    },
    "cells": [cell_record(x, y) for y in range(H) for x in range(W)],
    "runtime": {
        "tileset": {
            "id": "SNAG_RING_C_TILES",
            "image": "save/mod-derived/snag_quest/tilesets/snag_ring_c.png",
            "imageWidth": 128, "imageHeight": 128, "tilesPerRow": 16,
            "blocks": blocks, "collision": collision,
            "tilePalettes": pal_list, "tileAttrs": tile_attrs,
        },
        "blocks": grid, "borderBlock": 0,
        "gapClosedBlock": closed_block, "gapOpenBlock": open_block,
    },
}

header = """-- GENERATED by docs/ring_c/build_ring_c.py -- do not edit by hand.
-- Boxing room C (A-0082 stage 2): the shared room description (contract
-- `snag-ring-room`, exchange/CONTRACTS.md) plus the runtime tileset and map.
-- Snag WRITES these records; a renderer READS them and never rebuilds a second
-- gameplay map. Coordinates are zero-based 16 px cells.
-- BG priority sits only on the near (south) rope's lower tiles: engine v0.3.51
-- draws priority tiles opaque (World:drawBgPriorityOver passes keyed=false), so
-- a priority tile hides the whole 8x8 of sprite under it, colour 0 included.
-- The far rope stays under sprites so it never covers a fighter's head.
"""
with open(os.path.join(REPO, "ring_c_room.lua"), "w", encoding="utf-8", newline="\n") as f:
    f.write(header + "return " + lua(room) + "\n")

# the recipe: one op per composite tile
images = sorted({t["image"] for _, t in slots})
img_ix = {n: i + 1 for i, n in enumerate(images)}
ovs, ov_ix = [], {}
ops = []
for sid, t in slots:
    o = 0
    if t["ov"]:
        s = "".join("." if v is None else str(v) for row in t["ov"] for v in row)
        if s not in ov_ix:
            ovs.append(s); ov_ix[s] = len(ovs)
        o = ov_ix[s]
    ops.append([sid, img_ix[t["image"]], t["sid"], 1 if t["fx"] else 0, 1 if t["fy"] else 0, o])

recipe = """-- GENERATED by docs/ring_c/build_ring_c.py -- do not edit by hand.
-- assets_transforms (engine src/mods/AssetTransform.lua): builds boxing room C's
-- composite tileset from the player's OWN imported Crystal sheets. The zip
-- ships this recipe, never the pixels. Each op copies one 8x8 tile (flips baked
-- in, so the composite needs no flip attributes) and may draw over it with an
-- overlay mask: '.' keeps the copied pixel, 0-3 is a shade (0 lightest). The
-- overlays are this mod's own art (ropes, rope stubs, stand edges).
-- Crystal sheets are 128x128; anything else (Gold/Silver's cache) is skipped,
-- so the room is only ever built from the art it was measured against.
local SOURCES = %s
local OVERLAYS = %s
-- { slot, source, sheet tile, xFlip, yFlip, overlay }
local OPS = %s

local GREY = { 1, 2 / 3, 1 / 3, 0 }

return function(ctx)
  local src = {}
  for i, name in ipairs(SOURCES) do
    local rel = "tilesets/" .. name
    if not ctx.exists(rel) then return end
    local img = ctx.readImage(rel)
    if img:getWidth() ~= 128 or img:getHeight() ~= 128 then return end
    src[i] = img
  end
  local out = ctx.blank(128, 128, 1, 1, 1, 1)
  for _, op in ipairs(OPS) do
    local slot, s, sid, fx, fy, ov = op[1], src[op[2]], op[3], op[4], op[5], op[6]
    local sx, sy = (sid %% 16) * 8, math.floor(sid / 16) * 8
    local dx, dy = (slot %% 16) * 8, math.floor(slot / 16) * 8
    local mask = ov > 0 and OVERLAYS[ov] or nil
    for y = 0, 7 do
      for x = 0, 7 do
        local px = fx == 1 and 7 - x or x
        local py = fy == 1 and 7 - y or y
        local r, g, b, a = s:getPixel(sx + px, sy + py)
        if mask then
          local c = mask:sub(y * 8 + x + 1, y * 8 + x + 1)
          if c ~= "." then
            local v = GREY[tonumber(c) + 1]
            r, g, b, a = v, v, v, 1
          end
        end
        out:setPixel(dx + x, dy + y, r, g, b, a)
      end
    end
  end
  ctx.writeImage(out, "tilesets/snag_ring_c.png")
end
""" % (lua(images), lua(ovs), "{\n" + "".join("  " + lua(o) + ",\n" for o in ops) + "}")
with open(os.path.join(REPO, "transforms.lua"), "w", encoding="utf-8", newline="\n") as f:
    f.write(recipe)

# ---------------------------------------------------------------- previews
def bg_set(env):
    p = src.palettes
    row = p["environments"][env]
    return [[tuple(c) for c in p["bg"][i - 1]] for i in row["DAY"]]

def composite_sheet():
    """What the recipe will write, rebuilt here from the same ops."""
    out = Image.new("L", (128, 128), 255)
    for sid, t in slots:
        g = src.shades(t)
        for y in range(8):
            for x in range(8):
                out.putpixel(((sid % 16) * 8 + x, (sid // 16) * 8 + y), (3 - g[y][x]) * 85)
    return out

def render(env, grid_blocks, overlay_coll=False):
    sheet = composite_sheet()
    pal = bg_set(env)
    im = Image.new("RGB", (W * 16, H * 16))
    for by in range(H // 2):
        for bx in range(W // 2):
            b = grid_blocks[by * (W // 2) + bx]
            for ti, sid in enumerate(blocks[b]):
                colors = pal[tile_pals.get(sid + 1, 1) - 1]
                for y in range(8):
                    for x in range(8):
                        g = sheet.getpixel(((sid % 16) * 8 + x, (sid // 16) * 8 + y))
                        im.putpixel((bx * 32 + (ti % 4) * 8 + x, by * 32 + (ti // 4) * 8 + y),
                                    colors[3 - round(g / 85)])
    if overlay_coll:
        d = ImageDraw.Draw(im, "RGBA")
        for by in range(H // 2):
            for bx in range(W // 2):
                b = grid_blocks[by * (W // 2) + bx]
                for q, cv in enumerate(collision[b]):
                    x0, y0 = bx * 32 + (q % 2) * 16, by * 32 + (q // 2) * 16
                    if cv != COLL_FLOOR:
                        d.rectangle([x0, y0, x0 + 15, y0 + 15], fill=(230, 40, 40, 110))
                for ti, sid in enumerate(blocks[b]):
                    if tile_attrs.get(sid + 1):
                        x0, y0 = bx * 32 + (ti % 4) * 8, by * 32 + (ti // 4) * 8
                        d.rectangle([x0, y0, x0 + 7, y0 + 7], outline=(170, 60, 255, 255))
    return im

grid_open = list(grid); grid_open[gby * (W // 2) + gbx] = open_block
os.makedirs(OUT_DOCS, exist_ok=True)
for env in ("INDOOR", "DUNGEON"):
    render(env, grid).resize((W * 32, H * 32), Image.NEAREST).save(os.path.join(OUT_DOCS, f"room_c_{env.lower()}_x2.png"))
render("INDOOR", grid, True).resize((W * 32, H * 32), Image.NEAREST).save(os.path.join(OUT_DOCS, "room_c_collision_x2.png"))
render("INDOOR", grid_open, True).resize((W * 32, H * 32), Image.NEAREST).save(os.path.join(OUT_DOCS, "room_c_open_collision_x2.png"))
print(f"tiles {len(slots)}  blocks {len(blocks)}  overlays {len(ovs)}  priority tiles {len(tile_attrs)}"
      f"  closed block {closed_block}  open block {open_block}  sources {images}")
