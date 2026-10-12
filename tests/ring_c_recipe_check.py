"""Pre-phone check for boxing room C's install recipe and room data.

usage: python tests/ring_c_recipe_check.py <dumped-data-dir>
  1. dumps the six Crystal cache sheets as raw grey, runs transforms.lua through
     tests/ring_c_recipe.lua (engine sandbox globals, mock ctx), and compares the
     result pixel for pixel with what the generator says the sheet must be;
  2. checks the room data: no block 0 inside the grid, the gap's CLOSED/OPEN
     blocks differ only in the gap quadrant, and walkability of every cell the
     entry/exit paths and actors use.
"""
import os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(REPO, "docs", "ring_c"))
import ringlib as R
from PIL import Image

data = sys.argv[1]
src = R.Src(data)
tmp = tempfile.mkdtemp(prefix="ringc_")
for name in ("champions_room", "elite_four_room", "facility", "game_corner", "train_station", "underground"):
    im = Image.open(os.path.join(R.CACHE, "assets", "generated", "tilesets", name + ".png")).convert("L")
    with open(os.path.join(tmp, name + ".raw"), "w") as f:
        f.write(f"{im.width} {im.height}\n" + "\n".join(str(v) for v in im.getdata()) + "\n")
out = os.path.join(tmp, "out.raw")
subprocess.run(["luajit", os.path.join(HERE, "ring_c_recipe.lua"), os.path.join(REPO, "transforms.lua"), tmp, out], check=True)

# expected sheet: rebuild from the room's own runtime data + generator rules
lua = subprocess.run(["luajit", "-e", (
    "local t=dofile([[%s]]) local ts=t.runtime.tileset "
    "io.write(#ts.blocks)") % os.path.join(REPO, "ring_c_room.lua").replace("\\", "/")],
    capture_output=True, text=True, check=True).stdout
fails = []
with open(out) as f:
    w, h = map(int, f.readline().split())
    got = [int(f.readline()) for _ in range(w * h)]
if (w, h) != (128, 128):
    fails.append(f"sheet size {w}x{h}")
# the generator's own composite (same function the previews use)
import importlib.util
spec = importlib.util.spec_from_file_location("b", os.path.join(REPO, "docs", "ring_c", "build_ring_c.py"))
sys.argv = ["build_ring_c.py", data, tmp]          # previews/outputs into tmp, not the repo
b = importlib.util.module_from_spec(spec); spec.loader.exec_module(b)
exp = b.composite_sheet()
diff = sum(1 for i, v in enumerate(exp.getdata()) if abs(v - got[i]) > 1)
used = {sid for sid, _ in b.slots}
if diff:
    fails.append(f"{diff} pixels differ between recipe output and generator composite")

# room data checks
grid, blocks, coll = b.grid, b.blocks, b.collision
if 0 in grid:
    fails.append("block 0 (void) used inside the grid")
cb, ob = blocks[b.closed_block], blocks[b.open_block]
gap_tiles = {1 * 4 + 2, 1 * 4 + 3, 0 * 4 + 2, 0 * 4 + 3}   # TR quadrant of the block: tiles (2,0),(3,0),(2,1),(3,1)
changed = {i for i in range(16) if cb[i] != ob[i]}
if not changed or not changed <= {2, 3, 6, 7}:
    fails.append(f"open/closed gap blocks differ outside the gap quadrant: {sorted(changed)}")
if coll[b.closed_block][:1] + coll[b.closed_block][2:] != coll[b.open_block][:1] + coll[b.open_block][2:]:
    fails.append("open/closed collision differs outside the gap quadrant")

def walk(x, y, open_gap=False):
    bx, by = x // 2, y // 2
    blk = grid[by * 10 + bx]
    if open_gap and (bx, by) == (4, 6):
        blk = b.open_block
    return coll[blk][(x % 2) + 2 * (y % 2)] == 0
checks = [
    ("arrival", (9, 16), True, False), ("door mat L", (9, 17), True, False), ("door mat R", (10, 17), True, False),
    ("aisle", (9, 15), True, False), ("aisle top", (9, 14), True, False), ("stair L", (9, 13), True, False),
    ("hand post (stair R)", (10, 13), True, False), ("hand step back", (10, 14), True, False),
    ("gap closed", (9, 12), False, False), ("gap open", (9, 12), True, True), ("rope beside gap", (10, 12), False, True),
    ("inside", (9, 11), True, False), ("inside east", (10, 11), True, False),
    ("petrel", (11, 14), True, False), ("doorman", (11, 16), True, False), ("foe", (11, 9), True, False),
    ("spectator W", (4, 7), True, False), ("spectator E", (15, 7), True, False), ("VIP", (9, 3), True, False),
    ("near rope", (8, 12), True, False), ("band", (6, 9), False, False), ("riser", (9, 4), False, False),
    ("riser stair W", (5, 4), True, False), ("riser stair E", (14, 4), True, False),
]
for label, (x, y), want, og in checks:
    if walk(x, y, og) != want:
        fails.append(f"{label} ({x},{y}) walkable={not want} expected {want}")

print(f"recipe sheet: {len(used)} tiles, {diff} differing pixels; {len(checks)} walkability checks")
if fails:
    print("FAIL\n  " + "\n  ".join(fails)); sys.exit(1)
print("ALL PASS")
