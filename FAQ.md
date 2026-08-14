# Pokemon Snag — FAQ and spoiler guide

Every answer is collapsed. Tap only what you want revealed.

The two games have **separate questlines**. Gold's is first below; Kanto's
has its own section further down.

## Pokémon Gold

<details>
<summary>How do I start on Gold?</summary>

Go to **Cherrygrove City**. A sailor there gives you a single SNAG BALL and
points you at a girl with something unusual on her team. Beat her, throw
your one ball, and it is guaranteed to catch — the only time this mod bends
its own rules.

Find the sailor again **before you leave town** and he hands over five more
balls and tells you where to sell what you take. He waits until you have
claimed that reward, so leaving and coming back later does not forfeit it.
</details>

<details>
<summary>Where do I sell things on Gold?</summary>

A fence on **Route 36**, near Sudowoodo. He buys Pokémon you have snagged
and nothing else.

Later, the people who hand out contracts start buying too — the Goldenrod
broker once he has paid you for his job, and the Ecruteak contact once
you have the HEIST BALL. Same rules and same prices, different voices.
</details>

<details>
<summary>Where do I buy more Snag Balls on Gold?</summary>

**You do not.** Gold marts do not stock them at any price. Every ball you
own comes from the questline: the sailor's one, his five-ball reward,
selling to fences, and contract payouts.
</details>

<details>
<summary>Can I run out of Snag Balls and get stuck?</summary>

No. If you turn up at the Route 36 fence with **no Snag Balls of any kind
and nothing he wants to buy**, he hands you one free rather than let you
waste his time. He is not generous about it, and you can come back as often
as you need.

It only fires when you have absolutely nothing, so it cannot be used to
stockpile. Holding a HEIST BALL counts as having something to throw — you
are not stuck if you can still make an attempt.
</details>

<details>
<summary>What is a contract? (spoilers)</summary>

After the Cherrygrove introduction, a broker appears at **Goldenrod's
Magnet Train Station**. He offers you a lead and lets you pick the *kind*
you want — you choose blind, and he names the actual target once you have
taken the job. A trainer carrying it then turns up in the **Goldenrod
Underground**.

Somewhere in the city an ordinary passer-by is talking about something
strange they saw. They have no idea what you are; they are just gossip, and
they point you at the mark.
</details>

<details>
<summary>I knocked the contract target out. Have I failed?</summary>

No. The mark is re-armed so you can fight them again. Only snagging the
advertised Pokémon completes the job — knocking it out simply wastes the
trip.

The rest of that trainer's team is fair game, but they are ordinary goods,
not the bounty.
</details>

<details>
<summary>What is the second contract? (spoilers)</summary>

After the Goldenrod job, a contact in **Ecruteak** offers work that asks a
different question — not which Pokémon, but what kind of person is carrying
it. **Performer**, **Mystic** or **Collector**, each somewhere different
with a different team around them, and each a different amount of trouble.

As in Goldenrod, you choose before you know the species.
</details>

<details>
<summary>What is a contract target worth?</summary>

A contract's advertised target is a **bounty**: it sells for at least
**3 Snag Balls** rather than the going rate for casual theft, and the usual
bonuses still stack on top. Finishing the contract pays a flat **5** on top
of that, from the broker or the contact.

If you are carrying a mark from an older version, the fence works out that
it was a bounty and pays the new rate — nothing to redo.
</details>

<details>
<summary>What is the HEIST BALL?</summary>

The reward for finishing the Ecruteak contract. It is **twice as reliable**
as a plain Snag Ball, it is sold nowhere, and no fence will trade for one.
</details>

<details>
<summary>Does the Kanto story happen on Gold too?</summary>

No. Johto has an entirely separate questline — the mod splits on generation
when it loads, and the Kanto quest never runs on Gold. Nugget Bridge, the
four Kanto fences and the intro Meowth are Red/Blue/Yellow only.
</details>

<details>
<summary>Are there options on Gold?</summary>

No. The Gold questline has no settings, and the battle always continues
after a snag there. The options screen is Red/Blue/Yellow only.
</details>

## The Snag Ball

