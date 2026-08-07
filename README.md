# Snag Quest

A Team Rocket questline for **gen1recomp** (Red / Blue / Yellow). Jessie
recruits you into a shady side business: a custom **Snag Ball** that can
steal Pokémon straight from other trainers — and a network of black-market
"fences" across Kanto who'll pay you in Snag Balls for the goods.

> **Development Preview:** Snag Quest is in active development. Bug reports
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
  it at an opponent's Pokémon and it's yours. Snagged Pokémon are marked
  permanently and keep a record of who you took them from and at what
  level.
- **Keep fighting.** By default the battle continues after a successful
  snag (the trainer sends out their next Pokémon). This can be turned off
  in options if you prefer the snag to end the battle.
- **Fences.** Certain NPCs around Kanto quietly buy snagged Pokémon,
  paying **1–5 Snag Balls** depending on the mon's level, rarity and who
  you stole it from. VIP targets — a certain rival, gym leaders, the
  Elite Four — fetch top price.
- **Mart supply line.** Optionally, Snag Balls appear for sale in marts
  (default ON, and they are *not* cheap).

## Options

Open **MODS → SNAG QUEST → OPTIONS** (F10 mod manager):

| Option | Default | Effect |
| ------ | ------- | ------ |
| CONTINUE BATTLE AFTER SNAG | ON | Trainer battles continue after a successful snag instead of ending |
| SELL SNAG BALLS IN MARTS | ON | Snag Balls purchasable in marts for ₽10,000 |
| DEV: REPLAY MEOWTH QUEST | OFF | Dev/testing toggle — resets the intro quest |

## Installation

<!-- TODO/CONFIRM: exact wording for how users install mods in gen1recomp
     (folder path / mod manager import). Fill in the same instructions you
     follow yourself. -->

1. Download `snag_quest.zip` from the
   [latest release](../../releases/latest).
2. Install it like any other gen1recomp mod.
3. Requires gen1recomp **0.1.38 or newer** and the **Quest System** mod
   (hard dependency — quest journal entries live there).

## Compatibility

- **quest_system** — required. Snag Quest registers its questline in the
  journal (objectives, tracking, markers).
- **kanto_ribbons** — supported. Reads the snag marker on stolen Pokémon.
- **SHINY_POKEMON** — optional integration for shiny visuals; shininess
  itself is engine-native, so the guaranteed shiny snag works without it.
- **Dramatic Shape (voxel mode)** — played and tested in voxel mode.
- Works in Red, Blue and Yellow. Merchant NPCs are registered under both
  Red/Blue and Yellow text constants where known.
  <!-- TODO/CONFIRM: Pewter merchant Yellow constant still unverified -->

## How snag payouts work

Base payout is 1 Snag Ball, plus bonuses for high level, hard-to-catch
species and VIP victims, capped at 5. Exact thresholds are in the
[FAQ](FAQ.md) behind a spoiler fold.

## Credits

Built for [gen1recomp](https://github.com/bryanthaboi/gen1recomp).
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
