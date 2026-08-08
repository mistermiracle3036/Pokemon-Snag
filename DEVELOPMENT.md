# Pokemon Snag — developer notes

Engine internals this mod touches, and why. Written for anyone building
on gen1recomp — a lot of what's here isn't documented anywhere else, and
several items are traps that fail *silently*.

> **Spoilers:** this file describes quest mechanics plainly. If you're
> playing rather than modding, read the [FAQ](FAQ.md) instead, where the
> same details sit behind spoiler folds.

Player-facing docs: [README](README.md) · [FAQ](FAQ.md)

## Fields other mods can read

A snagged Pokémon carries three persistent fields, set at the moment of
the catch:

| Field | Meaning |
| --- | --- |
| `mon.snagged` | `true` — the mon was taken from a trainer |
| `mon.snagFrom` | the trainer class it was stolen from (e.g. `OPP_MISTY`) |
| `mon.snagLevel` | the level it was at when stolen |

These exist because `storeCaughtMon()` calls `stampOT`, which overwrites
OT with the player immediately — so without a marker of its own, a
snagged Pokémon is data-identical to a wild catch the instant the battle
ends. `pokemon.caught` fires with `ball == "SNAG_BALL"`, but that's only
usable in the moment; these fields are for anything checking later.

They survive save/load for free: `Party.add` / `Boxes.deposit` are plain
`table.insert` (no copy), and the save serializer is a generic recursive
table dump with no field whitelist.

`kanto_ribbons` reads `mon.snagged`. **Don't rename it.**

## Cross-mod contract

Declared in code (`mod.exports`) rather than in prose, so another mod can
check it at runtime instead of relying on a note that goes stale:

```lua
local sq = mod.find("snag_quest")
sq.exports.owns        -- { balls = { SNAG_BALL = {...} }, monFields = {...} }
sq.exports.ballColors  -- { SNAG_BALL = { body = {...}, accent = {...} } }
```

**What this mod owns:** the whole `SNAG_BALL` ball record — registration,
`attempt`, `tossAnim`, `flicker`. Patching those from elsewhere fights
this mod silently, because the last folded op wins with no error. Check
`exports.owns` and back off instead.

**What's open:** the colour. `pokeball_colors` keys its palette off ball
id and exposes `exports.colors` for other mods to register into, so this
mod registers its own entry there on `game.ready` (only if the key is
absent — a colour that mod deliberately ships wins). That inverts the
dependency: renaming, recolouring or adding a second ball here needs no
change in `pokeball_colors`, ever.

**Why `game.ready` and not load time:** `mod.find` can't see a mod that
hasn't loaded yet, and load order between two independent mods isn't
guaranteed either way. By `game.ready` both exist, and it still lands
long before anything draws a ball.

**The general rule this follows:** a mod that *owns* a thing registers
it; a mod that *decorates* things reads a registry keyed by id and never
writes to records it doesn't own. Follow that and two mods never need to
tell each other anything.

## Engine seams this mod patches

Everything below was verified by reading the engine's own source, not
inferred.

**`BattleState:throwBall(ball)`** — gates on `self.kind ~= "wild"` and
plays "the trainer blocked the BALL!" otherwise. This mod wraps it and,
for `SNAG_BALL` in a trainer battle, runs the engine's own wild-catch
body verbatim minus that check.

**`self.oppClass`** is set on the battle instance by *both*
`BattleState.newTrainer` call sites, so it's reliable for identifying the
current trainer. The `world.trainer_engaged` event is **not** — it only
fires from the overworld sight-engagement path, never from the
`start_battle` script command. Anything keyed to that event silently
never runs for scripted battles.

**Shiny DVs must be applied at battle creation** (wrap `newTrainer`), not
at catch time. `newTrainer` builds the party with `Pokemon.new` and then
*overwrites* every mon's DVs with a fixed trainer-DV constant, so DVs set
earlier are discarded. The battler holds a reference to the same mon
table (no copy), so patching after `newTrainer` returns is visible
everywhere. Shininess itself is engine-native (`Stats.isShiny`); the
Shiny Pokémon mod is only needed for visuals.

**Turning a Pokémon in** uses the engine's own in-game-trade pattern:
`Screens.push(game, "PartyMenu", { pickOnly = true, onCancel, onSwitch })`
then `runner:yield()`, resuming from the callbacks.