<details>
<summary>How do I use it?</summary>

Throw it from the bag during a **trainer** battle, like any ball. It
targets the opponent's current Pokémon.
</details>

<details>
<summary>Anything odd about snagging vs. a normal catch?</summary>

Because a snag reuses the engine's real faint pipeline to let the battle
continue, it also awards EXP (a normal catch doesn't), and the faint
sound and slide still play for the Pokémon you just took. Cosmetic, but
deliberate — it's the cost of the fight continuing correctly.
</details>

<details>
<summary>Does the battle end when I snag something?</summary>

On **Gold**, no — the trainer sends out their next Pokémon and the fight
continues. There is no setting for it.

On **Red, Blue and Yellow** it continues by default, and you can turn
**CONTINUE BATTLE AFTER SNAG** off if you'd rather it end the battle.
</details>

## Payouts

<details>
<summary>How is the payout calculated? (numbers)</summary>

Starting from **1 Snag Ball**:

- +1 if the mon was snagged at level 25+
- +1 if it was snagged at level 45+
- +1 if the species is hard to catch (catch rate ≤ 45)
- +1 if you stole it from a **VIP**

Then two floors are applied, so a sale never drops below them:

- **2 minimum** for any sale at all, on either game.
- **3 minimum** if it was a contract's advertised target.

Capped at **5**. The level used is the level it was *stolen* at — training
it up afterwards doesn't raise the price.

**Who counts as a VIP** differs by game. In Kanto: your rival, the eight
gym leaders, the Elite Four, Giovanni. On Gold: both rivals, all sixteen
gym leaders, Will, Koga, Bruno and Karen, Lance, and Red. Either way it is
recorded on the Pokémon when you take it, so the bonus holds later even if
you change your mod list.
</details>

<details>
<summary>A fence refused my Pokémon.</summary>

Three reasons, on either game:

- **It isn't snagged.** They only want stolen goods.
- **It's your last one that can battle.** No fence will leave you unable to
  fight, because you would have no way to snag anything else — and none of
  them is handing you a Pokémon. Each one says so in their own words.
  *(An egg doesn't count as a partner: it fills a party slot but can't
  battle. Before v0.15.8 it wrongly did count, and a fence could take your
  last real Pokémon.)*
- **Your Ball pocket is full.** The payment has to land before the Pokémon
  leaves, so if there's no room for the balls, you keep the Pokémon.

Pokémon snagged before **v0.8.0** can still be sold but can't earn the VIP
or level bonuses — those records didn't exist when they were caught.
</details>

## Red, Blue and Yellow

Kanto has its own questline, unchanged by Gold's arrival.

<details>
<summary>How do I start the questline in Kanto?</summary>

Cross **Nugget Bridge** on Route 24 and beat the Team Rocket recruiter
waiting at the end — the one who offers you the Nugget and asks you to
join. Beating him *is* the interview. Talk to him again afterwards and
the offer becomes real: one Snag Ball and your first target. The quest
appears in your journal as *Introduction to Thievery*.

Saying no costs nothing — he stays there and the offer stands.
</details>

<details>
<summary>The recruiter just says his normal line. Why?</summary>

You have to **beat him first**; before that everything he says is
vanilla, by design. If you've beaten him and he still only laments his
Team Rocket dreams, check the mod is actually loaded (F10 mod manager),
then open an issue with your version number.
</details>

<details>
<summary>I helped Bill and now the recruiter is gone.</summary>

That's vanilla Gen 1 behaviour — leaving Bill's house with the S.S.
Ticket removes him from Route 24 permanently, and it has nothing to do
with whether you beat him. This mod puts a Team Rocket grunt in the same
spot so the questline stays reachable: same job, same turn-in, and he
buys from you afterwards. He doesn't require beating anybody.
</details>

<details>
<summary>What do I get from the Kanto intro quest? (big spoiler)</summary>

The Picnicker's Meowth is a **guaranteed shiny**, and the snag is
guaranteed to succeed. Handing Meowth over pays **5 Snag Balls**, which
is your starting float — every snag after this one rolls normal catch
odds, so expect to spend a few before the fences start paying you back.

You will not be asked to hand it over if it is the only Pokémon you have;
the quest checks before it offers, rather than asking and then refusing.
</details>

<details>
<summary>Can I replay the intro quest?</summary>

Turn on **[DEV] REPLAY INTRO QUEST** in options. The recruiter will treat
the quest as unfinished so you can re-fight the Picnicker and hand Meowth in
again. It doesn't erase your real progress — switch it back off and the
quest is as completed as it was.
</details>

<details>
<summary>Where do I buy more Snag Balls in Kanto?</summary>

That depends on **GET NEW SNAG BALLS** in options:

- **BOTH** (default) — marts stock them at **₽10,000**, and fences pay in
  them too.
- **MART** — marts only; the fences won't deal.
- **FENCES** — the black market only; nothing on any shelf.

The recruiter's post-quest line follows whichever you've picked, so he
never points you at a source you've switched off.

*(Gold has none of this — see above.)*
</details>

<details>
<summary>Where are the Kanto fences? (spoilers)</summary>

- **Nugget Bridge (Route 24)** — the recruiter who gave you the job buys
  from you once it's done. No badge needed; finishing the job is the
  credential.
- **Celadon Game Corner** — a gambler on the floor. No badge needed. He
  doesn't work for Rocket and will tell you so.
- **Pewter City** — the middle-aged man in the Nidoran house, but only
  once you have the **Boulder Badge**. He has opinions about which
  Pokémon obey which trainers, and a stolen one obeying anybody is
  exactly what he wants to study.
- **Vermilion City** — the sailor at the S.S. Anne gangway, once you have
  the **Thunder Badge**. He stays at the dock after the ship sails, and
  he has stopped counting the crates.

All four only open for business after the intro quest is done, and only
if **GET NEW SNAG BALLS** is set to `BOTH` or `FENCES`. Otherwise they
give their ordinary dialogue and nothing looks different.
</details>

<details>
<summary>A Kanto NPC I expected to be a fence is just saying their normal
line.</summary>

Check the gates in this order — the first two catch almost everything:

1. **GET NEW SNAG BALLS is set to `MART`.** That closes every fence
   deliberately, and a closed fence just gives its ordinary line. This is
   the single most common cause.
2. **The intro quest isn't finished.** Every fence requires it.
3. **The badge.** Pewter needs the Boulder Badge, Vermilion the Thunder
   Badge. Celadon and the recruiter need none.
4. **Another mod claims the same character.** The Kanto questline works by
   taking over vanilla NPCs, so only one mod's dialogue can win for a given
   character and the loser's silently never runs. Try disabling other
   NPC-editing mods.

If all four are ruled out, that's worth an issue — include your game
version, since NPC internal names can differ between Red/Blue and Yellow.

*(This doesn't apply on Gold, where the mod places its own characters
instead of taking over anybody's.)*
</details>

<details>
<summary>The recruiter's vanilla lines repeat themselves before the
battle.</summary>

Known, and it isn't this mod. The "Congratulations! You beat our 5
contest trainers!" sequence is the engine's own vanilla text, which this
mod passes through untouched. That page is three lines long in a
two-line box, and the third line is joined with a plain newline instead
of a scroll marker — so it scrolls in without waiting and looks like the
previous line repeating.

You can confirm it by disabling Pokemon Snag entirely and talking to him
on the same save: the repeat still happens. It's worth reporting to
gen1recomp rather than here.
</details>

## Troubleshooting

<details>
<summary>I talked to an NPC and they just turned to face me — nothing
happened.</summary>

That's the signature of a swallowed script error. Please open an issue
with: your Pokemon Snag version (from the load log), your game
(Red/Blue/Yellow or Gold), which NPC and where, and which other mods were
enabled. If you can, retry with other mods disabled — knowing whether that
changes it helps enormously.
</details>

<details>
<summary>I updated the mod but it's acting like the old version.</summary>

Fully quit and relaunch the game. Hot-reload can keep stale code in
memory. The load log prints the version — confirm it matches the release
you installed. On iOS, also delete any older copy of the zip from Files
first, or importing it again can quietly reinstall the old one.
</details>
