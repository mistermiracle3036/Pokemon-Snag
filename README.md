# Pokemon Snag

A Team Rocket questline for **gen1recomp** (Red / Blue / Yellow). Jessie
recruits you into a shady side business: a custom **Snag Ball** that can
steal Pokémon straight from other trainers — and a network of black-market
"fences" across Kanto who'll pay you in Snag Balls for the goods.

> **Development Preview:** Pokemon Snag is in active development. Bug reports
> and feature ideas are welcome in
> [GitHub Issues](../../issues) — please include the version number from
> your load log and which other mods were enabled.

Looking for exact merchant locations, payout math or quest triggers?
Open the **[FAQ and spoiler guide](FAQ.md)** — every detailed answer is
collapsed so you only reveal what you want.

## Features

- **The intro quest.** After you've received the Pokédex, find Jessie in
  Viridian City. She'll set you up with your first Snag Ball and a target:
  a Picnicker with a very special Meowth. The snag is guaranteed — and so
  is a surprise about that Meowth.
- **The Snag Ball.** A custom ball that works in *trainer* battles. Throw
  it at an opponent's Pokémon and it's yours. It throws with the
  Ultra/Master-tier arc and flicker, because a ball that costs ₽10,000 or
  a stolen Pokémon shouldn't look like a starter item. Snagged Pokémon are marked
  permanently and keep a record of who you took them from and at what
  level.
- **Keep fighting.** By default the battle continues after a successful
  snag (the trainer sends out their next Pokémon). This can be turned off
  in options if you prefer the snag to end the battle.
- **Fences.** Certain NPCs around Kanto quietly buy snagged Pokémon,
  paying **1–5 Snag Balls** depending on the mon's level, rarity and who
  you stole it from. VIP targets — a certain rival, gym leaders, the
  Elite Four — fetch top price.
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
4. Requires gen1recomp **0.1.38 or newer** and the **Quest System** mod
   (hard dependency — quest journal entries live there).

**Updating:** once installed, the launcher checks this repo for new
releases. The mod's entry shows "vX.Y.Z available" → tap → **Update** →
fully quit and relaunch. No manual re-download.

After installing an update, **fully quit and relaunch** the game. The
load log prints the running version so you can confirm what's live.

## Compatibility

- **quest_system** — required. Pokemon Snag registers its questline in the
  journal (objectives, tracking, markers).
- **kanto_ribbons** — supported. Reads the snag marker on stolen Pokémon.
- **SHINY_POKEMON** — optional integration for shiny visuals; shininess
  itself is engine-native, so the guaranteed shiny snag works without it.
- **pokeball_colors** — optional. Recolours the Snag Ball to a Team
  Rocket palette (near-black body, red accent) when the game is in
  ADVANCED colour mode. The toss arc and flicker are set by Pokemon Snag
  itself and don't need it.
- **Dramatic Shape (voxel mode)** — played and tested in voxel mode.
- **Red, Blue and Yellow all supported.** Where an NPC's internal name
  differs between versions, both are registered. Jessie and the Pewter
  fence were verified identical across Red and Yellow on real saves; the
  Celadon fence genuinely differs and both names ship.

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
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
