## 0.15.0 - Johto

**Updating from v0.14.11? Pokemon Snag works on Pokemon Gold now.** Not a
port of the Kanto story — a questline of its own, from a first Snag Ball to
a network of contacts who hand out jobs and buy what you bring back.

### Where it starts

A sailor in **Cherrygrove City** gives you exactly one SNAG BALL and points
you at a girl with something unusual on her team. That one ball is
guaranteed to catch her **shiny Meowth** — the only time the mod bends its
own rules. Snag it, find him again before you leave town, and he hands over
five more balls and tells you where to sell what you steal.

### Selling

A **fence on Route 36**, near Sudowoodo, buys Pokemon you have snagged, and
only those. He quotes a price and asks you to confirm before anything
leaves your party, and he pays before it does. What he pays depends on the
Pokemon's level when you took it, how rare it is, and **who you took it
from** — the rivals, all sixteen Gym Leaders, the Elite Four, Lance and Red
are all worth more, and that is remembered on the Pokemon even if you
change your mod list later.

**No sale pays less than 2 SNAG BALLs.** Giving up a Pokemon is the most
expensive thing you can do — it leaves your party for good — and a single
ball back could not even repeat the throw that caught it. *This one applies
on Red as well.*

### Jobs

A broker at **Goldenrod's Magnet Train Station** offers you a lead and lets
you choose the type: **PSYCHIC**, **NORMAL** or **BUG**. Pick one and a
trainer carrying that Pokemon turns up in the **Goldenrod Underground**.
Somewhere in the city, an ordinary passer-by is gossiping about having seen
something strange — they have no idea what you are, and they are telling you
where to look.

Knock the target out and you have not failed; the mark comes back so you can
try again. Snag it and the contract is done.

Then **Ecruteak**, where the choice is not a type but a kind of person:
**PERFORMER**, **MYSTIC** or **COLLECTOR**. Each leads somewhere different,
with a different team around the target.

**Contract targets are bounties.** A job's advertised Pokemon fences for at
least 3 SNAG BALLs, and finishing a contract pays a flat **5** on top. If you
are already carrying a mark from an earlier version, the fence works out what
it was and pays the new rate — nothing to redo.

### Better balls

Finishing the first Ecruteak contract earns the **HEIST BALL**, which is
twice as reliable as a plain SNAG BALL.

### You cannot get permanently stuck

Gold has no marts selling Snag Balls, so running out used to end the
questline for good — the fence pays you for stolen Pokemon, which costs a
ball to earn a ball. Now, if you turn up at a fence with **no Snag Balls of
any kind and nothing they would buy**, you get handed one. They are not
generous about it. Come back as often as you need.

It only fires when you have absolutely nothing, so it cannot be used to
stockpile.

### Your contacts buy from you too

The Goldenrod broker starts buying snagged Pokemon directly once he has paid
you for his contract, and the Ecruteak contact does the same after handing
over the HEIST BALL — in a colder voice, and at a higher level. Same rules,
same protections: your last Pokemon is never sellable, and the payment
always lands before the Pokemon leaves.

### One more thing about Gold

Snagging a healthy Pokemon is meant to be hard, and the odds improve as the
target's HP drops, exactly as they would for a wild catch. A mark at full
health is a low-percentage throw. Weaken it first if you can do it without
knocking it out.

The mod has no settings on Gold — CONTINUE BATTLE AFTER SNAG and GET NEW
SNAG BALLS are Red/Blue/Yellow only, and on Gold the battle always
continues after a snag.

### Quest System is no longer required

It used to be a hard dependency: without it, Pokemon Snag refused to load at
all — no Snag Ball, no fences, no questline — for a mod that only supplies
the journal entry. Since Quest System is distributed as a loose file rather
than a release, the launcher could not fetch it for you, so a hand-installed
third-party mod was gating everything. It is optional now. Install it and
you get the journal entry; skip it and the questline plays identically.

### Red, Blue and Yellow

**Nothing about the Kanto story has changed.** Existing saves and existing
Snag Balls behave exactly as they did in v0.14.11. The one change that
crosses over is the 2-ball minimum at a fence, which applies on both games —
they share one valuation.

The mod also carries an MIT `LICENSE` now, which it never had, and the
README has screenshots of the Johto questline.

## 0.14.44 - Your contacts buy what you steal

- After paying out the Goldenrod contract, the broker now buys snagged
  Pokemon directly instead of sending you elsewhere.
- After paying the Ecruteak fee and handing over the HEIST BALL, the contact
  also becomes a fence with a colder, higher-level voice of their own.
- Both contacts use the same safe sale rules and payouts as the Route 36
  fence, including refusing your last Pokemon or a clean Pokemon and offering
  one recovery ball if you are completely stuck.
- Tidied three of the Route 36 fence's lines that ran past the width of the
  text box and were wrapping awkwardly. One of them only misbehaved for a
  Pokemon with a long nickname. Same words, better spacing.

## 0.14.43 - Groundwork: one sale flow, many fences

**Nothing changes in play.** This is preparation for letting the people who
hand out contracts also buy what you steal, and it deliberately ships on
its own so that "nothing changed" is a testable claim.

- The Route 36 fence's buy-and-pay routine is now a single shared routine
  that any number of fences can speak through. Each fence supplies only
  its own lines.
- The rules that protect you are in that one shared place: your last
  Pokemon is never sellable, the payment always lands before the Pokemon
  leaves your party, and the offer is re-checked after you confirm.
- Every fence is also a way out of a dead end, not just the Route 36 one.

## 0.14.42 - A fence never pays just one ball

Giving up a Pokemon is the most expensive thing you can do at a fence —
it leaves your party for good — and a single Snag Ball back could not
even repeat the throw that caught it.

- **No sale pays less than 2 Snag Balls.** The bonuses for level, rarity
  and a famous previous owner still stack on top exactly as before, so
  only the bottom rung moved: a level 45 rarity taken off a Gym Leader is
  still worth more than something common off a Youngster.
- Quest marks still floor at 3, so a contract target remains worth more
  than an ordinary theft.
- This applies on Red as well as Gold. Both games share one valuation.

Not addressed here, deliberately: snagging a healthy Pokemon is hard
enough that it invites reloading rather than spending. That is a separate
knob and it gets looked at on its own.

## 0.14.41 - Quest Pokemon are bounties now (Gold)

Contract targets were priced like any other stolen Pokemon, which meant
the first job — a level 16 YANMA — fenced for a single Snag Ball. A job
you chose, tracked across Goldenrod and spent balls on paid the same as
something grabbed in passing. And completing the Goldenrod contract paid
nothing at all: the broker congratulated you and that was it.

- A contract's advertised target is now a **bounty**: it fences for at
  least 3 Snag Balls, and the usual bonuses for level, rarity and a
  famous owner still stack on top, up to the cap of 5.
- Finishing a contract pays a flat **5 Snag Balls**. The Goldenrod broker
  pays it, and the Ecruteak contact pays it alongside the HEIST BALL.
- Other Pokemon on a mark's team are still fair game, but they are not
  the bounty — only the target you were sent for is.
- If a mark is already sitting in your party from an earlier version, the
  fence works out that it was a bounty and pays the new rate. You do not
  need to start over.

No change on Red.

## 0.14.40 - You can no longer run out of Snag Balls for good (Gold)

Reported from device play: on Gold, running out of Snag Balls ended the
questline permanently. Every ball came from a fixed list — one from the
Cherrygrove sailor, five from his reward, one HEIST BALL from Ecruteak —
and after that the Route 36 fence was the only source, but it pays you
for a *stolen* Pokemon, so it costs a ball to earn balls. Miss with your
last one while holding nothing stolen and there was no way back. Red has
marts as a safety net; Gold deliberately has no marts, so it had none.

- The Route 36 fence now hands you one SNAG BALL, free, when you turn up
  with no Snag Balls of any tier *and* nothing he would buy. He is not
  generous about it. Come back as often as you need.
- It only ever fires when you have absolutely nothing, so it cannot be
  used to stockpile — one ball, and only while you are stuck.
- Holding a HEIST BALL counts. You are not stuck if you can still throw
  something.
- The Cherrygrove sailor no longer empties your bag of Snag Balls before
  handing you the intro ball. That only ever mattered for the private
  test builds that stocked Gold marts, and on a save carried over from
  one of those it destroyed balls you had paid for.

No change on Red.

## 0.14.39 - Reconciliation into the repo

The Gold questline arc (0.14.14-0.14.38) was written outside git and is
committed here for the first time. Corrections made on intake:

- Removed a hard dependency on `shop_events` that no code referenced. Left
  in, the loader would have refused to start Pokemon Snag at all on any
  device without that mod installed — on Red as well as Gold — for zero
  functional gain.
- Fixed the version report on Red. 0.14.38 tried to fix a stale
  `mod.exports.version` by deleting it, but the replacement `VERSION` local
  lived inside the Gold arm, so a Red boot exported nothing: the load line
  read "Pokemon Snag nil loaded" and the wrap stamp that answers "which
  code is live" was stamped nil. `VERSION` is now declared once, above the
  generation split, and both arms report it.
- Fixed a crash-in-waiting on Gold: the error reporter `errs` was defined
  after the one function that calls it, so `snag.vip` hook failures would
  have thrown from the line meant to report them instead of showing up in
  [ERRS].
- Documented at the generation split that everything below it is Gen 1
  only. `gen2check` cannot see the early return and will report MK402/MK409
  against those lines on every release; they are unreachable on Gold.
- README: the Ecruteak reward is the HEIST BALL at 2x, not the GREAT SNAG
  BALL at 1.5x that 0.14.37 shipped; and Gold marts do not stock the SNAG
  BALL — the Gold questline is the only source.
- Added the MIT `LICENSE` file, which the repo never had.
- No gameplay change on Red. Existing saves and existing Snag Balls behave
  exactly as they did in v0.14.11.

## 0.14.38 - Tier brief reconciliation

- Fixed the stale end-of-file export that reported version 0.14.13 on newer builds.
- Unified Gold and Gen 1 fence valuation around one shared payout implementation.
- Replaced the experimental GREAT SNAG BALL from 0.14.37 with the brief-approved first tier, HEIST BALL.
- Base SNAG BALL remains unchanged at 1x catch reliability.
- HEIST BALL uses a 2x catch-rate multiplier on Gold and is awarded as the first Ecruteak upgrade reward.
- Gold trainer-snag eligibility and caught-Pokemon provenance now use the same `SNAG_BALL_TIERS` membership table.
- VAULT BALL, KINGPIN BALL, tier colors, and fence exchanges are intentionally deferred to later milestones.

