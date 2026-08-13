# Pokemon Snag — Steal Pokémon from Trainers

**Throw a ball at another trainer's Pokémon and take it.** Pokemon Snag
adds the Snag Ball to **gen1recomp** (Red / Blue / Yellow): a real,
reusable ball that works in trainer battles, so any Pokémon an opponent
sends out is a Pokémon you can walk away with.

A Team Rocket recruiter at the end of Nugget Bridge brings you into the
business, and a network of black-market "fences" across Kanto will pay
you in Snag Balls for the goods — so the better your thefts, the more you
can steal.

> **Development Preview:** Pokemon Snag is in active development. Bug reports
> and feature ideas are welcome in
> [GitHub Issues](../../issues) — please include the version number from
> your load log and which other mods were enabled.

Looking for exact merchant locations, payout math or quest triggers?
Open the **[FAQ and spoiler guide](FAQ.md)** — every detailed answer is
collapsed so you only reveal what you want.

## Features

- **The intro quest.** Beat the Team Rocket recruiter at the end of
  Nugget Bridge, then hear him out. He'll set you up with your first Snag
  Ball and a target: a Picnicker with a very special Meowth. The snag is
  guaranteed — and so is a surprise about that Meowth. Say no and the
  offer stays open; come back any time.
- **The Snag Ball.** A custom ball that works in *trainer* battles. Throw
  it at an opponent's Pokémon and it's yours. It throws with the
  Ultra/Master-tier arc and flicker, because a ball that costs ₽10,000 or
  a stolen Pokémon shouldn't look like a starter item. Snagged Pokémon are marked
  permanently and keep a record of who you took them from and at what
  level.
- **Keep fighting.** By default the battle continues after a successful
  snag (the trainer sends out their next Pokémon). This can be turned off
  in options if you prefer the snag to end the battle.
- **Four fences.** Certain NPCs around Kanto quietly buy snagged Pokémon,
  paying **1–5 Snag Balls** depending on the mon's level, rarity and who
  you stole it from. VIP targets — a certain rival, gym leaders, the
  Elite Four — fetch top price. They are not one organisation: two are
  Rocket, two are independents who simply like what falls off the back of
  a truck, and they each have their own opinion of you.
- **Choose your supply.** One setting decides where new Snag Balls come
  from: the marts (they are *not* cheap), the fences, or both.

## Options

Open **MODS → POKEMON SNAG → OPTIONS** (F10 mod manager):

| Option | Default | Effect |
| ------ | ------- | ------ |
| CONTINUE BATTLE AFTER SNAG | ON | Trainer battles continue after a successful snag instead of ending |
| GET NEW SNAG BALLS | BOTH | Where Snag Balls come from after the quest: `BOTH`, `MART` (₽10,000 each) or `FENCES` |
| [DEV] REPLAY INTRO QUEST | OFF | Dev/testing toggle — lets you redo *Introduction to Thievery* |

## Installation

1. Download `snag_quest-<version>.zip` from the
   [latest release](../../releases/latest).
2. In the launcher: **MODS → Import mod .zip**. On iOS, delete any older
   downloaded copy of the zip from Files first.
3. Fully quit and relaunch.
4. Requires gen1recomp **0.1.38 or newer**. Nothing else is mandatory.

