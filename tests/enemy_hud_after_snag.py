"""Regression capture for REQUESTS 813: the enemy HUD after a snag, on the switch prompt.

Phone report, 2026-11-10: after a trainer's POKEMON was snagged and the next one was announced ("Will <PLAYER>
change POKEMON?"), the party-ball row was drawn over the snagged POKEMON's name, level and HP bar.

Boots the whole Live set (current/, or current/ with --zip swapped in) once, offscreen and muted (soak's
launcher), starts a real trainer battle, throws a KINGPIN BALL and stops on the switch prompt. PASS when the
ball row is up and the old enemy HUD is NOT (BattleState.showEnemyHud false), which is what the engine does on
an ordinary faint. The frame is saved as a PNG.

  python Pokemon-Snag/tests/enemy_hud_after_snag.py [--zip PATH] [--png OUT.png]   # ~3 min; exit 0 PASS, 1 FAIL, 2 UNKNOWN
"""
import argparse, os, sys, tempfile, uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
WORK = HERE.parent.parent
sys.path.insert(0, str(WORK / "exchange"))
import soak, run_dirs, talk_order, publish  # noqa: E402

MARKER = "H.result.ready=true;H.result.startFrame=f"


def run(out, png, swap=None):
    temp = Path(tempfile.gettempdir()) / "talk_order"
    pb = soak.load_bundle(WORK)
    setdir = temp / f".set-{uuid.uuid4().hex[:8]}"
    setdir.mkdir(parents=True)
    builds = {}
    try:
        got, _ = publish.read_set(str(setdir))
        zips = {mid: Path(path) for mid, (_, path) in got.items()}
        if swap:
            zips[publish.zip_manifest(str(swap))["id"]] = Path(swap)
        for z in zips.values():
            b = talk_order.staged(z, temp, pb)
            builds[b["id"]] = b
    finally:
        run_dirs.remove(setdir)
    saved = soak.DRIVER
    soak.DRIVER = soak.DRIVER.split(MARKER)[0] + MARKER + (
        "\n local t=dofile(os.getenv('HUD_TEST_DRIVER'))\n t(game,H,step,tap,idle,act)\n"
        " H.result.complete=true;H.collect();H.flush()\nend\n")
    os.environ.update(HUD_TEST_DRIVER=str(HERE / "enemy_hud_after_snag_driver.lua"),
                      HUD_TEST_OUT=str(out), HUD_TEST_PNG=str(png))
    args = argparse.Namespace(engine=Path(os.environ.get("MOD_PROBE_ENGINE") or WORK / "engine"), love=None,
                              cache=None, rig=talk_order.RIG, speed=4, minutes=10, work=WORK)
    try:
        rec = soak.execute(args, builds, [next(iter(builds))], temp / "runs", 438)
    finally:
        soak.DRIVER = saved
    if rec.get("run"):
        run_dirs.remove(rec["run"])
    return rec


def judge(text):
    rows = {}
    for line in text.splitlines():
        p = line.split("\t")
        rows[p[0]] = dict(zip(p[1::2], p[2::2])) if len(p) > 2 else {}
    if "ERROR" in rows or "DONE" not in rows:
        return 2, "UNKNOWN -- driver did not finish: " + text.strip()[-400:]
    prompt = rows.get("PROMPT", {})
    if "showEnemyHud" not in prompt:
        return 2, "UNKNOWN -- the switch prompt never came up (phases: %s)" % text
    if rows.get("SNAG", {}).get("caughtInParty") != "true":
        return 2, "UNKNOWN -- the snag did not land"
    if prompt.get("ballRow") != "true":
        return 2, "UNKNOWN -- the ball row is not up on the prompt, so this is not the reported screen"
    if prompt.get("showEnemyHud") != "false":
        return 1, "FAIL -- the snagged POKEMON's HUD is still drawn under the ball row on the switch prompt"
    return 0, "PASS -- on the switch prompt after a snag: ball row up, old enemy HUD cleared"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--zip")
    ap.add_argument("--png", default=str(Path(tempfile.gettempdir()) / "snag_enemy_hud_after_snag.png"))
    a = ap.parse_args()
    a.png = str(Path(a.png).resolve())     # the game runs from its own directory
    if a.zip:
        a.zip = str(Path(a.zip).resolve())
    out = Path(tempfile.gettempdir()) / f"snag_hud_test_{uuid.uuid4().hex[:8]}.txt"
    rec = run(out, a.png, a.zip)
    text = out.read_text(encoding="utf-8") if out.exists() else ""
    print(text or f"no output; engine errors: {str(rec.get('result', {}).get('errors'))[:600]}")
    code, verdict = judge(text)
    print(verdict)
    print("frame:", a.png)
    try:
        out.unlink()
    except OSError:
        pass
    return code


if __name__ == "__main__":
    sys.exit(main())
