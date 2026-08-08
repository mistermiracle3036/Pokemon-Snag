# Pokemon Snag — FAQ and spoiler guide

Every answer is collapsed. Tap only what you want revealed.

## Getting started

<details>
<summary>How do I start the questline?</summary>

Get the Pokédex from Oak first. Then talk to the girl in **Viridian
City** — she's not who she appears to be. She gives you one Snag Ball and
your first target. The quest appears in your journal as *Introduction to
Thievery*.
</details>

<details>
<summary>The girl in Viridian just says her normal line. Why?</summary>

Two common reasons: you don't have the Pokédex yet, or the mod isn't
actually loaded (check the load log / F10 mod manager for the Pokemon Snag
version line). If it's loaded and you have the Pokédex, please open an
issue with your version number.
</details>

<details>
<summary>What do I get from the intro quest? (big spoiler)</summary>

The Picnicker's Meowth is a **guaranteed shiny**, and the snag is
guaranteed to succeed. You also get a Snag Ball as a reward, so you end
the quest with one in stock.
</details>

<details>
<summary>Can I replay the intro quest?</summary>

Turn on **[DEV] REPLAY INTRO QUEST** in options. Jessie will treat the
quest as unfinished so you can re-fight the Picnicker and hand Meowth in
again. It doesn't erase your real progress — switch it back off and the
quest is as completed as it was.
</details>

## The Snag Ball

<details>
<summary>How do I use it?</summary>

Throw it from the bag during a **trainer** battle, like any ball. It
targets the opponent's current Pokémon.
</details>

<details>
<summary>Does the battle end when I snag something?</summary>

By default, no — the trainer sends out their next Pokémon and the fight
continues. Turn **CONTINUE BATTLE AFTER SNAG** off if you'd rather it end
the battle.
</details>

<details>
<summary>Where do I buy more?</summary>

That depends on **GET NEW SNAG BALLS** in options:

- **BOTH** (default) — marts stock them at **₽10,000**, and fences pay in
  them too.
- **MART** — marts only; the fences won't deal.
- **FENCES** — the black market only; nothing on any shelf.

Jessie's post-quest hint follows whichever you've picked.
</details>

<details>
<summary>Anything odd about snagging vs. a normal catch?</summary>

Because a snag reuses the engine's real faint pipeline to let the battle
continue, it also awards EXP (a normal catch doesn't), and the faint
sound and slide still play for the Pokémon you just took. Cosmetic, but
deliberate — it's the cost of the fight continuing correctly.
</details>

## Fences (merchants)

<details>
<summary>Where are the fences? (spoilers)</summary>

- **Celadon Game Corner** — a gambler on the floor buys snagged mons.
- **Pewter City** — the middle-aged man in the Nidoran house, but only
  once you have the **Boulder Badge** (he has opinions about which
  Pokémon obey which trainers).

Both only open for business after the intro quest is done, and only if
**GET NEW SNAG BALLS** is set to `BOTH` or `FENCES`. More badge-town
fences are planned.
</details>

<details>
<summary>How is the payout calculated? (numbers)</summary>

Starting from **1 Snag Ball**:

- +1 if the mon was snagged at level 25+
- +1 if it was snagged at level 45+
- +1 if the species is hard to catch (catch rate ≤ 45)
- +1 if you stole it from a **VIP**: your rival, any of the eight gym
  leaders, the Elite Four, or Giovanni

Capped at **5**. Note the level used is the level it was *stolen* at —
training it up afterwards doesn't raise the price.
</details>

<details>
<summary>A fence refused my Pokémon.</summary>

They only want **snagged** ones, and they won't take your last party
Pokémon. Pokémon snagged before v0.8.0 can still be sold but can't earn
the VIP or level bonuses — those records didn't exist yet when they were
caught.
</details>

## Troubleshooting

<details>
<summary>I talked to an NPC and they just turned to face me — nothing
happened.</summary>

That's the signature of a swallowed script error. Please open an issue
with: your Pokemon Snag version (from the load log), your game version
(Red/Blue/Yellow), which NPC, and which other mods were enabled. If you
can, retry with other mods disabled — knowing whether that changes it
helps enormously.
</details>

<details>
<summary>I updated the mod but it's acting like the old version.</summary>

Fully quit and relaunch the game. Hot-reload can keep stale code in
memory. The load log prints the version — confirm it matches the release
you installed.
</details>

<details>
<summary>An NPC I expected to be a fence is just saying their normal
line.</summary>

Check the gate first: every fence needs the intro quest finished, and the
Pewter one also needs the Boulder Badge. If both are satisfied and they
still say their vanilla line, that's worth an issue — include your game
version, since NPC internal names can differ between Red/Blue and Yellow.
</details>
