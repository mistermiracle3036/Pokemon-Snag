# Trainer Journey integration handoff

Pokemon Snag owns the proposed path id `snag_quest:pokemon_thief`. Version
0.15.20 calls Trainer Journey's replay-safe queued award export for live Heart
gains and never writes another mod's save namespace.

For save reconstruction or a later formal integration, read
`mod.exports.trainerJourney.evidence()` (also exported directly as
`mod.exports.trainerJourneyEvidence`). It returns:

- `intro`: the Cherrygrove initiation was completed.
- `goldenrod`, `ecruteak`, `olivine`: each story mark was snagged.
- `zapdos`: the legendary job reached a resolved outcome.
- `zapdosOutcome`: `KEEP`, `SELL`, `RELEASE`, or nil.
- `repeatJobs`: durable count of completed repeatable contracts.
- `heartReleases`: durable count of targets released through repeatable
  RELEASE terms. Trainer Journey can convert this evidence into paced or
  capped Heart progression once its public award/reconstruction API exists.
- `heartPoints`: the current conversion, `floor(heartReleases / 2)`. Every
  second release calls `awardOnceAndQueue` with a unique source tag, so Trainer
  Journey owns deduplication, progression, and the shared gain card. Without a
  compatible API, the dossier states that there is no reward; the release
  remains valid and its durable evidence is still recorded.
- `heartAwards`: number of those points successfully awarded through Trainer
  Journey's live API.
- `heartUncredited`: `max(0, heartPoints - heartAwards)`, reserved for a future
  idempotent reconstruction/import contract.

Suggested Pokemon Thief rank names are Ball Lifter, Mark Runner, Fence
Regular, Heist Expert, and Master Snagger. Suggested thresholds are 0, 2, 5,
9, and 14 path progress. Starting career must not gate this path: any career
can become a Pokemon Thief through Snag Quest evidence.

Trainer Journey owns its ledger, deduplication, rank computation, and gain-card
presentation. Pokemon Snag continues to own quest state and evidence.
Legendary thefts can later ask Trainer Journey for the path rank, with a local
evidence fallback when Trainer Journey is absent. Since 0.15.13, two completed
repeat jobs serve as that fallback gate for Zapdos.