## 0.14.37 - Ecruteak archetype contract + Great Snag Ball

- Added the second real Gold contract, unlocked after the Goldenrod target is successfully snagged.
- Ecruteak changes the choice from Pokemon type to trainer archetype/risk:
  - PERFORMER -> SMEARGLE
  - MYSTIC -> MISDREAVUS
  - COLLECTOR -> GIRAFARIG
- Each archetype has a different multi-Pokemon party and a different destination.
- Added neutral Ecruteak gossip based on unusual Pokedex behavior; the witness never acknowledges the Snag network.
- The advertised Pokemon must be snagged to complete the contract, but the player may also snag other Pokemon from the mark's party.
- KOing/defeating the mark without snagging the target keeps the contract active and re-arms the trainer for another attempt.
- Added GREAT SNAG BALL as a Gold custom ball reward. The first Ecruteak completion awards exactly one.
- GREAT SNAG BALL uses a 1.5x catch-rate boost, mirroring the Gen II Great Ball tier, and works with the existing trainer-snag continuation system.
- Initial calibration placements:
  - Ecruteak contact: ECRUTEAK_CITY (27,24), facing down
  - neutral witness: ECRUTEAK_CITY (16,23), facing down
  - Performer: DANCE_THEATER (1,10), facing down
  - Mystic: ECRUTEAK_CITY (7,8), facing down, near Burned Tower
  - Collector: ROUTE_38_ECRUTEAK_GATE (4,5), facing down

## 0.14.36 - Goldenrod witness placement

- Moved the neutral Goldenrod rumor witness to the user-calibrated position `GOLDENROD_CITY (8,24)`.
- Witness remains facing down.
- No quest, contract, target, or dialogue logic changed.

## 0.14.35 - Neutral Goldenrod rumor clue

- Added a neutral Goldenrod City witness NPC for the first choice contract.
- The witness never acknowledges the Snag job; the dialogue is ordinary gossip about a strange Pokemon sighting.
- NATU rumor: an odd little bird stared at the witness and could not properly fly, echoing its Gen II Pokedex behavior.
- AIPOM rumor: a Pokemon was seen hanging by its tail before following a man downstairs.
- YANMA rumor: something smashed a nearby window before a large bug headed toward the stairs, echoing its violent-wingbeat lore.
- Each rumor indirectly points toward the Goldenrod Underground.
- Initial witness calibration position: GOLDENROD_CITY (14,12), facing down.
- Every new dialogue page is limited to two lines and every line is checked against the 18-glyph target.

## 0.14.34 - Goldenrod broker placement

- Moved the Magnet Train Station broker one tile up to (4,12).
- Broker now faces down/south.
- Contract and clue logic otherwise unchanged.

## 0.14.33 - Calibrated Goldenrod contract locations

- Moved the Goldenrod broker to `GOLDENROD_MAGNET_TRAIN_STATION` at (4,13), facing left.
- Moved the selected contract trainer to `GOLDENROD_UNDERGROUND` at (2,19), facing down.
- Split broker and mark reconciliation/interaction logic across their two real maps.
- Contract choices and mechanics remain PSYCHIC/NATU, NORMAL/AIPOM, BUG/YANMA.

## 0.14.32 - Goldenrod choice contract

- Added the first real Gold Snag contract in Goldenrod City after the Cherrygrove intro reward.
- A broker offers three lead types through a three-item list: PSYCHIC (NATU), NORMAL (AIPOM), or BUG (YANMA).
- The chosen lead is durable and spawns one matching trainer mark in Goldenrod.
- Targets are Lv16 and use normal SNAG BALL catch odds; the Cherrygrove guaranteed-catch exception does not apply.
- Knocking out the target does not complete the contract; the mark is re-armed so the player can retry.
- Successfully snagging the chosen species completes the contract. The mark remains for brief aftermath dialogue until Goldenrod is left.
- Broker follow-up reinforces the keep-versus-fence choice and foreshadows better Snag Balls.
- Initial calibration coordinates: broker (10,9), mark (24,18).

## 0.14.31 - Dialogue and Route 36 fence placement

- Shortened the lass's Cherrygrove aftermath text so no line exceeds Gold's 18-glyph text width.
- The sailor now hints that more SNAG BALLs can be earned from a fence on Route 36 near SUDOWOODO.
- Moved the Route 36 fence four tiles right and one tile up, from (38,11) to (42,10).
- The fence now uses Gold's STANDING_UP movement so he faces north by default.

## 0.14.30 - Gold sailor dialogue pagination fix

- Reworked the Cherrygrove intro so every mod-authored dialogue command is a single Gold text page of at most two lines.
- Removed form-feed page chaining from the sailor/lass intro dialogue.
- Kept the quest, shiny Meowth battle, five-ball reward, VIP bookkeeping, and Route 36 fence logic unchanged.

## 0.14.29 - Route 36 fence test

- Adds the first Gold fence on Route 36 near Sudowoodo.
- Fence accepts only Pokemon marked `snagged == true`.
- Preserves the original 1-5 SNAG BALL payout formula using snag-time level, rarity, and persisted Gold VIP status.
- Refuses a trade that would empty the player's party.
- Quotes the payout and requires YES/NO confirmation before consuming the Pokemon.
- Pays first; if the BALL pocket cannot accept the reward, the Pokemon is kept.

## 0.14.28 - Gold VIP provenance compatibility

- Added a conservative Gold VIP list: both rival classes; all 16 Gym Leaders; Will, Koga, Bruno and Karen; Champion Lance; and Red.
- Gold trainer provenance is now captured from `world.trainer_engaged` and persisted onto snagged Pokemon.
- Added the `snag.vip` hook so other mods can designate their own custom trainer encounters as VIP without Pokemon Snag hardcoding their trainer ids.
- VIP status is stamped as `mon.snagVip` at catch time, making later fence value stable even if the source mod is disabled or changes.
- Preserved the 0.14.27 reward-safe sailor behavior.

## 0.14.27 - Reward-safe sailor cleanup

- The Cherrygrove sailor stays available until the five-SNAG-BALL reward is successfully claimed.
- Leaving town before collecting the reward no longer forfeits it; the sailor is restored on a later Cherrygrove visit.
- The lass can still clean up after leaving town once the intro battle is complete.

## 0.14.26 - Cherrygrove intro reward

- After successfully snagging the shiny Meowth, the sailor now gives a one-time reward of 5 SNAG BALLs when spoken to before leaving Cherrygrove.
- Persist the reward claim separately from quest completion so repeated dialogue cannot duplicate the five-ball payout.
- Keep the original Snag Quest fence economy as the model for the upcoming Gold fence implementation: stolen Pokemon only, with payout weighted by snag level, rarity, and trainer provenance.

## 0.14.25 - Cherrygrove aftermath dialogue

- Move the fixed Cherrygrove sailor one tile right to `(14, 11)`.
- After the intro snag battle, the sailor and lass now have dialogue while they remain in town.
- Preserve the confirmed battle rule: ordinary Balls are still blocked against the trainer Meowth; only the intro SNAG BALL receives the guaranteed-catch exception.

## 0.14.24 - Cherrygrove NPC placement and delayed cleanup
- Move the intro sailor seven tiles left and one tile up from the 0.14.23 calibration point: (20, 12) -> (13, 11).
- After the shiny Meowth is successfully snagged, keep both the sailor and the girl visible for the rest of the current Cherrygrove visit.
- Remove the completed intro NPCs only after the player enters another map; later Cherrygrove visits keep them gone.

## 0.14.23 - Fixed Cherrygrove sailor placement test
- Replace the entry-relative sailor spawn with a fixed guessed Cherrygrove City coordinate at (20, 12), so device feedback can tune the NPC by exact tile offsets.
- Leave the working 0.14.22 intro battle, one-ball guarantee, shiny Meowth, and 0.14.21 trainer-continuation behavior unchanged.

## 0.14.22 - Gold Cherrygrove intro quest test
- Add a Gold-only intro in Cherrygrove City: a sailor gives exactly one SNAG BALL and points the player at a little-girl trainer whose battle auto-engages through Gold's normal trainer sight logic.
- Replace that intro trainer's party with one real shiny Lv.5 MEOWTH using Gen 2 shiny DVs (14/10/10/10).
- Cheat the SNAG BALL rules only for this encounter: the single ball is guaranteed to catch the shiny MEOWTH. Normal trainer snagging keeps normal odds.
- Remove the private-test Gold mart stocking so the intro grants the only SNAG BALL for this quest milestone.
- Keep the proven 0.14.21 trainer-party continuation fix intact.

## 0.14.21 - Gold trainer continuation roster fix
- Gold private test: preserve the trainer party roster after a snag by replacing the stolen active mon with a zero-HP battle-only ghost instead of removing its slot. This lets `resolveFaints()` see the trainer's remaining healthy Pokemon and keeps prize-money calculation intact.
- Fixes the 0.14.20 symptom where a snag incorrectly produced EXP, an immediate trainer victory, and a $0 payout even when another trainer Pokemon remained.

## 0.14.20
- Gold private test: after a successful SNAG BALL capture in a trainer battle, continue through the trainer's remaining party instead of ending the battle as a wild catch.

## 0.14.19
- Gold private-test dev pricing is explicitly enabled by default ($1 SNAG BALL) because the current engine menu-settings issue can prevent changing the toggle reliably.

# 0.14.18 — Gold dev test

- Added a `DEV_CHEAP_SNAG_BALL` toggle to make the Gold SNAG BALL cost 1 for testing.
- Set it back to `false` to restore the normal 10,000 price.

# Changelog

All notable changes to Snag Quest are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com); the top heading always
matches the version in `manifest.json`.

## 0.14.13

### Changed

- **Quest System is now OPTIONAL.** It was a hard dependency with an
  `assert` at load, so the whole mod refused to start without it -- the
  Snag Ball, the fences, the questline, all of it -- for a mod that only
  supplies the JOURNAL ENTRY. Everything here runs on its own save flags;
  the journal is presentation. Without Quest System the questline now
  plays identically, you simply track it yourself.
- That mattered more than it looks. Quest System ships as a zip committed
  to FAFF0x/gen1recomp with no GitHub releases, so the launcher cannot
  auto-update it and it has to be fetched by hand. Making a
  hand-installed third-party mod a hard gate on everything here was the
  wrong trade.