**Optional: Quest System.** Install it and the questline gets a proper
journal entry — objective, progress, map markers. Without it everything
still works exactly the same; you just track the quest yourself. Download
`quest_system_v<version>.zip` from the root of
[FAFF0x/gen1recomp](https://github.com/FAFF0x/gen1recomp) and import it
the same way. Note it is committed directly in that repo rather than
published under Releases, so grab the zip from the file list — and the
launcher's auto-update won't cover it.

**Updating:** once installed, the launcher checks this repo for new
releases. The mod's entry shows "vX.Y.Z available" → tap → **Update** →
fully quit and relaunch. No manual re-download.

After installing an update, **fully quit and relaunch** the game. The
load log prints the running version so you can confirm what's live.

## Compatibility

- **[quest_system](https://github.com/FAFF0x/gen1recomp)** by FAFF0x —
  optional. With it, the questline appears in the journal with an
  objective, progress and map markers. Without it the quest plays
  identically — it runs on its own save flags — you simply get no journal
  entry. Grab `quest_system_v<version>.zip` from that repo's file list;
  it is committed there rather than released. See Installation above.
- **[kanto_ribbons](https://github.com/mistermiracle3036/kanto_ribbons)** —
  supported. Reads the snag marker on stolen Pokémon and awards a ribbon.
- **[Shiny Pokémon](https://github.com/masterwebx/gen1recomp-shiny-pokemon)** —
  optional, and the division of labour matters: **this mod supplies the
  data, that mod supplies the picture.** The quest Meowth's shiny DVs are
  set here and are engine-native (`Stats.isShiny`), so it is genuinely
  shiny whether or not that mod is installed. Every *visual* — the ◆
  marker beside the name, the sparkle animation on send-out — is drawn
  entirely by Shiny Pokémon. The engine draws no shiny effects of its
  own and Pokemon Snag draws nothing at all. Turning that mod off leaves
  the Meowth just as shiny, only undecorated. Note its marker and its
  recolour are separate options, so a Meowth showing the ◆ but the wrong
  colour means **SHINY COLORS** is switched off.
- **[Pokéball Colors](https://github.com/mistermiracle3036/Pokeball-Colors)** —
  optional. Gives the Snag Ball its own colours.
- **[NPC Inspector](https://github.com/mistermiracle3036/npc_inspector)** —
  not required to play; the dev tool used to target this mod's NPCs
  correctly across Red, Blue and Yellow.
- **Dramatic Shape (voxel mode)** — played and tested in voxel mode.
- **Red, Blue and Yellow all supported.** Where an NPC's internal name
  differs between versions, both names are registered. Every NPC this mod
  takes over was checked against the engine's Red and Yellow symbol
  tables: the Nugget Bridge recruiter, the Pewter fence and the Vermilion
  fence are identical across versions; the Celadon fence genuinely
  differs, so that one ships both names.
- **Other mods that change the same NPCs.** This mod takes over specific
  vanilla characters. If another mod claims the same character, only one
  of them wins and the other's dialogue silently never runs — that is how
  the engine resolves the conflict, not a bug in either mod. If a fence
  only ever gives their ordinary line, try disabling other NPC-editing
  mods to see which one is winning. (Team Rocket Returns was tested
  alongside this mod and does **not** conflict.)

## How snag payouts work

Base payout is 1 Snag Ball, plus bonuses for high level, hard-to-catch
species and VIP victims, capped at 5. Exact thresholds are in the
[FAQ](FAQ.md) behind a spoiler fold.

## For modders

If you're building on this, [DEVELOPMENT.md](DEVELOPMENT.md) documents the
engine internals this mod touches and the reasoning behind them — the
trainer-battle ball gate, the faint-pipeline handoff, and the
`mon.snagged` / `mon.snagFrom` / `mon.snagLevel` fields other mods can
read.

## Credits

Built for [gen1recomp](https://github.com/bryanthaboi/gen1recomp).
By **Mister Miracle**
([@mistermiracle3036](https://github.com/mistermiracle3036)).

The Nugget Bridge opening was **trikus's** idea, suggested in the
gen1recomp Discord: instead of inventing a character to hand out the
quest, use the Team Rocket grunt who already asks whether you want to
join — and let saying yes actually mean something. Vanilla asks the
question and then ignores your answer, so the hook was already there.
It replaced an earlier opening built around the Viridian City girl.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Gold private test

The Gold path is a separate questline, not a port of the Kanto one — the mod splits on generation at load and the Kanto quest never runs on Gold. Gold marts do **not** stock the SNAG BALL: every ball comes from the questline, starting with the single ball the Cherrygrove sailor hands you.

### Custom trainer VIP compatibility (Gold)

Pokemon Snag exposes a `snag.vip` hook for mods that add important custom trainers.
The hook receives the built-in VIP verdict plus encounter context and may return `true`
to mark that trainer as VIP for Snag Ball fence valuation. The verdict is stamped onto
the stolen Pokemon as `mon.snagVip`, so the bonus remains stable later.

```lua
mod.hooks:wrap("snag.vip", function(next_, vip, ctx)
  vip = next_(vip, ctx)
  if ctx.npc and ctx.npc.def and ctx.npc.def.name == "MY_CUSTOM_BOSS" then
    return true
  end
  return vip
end)
```

`ctx` includes `game`, `world`, `npc`, `mapId`, `trainerClass`, `classIndex`,
`trainerName`, `memberIndex`, `trainerEvent`, and `sight`.


## Gold private test: Goldenrod contract

After completing the Cherrygrove introduction and claiming the sailor's five-ball reward, a broker appears in Goldenrod City. He offers one of three leads:

- PSYCHIC -> NATU
- NORMAL -> AIPOM
- BUG -> YANMA

This is the first non-tutorial Snag job: no free ball and no guaranteed catch. The selected target can be retried if it is knocked out. Snagging it completes the contract.


## Gold private test: Ecruteak archetype contract

After successfully snagging the selected Goldenrod target, an Ecruteak contact offers a second contract based on trainer archetype rather than Pokemon type.

- PERFORMER: Smeargle / easier two-Pokemon party / Dance Theater
- MYSTIC: Misdreavus / three-Pokemon Ghost party / Burned Tower side of Ecruteak
- COLLECTOR: Girafarig / stronger rare-species party / west gate

A neutral resident gives Pokedex-flavored gossip that points toward the chosen mark. Only snagging the advertised target completes the job, but other Pokemon in the mark's party remain valid Snag targets.

Returning to the Ecruteak contact after completion awards one HEIST BALL. It doubles the catch rate; it is not sold anywhere and fences do not trade for it. (0.14.37 called this reward the GREAT SNAG BALL at 1.5x — 0.14.38 replaced it with the HEIST BALL from the tier brief.)
