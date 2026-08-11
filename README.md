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
- **[kanto_ribbons](https://github.com/mistermiracle3036/kanto_ribbons)** —
  supported. Reads the snag marker on stolen Pokémon and awards a ribbon.
- **[Shiny Pokémon](https://github.com/masterwebx/gen1recomp-shiny-pokemon)** —
  optional, and the division of labour matters: **this mod supplies the
  data, that mod supplies the picture.** The quest Meowth's shiny DVs are
  set here and are engine-native (`Stats.isShiny`), so it is genuinely
  shiny whether or not that mod is installed. Every *visual* — the ◆
  marker beside the name, the sparkle animation on send-out — is drawn
  entirely by Shiny Pokémon. The engine draws no shiny effects of its
  own and Pokemon Snag draws nothing at all. The contract is one-way by
  design: Pokemon Snag writes only engine-native data and calls that
  mod's published exports — it never writes that mod's own fields. So any rendering oddity
  around a shiny (stray tiles, sparkle artifacts) belongs to that mod;
  turning it off leaves the Meowth just as shiny, only undecorated,
  which is also the way to confirm where an artifact came from.
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
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
