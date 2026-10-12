"""Room C source loader: native Crystal pieces resolved to 8x8 tile references.

Follows engine v0.3.51 rules (src/world/gen2/TileAttrs.lua forTile/sheetTileId,
src/render/GbcPalette.lua shade = 3 - grey/85). Piece sources are the room
package's (exchange/outbox/snag-boxing-ring/tools/kit.py native()); this file
only re-expresses them as tile references so a recipe can rebuild them from
the player's own cache. Reads the cache read-only.
"""
import json, os
from PIL import Image

CACHE = os.path.join(os.environ.get("APPDATA", ""), "pokemon-love2d", "crystal")

class Src:
    def __init__(self, data_dir):
        with open(os.path.join(data_dir, "tilesets.json"), encoding="utf-8") as f:
            self.tilesets = json.load(f)
        with open(os.path.join(data_dir, "maps.json"), encoding="utf-8") as f:
            self.maps = json.load(f)
        with open(os.path.join(data_dir, "palettes.json"), encoding="utf-8") as f:
            self.palettes = json.load(f)
        self._sheets = {}

    def sheet(self, ts):
        p = os.path.join(CACHE, ts["image"].replace("/", os.sep))
        if p not in self._sheets:
            self._sheets[p] = Image.open(p).convert("L")
        return self._sheets[p]

    @staticmethod
    def for_tile(ts, tile_id):
        attrs = ts.get("tileAttrs") or {}
        a = attrs.get(str(tile_id + 1))
        if a:
            return a
        if tile_id < 0x80:
            a = attrs.get(str(0x80 + tile_id + 1))
            if a and a.get("vramBank") == 1:
                return a
        bank = 1 if 0x80 <= tile_id < 0xE0 else 0
        norm = tile_id % 0x80
        tp = ts.get("tilePalettes") or {}
        slot = tp.get(str(tile_id + 1)) or (bank == 1 and tp.get(str(0x80 + norm + 1))) or tp.get(str(norm + 1)) or 1
        return {"palette": slot, "vramBank": bank, "xFlip": False, "yFlip": False, "priority": False}

    @staticmethod
    def sheet_tile_id(tile_id, a):
        if tile_id >= 0x80:
            return tile_id
        if a and a.get("vramBank") == 1:
            return 0x80 + tile_id
        return tile_id

    def tile_ref(self, tsid, raw):
        """One 8x8 tile as the recipe will copy it: source sheet, sheet index,
        the source attribute's own flips, and its palette slot."""
        ts = self.tilesets[tsid]
        a = self.for_tile(ts, raw)
        return {
            "ts": tsid, "image": ts["image"].split("/")[-1], "sid": self.sheet_tile_id(raw, a),
            "fx": bool(a.get("xFlip")), "fy": bool(a.get("yFlip")),
            "pal": a.get("palette") or 1, "ov": None,
        }

    def shades(self, ref):
        """8x8 shade grid (0 lightest .. 3 darkest) of a tile reference, flips applied."""
        ts = self.tilesets[ref["ts"]]
        tpr = ts.get("tilesPerRow", 16)
        sx, sy = (ref["sid"] % tpr) * 8, (ref["sid"] // tpr) * 8
        sp = self.sheet(ts).load()
        g = [[3 - round(sp[sx + x, sy + y] / 85) for x in range(8)] for y in range(8)]
        if ref["fx"]:
            g = [row[::-1] for row in g]
        if ref["fy"]:
            g = g[::-1]
        if ref.get("ov"):
            g = [[g[y][x] if ref["ov"][y][x] is None else ref["ov"][y][x] for x in range(8)] for y in range(8)]
        return g

    def quadrant(self, tsid, block, q):
        """Four tile refs (TL, TR, BL, BR) of one 16x16 quadrant of a block."""
        tl = self.tilesets[tsid]["blocks"][block]
        qx, qy = (q % 2) * 2, (q // 2) * 2
        raws = [tl[(qy + j) * 4 + qx + i] for j in range(2) for i in range(2)]
        return [self.tile_ref(tsid, r) for r in raws], self.tilesets[tsid]["collision"][block][q]

    def map_cell(self, map_id, cx, cy):
        m = self.maps[map_id]
        b = m["blocks"][(cy // 2) * m["width"] + cx // 2]
        q = (cx % 2) + 2 * (cy % 2)
        return self.quadrant(m["tileset"], b, q)

def vflip_cell(tiles):
    """yFlip a whole 16x16 cell: rows swap and every tile flips."""
    tl, tr, bl, br = [dict(t) for t in tiles]
    for t in (tl, tr, bl, br):
        t["fy"] = not t["fy"]
    return [bl, br, tl, tr]

def native_pieces(src):
    """Piece id -> (four tile refs, native collision byte). Sources: kit.py native()."""
    P = {}
    lance = {"N-BAND-W": (1, 3), "N-BAND-E": (8, 3), "N-BAND-S": (3, 5), "N-CORNER-SW": (1, 5),
             "N-CORNER-SE": (8, 5), "N-STAIR-L": (4, 5), "N-STAIR-R": (5, 5),
             "N-POST-W": (2, 4), "N-POST-E": (7, 4)}
    for pid, (cx, cy) in lance.items():
        P[pid] = src.map_cell("LANCES_ROOM", cx, cy)
    for pid, base in (("N-BAND-N", "N-BAND-S"), ("N-CORNER-NW", "N-CORNER-SW"), ("N-CORNER-NE", "N-CORNER-SE")):
        P[pid] = (vflip_cell(P[base][0]), P[base][1])
    for pid, tsid, b, q in (
        ("N-CANVAS", "TILESET_CHAMPIONS_ROOM", 51, 0),
        ("N-SEAT", "TILESET_TRAIN_STATION", 1, 0),
        ("N-STANDFLOOR", "TILESET_TRAIN_STATION", 3, 0),
        ("N-STOOL", "TILESET_GAME_CORNER", 5, 1),
        ("N-GCFLOOR", "TILESET_GAME_CORNER", 1, 0),
        ("N-SOFA-L", "TILESET_FACILITY", 45, 0),
        ("N-SOFA-R", "TILESET_FACILITY", 45, 1),
        ("N-SLAB-FACE", "TILESET_ELITE_FOUR_ROOM", 42, 2),
        ("N-UFLOOR", "TILESET_UNDERGROUND", 13, 0),
        ("N-UWALL-T", "TILESET_UNDERGROUND", 9, 0),
        ("N-UWALL-B", "TILESET_UNDERGROUND", 9, 2),
        ("N-UDARK", "TILESET_UNDERGROUND", 44, 2),
        ("N-MAT", "TILESET_UNDERGROUND", 36, 2),
    ):
        P[pid] = src.quadrant(tsid, b, q)
    return P

def cell_shades(src, tiles):
    """16x16 shade grid of a cell."""
    g = [[0] * 16 for _ in range(16)]
    for i, t in enumerate(tiles):
        s = src.shades(t)
        ox, oy = (i % 2) * 8, (i // 2) * 8
        for y in range(8):
            for x in range(8):
                g[oy + y][ox + x] = s[y][x]
    return g