- It is declared in `optional_dependencies` rather than dropped, because
  that STILL ORDERS THE LOAD -- `src/mods/Loader.lua` builds a dependency
  edge for optional specs too ("optional dependencies order without
  requiring anything"). So it is loaded before this mod whenever it is
  installed, and the lookup stays reliable at load time instead of having
  to wait for `game.ready`.
- The three journal calls now route through a shim that re-reads the
  export at call time and pcalls it. A missing mod, a missing function,
  or a future API change in someone else's mod degrades to "no journal
  entry" rather than taking the questline down.

### Verified

- **`modkit validate --strict` completes for the first time.** 0.14.12
  established that MK003 was structural -- modkit mounts exactly one mod,
  so a hard dependency can never resolve. With the dependency optional
  the loader runs the mod's code end to end under gen1recomp 0.1.77.
- The only findings are two `MK102 unresolved reference` errors, for
  `MEOWTH` and `OPP_JR_TRAINER_F`. Both are the known ROM-free-fixture
  artifact, not real: both ids are present in `tools/rom_manifest.json`
  AND `rom_manifest_yellow.json`, and this tree ships no imported cache
  to validate against instead. Checked rather than assumed.
- Compile, script-row validation and the dialogue audit re-run clean.

### Docs

- README Installation and Compatibility, `mod.card` and the manifest
  description all now describe Quest System as optional and say exactly
  what is lost without it.

## 0.14.12

### Docs

- **The README named a required dependency with no way to get it.**
  `quest_system` is a hard dependency -- the manifest declares it and the
  mod asserts on it at load, so Pokemon Snag simply will not run without
  it -- but both places the README mentioned it were bare text while every
  optional mod beside them was a link. A new player had no path to it.
  Raised by the cross-repo checker agent.
- It ships from **[FAFF0x/gen1recomp](https://github.com/FAFF0x/gen1recomp)**,
  as `quest_system_v<version>.zip` committed at the repo root. That repo
  publishes no GitHub Releases, so the README deliberately points at the
  file list and the filename pattern rather than pinning a version or a
  releases page -- and says plainly that the launcher's auto-update does
  not cover it. Installation and Compatibility both updated, and
  `mod.card` now names the source too, since that renders in the mod
  manager.

### Verified against gen1recomp 0.1.77

- Engine 0.1.77 changes nothing this mod depends on. Checked function by
  function rather than by file, since several files changed for unrelated
  reasons:
  - `BattleState.throwBall`, `newTrainer`, `storeCaughtMon` and `onFaint`
    are byte-identical. That matters most for `throwBall`, whose
    wild-catch body this mod reproduces verbatim to reach it in a trainer
    battle -- a silent change there would have been the dangerous kind.
  - `TextBox.paginate` and `TextBox:beginLine` identical, so the two-row
    behaviour the dialogue is authored against still holds.
  - `Commands.show_text` / `ask` / `give_item`, and
    `OverworldState.showMapText` / `talkTo` identical.
  - The vanilla scripts this mod delegates to or takes over are
    identical: `ROUTE_24` (the recruiter's own dialogue, reached through
    base_talk), `VERMILION_CITY` (the sailor, including the S.S. ANNE
    step trigger) and `ROUTE_25` (Bill hiding the recruiter).
  - `MapScripts`, `ScriptRunner`, `Stats`, `Badges`, `Data`, `Runtime`,
    `Screens` and the Game Corner / Pewter flavor scripts are unchanged
    files outright.
- What did change nearby is additive and irrelevant here: a
  `battle.bottom_ui_visible` hook, per-category game speed flags, A/B
  press sounds in the battle menus, data-driven item effects, and
  optional sprite-sheet geometry fields in the mod schema.
- `game_version` stays `>=0.1.38 <2.0.0`, which 0.1.77 satisfies. No
  manifest change needed.

### Closed a long-standing open item

- **`modkit validate --strict` cannot pass for this mod, and now we know
  why.** It has been recorded for months as an environment problem --
  "put snag_quest and quest_system in mods/ and it should work". It
  cannot: `run_loader` in `tools/modkit.py` mounts exactly ONE mod,
  building a virtual file table from that directory alone, so a sibling
  mod on disk is never visible to the loader. `MK003 missing dependency`
  is therefore structural for any mod with a hard dependency, not a
  missing install.
- Confirmed by validating a copy with the dependency list emptied: it
  gets past MK003 and stops at this mod's own
  `assert(mod.find("quest_system"), "Quest System is required")`. So the
  headless validator can never run this mod's code as long as that
  assert stands.
- `lint` still passes and is unaffected. Script rows are validated
  instead against the engine's own `ScriptRunner.validate`, and dialogue
  against `TextBox.paginate`, both run directly against 0.1.77 for this
  release.

## 0.14.11

### Updating from 0.11.7?

That is the last version that was published, so everything below is new
to you.

**The questline starts somewhere else now** -- **trikus's** idea, from
the gen1recomp Discord: rather than invent a character to hand out the
quest, use the Team Rocket grunt who already asks whether you want to
join, and let saying yes mean something.

It used to be the girl in Viridian City. It is now the **TEAM ROCKET
recruiter at the end of Nugget Bridge** on Route 24 -- the one who offers you the Nugget and asks
if you want to join. Beat him, then talk to him again and the offer
becomes real. Viridian City is untouched by this mod again; that girl is
back to her ordinary self.

If Bill has already sent you on your way, that recruiter is gone from the
map -- that is normal Gen 1 behaviour, not a bug. A Team Rocket grunt now
stands in his spot instead so the questline is never locked out.

**Your save is fine either way.** A quest already started or finished
under the old opening carries over: the recruiter picks up wherever you
left off, and finished quests stay finished.

**Four fences instead of two.** They buy snagged Pokemon for Snag Balls:

- the **Nugget Bridge recruiter** himself, once you have done his job
- the **Celadon Game Corner** gambler
- the **Pewter City** man in the Nidoran house (Boulder Badge)
- the **Vermilion City** sailor at the S.S. Anne gangway (Thunder Badge)

They are deliberately not one organisation. Two are Rocket, two are
independents who just like what falls off the back of a truck, and they
all have their own opinion of you. Their dialogue has been rewritten to
match.

**Turning in MEOWTH now pays 5 Snag Balls**, up from 1. One was too
tight: every snag after the quest rolls ordinary catch odds, so a single
ball was one failed throw away from having none. Five is a starting
float, not a stockpile -- you will still want the fences.

**Fixes you will notice:**

- The Pewter fence said nothing at all before you had the Boulder Badge.
  He now gives his ordinary line, like everyone else behind a gate.
- Dialogue no longer scrolls lines away before you can read them.
- The quest journal pointed at Viridian City and at an NPC that Bill
  removes. Both corrected.

All of this works on Red, Blue and Yellow.

### Also in this version

- The quest journal marker now follows the recruiter after Bill removes
  the original. It only ever pointed at the vanilla NPC, so once he was
  gone the marker pointed at nobody -- which is the situation every
  player ends up in eventually.
- Corrected this entry's own claim that the turn-in used to pay nothing.
  That was true only of unreleased test builds; v0.11.7 paid 1.

## 0.14.8

- TEST VERSION, not for release.

### Fixed

- **Restored `mon.shiny` on the quest MEOWTH.** 0.14.6 removed it and the
  MEOWTH lost its shiny colours on device -- the name marker still drew,
  so detection was fine, but the recolour never baked. Reported with the
  Shiny Pokemon mod's own settings confirmed correct (SHINY ON, SHINY
  COLORS ON, SHINY INTRO ON), so this was a regression here, not a
  misconfiguration.
- 0.14.6's reasoning was half right and its conclusion was wrong.
  `mon.shiny` genuinely is not an engine field -- nothing in the engine's
  `src/` or `data/` reads or writes it, and the engine's own truth is
  `Stats.isShiny(mon.dvs)`. But not-engine-native does not mean private.
  Their detector READS it off arbitrary Pokemon --
  `isShinyMon(mon) = mon.shiny or Stats.isShiny(mon.dvs)` -- which makes
  it part of that mod's **input contract**, the supported way for another
  mod to say "this one is shiny", not internal state to keep out of.
- The distinction that actually matters, and the rule this mod follows
  now: write engine-native truth (`mon.dvs`/`stats`/`hp`), write the
  input marker other mods read (`mon.shiny`), call published exports
  (`makeShinyDVs`) -- and never write battler-scoped internals
  (`battler.shiny`, `battler._shinySpriteApplied`) that only their own
  code maintains. 0.14.6's refusal to patch around their missing
  `newTrainer` path still stands.

### Docs

- Removed the FAQ entry about a stray square during the Meowth fight. It
  was a conflict with an unrelated mod, already fixed by that mod's
  author, and never involved this mod -- no reason to carry a
  troubleshooting entry for something resolved between releases.
- README's Shiny Pokemon note corrected: it claimed this mod never writes
  any of that mod's fields, which is no longer true and was the wrong
  framing anyway. It now just records that the marker and the recolour
  are separate options.

## 0.14.7

- TEST VERSION, not for release.

### Fixed

- **The intro quest paid nothing.** `QUEST_REWARD_BALLS` was declared and
  then never used -- neither success branch had a `give_item` row -- so
  turning MEOWTH in awarded **zero** SNAG BALLs, not the one the constant
  claimed. The quest ball is spent on MEOWTH, so the quest ended with an
  empty bag: nothing to snag with, and no route to a fence either, since
  fences only pay for snagged Pokemon. The mod's entire loop was
  unreachable without first buying a 10,000 ball. NOTE: this only ever
  existed in unreleased versions -- v0.11.7, the last public release,
  paid its reward correctly. The give_item row was dropped during the
  0.13.x questline rewrite, so no player outside these test builds was
  ever affected.
- The dialogue made it worse by saying *"Keep the spare BALL"* about a
  ball that had already been spent. Rewritten on both the vanilla
  recruiter and the post-BILL stand-in.

### Changed

- **The turn-in reward is now 5 SNAG BALLs**, handed over with the new
  line. Deliberately a starting float rather than a stockpile: every snag
  after the quest rolls normal catch odds -- `snagAttempt` just calls
  `ctx.vanillaAttempt`, and the guaranteed catch is scoped to this quest's
  own trainer class and species -- so one ball would be a single failed
  roll from stuck again. Five is still tight enough that the fences and
  the marts matter.
- Quest journal reward line updated to match.

### Docs

- FAQ, `mod.card` and the journal entry all said one ball. Corrected.
- **FAQ troubleshooting entry for the battle artifact rewritten -- the
  previous one was wrong.** It blamed the Shiny Pokemon mod. The artifact
  was actually a conflict with an unrelated mod (Blackjack Corner), found
  by the developer bisecting the mod list, and has since been fixed by
  that mod's author. Nothing in this mod changed. The entry now leads
  with the bisect method instead of naming a suspect, since that is what
  actually found it.
- Added a note that the Shiny Pokemon mod's marker and recolour are
  separate options: a Meowth showing the marker but the wrong colour
  means that mod's SHINY COLORS toggle is off, not a fault here.

## 0.14.6

- TEST VERSION, not for release. One change: this mod no longer writes a
  field belonging to another author's mod.

### Changed

- **Stopped setting `mon.shiny`.** Shininess is engine-native --
  `Stats.isShiny(mon.dvs)`, defense/speed/special == 10 with attack in a
  fixed set -- and the DVs this mod assigns to the quest MEOWTH already
  satisfy it. `mon.shiny` is **not an engine field at all**: nothing in
  the engine's `src/` or `data/` reads or writes it. It belongs entirely
  to the Shiny Pokemon mod (`SHINY_POKEMON`) as a cache flag.
- Writing it was this mod reaching across a **cross-author boundary**.
  Ownership between this project's own mods can be declared and honoured
  through `mod.exports.owns`; with a third-party mod none of that
  applies -- we cannot declare on their behalf and their internals may
  change in any release. The correct posture, already used with
  `pokeball_colors`, is: write engine-native state, call their published
  exports, let them derive the rest. `exports.makeShinyDVs` is still used
  when that mod is present.
- It was also actively unhelpful, not merely impolite. Their detector is
  `isShinyMon(mon) = mon.shiny or Stats.isShiny(mon.dvs)`, and their
  `ensureShinyBattler` sets the pair together -- `battler.mon.shiny` AND
  `battler.shiny`. Pre-setting only `mon.shiny` handed them a half-set
  state: mon flagged, battler never marked. Setting only the DVs lets
  their own code detect the MEOWTH and mark both halves in its own order.

### Open: the square artifact in the MEOWTH fight

- Diagnosed against SHINY_POKEMON 1.0.8, not guessed. That mod wraps
  `Pokemon.new` and `BattleState.newWild` but **never `newTrainer`**. Its
  wild path carries an explicit late-shiny fixup --
  `result.enemy._shinySpriteApplied = false; result.enemy.shiny = true` --
  precisely because a Pokemon can become shiny after its battler was
  built. There is no trainer equivalent, because a trainer's Pokemon
  being shiny is a case that mod was never written for. This mod is the
  only thing that creates it, which matches the report exactly: the
  artifact appears for this fight and for no other shiny.
- The colours still work because `syncBattleShinies` re-bakes every frame
  from a `drawPicsLayer` wrap; only the one-shot/HUD decorations are left
  half-set.
- This version may or may not resolve it -- it removes the half-set state
  this mod was contributing, which is worth testing, but the missing
  `newTrainer` path is theirs. Two option flips narrow it with no build:
  turning off their SHINY INTRO toggle separates the sparkle FX from the
  name-star drawing, and disabling Dramatic Shape separates the voxel
  `snapHUDs` star path from the plain overlay one.
- Deliberately NOT worked around by resetting `_shinySpriteApplied` or
  `battler.shiny` from here. That would be writing their private fields
  to patch their bug -- the same mistake this version is undoing.

## 0.14.5

- TEST VERSION, not for release. A dialogue presentation pass plus one
  new line. **No wording was changed anywhere** -- verified mechanically,
  see below.

### Fixed

- **Dialogue was losing lines off the top of the box.** The text box holds
  exactly two rows: `TextBox:beginLine()` drops the oldest line once two
  are already showing, and `draw` keeps only two row positions. A third
  line on a page therefore discards the first. Whether that is polite depends on the separator --
  a line introduced by `\v` prints the arrow and waits for A first, a
  line introduced by `\n` just scrolls. Unprompted, it reads on screen as
  the previous line repeating itself.
- 37 pages of this mod's dialogue did that, including the intro mission
  briefing (a 10-row page) and text added in 0.14.0. All are fixed by
  changing the separator before row 3+ from `\n` to `\v`. Every authored
  line break is preserved.
- A second cause was easy to miss: an authored line wider than 18 columns
  is soft-wrapped into extra rows that inherit no continuation marker, so
  a page can bust the two-row budget while looking like two lines in the
  source. Those lines are re-wrapped -- again without changing words.
- One string is deliberately left alone: `"All right!\n%s was\ncaught!"`
  is the engine's own wild-catch message, reproduced verbatim so a snag
  reads like a normal catch. Vanilla's own page is three rows and
  matching vanilla wins here.
- **Verification:** the word stream of every dialogue literal was compared
  before and after -- identical. The pagination audit goes from 37
  offending pages to 1 (the vanilla-copy above).

### Added

- The pre-BILL recruiter now signs off with *"One more thing. My bridge
  shift is done... I can finally get out of these civilian clothes.
  You'll know me when you see me."* -- said once, after the mission is
  turned in.
  Reported from the first pre-BILL playthrough: the quest-giver never
  looks like a TEAM ROCKET grunt, and the change of appearance after BILL
  removes him reads as a different NPC appearing rather than the same man
  in uniform. This is on the VANILLA recruiter only -- it is the last
  thing he says before BILL removes him for good, so the grunt standing
  in his spot afterwards pays it off. It cannot go on the stand-in, whose
  own lines are written as a different grunt anyway.

### Not fixed, on purpose

- The vanilla recruiter's own pre-battle lines still appear to repeat.
  **Confirmed this build cycle with every mod disabled** -- it is engine
  text (`data/scripts/story4.lua`) hitting the exact two-row behaviour
  above, three `\n` lines on one page. Nothing this mod can fix; it
  belongs upstream in gen1recomp.

### Corrected

- 0.14.4 claimed "all 29 of this mod's own dialogue strings were checked
  against `TextBox.paginate` and pass". That was wrong. The check shelled
  out per string and the string never reached the interpreter, so it was
  validating empty input and could not fail. The rebuilt check reports
  known-bad strings as bad before it is trusted, and DEVELOPMENT.md now
  says so.

## 0.14.4

- TEST VERSION, not for release. **Documentation only -- no code or
  behaviour change.** Records what the first pre-BILL playthrough turned
  up. Nothing here needs re-testing in game.

### Not our bugs (both confirmed against engine source)

- **The recruiter's vanilla lines appear to repeat before the battle.**
  Engine text, passed through untouched. `data/scripts/story4.lua` builds
  the page `"Congratulations!\nYou beat our 5\ncontest trainers!"` --
  three lines, joined with `\n`, in a box that shows two. Running that
  exact string through the engine's own `TextBox.paginate` returns one
  page of 3 lines with `contBefore` false on all of them, so the third
  scrolls in unprompted and reads as the previous line repeating.
  Reproducible with this mod disabled; belongs upstream.
- **Stray square artifact during the Meowth fight.** The Shiny Pokemon
  mod's. This mod sets the shiny DVs (data, engine-native) and draws
  nothing whatsoever; the engine has no shiny visuals of its own. The
  marker beside the name and the sparkles are both that mod's. Disabling
  it leaves the MEOWTH just as shiny, undecorated -- which is also how to
  confirm the source of any artifact around a shiny.

### Working as designed

- **The quest-giver doesn't look like a TEAM ROCKET grunt pre-BILL.**
  Correct. Pre-BILL he is the untouched vanilla NPC and this mod does not
  change sprites -- and vanilla already gives that object
  `trainerClass = OPP_ROCKET`, so he fights as a Rocket while looking
  like a Cooltrainer. After BILL hides him, the stand-in this mod spawns
  probes for `SPRITE_ROCKET` (confirmed present in the engine's sprite
  table) and does look the part. The two therefore differ on purpose, and
  the stand-in's dialogue is written as a different grunt who has been
  watching, not as the same man.

### Docs

- README, FAQ and `mod.card` now state the Shiny Pokemon division of
  labour explicitly: **this mod supplies the data, that mod supplies the
  picture.** Added to Compatibility, with the disable-to-confirm step.
- FAQ gained troubleshooting entries for both artifacts above.
- DEVELOPMENT.md gained a "Writing dialogue: the two-row rule" section --
  18 columns, two rows, and the rule that any line past row 2 on a page
  must be introduced with `\v` rather than `\n`, or it scrolls
  unprompted and looks like a repeat. All 29 of this mod's own dialogue
  strings were checked against `TextBox.paginate` and pass.

## 0.14.3

- TEST VERSION, not for release. Clean-up pass: the 0.14.2 diagnostics
  come out, the docs catch up with the 0.13.x redesign, and the Yellow
  question is closed.

### Removed

- All 0.14.2 diagnostics: the `snag_quest:probe` command and its rows on
  every fence script, and the `load v<version>` stamp on boot. Nothing
  writes to [ERRS] any more. They did their job -- the probe line
  `f=n` on all five NPCs is what identified the cause in one round.

### Fixed

- The `base_talk` fallback could print a raw `TEXT_` constant into a
  dialogue box. `Commands.show_text`'s last resort is to print whatever
  string it was handed, which is right for the hand-ported scripts that
  pass literal dialogue but wrong here, where it is handed a constant.
  It now resolves first and stays silent if nothing resolves, which is
  what `showMapText`'s own miss path does.

### Verified

- **Yellow: closed, no rename.** Every NPC this mod takes over was
  checked against the engine's own symbol tables
  (`tools/rom_manifest.json` and `tools/rom_manifest_yellow.json`).
  `maps.VERMILION_CITY.objects` carries
  `{ name = "VERMILIONCITY_SAILOR1", text = "TEXT_VERMILIONCITY_SAILOR1" }`
  in BOTH, so the new fence needs no second constant. The same pass
  re-confirmed the Route 24 recruiter (never previously checked for
  Yellow) and the Pewter man as identical, and the Game Corner
  coin-giver as genuinely renamed -- which is why that one alone
  registers two constants. All six mart clerk constants match too.
- **Team Rocket Returns does not conflict.** Tested on device with both
  mods enabled: this mod's dialogue wins normally on every fence.

### Corrected

- 0.14.2's entry claimed the 0.14.1 badge fix "was not the cause". That
  is very likely wrong and is withdrawn. With the source option set to
  `MART` the gate closes at row 2 and `check_badge` never runs at all,
  so the observations that looked like they cleared it never exercised
  it. The most probable sequence is: the first PEWTER test ran while the
  option was still `BOTH`, `check_badge` threw on a non-numeric badge
  value, and the [ERRS] check that came back empty happened after a
  relaunch -- `Runtime.errors` is rebuilt per boot, so the evidence was
  already gone. Marked as inferred, not proven: distinguishing a stored
  `true` from `1` was not worth another device round, and the truthiness
  check is correct either way.

### Docs

- README, FAQ and `mod.card` rewritten for the Nugget Bridge opening and
  the four fences. They had still described the pre-0.13 Viridian
  ("Jessie") opening and two fences.
- All three now document the NPC-takeover conflict rule: only one mod's
  dialogue can win for a given character and the loser's silently never
  runs. The FAQ's troubleshooting entry now leads with the actual most
  common cause -- GET NEW SNAG BALLS set to `MART`, which closes every
  fence by design and makes them look broken.

## 0.14.2

- TEST VERSION, not for release. **DIAGNOSTIC BUILD.** It adds no
  features and fixes nothing new -- it exists to make the fence failure
  visible on a device with no console. The probe rows and the load stamp
  are marked in code and must be removed before release.
- What 0.14.1 established: all three `registerMerchant` fences (CELADON,
  PEWTER, VERMILION) do nothing on device and write NO entry to [ERRS],
  while the Nugget Bridge recruiter -- the one fence that does not go
  through `registerMerchant` -- works. No [ERRS] entry means nothing is
  throwing, which rules out the swallowed-script-error family.
- Running the exact registered rows through the engine's real
  ScriptRunner off device shows all three fences taking the fence path
  and building their intro text box correctly, with a trace identical to
  the recruiter's. So the script rows, the gate commands and the badge
  check are all doing the right thing. The difference is not in the
  rows, which means it is in dispatch (the talk never reaches our
  script) or in save state.
- **Added: `snag_quest:probe`,** the first row of every fence script. It
  writes one line to [ERRS] through `Runtime.reportError`, the only
  output channel that exists on iOS:
  `snag_quest: PEW qY fY bY tnil`
  - tag: `CEL` / `PEW` / `VER` / `R24` / `STD`
  - `q` questDoneForReal, `f` fences enabled, `b` badge held (`-` if the
    fence is ungated), `t` the vanilla handler's type (`fun`/`tab`/`nil`)
  - **No line at all for an NPC is itself the answer:** the talk never
    reached this mod, so the TEXT_ constant does not match that NPC on
    that game version, or something outranks our registration.
- **Added: a load stamp** -- `snag_quest: load v0.14.2` in [ERRS] on
  boot. `mod.log:info` goes to a console that does not exist on iOS, so
  until now "is the new build actually live?" was unanswerable on
  device. It is the first line to check for every future test.
- The 0.14.1 badge fix is kept. It was not the cause, but
  `(inv[badgeId] or 0) > 0` was still the only numeric badge test in the
  mod or the engine and a latent throw site.

## 0.14.1

- TEST VERSION, not for release. ONE change from 0.14.0, so the next
  device test isolates it.
- **Fixes both badge-gated fences saying nothing at all.** Reported on
  0.14.0: the PEWTER man turns to face you and no text box appears, and
  the VERMILION sailor shows no fence dialogue -- while the CELADON
  gambler and the Nugget Bridge recruiter, the two fences with NO badge
  gate, work. That split is a single script row: `snag_quest:check_badge`
  is the only command the failing scripts run that the working ones
  don't, and it runs before their first text row.
- Cause: the check read `(inv[badgeId] or 0) > 0`, which assumes the
  stored badge value is a number. If it is anything else, `> 0` raises
  "attempt to compare <type> with number", the script runner swallows
  it, and the talk aborts before printing anything -- the classic
  face-the-player-and-say-nothing signature. It now tests truthiness,
  which is what every badge check in the engine does
  (src/inventory/Badges.lua's Badges.count, OverworldController:1561 and
  :2067, data/scripts/flavor/viridian_city.lua). This mod was the only
  place comparing numerically.
- PRE-EXISTING, not from the 0.14.0 fence work: this row is unchanged
  since the PEWTER fence was added. It most likely means that fence has
  never worked post-BOULDERBADGE, and the failure being silent is why it
  went unnoticed.
- If a fence is STILL silent on this build, the real error is already
  being written to the mod manager's [ERRS] screen --
  `ScriptRunner:resume` reports swallowed script errors through
  `Runtime.reportError` under this mod's id.

## 0.14.0

- TEST VERSION, not for release. Reworks who buys stolen Pokemon: the
  fences go from three to four, and the Nugget Bridge recruiter becomes
  one of them.

### Fences

- **Cut the Cerulean grunt entirely.** The mod-spawned Rocket in
  CERULEAN_CITY, his dialogue and his CASCADEBADGE-gated merchant
  registration are gone. His position (cell 32,17) had been verified in
  game and he worked -- this is a design cut, not a bug fix. The Nugget
  Bridge recruiter replaces him, and one fewer spawned NPC is one fewer
  thing that can fail silently. The Route 24 stand-in still spawns and
  still uses the shared sprite-probing helper.
- **The Nugget Bridge recruiter is now a fence.** No badge gate --
  finishing the first job is the credential, and it already lands later
  than CASCADEBADGE in practice. Standard payout, no VIP bonus of his
  own. He buys in BOTH of his forms (the vanilla NPC pre-BILL and this
  mod's stand-in after BILL hides him), because they are the same
  character and which one you meet is an accident of progress.
- His post-quest hint pointing at the CELADON gambler is gone rather
  than kept alongside: with him buying, sending the player to another
  city to sell was redundant. The MART hint still stands in when the
  GET NEW SNAG BALLS option has fences switched off, so that branch
  never points at a closed door.
- **New fourth fence: the VERMILION CITY sailor** guarding the S.S.
  ANNE gangway (TEXT_VERMILIONCITY_SAILOR1), gated on the
  THUNDERBADGE. Verified against engine source before writing: his
  `onStep` ticket check at cell (18,30) is a separate hook from his
  `talk` entry and is untouched, so boarding the ship still works
  pre-departure; and the engine's own comment that "the sailor himself
  never hides" still reads true, so he persists as a permanent fence
  after the ship sails.
  - **TODO/CONFIRM (Yellow):** the text constant is the Red/Blue name
    and has NOT been verified on a Yellow save. Yellow renames objects
    per map, so this needs reading off a running Yellow game with the
    NPC Inspector before it ships.

### Fixed

- **`base_talk` only ever handled one of the three shapes a vanilla
  talk can take.** A talk entry can be a Lua handler, a row list, or
  absent entirely (confirmed from OverworldState:showMapText). It
  handled the handler case; a row list was called as if it were a
  function, and an absent entry returned with no text at all. Both
  failures look identical in game -- the NPC turns to face you and says
  nothing. This mattered immediately, because the Vermilion sailor's
  base talk is a row list, and it had been silently eating the PEWTER
  man's vanilla line for every player who had not yet earned the
  BOULDERBADGE. All three shapes are handled now.
- The quest journal's in-progress objective still read "Bring a MEOWTH
  back to the girl in Viridian City" -- left over from the pre-0.13.0
  opening and wrong since. It now names the Nugget Bridge recruiter.

### Internal

- The fence transaction is factored into shared script rows so the
  recruiter can use it without going through `registerMerchant`. He
  can't: he already owns a talk entry for his own text constant, and
  two contributions for one map + constant do not merge -- MapScripts
  picks a single winner per constant and drops the loser silently. The
  rows are shared instead of the registration, with per-copy label
  suffixes so two copies can coexist in one script.
- All six registered talk scripts were run through the engine's own
  `ScriptRunner.validate`: every command resolves, every jump target
  has a matching label, no duplicate labels.

### Known stale

- README, FAQ and `mod.card` still describe the pre-0.13 Jessie opening
  and say there are two fences. Deliberately left for a docs pass once
  this design is confirmed to stick.

## 0.13.1

- TEST VERSION. Fixes the recruiter being missing entirely on an
  established save.
- Cause, confirmed from data/scripts/story.lua: the vanilla recruiter
  is NOT removed by beating him -- he stays and laments his dreams of
  Team Rocket. BILL removes him. Leaving Bill's house with the S.S.
  Ticket sets EVENT_LEFT_BILLS_HOUSE_AFTER_HELPING, which hides
  ROUTE24_COOLTRAINER_M1 permanently. That's vanilla Gen 1 behaviour
  and unrelated to the battle. (0.13.0 was built on the assumption he
  sticks around, which was wrong.)
- Once that flag is set, this mod now spawns its own Rocket in his
  vanilla spot (ROUTE_24, cell 10,14) with its own text key, and keeps
  him there permanently -- mission giver, turn-in, post-quest hint,
  and a natural home for a future fence.
- The stand-in deliberately does NOT require beating the recruiter:
  by then that fight is either already done or impossible, since he
  has no trainer header and sight never engages him, so he can be
  walked past entirely.
- The two never coexist: the stand-in only appears once vanilla has
  hidden its own copy, so the original keeps its nugget and battle.
- Position (10,14) is derived from story4.lua's onStep, which triggers
  when the player stands on (10,15) "in front of the recruiter" --
  worth confirming in game.

## 0.13.0

- TEST VERSION, not for release. Replaced the quest opening: the intro
  is no longer given by the girl in Viridian City. She reverts to
  fully vanilla and this mod no longer touches VIRIDIAN_CITY at all.
- The questline now starts with the TEAM ROCKET recruiter at the end
  of NUGGET BRIDGE (ROUTE_24 / TEXT_ROUTE24_COOLTRAINER_M1). Beat him,
  and he offers you the job for real -- your first mission from the
  boss. He is also the turn-in and the post-quest hint.
- Everything before the battle stays vanilla, reached through
  base_talk: the NUGGET, the recruitment pitch, the fight. Only his
  POST-DEFEAT line is taken over, which vanilla spends on one lament
  about his dreams of Team Rocket.
- Declining is safe: confirmed from data/scripts/story4.lua that he
  stays talkable forever once beaten (the battleOrDone branch), so the
  offer stays open. Come back and talk to him again.
- Note on the vanilla ask: the base game's "would you like to join
  TEAM ROCKET?" IGNORES the answer -- it replies "Arrgh! You are not
  convinced?" either way. So the real choice is now the one after the
  battle, which also fits "beat him first" better than hooking the
  vanilla prompt would have.
- The Picnicker, the guaranteed shiny MEOWTH, the one-ball-in /
  one-ball-out economy and all three fences are unchanged.
- Save flags are deliberately REUSED (MOD_SNAG_QUEST_GIRL_STARTED /
  _DONE) so an in-progress save keeps its state while this is being
  tried out. Worth renaming if this sticks.

## 0.12.1

- Testing only, not for release. Moved the Cerulean Rocket 2 cells
  right, 2 cells down: (30,15) -> (32,17).

## 0.12.0

- New fence in **Cerulean City**: a Team Rocket grunt loitering near the
  robbed house. Gated on the quest, the CASCADEBADGE, and the fence
  supply option, same as the others.
- This is the first NPC this mod CREATES rather than takes over.
  Spawned with mod.world:spawnNpc, so its text key is ours
  (TEXT_SNAG_CERULEAN_ROCKET) -- no ROM constant to look up and no
  Red/Blue-vs-Yellow rename risk for this one.
- Runtime spawn rather than a maps:patch, deliberately: a rejected map
  record silently disables the WHOLE mod while the manager still shows
  it Ready, so patching vanilla map data is the riskiest option here.
  Runtime objects are also trivially repositionable while the exact
  spot is still being worked out.
- He stands still (movement = "STAY") for now.
- Handled two documented traps: runtime objects aren't serialized and
  map.entered is skipped on a save restore, so the spawn runs from BOTH
  map.entered and game.ready; and errors inside event handlers are
  swallowed whole, so the spawn is wrapped in pcall.
- The sprite id is probed against game.data.sprites rather than
  hardcoded -- an unknown sprite makes NPC.new assert, and that assert
  is swallowed inside a handler, producing an invisible NPC with no
  error anywhere.
- registerMerchant gained a `fallback` line, used when a merchant is
  mod-spawned and so has no vanilla dialogue to fall back to.

**Position is a first guess** (cell 30,15). Map grids aren't readable
from the engine repo, so expect to nudge it.

## 0.11.7

- Releases are now fully automatic: bump `version` in `manifest.json`,
  commit to main, and CI tags it, builds the zip and publishes the
  release. No Releases form, no hand-attached asset. Idempotent -- an
  ordinary docs commit does nothing, because the tag check
  short-circuits it.
- Release notes are generated from that version's CHANGELOG section and
  now include install steps and a **SHA-256 checksum** of the archive.
- Cross-linked the actual repos for kanto_ribbons, Shiny Pokemon,
  Pokeball Colors and NPC Inspector in the compatibility list, instead
  of naming them as plain text.
- Documented the release process in DEVELOPMENT.md.
- Approach adapted from ArmstrongThomas/gen1-modern-ui, which releases
  on manifest version change rather than on a manually created tag.

## 0.11.6

- Presentation only, no behaviour change. Led with the actual hook --
  stealing Pokemon from other trainers -- rather than describing the
  questline first:
  - README title is now "Pokemon Snag - Steal Pokemon from Trainers",
    and the opening line says what the mod does in one sentence.
  - manifest description and mod.card summary rewritten to match. The
    manifest one is what shows in the in-game mod manager, so it was
    the most valuable place to fix.
- The in-game mod NAME stays "Pokemon Snag" -- a tagline belongs on a
  repo page, not in a menu list.

## 0.11.5

- Future-proofing for coexistence with pokeball_colors, so the two mods
  stop needing to coordinate by hand:
  - `mod.exports.owns` now declares what this mod owns (the whole
    SNAG_BALL record: registration, attempt, tossAnim, flicker; plus the
    mon.snagged/snagFrom/snagLevel fields) so another mod can check at
    runtime rather than relying on a handoff note.
  - `mod.exports.ballColors` carries this mod's own Team Rocket palette,
    and on game.ready it registers itself into pokeball_colors'
    `exports.colors` table -- but only if that key is absent, so a
    colour that mod deliberately ships still wins.
- This inverts the dependency: pokeball_colors currently hardcodes a
  SNAG_BALL entry, which means renaming, recolouring or adding a second
  ball here forces a change there. With this, it doesn't -- and that
  mod can drop its hardcoded entry whenever it likes, with no
  coordination and no flag day.
- Registered on game.ready rather than at load, because mod.find can't
  see a mod that hasn't loaded yet and load order between two
  independent mods isn't guaranteed either way.
- Trimmed the pokeball_colors note in the README and mod.card down to
  one line. Implementation detail (which colour fields, which colour
  mode, who owns tossAnim) belongs in DEVELOPMENT.md, not in docs a
  player reads.

## 0.11.4

- Added `"github": "mistermiracle3036/Pokemon-Snag"` to the manifest,
  enabling the launcher's in-app update check. Confirmed a real field
  from src/mods/Manifest.lua ("Optional GitHub repo for launcher
  auto-update"; accepts owner/repo or a github.com URL).
- Release assets are now named `snag_quest-<version>.zip`. That's the
  exact name the updater looks for first -- ModUpdate.pickZipAsset
  tries `<id>-<version>.zip`, then any `<id>*.zip`, then the first zip
  in the release. Note it keys off the MOD ID, not the repo name; those
  differ here (repo `Pokemon-Snag`, id `snag_quest`).
- The release workflow builds that name automatically, and now also
  warns if the manifest ever loses its `github` field -- that failure
  is invisible otherwise, since updates simply never appear.
- Fixed a stale manifest description: it still described a "Rocket
  grunt" swiping the Meowth and called the quest "Grandpas Meowth".
- Listed `pokeball_colors` as an optional dependency.

## 0.11.3

- The quest is now titled **Introduction to Thievery** in the Quest
  System journal (was "Grandpa's Meowth"). It still sits under the
  source label "Pokemon Snag".
- The dev option label shortened to "[DEV] Replay intro quest", since
  it named the old quest title.
- Set the author to Mister Miracle in mod.card -- it was still the
  YOUR_HANDLE_HERE placeholder from the template.

## 0.11.2

- Renamed the mod to **Pokemon Snag** everywhere it's displayed: the
  manifest name (was "Team Rocket: Snag Quest"), the in-game load log
  line, the quest journal's source label (was "Snag Quest"), and all
  docs.
- The mod id stays `snag_quest`. It is not a display name -- it's the
  key other mods look this one up by (`mod.find("snag_quest")` in
  pokeball_colors), the folder name the engine expects inside the
  release zip, and the key its saved options are stored under.
  Changing it would silently break all three.
- The quest itself is still titled "Grandpa's Meowth"; only its source
  label changed.

## 0.11.1

- The Snag Ball now throws with the Ultra/Master-tier presentation:
  `tossAnim = "ULTRATOSS_ANIM"` and `flicker = true`. It was using the
  plain Poke Ball arc with no flicker, which undersold an item that
  costs 10,000 or a stolen Pokemon.
- These are ENGINE fields on the ball record (confirmed from
  src/mods/Schemas.lua's R.balls and from src/battle/Catching.lua,
  where MASTER_BALL and ULTRA_BALL use exactly this pair), so this
  applies to everyone -- it is not a pokeball_colors feature and does
  not depend on that mod being installed.
- Cross-mod note: pokeball_colors recolours the Snag Ball to a Rocket
  palette (near-black body, red accent) when the game is in ADVANCED
  colour mode. Its complemented-palette ("f0x") branch handles the
  flicker in the ball's own colours -- that branch was previously
  unreachable for SNAG_BALL, because the plain TOSS_ANIM never
  flickers. This change makes it reachable.
- snag_quest now owns tossAnim/flicker for SNAG_BALL. Per
  pokeball_colors' own coordination rule, it should not also patch
  those two fields, or the last-folded op wins silently.

## 0.11.0

- Replaced the "Sell Snag Balls in marts" toggle with a single choice
  option, **GET NEW SNAG BALLS: BOTH / MART / FENCES** (default BOTH).
  It now controls both supply routes rather than only the marts, so
  turning marts off no longer leaves the fences implicitly always-on.
  Uses the engine's real `choice` row type (confirmed shape from
  src/mods/ManagerState.lua: `choices` is a list of
  { displayLabel, storedValue } pairs).
- Fences are gated on the new setting as well as the quest. Jessie's own
  dialogue deliberately is NOT, so choosing MART can never break the
  questline itself.
- Jessie's post-quest tip now matches the active setting: she points you
  at the Celadon gambler only when fences are actually open, and at the
  marts otherwise. Sending a player to a fence that won't deal would be
  a small but real lie.
- Unknown/legacy values fall back to BOTH rather than silently disabling
  every source. Note the old `sell_snag_balls_in_marts` value is not
  migrated -- if you had marts turned off, set the new option to FENCES.

## 0.10.1

- Yellow compatibility VERIFIED for both story NPCs, by running the
  NPC Inspector on a real Yellow save rather than assuming:
  - VIRIDIAN_CITY / TEXT_VIRIDIANCITY_GIRL -- same as Red/Blue
  - PEWTER_NIDORAN_HOUSE / TEXT_PEWTERNIDORANHOUSE_MIDDLE_AGED_MAN --
    same as Red/Blue
  No code change was needed; the outstanding Yellow caveat on the
  Pewter merchant is now resolved.
- Documented the real rule this establishes: Yellow's object renames
  are PER-MAP, not universal. The Game Corner coin-giver is renamed
  (CLERK2 -> MIDDLE_AGED_MAN2), these two are not -- so each new
  merchant NPC has to be checked individually rather than assumed to
  differ (or assumed to match).

## 0.10.0

- New merchant: the Pewter City man who explains that traded Pokemon
  disobey without badges now buys snagged Pokemon, on the same rules
  as the Celadon gambler. His new line leans on his own vanilla topic:
  snagged Pokemon "listen to anybody" regardless of badges.
  - Map and text constant were READ OFF THE RUNNING GAME with the NPC
    Inspector dev tool rather than guessed:
    PEWTER_NIDORAN_HOUSE / TEXT_PEWTERNIDORANHOUSE_MIDDLE_AGED_MAN.
    He shares the Nidoran's house (an earlier guess that he lived in a
    separate "speech house" was wrong).
  - No conflict: the engine's flavor script for that map defines only
    TEXT_PEWTERNIDORANHOUSE_NIDORAN, so this NPC is unscripted in the
    base game.
  - Gated on the BOULDERBADGE. Without it -- or before the Meowth
    quest -- he says his ordinary vanilla line, untouched.
- Refactored the merchants into one shared registerMerchant(spec)
  factory, so adding a town is now a map, its text constant(s), an
  optional badge id and three lines. The Celadon gambler was moved
  onto it with no behaviour change.
- New snag_quest:check_badge script command. Badges live in the save
  inventory keyed by badge id (confirmed from src/inventory/Badges.lua:
  Badges.itemFor is entry.item or entry.id, and Badges.count reads
  save.inventory[thatKey]), so this is a plain inventory lookup.
- YELLOW CAVEAT: the Pewter constant is confirmed for Red/Blue only.
  Yellow renames objects on some maps (exactly how the Game Corner
  gambler broke). If he stays vanilla on Yellow, run the NPC Inspector
  there and add the reported constant to his `texts` list -- extra
  entries are harmless, since a constant that doesn't exist simply
  never dispatches.

## 0.9.4

- FIXED a hot-reload bug that silently ate mod updates -- and is the
  likely reason 0.9.3's guaranteed catch appeared to change nothing.
  install() guarded with a plain `if BattleState._snagQuestWrapped
  then return end` sentinel, but that sentinel lives on the ENGINE
  MODULE TABLE, which persists in Lua's module cache for the whole
  game process. Swapping the mod and re-enabling it without a full
  game restart meant the new install() saw the OLD version's sentinel,
  returned immediately, and left the OLD version's wrapped throwBall/
  newTrainer live. Every mod update since this pattern was introduced
  was subject to this.
- Now stashes the true original functions once
  (BattleState._snagQuestOriginals) and always rebuilds the wrappers
  from those, so re-running install() replaces the previous wrapper
  rather than skipping, without stacking wrappers.
- The load line now logs the running version ("Snag Quest 0.9.4
  loaded"), so which build is actually live is checkable.

## 0.9.3

- The intro quest's MEOWTH is now a guaranteed catch: throwing the
  Snag Ball at it always works. Scoped tightly to this mod's own
  trainer class (OPP_SNAG_QUEST_PICNICKER, which nothing else uses)
  plus a MEOWTH species check, so no ordinary snag anywhere else in
  the game is affected. Returns `true, 3` -- exactly what the engine's
  own guaranteed-catch path returns (Catching.lua's autoCatch branch),
  so the normal three-wobble catch animation plays.
- Intro ball economy tightened: Jessie now hands over ONE Snag Ball
  instead of five (the catch is guaranteed, so one does the job), and
  ONE more as the reward for turning MEOWTH in. You finish the quest
  holding a single ball and have to earn the rest from the fence or
  the marts.
- If you decline the turn-in and ask for a rematch, she hands over
  another ball first -- otherwise the guaranteed catch would have
  consumed the only one and left an unwinnable fight.
- Quest journal reward text updated to match ("A SNAG BALL, and
  someone who'll sell you more").

## 0.9.2

- FIXED the real cause of "Jessie turns to face me but no text box
  appears" -- a 0.9.0 regression introduced with the dev toggle, and
  confirmed to be ours after testing with every other mod disabled.
  questDoneForReal was defined ABOVE the `local function hasFlag`
  declaration it calls. Lua resolves an undeclared name at compile
  time as a GLOBAL lookup, so it compiled to a global `hasFlag` that
  is nil at runtime: snag_quest:check_quest_done threw "attempt to
  call a nil value" on every single talk, the script runner caught and
  swallowed the error, and the whole script aborted before any text
  row ran. Moved below hasFlag, with a comment explaining why it has
  to stay there.
- This explains why it reproduced with dev mode both ON and OFF: the
  crash happened before the toggle was ever read.
- Audited the rest of the file for the same use-before-declaration
  mistake; no others found.
- 0.9.1's change (a line of dialogue before any PartyMenu push) is
  kept -- it wasn't the cause, but leading with text reads better than
  a menu appearing out of nowhere.

## 0.9.1

- Possible fix for "NPC turns to face me but no text box appears"
  (reported for Jessie, both with and without dev mode -- and matching
  a previously-seen bug on an unrelated vanilla sequence, Bill's SS
  Anne ticket). Found a concrete, plausible trigger in our own code:
  on a re-talk, Jessie's script jumped straight from label "started"
  into snag_quest:turn_in_meowth, which pushes a PartyMenu screen with
  NO preceding text box -- every other screen-push in this mod happens
  after a line of dialogue, this was the one exception. Same pattern
  existed in the gambler's sell flow. Both now show a line of text
  first ("Well? Did you get MEOWTH?" / "Got something for me?") before
  ever touching Screens.push.
- Not fully certain this is the whole story given it echoes a
  separately-seen vanilla-sequence bug, but it's a real, concrete
  divergence from this mod's own established pattern and a reasonable
  place to start.

## 0.9.0

- FIXED the gambler for Red/Blue saves. Confirmed from source
  (data/scripts/flavor/game_corner.lua's own comment): the NPC we
  registered for, TEXT_GAMECORNER_MIDDLE_AGED_MAN2, is Yellow-only --
  its Red/Blue equivalent (same text, same event) is
  TEXT_GAMECORNER_CLERK2. Registering only the Yellow constant meant
  the fence never triggered at all on a Red/Blue save, and the merge-
  priority/flag-check investigation that preceded this fix came up
  clean because our code was never even reached. Both constants are
  now registered (one script factory, two targets), so this works on
  Red, Blue, and Yellow alike.
- Story rewrite: the quest-giver's name is now Jessie in her own
  dialogue. New motive -- she's disappointed in Grandpa's "do-gooder"
  streak and lifts money from his wallet to have a Snag Ball made,
  rather than him handing you his own. The target is no longer a
  Rocket grunt; it's a PICNICKER holding the odd-colored Meowth. The
  trainer's real sprite/data class is OPP_JR_TRAINER_F -- confirmed
  as the actual pokered constant for this class (localized as
  "Picnicker" starting in later games; this engine's disassembly
  predates that rename), with "PICNICKER" as the display name.
- New dev option, "[DEV] Allow replaying Grandpa's Meowth quest"
  (default off). While on, Jessie's dialogue treats the quest as not
  finished regardless of the real flag, dropping into the turn-in/
  rematch loop so the picnicker fight and turn-in can be repeated for
  testing. Doesn't clear FLAG_STARTED/FLAG_DONE -- turning it back off
  leaves the quest exactly as done as it already was. The gambler's
  own gate respects the same toggle for consistency.

## 0.8.0

- New: a fence. The Game Corner's own gambler (the real
  TEXT_GAMECORNER_MIDDLE_AGED_MAN2 -- canonically the man whose whole
  vanilla line is needing more coins for "the POKeMON I want") buys
  snagged Pokemon for Snag Balls once the Meowth quest is done. His
  vanilla 20-coin handout is preserved untouched before then.
- Payout is conservative and hard-capped at 5: 1 base, +1 at snag
  level 25+, +1 more at 45+, +1 for a rare species (catchRate <= 45),
  +1 for VIP provenance -- snagged from the rival, a gym leader, the
  Elite Four, or Giovanni.
- Snags now also record mon.snagFrom (the trainer class it was stolen
  from) and mon.snagLevel (the level at the moment of the snag --
  training it up afterward doesn't raise the fence's price). Like
  mon.snagged, these survive save/load and only exist on Pokemon
  snagged from this version onward.
- Selling: party picker, snagged Pokemon only, price quoted with a
  Deal?/refuse confirm before anything is taken, and the fence will
  never take your last party Pokemon.
- The quest girl's post-quest dialogue now tips you off about the
  gambler ("don't tell Grandpa").
- Works alongside the mart option independently: marts off + fence is
  the intended "earn them by fencing" economy, but both can be on.

## 0.7.4

- Added a persistent mon.snagged = true marker, set on the enemy mon
  right before storeCaughtMon runs (for cross-mod use, e.g. a ribbon
  mod's Snag Ribbon). This exists because storeCaughtMon's own stampOT
  call overwrites OT with the player immediately -- without a marker
  of our own, a snagged Pokemon becomes data-identical to a wild catch
  the instant the battle ends, so the ball == "SNAG_BALL" on the
  pokemon.caught event is only usable in the moment, not later (after
  a save/reload, a trade, or whenever some other UI wants to check).
- Confirmed safe two ways: Party.add/Boxes.deposit both just
  table.insert the same mon reference (no copy), so the field survives
  into the party/box as-is; and SaveSerializer.encode/decode
  (src/core/SaveSerializer.lua) is a fully generic recursive table
  dump with no field whitelist, so it round-trips through save/load
  with no extra work needed.
- This only affects Pokemon snagged from 0.7.4 onward -- it cannot be
  applied retroactively to a Meowth (or anything else) already caught
  under an earlier version, for the same OT-overwrite reason above.

## 0.7.3

- "Continue battle after snag" now defaults to ON, confirmed working
  by live testing across the 0.7.1 freeze fix and 0.7.2 sprite fix:
  no freeze, snagged Pokemon kept, trainer's next Pokemon sent out and
  correctly visible. The option still exists if you'd rather a snag
  just end the fight as a win.

## 0.7.2

- Fixed the invisible sprite after a snag-switch, confirmed from
  source after live testing ruled out the voxel renderer (bug
  reproduced with it off, and normal faint-switches rendered fine
  either way): the catch animation hides the enemy pic
  (SE_HIDE_ENEMY_MON_PIC -> self.enemyHidden = true) because the mon
  is inside the ball, and a wild catch ends the battle right there so
  vanilla never clears the flag. A faint never sets it -- exactly why
  faint-switches always rendered. The unhide is queued as a row after
  everything onFaint queues, so it lands once the new mon's send-out
  has begun; the ghost's faint slide also now plays while hidden, so
  the just-caught mon no longer risks visibly sliding away.

## 0.7.1

- Best-yet fix for the continue-battle freeze, driven by live testing
  that finally isolated it: the freeze ONLY happens when a player mon
  levels up from the snag, and even without a level-up the trainer's
  next Pokemon came out with no sprite (battle still playable).
- Root cause identified: in a real faint the enemy mon's hp is 0 by
  the time the faint pipeline runs, and everything downstream (faint
  anim chain, send-out grow-in, awardExp's level-up HUD rows) assumes
  it. Our caught mon still had FULL hp -- and it's the same table now
  in the player's party, so the pipeline was reading (and could write
  to) the player's own new Pokemon. The enemy battler's mon is now
  swapped for a shallow clone with hp = 0 before the faint handoff:
  the pipeline sees exactly what a real faint looks like, and the
  player's copy is fully decoupled.
- This should fix both the level-up freeze and the missing-sprite
  switch; needs a test to confirm.

## 0.7.0

- New feature: Snag Balls can now be bought in marts, price 10,000,
  once the quest is complete. Behind a new option, "Sell Snag Balls in
  marts (after quest)" (default ON) -- toggle it off any time to pull
  them from shelves again, no restart needed.
- Stocked at the same six marts Custom Pokeballs uses for GREAT_BALL/
  ULTRA_BALL (Celadon Dept. Store 2F, Lavender, Saffron, Fuchsia,
  Cinnabar, Indigo Plateau Lobby), confirmed straight from that mod's
  own shipped source.
- Implementation note: a mart's stock is normally static data
  (Data:textEntry(map, text).mart), so this wraps Data:textEntry
  itself to append SNAG_BALL to a COPY of the entry only when the
  quest is done and the option is on -- the underlying data table is
  never mutated, so turning the option off mid-save cleanly pulls it
  back out.
- Snag Ball's price is now 10,000 (was 0 -- it used to be quest-reward
  only and never sold).

## 0.6.1

- Fixed: the quest MEOWTH only turned shiny at the moment the Snag
  Ball caught it -- it fought the whole battle in normal colours.
  The shiny DVs are now applied when the battle is CREATED, by
  wrapping BattleState.newTrainer, so it's shiny from the first frame.
- Why it has to be there rather than earlier: newTrainer builds
  enemyParty with Pokemon.new and then OVERWRITES each mon's dvs with
  the fixed trainerDvs constant (recomputing stats and hp), only then
  building the battler. The trainer.party hook fires before any mon
  exists, so DVs set there would just be overwritten. makeBattler
  holds a reference to the same mon table rather than copying it, so
  patching the mon after newTrainer returns is visible through
  battle.enemy.mon, which is what the sprite/palette code reads.
- Both battle entry points (Commands.start_battle and the overworld's
  own engagement path) call BattleState.newTrainer as a field lookup
  on the shared table, so the wrap covers scripted and walk-up battles
  alike.

## 0.6.0

- CONTINUE_BATTLE_AFTER_SNAG is now a real in-game mod option instead
  of a hardcoded local: "Continue battle after snag" (default OFF),
  toggleable from the mod manager's per-mod options screen. Confirmed
  schema shape from src/mods/ManagerState.lua's buildOptionRows:
  { key, type = "toggle", label, default }. Read live via
  mod.options:get(key) at the point of use (not cached), so toggling
  it mid-session takes effect on the very next snag.
- Still the same underlying behaviour as 0.5.6: OFF ends the battle as
  a clean win (stable); ON reuses the real faint pipeline for a
  seamless continuation, which still freezes in some battles (see
  README).

## 0.5.6

- Snagging mid-trainer-battle now ENDS the battle as a proper win by
  default (victory music, defeat text, prize money), and the snagged
  Pokemon is kept. This is stable.
- The "trainer keeps fighting with their next Pokemon" behaviour is
  now behind CONTINUE_BATTLE_AFTER_SNAG at the top of main.lua,
  defaulting to false, because it STILL FREEZES. Three fixes to that
  path (calling enemyMonFainted directly, forcing battleStyle "set",
  and the afterQueue="menu" correction) each looked right from source
  and each still froze. Rather than ship a fourth guess as though it
  were a fix, the working behaviour is the default and the broken one
  is opt-in.
- Current best lead on the freeze, from a screenshot: the enemy HUD
  still shows the snagged mon, no next sprite appears, and the message
  box sits EMPTY forever -- so it's blocking on a queued row, not
  crashing. enemyMonFainted calls awardExp() before the switch, and
  awardExp can queue a level-up StatBox via uiNext, a row that blocks
  the queue until its pushed screen pops. The reporting save had a
  L32 player mon against a L36 target, i.e. squarely in level-up
  range. Unconfirmed.

## 0.5.5

- FIXED the freeze, confirmed from source rather than guessed.
  enemyMonFainted has two exits: the victory exit (trainer's last mon)
  sets self.result = "win" and self.afterQueue = "finish" itself, but
  the SWITCH exit returns early and never touches afterQueue -- in the
  normal flow the caller (endOfTurn) has already set it to "menu".
  This snag path never calls endOfTurn, and 0.5.3/0.5.4 set
  afterQueue = nil, so after the trainer switched, the queue drained
  and update()'s `if afterQueue == "menu" ... elseif == "finish"`
  matched NEITHER branch: phase stayed "messages" with an empty queue
  and the battle idled forever. That's the silent freeze right after
  the send-out text, with no error message. Now sets "menu" up front,
  which is safe for both exits (the victory path overwrites it).
- Reverted 0.5.4's battleStyle "set" override -- that was a wrong
  guess (the freeze reproduced on Set mode, which never takes the
  SHIFT-prompt branch) and it added risk for no benefit.
- Seamlessness: the "<mon> fainted!" line is now suppressed on a snag,
  since the Pokemon was caught, not knocked out. Done by swapping
  self.sayNext only for the duration of the synchronous onFaint call.
- Safety net: the faint handoff runs under pcall -- if anything in it
  throws, the battle ends cleanly as a win instead of stranding the
  player in a frozen "messages" phase.
- Still imperfect: the faint sound and slide animation still play on a
  snag. They're queued inside deferred closures rather than emitted
  synchronously, so suppressing them would need riskier global
  patching; left alone deliberately rather than risk re-breaking the
  freeze fix.

## 0.5.4

- Attempted fix for a freeze reported right at the "trainer sends out
  next Pokemon" step, after the 0.5.3 crash fix got further than
  before. Best-supported hypothesis: the switch continuation can
  optionally push an interactive "Will PLAYER change POKéMON?"
  PartyMenu prompt when battleStyle isn't "set" (confirmed from
  source), and that prompt's input handling likely assumes the normal
  battle-phase flow, which this snag-triggered call doesn't fully go
  through. Forces "set" for just this one switch (restored right
  after, via a queued action so the restore lands after the read it's
  guarding, not before) to skip that branch entirely.
- Not fully certain this is the actual cause without a stack trace or
  further testing -- flagging that honestly rather than presenting it
  as a confirmed fix.

## 0.5.3

- Fixed a crash when a trainer switched to their next Pokemon after a
  snag. self:enemyMonFainted() (confirmed from source) is only ever
  called through self:onFaint(battler), which sets up state --
  fainted/faintQueued flags, the battle.fainted event, faint sound and
  slide queueing -- that enemyMonFainted() and awardExp() assume is
  already in place. Calling it directly, skipping that setup, is what
  crashed. Now routes through self:onFaint(self.enemy) instead, the
  real entry point every faint (and now every snag) goes through.
- Known cosmetic rough edge from that fix: since onFaint plays the
  normal faint sound/slide and "<mon> fainted!" text, that now shows
  right after "<mon> was caught!" on a snag -- correct mechanically,
  a little redundant-sounding. A polish pass to suppress just that
  text for a snag would be a reasonable follow-up if it bothers you.

## 0.5.2

- Fixed: catching a trainer's Pokemon ended the whole battle instantly
  instead of letting the trainer send out their next one. The catch
  code was reusing storeCaughtMon's battle-ending flags verbatim,
  correct for a wild encounter but wrong for a multi-mon trainer team.
  Now clears those flags and calls self:enemyMonFainted() -- the same
  function a real KO uses -- so the fight continues normally if the
  trainer has another Pokemon, and only ends as a win if they don't.
  Side effect, and a reasonable one: your party now earns exp for a
  snag, same as it would for a KO.
- Fixed: the quest's Meowth wasn't visually shiny even with the Shiny
  Pokemon mod installed. Setting the DVs alone wasn't enough -- that
  mod's recolor/sparkle code keys off a cached mon.shiny flag it sets
  at its own hook points (Pokemon.new, BattleState.newWild), neither
  of which a trainer's pre-existing mon passes through. Now set
  directly, matching that mod's own internal pattern.
- Fixed shiny check: was tracking the current trainer via the
  world.trainer_engaged event, which (confirmed from
  src/world/OverworldController.lua) only fires from the normal
  sight-triggered battle path -- never from the Commands.start_battle
  script command this quest's own grunt fight uses, so the shiny check
  never actually ran. Switched to self.oppClass, set directly on the
  battle instance by both BattleState.newTrainer call sites, confirmed
  reliable everywhere.
- Fixed catching mid-trainer-battle: storeCaughtMon() (confirmed from
  src/battle/BattleState.lua) unconditionally ends the whole battle --
  correct for a single wild mon, wrong for one Pokemon out of a
  trainer's full roster. Now clears storeCaughtMon's own finish flags
  and hands off to self:enemyMonFainted() -- the same method a real
  faint uses -- to either send out the trainer's next Pokemon or run
  the normal victory sequence if that was their last one.
- Known simplification: because enemyMonFainted() is reused wholesale
  (rather than partially reimplementing its send-out/HUD logic), a
  snag now also awards EXP, unlike a normal catch.

## 0.5.1

- Fixed: FLAG_STARTED/FLAG_DONE reused the exact same names as every
  earlier draft of this mod (0.1.2-0.4.0). A save that completed the
  quest in a prior version would see the girl jump straight to
  "already done" on 0.5.0. Renamed to MOD_SNAG_QUEST_GIRL_STARTED /
  MOD_SNAG_QUEST_GIRL_DONE, a fresh namespace this quest owns alone.

## 0.5.0

- Story rewrite: the quest is now given by the real
  TEXT_VIRIDIANCITY_GIRL NPC (Viridian City, next to the sleeping man),
  gated on EVENT_GOT_POKEDEX -- confirmed to be the single flag that
  also gets the sleeping man up in the real game, so the two
  conditions the story wanted collapse to one real check.
- New turn-in step: bring a MEOWTH back to her in person via a real
  party-picker flow, copied from the engine's own Commands.trade
  pattern. Any MEOWTH in the party qualifies.
- The quest's Meowth is genuinely shiny by data (engine-native
  Stats.isShiny DVs), with optional integration with the Shiny Pokemon
  mod for visuals if it's installed.
- Dropped the separate "unlock" flag from 0.4.0 -- the ball just works
  once she hands it to you, no extra gate.

## 0.4.0

- The trainer-battle ball gate confirmed and wired for real against
  src/battle/BattleState.lua. Corrected the catch-completion event
  from a guessed "pokemon.give" to the real "pokemon.caught". Removed
  the invalid `sellable` item field.

## 0.3.0

- Reintroduced the general catch mechanic as a real item+ball, with an
  unlock quest.

## 0.2.0

- Prior design: a scripted give-Pokemon reward instead of a real ball.

## 0.1.2

- Corrected NPC/dialogue approach: map_scripts + Flags + base_talk
  against a real vanilla NPC, replacing an invented npcs registry.

## 0.1.1

- Fixed: quest location was hardcoded to Route 24 even before start.

## 0.1.0

- Initial skeleton.

## 0.14.17 — Gold private mechanics test

- Added a Gold-only private test path for the SNAG BALL.
- SNAG BALL is stocked on Gold mart shelves and stamped into the BALL pocket.
- Gold trainer throws use the native Gold capture pipeline for SNAG BALL instead of the trainer-ball refusal path.
- Cooperates with Too Many Balls' `requestBallSlots(1)` capacity API when installed.
- The existing Gen 1 quest/content path is not registered on Gold in this test build.