## Continuing a battle after a catch — the hard part

`storeCaughtMon()` does the party/box/dex/OT bookkeeping *and*
unconditionally ends the battle (`result = "caught"`,
`afterQueue = "finish"`). Correct for a wild encounter; wrong for one
Pokémon out of a trainer's team. Making the fight continue needs four
things, and missing any one fails differently:

1. **Route through `self:onFaint(battler)`.** It is the only entry point
   into the faint pipeline and does setup that `enemyMonFainted()`
   assumes. Calling `enemyMonFainted()` directly **crashes**.
2. **Set `afterQueue = "menu"`, never `nil`.** `enemyMonFainted`'s
   *switch* exit returns early without setting it (its normal caller,
   `endOfTurn`, already did); only the *victory* exit sets `"finish"`.
   Leave it `nil` and the queue drains into neither branch — the battle
   idles forever in the message phase. **Silent freeze, no error.**
3. **Give the pipeline an HP-0 mon.** Everything downstream (faint
   animation, send-out grow-in, level-up HUD rows) assumes the fainting
   mon is at 0 HP. The just-caught mon is at full HP *and* is the same
   table now in the player's party — so the pipeline reads, and can
   write to, the player's own new Pokémon. Swap in a shallow clone with
   `hp = 0` first.
4. **Clear `self.enemyHidden`.** The catch animation sets it (the mon is
   inside the ball) and a wild catch ends the battle before it matters;
   a real faint never sets it. Skip this and the trainer's next Pokémon
   is invisible.

Reusing the real faint pipeline has a deliberate cost: a snag awards EXP
and plays the faint sound/slide. The "`<mon>` fainted!" text is
suppressed, since that one is emitted synchronously and can be dropped
cleanly.

## Dialogue and merchants

There is no NPC registry. Dialogue is added by taking over an existing
NPC's `TEXT_` constant on its map, with a `base_talk` fallback so every
gated-off branch still plays the original vanilla line:

```lua
mod.content.map_scripts:register(mapId, {
  talk = { TEXT_CONSTANT = rows },
  priority = 500,
})
```

Merchants are one factory —
`registerMerchant{ map, texts, badge, intro, refuse, sold }` — so a new
town is a map id, its constant(s), an optional badge id, and three lines.
Badges are a plain inventory lookup (`save.inventory.BOULDERBADGE`).

### The text-constant trap

`TEXT_` constants are extracted from the ROM at load, so they **can't be
grepped in the engine repo**, and some objects are **renamed between
Red/Blue and Yellow**. Register the wrong one and the mod does nothing at
all — no error, just vanilla dialogue. It is very slow to diagnose.

Use the [NPC Inspector](https://github.com/mistermiracle3036/npc_inspector)
dev tool to read the map id and constant off the running game instead of
guessing.

Renames are **per-map, not universal** — verified on real Red and Yellow
saves:

| NPC | Red/Blue vs Yellow |
| --- | --- |
| Viridian girl | identical (`TEXT_VIRIDIANCITY_GIRL`) |
| Pewter Nidoran-house man | identical (`TEXT_PEWTERNIDORANHOUSE_MIDDLE_AGED_MAN`) |
| Celadon Game Corner coin-giver | **differs** (`..._CLERK2` vs `..._MIDDLE_AGED_MAN2`) |

So check each NPC on each version. Extra `texts` entries are harmless —
a constant that doesn't exist simply never dispatches.

## Two silent-failure signatures worth memorising

- **NPC turns to face you, no text box.** A script command threw and the
  runner swallowed it. A classic cause is Lua use-before-declaration: a
  function calling a `local` declared *later* in the file compiles that
  name as a global, which is `nil` at runtime.
- **An updated mod behaves like the old version.** Engine module tables
  persist in Lua's module cache for the whole process, so an
  "already wrapped" sentinel makes a re-enabled mod keep running stale
  code. Stash the original function once and always rebuild wrappers
  from it. Log the version on load so "which build is live" is
  answerable, and fully quit/relaunch when in doubt.

## Mart integration

Mart stock is static data, so conditional stock (quest-gated,
option-controlled) is done by wrapping `Data:textEntry` and appending to
a **copy** of the entry. The underlying table is never mutated, so turning
the option off cleanly removes the item again.
