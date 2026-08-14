-- Pokemon Snag -- "Introduction to Thievery"
--
-- The Nugget Bridge opening is trikus's idea, suggested in the
-- gen1recomp Discord: rather than inventing a character to hand out the
-- quest, use the TEAM ROCKET grunt who already asks whether you want to
-- join, and let saying yes actually mean something. That is the whole
-- design -- vanilla asks the question and then ignores the answer, so
-- the hook was already written and just needed following through. It
-- replaced an earlier opening built around the VIRIDIAN_CITY girl.
--
-- The TEAM ROCKET recruiter at the end of NUGGET BRIDGE (ROUTE_24,
-- TEXT_ROUTE24_COOLTRAINER_M1) hands out the NUGGET, asks whether
-- you'd like to join TEAM ROCKET, and battles you regardless of the
-- answer -- vanilla ignores it entirely, replying "Arrgh! You are not
-- convinced?" either way.
--
-- This mod leaves all of that untouched and takes over only his
-- POST-DEFEAT line, which vanilla spends on a single lament about his
-- dreams of Team Rocket. Beat him and the recruitment becomes real:
-- your first assignment from the boss is an oddly-coloured MEOWTH a
-- PICNICKER is holding.
--
-- Gate: beating him. Because he stays talkable forever once defeated
-- (confirmed from data/scripts/story4.lua's battleOrDone branch),
-- declining costs nothing -- the offer is still there next time.
--
-- Everything below is confirmed against the engine's own dev source
-- (src/battle/BattleState.lua, src/script/Commands.lua,
-- src/pokemon/Stats.lua, src/mods/Schemas.lua, data/scripts/
-- flavor/viridian_city.lua, data/scripts/story.lua) or against real
-- shipped mods (Quest System, Custom Pokeballs, Team Rocket Returns,
-- Trainer Rematch, and now Shiny Pokemon for the optional shiny
-- integration).

local MapScripts = require("src.script.MapScripts")
local Flags = require("src.script.Flags")

return function(mod)

  -- ONE version local for the whole mod, declared before the Gen 1/Gen 2
  -- split so both arms report the same number. It used to be declared
  -- inside the `if GEN2` arm only (0.14.17-0.14.38), which left
  -- `mod.exports.version` NIL on a Red boot -- the load line printed
  -- "Pokemon Snag nil loaded" and BattleState._snagQuestWrapped, the
  -- stamp that answers "which code is live", was stamped nil. Keep this
  -- at the top; keep it equal to manifest.json.
  local VERSION = "0.15.6"
  mod.exports.version = VERSION

  -- A quest mark is a BOUNTY, not merchandise (0.14.41).  The fence's ordinary
  -- valuation is built for opportunistic theft -- base 1, and the bonuses only
  -- fire for a high level, a rare species or a VIP owner -- so the first
  -- contract target, a level 16 YANMA with a catch rate of 75 owned by a BUG
  -- CATCHER, priced out at exactly 1 ball.  A job the player chose, tracked
  -- across a city and spent balls on paid the same as a mon grabbed in passing.
  --
  -- A bounty therefore has a FLOOR rather than a bonus: at least this many,
  -- with the ordinary bonuses stacking on top to the usual cap of 5.  A floor
  -- keeps one dial instead of two and means a later, tougher mark is still
  -- worth more than an early one.
  local BOUNTY_FLOOR = 3

  -- And nothing is worth only one ball (0.14.42).  Giving up a Pokemon is the
  -- most expensive thing the player can do at a fence -- it leaves the party
  -- for good -- and one ball back could not even repeat the throw that caught
  -- it.  A floor rather than a higher base: the bonuses keep their spread and
  -- only the bottom rung moves, so a level 45 rarity from a Gym Leader is
  -- still worth more than a common one off a Youngster.
  --
  -- This does NOT address the real complaint behind it.  Snagging at full HP
  -- is ~catchRate/3 out of 256 per throw (src/battle/gen2/Catching.lua:301),
  -- so a 45-catch-rate target is about 6% a ball and the player reloads rather
  -- than spends.  A payout floor changes the drain, not the wall.  Deferred
  -- deliberately, one change at a time.
  local MIN_PAYOUT = 2

  -- Shared fence valuation. Gold stamps snagVip at encounter time; the legacy
  -- Gen 1 path may still supply a class table for old captured Pokemon.
  local function computeSnagPayout(game, mon, vipClasses)
    local n = 1
    local lv = tonumber(mon and (mon.snagLevel or mon.level)) or 1
    if lv >= 25 then n = n + 1 end
    if lv >= 45 then n = n + 1 end
    local data = game and game.data
    local def = data and data.pokemon and mon and data.pokemon[mon.species]
    if def and tonumber(def.catchRate) and def.catchRate <= 45 then n = n + 1 end
    local vip = mon and mon.snagVip == true
    if not vip and vipClasses and mon and mon.snagFrom then
      vip = vipClasses[mon.snagFrom] == true
    end
    if vip then n = n + 1 end
    if n < MIN_PAYOUT then n = MIN_PAYOUT end
    if mon and mon.snagBounty == true and n < BOUNTY_FLOOR then
      n = BOUNTY_FLOOR
    end
    return math.min(5, n)
  end

  -- GOLD PRIVATE TEST PATH (0.14.17): keep the existing Kanto quest code
  -- completely out of a Gold boot. Gold has a parallel BattleState/World
  -- implementation and, more importantly for this mod, the old Kanto
  -- trainer/map-script registrations are not meaningful on Gold. The first
  -- Gold milestone is deliberately much smaller: SNAG BALL in a Gold mart,
  -- then let Gold's own capture pipeline catch a trainer Pokemon.
  local GameVersion = require("src.core.GameVersion")
  local GEN2 = GameVersion.generation() == 2

  if GEN2 then
    local Runtime = require("src.mods.Runtime")
    local Bag = require("src.inventory.Bag")
    local Mon = require("src.battle.gen2.Mon")
    local ListMenu = require("src.ui.ListMenu")

    local MAP = "CHERRYGROVE_CITY"
    local FENCE_MAP = "ROUTE_36"
    local FENCE_NAME = "SNAG_VIOLET_FENCE"
    -- Sudowoodo itself is at (35,9) in vanilla Gold.  First-pass fence
    -- placement is a few tiles southeast on the Violet-side approach; tune
    -- by device feedback if the collision layout wants a neighboring cell.
    local FENCE_X, FENCE_Y = 42, 10
    local SAILOR_NAME = "SNAG_INTRO_SAILOR"
    local GIRL_NAME = "SNAG_INTRO_GIRL"

    -- First real contract: a Goldenrod broker lets the player choose the
    -- KIND of mark rather than prescribing one Pokemon.  Coordinates are
    -- deliberately fixed calibration points, like the Cherrygrove/Route 36
    -- NPCs, so device feedback can tune them by exact tile offsets.
    local GOLDENROD_MAP = "GOLDENROD_MAGNET_TRAIN_STATION"
    local GOLDENROD_CITY_MAP = "GOLDENROD_CITY"
    local MARK_MAP = "GOLDENROD_UNDERGROUND"
    local BROKER_NAME = "SNAG_GOLDENROD_BROKER"
    local CLUE_NAME = "SNAG_GOLDENROD_WITNESS"
    local MARK_NAME = "SNAG_GOLDENROD_MARK"
    local BROKER_X, BROKER_Y = 4, 12
    local CLUE_X, CLUE_Y = 8, 24
    local MARK_X, MARK_Y = 2, 19
    local CONTRACT_NONE, CONTRACT_ACTIVE, CONTRACT_DONE = 0, 1, 2

    -- Contract #2: Ecruteak changes the player's decision from Pokemon type
    -- to trainer archetype/risk. Each lead has its own destination.
    local ECRUTEAK_MAP = "ECRUTEAK_CITY"
    local ECRUTEAK_CONTACT_NAME = "SNAG_ECRUTEAK_CONTACT"
    local ECRUTEAK_WITNESS_NAME = "SNAG_ECRUTEAK_WITNESS"
    local ECRUTEAK_MARK_NAME = "SNAG_ECRUTEAK_MARK"
    local ECRUTEAK_CONTACT_X, ECRUTEAK_CONTACT_Y = 27, 24
    local ECRUTEAK_WITNESS_X, ECRUTEAK_WITNESS_Y = 16, 23

    -- Contract #3: the Olivine foreman makes LOCATION the player's choice.
    -- Coordinates come from Gold Dev Kit 0.1.5 dumps captured on device:
    -- the city waterfront and port platform are broad, while the upper
    -- gangway is two cells wide. The one-cell lower gangway is never used.
    local OLIVINE_MAP = "OLIVINE_CITY"
    local OLIVINE_PORT_MAP = "OLIVINE_PORT"
    -- 0.15.6: the MAGNETON job moved off the port. Two of the three routes
    -- were both on OLIVINE_PORT, close enough that choosing between them
    -- barely changed where you went -- the whole point of this contract is
    -- that the CHOICE is a location. The lighthouse is a genuinely separate
    -- destination and the target suits it.
    local OLIVINE_LIGHTHOUSE_MAP = "OLIVINE_LIGHTHOUSE_1F"
    local OLIVINE_CONTACT_NAME = "SNAG_OLIVINE_FOREMAN"
    -- A sound recordist over from the GOLDENROD radio station (0.15.6).
    -- Tile (17,13) shares block id 1 AND quadrant (1,1) with the
    -- foreman's device-calibrated tile (15,23), and Gold collision is per
    -- block quadrant, so it is standable by the same argument rather than
    -- by guess. Clear of all eleven OLIVINE_CITY warps and of every
    -- vanilla object. Confirm with Position Reporter anyway.
    local OLIVINE_WITNESS_NAME = "SNAG_OLIVINE_WITNESS"
    local OLIVINE_WITNESS_X, OLIVINE_WITNESS_Y = 17, 13
    local OLIVINE_MARK_NAME = "SNAG_OLIVINE_MARK"
    local OLIVINE_CONTACT_X, OLIVINE_CONTACT_Y = 15, 23

    local MOVE_STANDING_DOWN = 6
    local MOVE_STANDING_UP = 7
    local MOVE_STANDING_LEFT = 8
    local INTRO_LEVEL = 5
    local STAGE_NEW, STAGE_ARMED, STAGE_DONE = 0, 1, 2

    local GIRL_SEEN = "SNAG_G2_GIRL_SEEN"
    local GIRL_WIN  = "SNAG_G2_GIRL_WIN"
    local GIRL_LOSS = "SNAG_G2_GIRL_LOSS"

    -- Gold intro quest text.  The sailor is mod-owned dialogue; the girl's
    -- three rows are VM text keys consumed by the cart's trainer script.
    mod.content.text:register(GIRL_SEEN,
      "Hey! Stay away\nfrom my MEOWTH!")
    mod.content.text:register(GIRL_WIN,
      "No! MEOWTH!\nGive it back!")
    mod.content.text:register(GIRL_LOSS,
      "I told you to\nstay away!")

    local CONTRACTS = {
      NATU = {
        key = "NATU", label = "PSYCHIC", species = "NATU", level = 16,
        class = "PSYCHIC_T", sprite = "SPRITE_SUPER_NERD",
        seen = "SNAG_G2_NATU_SEEN", win = "SNAG_G2_NATU_WIN",
        loss = "SNAG_G2_NATU_LOSS",
        clue1 = "Strange bird.\nStares through ya.",
        clue2 = "Look around\nGOLDENROD.",
        gossip = {
          "Odd little bird.\nJust stared at me.",
          "Couldn't even fly.\nHopped down below.",
        },
        after1 = "I saw that coming.",
        after2 = "Still hurts.",
      },
      AIPOM = {
        key = "AIPOM", label = "NORMAL", species = "AIPOM", level = 16,
        class = "POKEFANM", sprite = "SPRITE_POKEFAN_M",
        seen = "SNAG_G2_AIPOM_SEEN", win = "SNAG_G2_AIPOM_WIN",
        loss = "SNAG_G2_AIPOM_LOSS",
        clue1 = "Little thief.\nHandy tail.",
        clue2 = "Look around\nGOLDENROD.",
        gossip = {
          "Saw a POKEMON\nhang by its tail!",
          "Then it followed\na guy downstairs.",
        },
        after1 = "My collection!",
        after2 = "That was my best!",
      },
      YANMA = {
        key = "YANMA", label = "BUG", species = "YANMA", level = 16,
        class = "BUG_CATCHER", sprite = "SPRITE_BUG_CATCHER",
        seen = "SNAG_G2_YANMA_SEEN", win = "SNAG_G2_YANMA_WIN",
        loss = "SNAG_G2_YANMA_LOSS",
        clue1 = "Fast wings.\nHard to find.",
        clue2 = "Look around\nGOLDENROD.",
        gossip = {
          "Something smashed\na window nearby!",
          "Big BUG flew down\ntoward the stairs.",
        },
        after1 = "That took weeks",
        after2 = "to catch!",
      },
    }

    mod.content.text:register("SNAG_G2_NATU_SEEN", "I knew you'd\ncome for NATU.")
    mod.content.text:register("SNAG_G2_NATU_WIN", "I knew you'd\nthrow that BALL.")
    mod.content.text:register("SNAG_G2_NATU_LOSS", "Just as NATU\nforesaw.")
    mod.content.text:register("SNAG_G2_AIPOM_SEEN", "You've never seen\none like AIPOM!")
    mod.content.text:register("SNAG_G2_AIPOM_WIN", "Hey! That's part\nof my collection!")
    mod.content.text:register("SNAG_G2_AIPOM_LOSS", "AIPOM is one of\nmy best!")
    mod.content.text:register("SNAG_G2_YANMA_SEEN", "Took me WEEKS\nto catch YANMA!")
    mod.content.text:register("SNAG_G2_YANMA_WIN", "No! My YANMA!")
    mod.content.text:register("SNAG_G2_YANMA_LOSS", "Worth the hunt!")

    local ECRUTEAK_CONTRACTS = {
      SMEARGLE = {
        key = "SMEARGLE", label = "PERFORMER", target = "SMEARGLE",
        class = "KIMONO_GIRL", sprite = "SPRITE_KIMONO_GIRL",
        map = "DANCE_THEATER", x = 1, y = 10,
        seen = "SNAG_G2_SMEARGLE_SEEN", win = "SNAG_G2_SMEARGLE_WIN",
        loss = "SNAG_G2_SMEARGLE_LOSS",
        pitch1 = "PERFORMER.", pitch2 = "Should be easy.",
        gossip = {
          "Paint all over\nthe THEATER floor!",
          "That POKEMON used\nits own tail!",
        },
        party = {
          { species = "SMEARGLE", level = 20 },
          { species = "CLEFAIRY", level = 18 },
        },
        after1 = "My masterpiece!",
        after2 = "You took it!",
      },
      MISDREAVUS = {
        key = "MISDREAVUS", label = "MYSTIC", target = "MISDREAVUS",
        class = "SAGE", sprite = "SPRITE_SAGE",
        map = "ECRUTEAK_CITY", x = 7, y = 8,
        seen = "SNAG_G2_MISDREAVUS_SEEN", win = "SNAG_G2_MISDREAVUS_WIN",
        loss = "SNAG_G2_MISDREAVUS_LOSS",
        pitch1 = "MYSTIC.", pitch2 = "Battles well.",
        gossip = {
          "Awful wailing by\nthe BURNED TOWER.",
          "Some GHOST scared\nhalf the street.",
        },
        party = {
          { species = "GASTLY", level = 20 },
          { species = "MISDREAVUS", level = 22 },
          { species = "HAUNTER", level = 21 },
        },
        after1 = "The crying ends.",
        after2 = "So did my luck.",
      },
      GIRAFARIG = {
        key = "GIRAFARIG", label = "COLLECTOR", target = "GIRAFARIG",
        class = "POKEMANIAC", sprite = "SPRITE_POKEFAN_M",
        map = "ROUTE_38_ECRUTEAK_GATE", x = 4, y = 5,
        seen = "SNAG_G2_GIRAFARIG_SEEN", win = "SNAG_G2_GIRAFARIG_WIN",
        loss = "SNAG_G2_GIRAFARIG_LOSS",
        pitch1 = "COLLECTOR.", pitch2 = "Guards his finds.",
        gossip = {
          "That POKEMON had\nface on its tail!",
          "It tried to bite\nby the west gate.",
        },
        party = {
          { species = "DUNSPARCE", level = 21 },
          { species = "GIRAFARIG", level = 23 },
          { species = "PORYGON", level = 22 },
        },
        after1 = "My rarest find!",
        after2 = "Give it back!",
      },
    }

    mod.content.text:register("SNAG_G2_SMEARGLE_SEEN",
      "My SMEARGLE made\nthis latest work!")
    mod.content.text:register("SNAG_G2_SMEARGLE_WIN",
      "My masterpiece!")
    mod.content.text:register("SNAG_G2_SMEARGLE_LOSS",
      "Art wins again!")
    mod.content.text:register("SNAG_G2_MISDREAVUS_SEEN",
      "MISDREAVUS hears\nyou coming.")
    mod.content.text:register("SNAG_G2_MISDREAVUS_WIN",
      "The spirits knew.")
    mod.content.text:register("SNAG_G2_MISDREAVUS_LOSS",
      "You were warned.")
    mod.content.text:register("SNAG_G2_GIRAFARIG_SEEN",
      "Rare GIRAFARIG.\nDon't touch.")
    mod.content.text:register("SNAG_G2_GIRAFARIG_WIN",
      "My collection!")
    mod.content.text:register("SNAG_G2_GIRAFARIG_LOSS",
      "Hands off!")

    local OLIVINE_CONTRACTS = {
      WATERFRONT = {
        key = "WATERFRONT", label = "WATERFRONT", target = "CORSOLA",
        class = "FISHER", sprite = "SPRITE_FISHING_GURU",
        map = OLIVINE_MAP, x = 24, y = 23,
        seen = "SNAG_G2_CORSOLA_SEEN", win = "SNAG_G2_CORSOLA_WIN",
        loss = "SNAG_G2_CORSOLA_LOSS",
        lead1 = "WATERFRONT.", lead2 = "East end.\nOpen ground.",
        gossip = {
          "Taping waves out\neast. Got a click.",
          "Something coral\nclicked back.",
        },
        party = {
          { species = "KRABBY", level = 24 },
          { species = "CORSOLA", level = 26 },
          { species = "POLIWHIRL", level = 24 },
        },
        after1 = "Years of growth",
        after2 = "gone in a blink.",
      },
      -- The KEY stays "CUSTOMS" even though nothing the player sees says so.
      -- g2_contract3_choice stores this string, and olivineChoice() validates
      -- it against this table -- so renaming the key would make a save that is
      -- mid-contract read back nil, leaving the stage ACTIVE with no chosen
      -- route and no mark to find. Only `label` and the copy are player-facing.
      --
      -- Tile (12,2) on OLIVINE_LIGHTHOUSE_1F is standable, not a guess: the
      -- vanilla SPRITE_SAILOR stands at (8,2), which is the SAME quadrant
      -- (x,y both even) of the SAME block id (39) in the imported map data,
      -- and block collision on Gold is per quadrant. It is clear of all five
      -- warps -- the OLIVINE_CITY door at (10,17)/(11,17) and the 2F stairs at
      -- (3,11)/(16,13)/(17,13) -- and of both vanilla objects. Still worth a
      -- Position Reporter confirmation on device, since every other placement
      -- in this contract was calibrated that way and this one was derived.
      CUSTOMS = {
        key = "CUSTOMS", label = "LIGHTHOUSE", target = "MAGNETON",
        class = "SCIENTIST", sprite = "SPRITE_SCIENTIST",
        map = OLIVINE_LIGHTHOUSE_MAP, x = 12, y = 2,
        seen = "SNAG_G2_MAGNETON_SEEN", win = "SNAG_G2_MAGNETON_WIN",
        loss = "SNAG_G2_MAGNETON_LOSS",
        lead1 = "THE LIGHTHOUSE.", lead2 = "Ground floor.\nNorth wall.",
        gossip = {
          "Bad interference\nby the LIGHTHOUSE.",
          "Ruined my tape.\nAll static.",
        },
        party = {
          { species = "VOLTORB", level = 24 },
          { species = "MAGNETON", level = 26 },
          { species = "KOFFING", level = 24 },
        },
        after1 = "Months of data.",
        after2 = "Gone with it.",
      },
      GANGWAY = {
        key = "GANGWAY", label = "GANGWAY", target = "QWILFISH",
        class = "SAILOR", sprite = "SPRITE_SAILOR",
        map = OLIVINE_PORT_MAP, x = 10, y = 10,
        seen = "SNAG_G2_QWILFISH_SEEN", win = "SNAG_G2_QWILFISH_WIN",
        loss = "SNAG_G2_QWILFISH_LOSS",
        lead1 = "GANGWAY.", lead2 = "Upper bridge.\nOne lane.",
        gossip = {
          "Up on the gangway\nsomething hissed.",
          "Like air leaving\na balloon.",
        },
        party = {
          { species = "TENTACOOL", level = 24 },
          { species = "QWILFISH", level = 26 },
          { species = "KRABBY", level = 24 },
        },
        after1 = "Off my own deck.",
        after2 = "That's a first.",
      },
    }

    -- Choice-menu rows are built FROM the contract tables (0.15.6).
    --
    -- Each menu used to carry its own hardcoded copy of the labels, which is
    -- the same string written in two places -- and the LIGHTHOUSE rename
    -- proved the trap immediately: the table said LIGHTHOUSE, the menu still
    -- offered CUSTOMS, and nothing failed because both were valid strings.
    -- The label now has one home. `key` remains the stored save value, so
    -- renaming a label can never move what a save holds.
    --
    -- The order is explicit because `pairs` is unordered and these menus must
    -- not reshuffle between visits.
    local CONTRACT_ORDER = { "NATU", "AIPOM", "YANMA" }
    local ECRUTEAK_ORDER = { "SMEARGLE", "MISDREAVUS", "GIRAFARIG" }
    local OLIVINE_ORDER = { "WATERFRONT", "CUSTOMS", "GANGWAY" }

    local function menuItems(order, contracts)
      local items = {}
      for _, key in ipairs(order) do
        local c = contracts[key]
        if c then items[#items + 1] = { label = c.label, value = key } end
      end
      return items
    end

    mod.content.text:register("SNAG_G2_CORSOLA_SEEN",
      "Took years to\ngrow that coral.")
    mod.content.text:register("SNAG_G2_CORSOLA_WIN",
      "You'll never grow\none of your own!")
    mod.content.text:register("SNAG_G2_CORSOLA_LOSS",
      "Fish your own\nreef.")
    mod.content.text:register("SNAG_G2_MAGNETON_SEEN",
      "Three magnets,\none mind. Careful.")
    mod.content.text:register("SNAG_G2_MAGNETON_WIN",
      "My readings!\nMonths of them!")
    mod.content.text:register("SNAG_G2_MAGNETON_LOSS",
      "Static ruins\neverything here.")
    mod.content.text:register("SNAG_G2_QWILFISH_SEEN",
      "Mind the spines.\nIt bites back.")
    mod.content.text:register("SNAG_G2_QWILFISH_WIN",
      "Hope it stings\nyou on the way!")
    mod.content.text:register("SNAG_G2_QWILFISH_LOSS",
      "Off my gangway.")

    -- Gold item registration.  This build deliberately does NOT stock marts:
    -- the intro is supposed to hand the player exactly one SNAG BALL.
    local SNAG_BALL_TIERS = {
      SNAG_BALL = {
        name = "SNAG BALL", multiplier = 1.0, price = 10000,
        description = "Steals a POKeMON.\nNormal catch rate.",
      },
      HEIST_BALL = {
        name = "HEIST BALL", multiplier = 2.0, price = 20000,
        description = "Steals a POKeMON.\nGood catch rate.",
      },
    }
    for id, tier in pairs(SNAG_BALL_TIERS) do
      mod.content.items:register(id, {
        id = id, name = tier.name, price = tier.price, tossable = true,
        description = tier.description,
      })
    end

    local function stage()
      return tonumber(mod.save:get("g2_intro_stage", STAGE_NEW)) or STAGE_NEW
    end
    local function setStage(v) mod.save:set("g2_intro_stage", v) end
    local function rewardClaimed()
      return mod.save:get("g2_intro_rewarded", false) == true
    end
    local function setRewardClaimed(v)
      mod.save:set("g2_intro_rewarded", v and true or false)
    end
    local function contractStage()
      return tonumber(mod.save:get("g2_contract1_stage", CONTRACT_NONE)) or CONTRACT_NONE
    end
    local function setContractStage(v) mod.save:set("g2_contract1_stage", v) end
    local function contractChoice()
      local v = mod.save:get("g2_contract1_choice", "")
      return CONTRACTS[v] and v or nil
    end
    local function setContractChoice(v)
      mod.save:set("g2_contract1_choice", CONTRACTS[v] and v or "")
    end
    local function contractRewarded()
      return mod.save:get("g2_contract1_rewarded", false) == true
    end
    local function setContractRewarded(v)
      mod.save:set("g2_contract1_rewarded", v and true or false)
    end
    local function ecruteakStage()
      return tonumber(mod.save:get("g2_contract2_stage", CONTRACT_NONE)) or CONTRACT_NONE
    end
    local function setEcruteakStage(v) mod.save:set("g2_contract2_stage", v) end
    local function ecruteakChoice()
      local v = mod.save:get("g2_contract2_choice", "")
      return ECRUTEAK_CONTRACTS[v] and v or nil
    end
    local function setEcruteakChoice(v)
      mod.save:set("g2_contract2_choice", ECRUTEAK_CONTRACTS[v] and v or "")
    end
    local function ecruteakRewarded()
      return mod.save:get("g2_contract2_rewarded", false) == true
    end
    local function setEcruteakRewarded(v)
      mod.save:set("g2_contract2_rewarded", v and true or false)
    end
    -- The Ecruteak payout is TWO items -- the flat fee and the HEIST BALL --
    -- so it needs two flags.  One flag covering both means a full BALL pocket
    -- on the tier ball leaves the whole payout unclaimed, and the fee pays out
    -- again on every visit: a farm, gated on nothing but keeping the bag full.
    local function ecruteakFeePaid()
      return mod.save:get("g2_contract2_feepaid", false) == true
    end
    local function setEcruteakFeePaid(v)
      mod.save:set("g2_contract2_feepaid", v and true or false)
    end
    -- 0.15.2 gives the tier reward its own durable receipt. Older builds
    -- reused g2_contract2_rewarded across the GREAT/HEIST transition, so an
    -- upgraded save could collect the new five-ball fee while being treated
    -- as though its HEIST BALL had already been handed over. If that legacy
    -- flag is set and a HEIST BALL is still in the bag, record the migration
    -- without duplicating it. If none is present, owe one replacement. This
    -- can replace a HEIST BALL an old player already used, but only once; that
    -- player-favouring edge is safer than permanently withholding the tier.
    local function ecruteakHeistPaid()
      if mod.save:get("g2_contract2_heistpaid_v2", false) == true then
        return true
      end
      if ecruteakRewarded() then
        local inv = mod.game and mod.game.save and mod.game.save.inventory
        if type(inv) == "table" and (tonumber(inv.HEIST_BALL) or 0) > 0 then
          mod.save:set("g2_contract2_heistpaid_v2", true)
          return true
        end
      end
      return false
    end
    local function setEcruteakHeistPaid(v)
      local paid = v and true or false
      mod.save:set("g2_contract2_heistpaid_v2", paid)
      -- Keep the legacy receipt current for downgrade/save compatibility.
      setEcruteakRewarded(paid)
    end
    local function olivineStage()
      return tonumber(mod.save:get("g2_contract3_stage", CONTRACT_NONE)) or CONTRACT_NONE
    end
    local function setOlivineStage(v) mod.save:set("g2_contract3_stage", v) end
    local function olivineChoice()
      local v = mod.save:get("g2_contract3_choice", "")
      return OLIVINE_CONTRACTS[v] and v or nil
    end
    local function setOlivineChoice(v)
      mod.save:set("g2_contract3_choice", OLIVINE_CONTRACTS[v] and v or "")
    end
    local function olivineRewarded()
      return mod.save:get("g2_contract3_rewarded", false) == true
    end
    local function setOlivineRewarded(v)
      mod.save:set("g2_contract3_rewarded", v and true or false)
    end
    local function olivineHeistPaid()
      return mod.save:get("g2_contract3_heistpaid", false) == true
    end
    local function setOlivineHeistPaid(v)
      mod.save:set("g2_contract3_heistpaid", v and true or false)
    end

    local introBattleActive = false
    local contractBattleActive = false
    local contractCleanupPending = false
    local ecruteakBattleActive = false
    local ecruteakCleanupPending = false
    local olivineBattleActive = false
    local olivineCleanupPending = false
    local cleanupPending = false
    local girlClassIx, girlMemberIx
    local contractCarriers = {}
    local ecruteakCarriers = {}
    local olivineCarriers = {}

    -- Gold VIP provenance.  Keep this list conservative: the rival, all 16
    -- Gym Leaders, the Elite Four/Champion, and Red.  The value is stamped on
    -- the Pokemon at snag time so later fence payouts never depend on the
    -- source trainer still existing.
    local GOLD_VIP_CLASSES = {
      RIVAL1 = true, RIVAL2 = true,
      FALKNER = true, WHITNEY = true, BUGSY = true, MORTY = true,
      PRYCE = true, JASMINE = true, CHUCK = true, CLAIR = true,
      BROCK = true, MISTY = true, LT_SURGE = true, ERIKA = true,
      JANINE = true, SABRINA = true, BLAINE = true, BLUE = true,
      WILL = true, KOGA = true, BRUNO = true, KAREN = true,
      CHAMPION = true, RED = true,
    }
    local activeTrainer = nil

    local function resolveTrainerClassName(classIx)
      local classes = mod.game and mod.game.data and mod.game.data.gen2Trainers
          and mod.game.data.gen2Trainers.classes
      if type(classes) ~= "table" then return nil end
      for name, row in pairs(classes) do
        if type(row) == "table" and row.index == classIx then return name end
      end
      return nil
    end

    local function resolveTrainerMemberName(className, memberIx)
      local classes = mod.game and mod.game.data and mod.game.data.gen2Trainers
          and mod.game.data.gen2Trainers.classes
      local row = classes and className and classes[className]
      local tr = row and row.trainers and row.trainers[memberIx]
      return tr and tr.name or nil
    end

    -- Declared BEFORE its first use. `errs` used to be defined below
    -- trainerIsVip, which in Lua means the call inside trainerIsVip
    -- compiled to a GLOBAL read of `errs` (nil) rather than the local --
    -- so the one line that reports a broken snag.vip hook would itself
    -- have thrown "attempt to call a nil value". Confirmed from the
    -- bytecode: it was the only global read in the whole file.
    local function errs(fmt, ...)
      local ok, msg = pcall(string.format, fmt, ...)
      pcall(Runtime.reportError, "snag_quest", ok and msg or tostring(fmt))
    end

    -- Compatibility seam for mods that create their own important trainers.
    -- Another mod may:
    --   mod.hooks:wrap("snag.vip", function(next_, vip, ctx)
    --     vip = next_(vip, ctx)
    --     if ctx.npc and ctx.npc.def.name == "MY_BOSS" then return true end
    --     return vip
    --   end)
    -- The answer is captured at encounter time and saved on the stolen mon.
    local function trainerIsVip(ctx)
      local base = GOLD_VIP_CLASSES[ctx.trainerClass] == true
      if Runtime.wantsHook("snag.vip") then
        local ok, value = pcall(Runtime.call, "snag.vip",
          function(v) return v end, base, ctx)
        if ok then return value == true end
        errs("VIP HOOK ERR")
      end
      return base
    end

    mod.exports.owns = mod.exports.owns or {}
    mod.exports.owns.monFields =
      { "snagged", "snagFrom", "snagLevel", "snagVip", "snagBounty" }
    mod.exports.vipClasses = GOLD_VIP_CLASSES

    -- Same valuation function is used by both generations.
    local function snagPayout(mon)
      return computeSnagPayout(mod.game, mon, nil)
    end
    mod.exports.snagPayout = snagPayout

    local function monName(mon)
      if not mon then return "POKEMON" end
      if mon.nickname and mon.nickname ~= "" then return mon.nickname end
      local data = mod.game and mod.game.data
      local def = data and data.pokemon and data.pokemon[mon.species]
      return (def and def.name) or mon.species or "POKEMON"
    end

    local function contractTargetLine(c)
      local species = c and (c.target or c.species) or "POKEMON"
      return "Take " .. species .. "."
    end

    local function objectNamed(world, mapId, name)
      local def = world and world.maps and world.maps[mapId]
      for _, obj in ipairs(def and def.objects or {}) do
        if obj.name == name then return obj end
      end
      return nil
    end

    local function removeNamed(world, mapId, name)
      local obj = objectNamed(world, mapId, name)
      if not obj then return end
      local id = mapId .. "_obj_" .. tostring(obj.index)
      pcall(function() mod.world:removeNpc(id) end)
    end

    local function walkable(map, x, y)
      local ok, res = pcall(map.isWalkableCell, map, x, y)
      return ok and res == true
    end

    local function usable(world, x, y)
      local map = world and world.map
      if not map or not walkable(map, x, y) then return false end
      if world:npcAt(x, y) then return false end
      local okWarp, warp = pcall(map.warpAtCell, map, x, y)
      if okWarp and warp then return false end
      local p = world.player
      if p and p.cellX == x and p.cellY == y then return false end
      return true
    end

    -- Fixed placement test for Cherrygrove.  This is intentionally a guessed
    -- coordinate so device feedback can tune it by exact tile offsets.  Keep
    -- it away from known vanilla objects, doors, signs, and the rival scene.
    local SAILOR_X, SAILOR_Y = 14, 11
    local function sailorCell(world)
      if not (world and world.map) then return nil end
      return SAILOR_X, SAILOR_Y
    end

    local function ensureSailor(world)
      if objectNamed(world, MAP, SAILOR_NAME) then return true end
      local x, y = sailorCell(world)
      if not x then return false end
      local id, err = mod.world:spawnNpc(MAP, {
        name = SAILOR_NAME, sprite = "SPRITE_SAILOR",
        x = x, y = y, movement = MOVE_STANDING_DOWN,
      })
      if not id then errs("SAILOR SPAWN\n%s", tostring(err)); return false end
      return true
    end

    local function ensureFence(world)
      if objectNamed(world, FENCE_MAP, FENCE_NAME) then return true end
      local id, err = mod.world:spawnNpc(FENCE_MAP, {
        name = FENCE_NAME, sprite = "SPRITE_SUPER_NERD",
        x = FENCE_X, y = FENCE_Y, movement = MOVE_STANDING_UP,
      })
      if not id then errs("FENCE SPAWN\n%s", tostring(err)); return false end
      return true
    end

    local function ensureBroker(world)
      if objectNamed(world, GOLDENROD_MAP, BROKER_NAME) then return true end
      local id, err = mod.world:spawnNpc(GOLDENROD_MAP, {
        name = BROKER_NAME, sprite = "SPRITE_SUPER_NERD",
        x = BROKER_X, y = BROKER_Y, movement = MOVE_STANDING_DOWN,
      })
      if not id then errs("BROKER SPAWN\n%s", tostring(err)); return false end
      return true
    end

    local function ensureClueNpc(world)
      if objectNamed(world, GOLDENROD_CITY_MAP, CLUE_NAME) then return true end
      local id, err = mod.world:spawnNpc(GOLDENROD_CITY_MAP, {
        name = CLUE_NAME, sprite = "SPRITE_TEACHER",
        x = CLUE_X, y = CLUE_Y, movement = MOVE_STANDING_DOWN,
      })
      if not id then errs("CLUE SPAWN\n%s", tostring(err)); return false end
      return true
    end

    local function resolveContractCarrier(key)
      local c = CONTRACTS[key]
      if not c then return false end
      local td = mod.game and mod.game.data and mod.game.data.gen2Trainers
      local cls = td and td.classes and td.classes[c.class]
      if not (cls and cls.index and cls.trainers and cls.trainers[1]) then
        return false
      end
      contractCarriers[key] = { classIx = cls.index, memberIx = 1 }
      return true
    end

    local function armContractMark(world)
      local key = contractChoice()
      local c = key and CONTRACTS[key]
      local carrier = key and contractCarriers[key]
      local obj = objectNamed(world, MARK_MAP, MARK_NAME)
      if not (c and carrier and obj) then return false end
      obj.trainer = {
        class = carrier.classIx, member = carrier.memberIx,
        seenText = c.seen, winText = c.win, lossText = c.loss,
      }
      return true
    end

    local function ensureContractMark(world)
      if contractStage() ~= CONTRACT_ACTIVE then return true end
      local key = contractChoice()
      local c = key and CONTRACTS[key]
      local carrier = key and contractCarriers[key]
      if not (c and carrier) then return false end
      local obj = objectNamed(world, MARK_MAP, MARK_NAME)
      if obj then
        if not obj.trainer then armContractMark(world) end
        return true
      end
      local id, err = mod.world:spawnNpc(MARK_MAP, {
        name = MARK_NAME, sprite = c.sprite,
        x = MARK_X, y = MARK_Y, movement = MOVE_STANDING_DOWN,
        trainer = {
          class = carrier.classIx, member = carrier.memberIx,
          seenText = c.seen, winText = c.win, lossText = c.loss,
        },
      })
      if not id then errs("MARK SPAWN\n%s", tostring(err)); return false end
      return true
    end

    local function ensureEcruteakContact(world)
      if objectNamed(world, ECRUTEAK_MAP, ECRUTEAK_CONTACT_NAME) then return true end
      local id, err = mod.world:spawnNpc(ECRUTEAK_MAP, {
        name = ECRUTEAK_CONTACT_NAME, sprite = "SPRITE_GENTLEMAN",
        x = ECRUTEAK_CONTACT_X, y = ECRUTEAK_CONTACT_Y,
        movement = MOVE_STANDING_DOWN,
      })
      if not id then errs("ECR CONTACT\n%s", tostring(err)); return false end
      return true
    end

    local function ensureEcruteakWitness(world)
      if objectNamed(world, ECRUTEAK_MAP, ECRUTEAK_WITNESS_NAME) then return true end
      local id, err = mod.world:spawnNpc(ECRUTEAK_MAP, {
        name = ECRUTEAK_WITNESS_NAME, sprite = "SPRITE_GRAMPS",
        x = ECRUTEAK_WITNESS_X, y = ECRUTEAK_WITNESS_Y,
        movement = MOVE_STANDING_DOWN,
      })
      if not id then errs("ECR WITNESS\n%s", tostring(err)); return false end
      return true
    end

    local function resolveEcruteakCarrier(key)
      local c = ECRUTEAK_CONTRACTS[key]
      if not c then return false end
      local td = mod.game and mod.game.data and mod.game.data.gen2Trainers
      local cls = td and td.classes and td.classes[c.class]
      if not (cls and cls.index and cls.trainers and cls.trainers[1]) then
        return false
      end
      ecruteakCarriers[key] = { classIx = cls.index, memberIx = 1 }
      return true
    end

    local function armEcruteakMark(world)
      local key = ecruteakChoice()
      local c = key and ECRUTEAK_CONTRACTS[key]
      local carrier = key and ecruteakCarriers[key]
      local obj = c and objectNamed(world, c.map, ECRUTEAK_MARK_NAME)
      if not (c and carrier and obj) then return false end
      obj.trainer = {
        class = carrier.classIx, member = carrier.memberIx,
        seenText = c.seen, winText = c.win, lossText = c.loss,
      }
      return true
    end

    local function ensureEcruteakMark(world)
      if ecruteakStage() ~= CONTRACT_ACTIVE then return true end
      local key = ecruteakChoice()
      local c = key and ECRUTEAK_CONTRACTS[key]
      local carrier = key and ecruteakCarriers[key]
      if not (c and carrier) then return false end
      local obj = objectNamed(world, c.map, ECRUTEAK_MARK_NAME)
      if obj then
        if not obj.trainer then armEcruteakMark(world) end
        return true
      end
      local id, err = mod.world:spawnNpc(c.map, {
        name = ECRUTEAK_MARK_NAME, sprite = c.sprite,
        x = c.x, y = c.y, movement = MOVE_STANDING_DOWN,
        trainer = {
          class = carrier.classIx, member = carrier.memberIx,
          seenText = c.seen, winText = c.win, lossText = c.loss,
        },
      })
      if not id then errs("ECR MARK\n%s", tostring(err)); return false end
      return true
    end

    local function ensureOlivineContact(world)
      if objectNamed(world, OLIVINE_MAP, OLIVINE_CONTACT_NAME) then return true end
      local id, err = mod.world:spawnNpc(OLIVINE_MAP, {
        name = OLIVINE_CONTACT_NAME, sprite = "SPRITE_SAILOR",
        x = OLIVINE_CONTACT_X, y = OLIVINE_CONTACT_Y,
        movement = MOVE_STANDING_DOWN,
      })
      if not id then errs("OLI CONTACT\n%s", tostring(err)); return false end
      return true
    end

    local function ensureOlivineWitness(world)
      if objectNamed(world, OLIVINE_MAP, OLIVINE_WITNESS_NAME) then return true end
      local id, err = mod.world:spawnNpc(OLIVINE_MAP, {
        name = OLIVINE_WITNESS_NAME, sprite = "SPRITE_ROCKER",
        x = OLIVINE_WITNESS_X, y = OLIVINE_WITNESS_Y,
        movement = MOVE_STANDING_DOWN,
      })
      if not id then errs("OLV WITNESS\n%s", tostring(err)); return false end
      return true
    end

    local function resolveOlivineCarrier(key)
      local c = OLIVINE_CONTRACTS[key]
      if not c then return false end
      local td = mod.game and mod.game.data and mod.game.data.gen2Trainers
      local cls = td and td.classes and td.classes[c.class]
      if not (cls and cls.index and cls.trainers and cls.trainers[1]) then
        return false
      end
      olivineCarriers[key] = { classIx = cls.index, memberIx = 1 }
      return true
    end

    local function armOlivineMark(world)
      local key = olivineChoice()
      local c = key and OLIVINE_CONTRACTS[key]
      local carrier = key and olivineCarriers[key]
      local obj = c and objectNamed(world, c.map, OLIVINE_MARK_NAME)
      if not (c and carrier and obj) then return false end
      obj.trainer = {
        class = carrier.classIx, member = carrier.memberIx,
        seenText = c.seen, winText = c.win, lossText = c.loss,
      }
      return true
    end

    local function ensureOlivineMark(world)
      if olivineStage() ~= CONTRACT_ACTIVE then return true end
      local key = olivineChoice()
      local c = key and OLIVINE_CONTRACTS[key]
      local carrier = key and olivineCarriers[key]
      if not (c and carrier) then return false end
      local obj = objectNamed(world, c.map, OLIVINE_MARK_NAME)
      if obj then
        if not obj.trainer then armOlivineMark(world) end
        return true
      end
      local id, err = mod.world:spawnNpc(c.map, {
        name = OLIVINE_MARK_NAME, sprite = c.sprite,
        x = c.x, y = c.y, movement = MOVE_STANDING_DOWN,
        trainer = {
          class = carrier.classIx, member = carrier.memberIx,
          seenText = c.seen, winText = c.win, lossText = c.loss,
        },
      })
      if not id then errs("OLI MARK\n%s", tostring(err)); return false end
      return true
    end

    local function giveHeistBalls(n)
      local game = mod.game
      local save, data = game and game.save, game and game.data
      if not (save and save.inventory and data) then return false end
      return Bag.add(save, "HEIST_BALL", n or 1, data) == true
    end

    -- The girl is placed in the first safe orthogonal cell beside the player.
    -- sight=1 + facing the player makes Gold's own CheckTrainerBattle engage
    -- her automatically on the next world tick; no fake battle launcher.
    local function spawnGirlForAmbush(world)
      removeNamed(world, MAP, GIRL_NAME)
      local p = world and world.player
      if not p then return false end
      local choices = {
        { 0, -1, "down" }, { 1, 0, "left" },
        { 0, 1, "up" }, { -1, 0, "right" },
      }
      local x, y, facing
      for _, c in ipairs(choices) do
        local tx, ty = p.cellX + c[1], p.cellY + c[2]
        if usable(world, tx, ty) then x, y, facing = tx, ty, c[3]; break end
      end
      if not x then return false end
      local id, err = mod.world:spawnNpc(MAP, {
        name = GIRL_NAME, sprite = "SPRITE_LASS",
        x = x, y = y, movement = MOVE_STANDING_DOWN, sight = 1,
        trainer = {
          class = girlClassIx, member = girlMemberIx,
          seenText = GIRL_SEEN, winText = GIRL_WIN, lossText = GIRL_LOSS,
        },
      })
      if not id then errs("GIRL SPAWN\n%s", tostring(err)); return false end
      local h = mod.world:npc(MAP, GIRL_NAME)
      if h and facing then pcall(h.face, h, facing) end
      return true
    end

    -- Exactly one ball for the intro.
    --
    -- 0.14.40: this used to Bag.remove the player's ENTIRE SNAG BALL stack
    -- first, to normalize a leftover stack from the private test builds
    -- that stocked Gold marts.  Those builds are gone and marts are not
    -- stocked on Gold, so the only thing that line can do now is destroy
    -- balls belonging to someone carrying a save from one of them.  Adding
    -- is enough; the intro is gated on STAGE_NEW and cannot repeat.
    local function giveOneSnagBall()
      local game = mod.game
      local save, data = game and game.save, game and game.data
      if not (save and save.inventory and data) then return false end
      return Bag.add(save, "SNAG_BALL", 1, data) == true
    end

    -- Completing a contract pays a flat fee on top of whatever the mark
    -- itself fences for (0.14.41).  Finishing the Goldenrod job used to pay
    -- literally nothing -- the broker congratulated the player and that was
    -- the whole reward -- so a contract cost balls and returned none.
    local CONTRACT_REWARD_BALLS = 5

    local function giveSnagBalls(n)
      local game = mod.game
      local save, data = game and game.save, game and game.data
      if not (save and save.inventory and data) then return false end
      return Bag.add(save, "SNAG_BALL", n, data) == true
    end

    local function giveRewardSnagBalls()
      return giveSnagBalls(5)
    end

    ------------------------------------------------------------------
    -- THE DEAD-END VALVE (0.14.40).
    --
    -- Every Snag Ball on Gold comes from a finite list: one from the
    -- sailor, five from his reward, one HEIST BALL from Ecruteak.  After
    -- that the fence is the only source, and it pays for a SNAGGED
    -- Pokemon -- so it costs a ball to earn balls.  Miss with the last
    -- one holding nothing stolen and the questline is over permanently,
    -- with no recovery path in the game.  Gold marts are deliberately
    -- not stocked, so Red's mart safety net does not exist here.
    --
    -- Reported from device play, 2026-08-13.
    --
    -- The fix is a valve, not an economy: the fence hands over exactly
    -- one base ball when the player has NOTHING to act with.  Both
    -- halves of that test matter --
    --
    --   * count every tier, not just SNAG_BALL.  A player holding a
    --     HEIST BALL is not stuck, and firing for them would hand out a
    --     free ball on every visit.
    --   * "sellable" means the fence would actually take it: the sale
    --     path below refuses to leave the player with no Pokemon
    --     (#party < 2), so a lone snagged mon is NOT a way out and must
    --     not suppress the valve.  Getting this wrong leaves the player
    --     exactly as stuck as before, which is the failure this whole
    --     change exists to remove.
    --
    -- It can fire repeatedly -- throw the free ball, miss, walk back,
    -- get another.  That is the point and it is not farmable: it only
    -- ever fires at total zero, so nothing can be accumulated.
    ------------------------------------------------------------------
    local function snagBallsHeld()
      local inv = mod.game and mod.game.save and mod.game.save.inventory
      if type(inv) ~= "table" then return 0 end
      local n = 0
      for id in pairs(SNAG_BALL_TIERS) do
        n = n + (tonumber(inv[id]) or 0)
      end
      return n
    end

    local function hasSellableSnaggedMon()
      local party = mod.game and mod.game.save and mod.game.save.party
      if type(party) ~= "table" or #party < 2 then return false end
      for _, mon in ipairs(party) do
        if mon and mon.snagged == true then return true end
      end
      return false
    end

    local function isDeadEnded()
      return snagBallsHeld() == 0 and not hasSellableSnaggedMon()
    end

    -- One-time retro-fit (0.14.41).  A mon snagged before this version carries
    -- no snagBounty field at all, so a mark already sitting in the player's
    -- party would still fence for the old price.  nil means "snagged before
    -- the field existed"; every mon snagged from here on gets an explicit
    -- true or false, so this can never fire for a new one.
    --
    -- Deliberately narrow: the contract must be COMPLETE and the species must
    -- be the one that contract advertised.  It can still be fooled by a mon of
    -- the same species snagged from an unrelated trainer on an old save, which
    -- is a few balls in the player's favour once, and is worth less than
    -- leaving a real bounty underpaid.
    local function ensureBountyFlag(mon)
      if not mon or mon.snagged ~= true or mon.snagBounty ~= nil then return end
      local c1 = CONTRACTS[contractChoice() or ""]
      local c2 = ECRUTEAK_CONTRACTS[ecruteakChoice() or ""]
      local c3 = OLIVINE_CONTRACTS[olivineChoice() or ""]
      local isMark =
        (c1 and contractStage() == CONTRACT_DONE and mon.species == c1.species)
        or (c2 and ecruteakStage() == CONTRACT_DONE and mon.species == c2.target)
        or (c3 and olivineStage() == CONTRACT_DONE and mon.species == c3.target)
      mon.snagBounty = isMark and true or false
    end

    -- Resolve one real LASS carrier from the live Gold trainer table.  The
    -- trainer's portrait/name/money/AI remain vanilla; trainer.party below
    -- replaces only her team with our shiny MEOWTH.
    local function resolveGirlCarrier()
      local td = mod.game and mod.game.data and mod.game.data.gen2Trainers
      local cls = td and td.classes and td.classes.LASS
      if not (cls and cls.index) then return false end
      for i, row in ipairs(cls.trainers or {}) do
        if row.id == "CARRIE" or row.name == "CARRIE" then
          girlClassIx, girlMemberIx = cls.index, i
          return true
        end
      end
      if cls.trainers and cls.trainers[1] then
        girlClassIx, girlMemberIx = cls.index, 1
        return true
      end
      return false
    end

    mod.events:on("game.ready", function(p)
      local game = p and p.game
      local kantoBalls = mod.find("kanto_balls")
      local api = kantoBalls and kantoBalls.exports
      if api and type(api.requestBallSlots) == "function" then
        api.requestBallSlots(2)
      end
      if game and game.data and game.data.items then
        local def = game.data.items.SNAG_BALL
        if def then def.pocket = "BALL" end
        local heist = game.data.items.HEIST_BALL
        if heist then heist.pocket = "BALL" end
      end
      if not resolveGirlCarrier() then errs("GIRL CARRIER\nLASS missing") end
      for key in pairs(CONTRACTS) do
        if not resolveContractCarrier(key) then
          errs("MARK CARRIER\n%s missing", key)
        end
      end
      for key in pairs(ECRUTEAK_CONTRACTS) do
        if not resolveEcruteakCarrier(key) then
          errs("ECR CARRIER\n%s missing", key)
        end
      end
      for key in pairs(OLIVINE_CONTRACTS) do
        if not resolveOlivineCarrier(key) then
          errs("OLI CARRIER\n%s missing", key)
        end
      end
    end)

    -- Cherrygrove placement/recovery.  A stale ARMED state cannot normally be
    -- saved (the battle auto-starts immediately), but resetting it on a fresh
    -- map entry makes a test save recover instead of getting stuck.
    mod.events:on("map.entered", function(ev)
      if not ev then return end
      local ok, err = pcall(function()
        local world = mod.world:overworld()
        if not world then return end

        -- After a successful intro, leave both actors standing in Cherrygrove
        -- for the rest of that visit.  Clean them up only once the player has
        -- actually entered another map; on later Cherrygrove visits they stay
        -- gone because STAGE_DONE is durable quest state.
        if ev.mapId ~= MAP then
          if stage() == STAGE_DONE then
            removeNamed(world, MAP, GIRL_NAME)
            if rewardClaimed() then
              removeNamed(world, MAP, SAILOR_NAME)
            end
            if ev.mapId == FENCE_MAP then ensureFence(world) end
            if rewardClaimed() and ev.mapId == GOLDENROD_MAP then
              ensureBroker(world)
            end
            if rewardClaimed() and ev.mapId == GOLDENROD_CITY_MAP
                and contractStage() == CONTRACT_ACTIVE then
              ensureClueNpc(world)
            elseif contractStage() == CONTRACT_DONE
                and ev.mapId ~= GOLDENROD_CITY_MAP then
              removeNamed(world, GOLDENROD_CITY_MAP, CLUE_NAME)
            end
            if rewardClaimed() and ev.mapId == MARK_MAP then
              if contractStage() == CONTRACT_ACTIVE then
                ensureContractMark(world)
              elseif contractStage() == CONTRACT_DONE then
                removeNamed(world, MARK_MAP, MARK_NAME)
              end
            elseif contractStage() == CONTRACT_DONE and ev.mapId ~= MARK_MAP then
              -- Let a successfully snagged mark remain for aftermath dialogue
              -- until the player actually leaves the Underground.
              removeNamed(world, MARK_MAP, MARK_NAME)
            end

            -- Ecruteak contract #2 unlocks only after the Goldenrod target was
            -- actually snagged. Contact persists; witness/mark are job state.
            if contractStage() == CONTRACT_DONE then
              local ec = ECRUTEAK_CONTRACTS[ecruteakChoice() or ""]
              if ev.mapId == ECRUTEAK_MAP then
                ensureEcruteakContact(world)
                if ecruteakStage() == CONTRACT_ACTIVE then
                  ensureEcruteakWitness(world)
                elseif ecruteakStage() == CONTRACT_DONE then
                  removeNamed(world, ECRUTEAK_MAP, ECRUTEAK_WITNESS_NAME)
                end
              end
              if ec and ev.mapId == ec.map then
                if ecruteakStage() == CONTRACT_ACTIVE then
                  ensureEcruteakMark(world)
                elseif ecruteakStage() == CONTRACT_DONE then
                  -- Keep the completed mark until the player leaves this map.
                end
              elseif ec and ecruteakStage() == CONTRACT_DONE then
                removeNamed(world, ec.map, ECRUTEAK_MARK_NAME)
              end
            end

            -- Olivine opens only after both halves of Ecruteak's payout are
            -- collected. The foreman persists and becomes a fence; the mark
            -- exists only while its chosen route is active or for the single
            -- post-snag conversation before the player leaves that map.
            if ecruteakStage() == CONTRACT_DONE
                and ecruteakFeePaid() and ecruteakHeistPaid() then
              local oc = OLIVINE_CONTRACTS[olivineChoice() or ""]
              if ev.mapId == OLIVINE_MAP then
                ensureOlivineContact(world)
                if olivineStage() == CONTRACT_ACTIVE then
                  ensureOlivineWitness(world)
                else
                  removeNamed(world, OLIVINE_MAP, OLIVINE_WITNESS_NAME)
                end
              end
              if oc and ev.mapId == oc.map then
                if olivineStage() == CONTRACT_ACTIVE then
                  ensureOlivineMark(world)
                elseif olivineStage() == CONTRACT_DONE then
                  removeNamed(world, oc.map, OLIVINE_MARK_NAME)
                end
              elseif oc and olivineStage() == CONTRACT_DONE then
                removeNamed(world, oc.map, OLIVINE_MARK_NAME)
              end
            end
          end
          return
        end

        if stage() == STAGE_ARMED then
          setStage(STAGE_NEW)
          removeNamed(world, MAP, GIRL_NAME)
        end
        if stage() ~= STAGE_DONE or not rewardClaimed() then
          ensureSailor(world)
        end
      end)
      if not ok then errs("ENTER\n%s", tostring(err)) end
    end)

    -- Sailor dialogue.  Gold mod-owned NPCs fall through to kind="none";
    -- queue one paged text box, then gift the ball and create the sight-cone
    -- trainer only after the player dismisses the final page.
    mod.events:on("world.interacted", function(ev)
      if not ev or ev.mapId ~= MAP or ev.kind ~= "none" then return end
      local world = mod.world:overworld()
      local sailor = objectNamed(world, MAP, SAILOR_NAME)
      local girl = objectNamed(world, MAP, GIRL_NAME)
      local isSailor = sailor and ev.x == sailor.x and ev.y == sailor.y
      local isGirl = girl and ev.x == girl.x and ev.y == girl.y
      if not isSailor and not isGirl then return end

      local cur = mod.world:current()
      local opposite = { up = "down", down = "up", left = "right", right = "left" }
      local who = isSailor and SAILOR_NAME or GIRL_NAME
      local h = mod.world:npc(MAP, who)
      if h and cur and cur.facing then pcall(h.face, h, opposite[cur.facing]) end

      -- After the successful snag both NPCs remain in town until the player
      -- leaves, so give each of them a short aftermath line instead of
      -- leaving inert scenery behind.
      if stage() == STAGE_DONE then
        if isSailor and not rewardClaimed() then
          mod.world:queueScript({
            { "text", "SAILOR: Good.\nMEOWTH is safe." },
            { "text", "You handled that\ncleanly." },
            { "text", "Here. Five more\nSNAG BALLs." },
            { "text", "Need more BALLs?\nTry Route 36." },
            { "text", "Near SUDOWOODO,\na fence trades." },
          }, {
            onDone = function()
              local ok, err = pcall(function()
                if rewardClaimed() then return end
                if not giveRewardSnagBalls() then
                  errs("REWARD BALLS\nBAG FULL")
                  return
                end
                setRewardClaimed(true)
              end)
              if not ok then errs("SAILOR REWARD\n%s", tostring(err)) end
            end,
          })
          return
        end

        local text
        if isSailor then
          mod.world:queueScript({
            { "text", "Need more BALLs?\nTry Route 36." },
            { "text", "Near SUDOWOODO,\na fence trades." },
          })
        else
          mod.world:queueScript({
            { "text", "LASS: You stole\nmy MEOWTH!" },
            { "text", "Take care of\nMEOWTH." },
          })
        end
        return
      end

      -- Before the battle only the sailor is conversational; the girl is
      -- armed as a trainer and Gold owns her engagement dialogue.
      if not isSailor then return end

      mod.world:queueScript({
        { "text", "SAILOR: See that\ngirl over there?" },
        { "text", "That shiny MEOWTH\nwas stolen." },
        { "text", "Take this\nSNAG BALL." },
      }, {
        onDone = function()
          local ok, err = pcall(function()
            if stage() == STAGE_DONE then return end
            if not girlClassIx and not resolveGirlCarrier() then
              errs("NO LASS CARRIER")
              return
            end
            if not giveOneSnagBall() then
              errs("SNAG BALL\nBAG FULL")
              return
            end
            setStage(STAGE_ARMED)
            local w = mod.world:overworld()
            if not spawnGirlForAmbush(w) then
              setStage(STAGE_NEW)
              errs("GIRL AMBUSH\nNO SAFE CELL")
            end
          end)
          if not ok then errs("SAILOR DONE\n%s", tostring(err)) end
        end,
      })
    end)

    ------------------------------------------------------------------
    -- ONE sale flow, spoken by different people (0.14.43).
    --
    -- The first dialogue is only an invitation; once it closes, Gold's real
    -- Gen2PartyMenu is opened through World:selectPartyMon.  Selecting a mon
    -- is an offer, not an irreversible sale: valid stolen mons get a quoted
    -- payout and an explicit YES/NO before anything is removed.
    --
    -- This is extracted rather than copied because of what it protects, all
    -- of which is easy to get subtly wrong and expensive when it is:
    --
    --   * the player's last Pokemon is never sellable (#party < 2);
    --   * the slot is RE-VERIFIED after the confirmation box, because the
    --     party can move while a menu is open;
    --   * payment lands BEFORE the Pokemon is removed, so a full BALL pocket
    --     costs the player nothing instead of eating the mon;
    --   * the dead-end valve runs first, so every fence is a way out rather
    --     than only the one the player happens to be standing next to.
    --
    -- A new fence is therefore a VOICE table and a gate.  It is never a
    -- second copy of this function -- two copies drift, and the copy that
    -- drifts is the one that loses somebody's Pokemon.
    ------------------------------------------------------------------
    local function runFenceSale(voice)
      if isDeadEnded() then
        local game = mod.game
        local save, data = game and game.save, game and game.data
        if not (save and save.inventory and data) then return end
        if Bag.add(save, "SNAG_BALL", 1, data) ~= true then
          mod.world:queueScript({ { "text", voice.valveFull } })
          return
        end
        mod.world:queueScript({ { "text", voice.valveGive } })
        return
      end

      mod.world:queueScript({ { "text", voice.invite } }, {
        onDone = function()
          local w = mod.world:overworld()
          local game = mod.game
          local save = game and game.save
          if not (w and save and save.party) then return end
          if #save.party < 2 then
            mod.world:queueScript({ { "text", voice.lastMon } })
            return
          end
          w:selectPartyMon("choose", function(index, picked)
            if not index or not picked then return end
            if picked.snagged ~= true then
              mod.world:queueScript({ { "text", voice.notSnagged } })
              return
            end
            ensureBountyFlag(picked)
            local n = snagPayout(picked)
            local name = monName(picked)
            mod.world:queueScript({ { "text", string.format(
              voice.quote, name, n, n == 1 and "" or "s") } }, {
              onDone = function()
                local ChoiceBox = require("src.ui.ChoiceBox")
                local g = mod.game
                if not (g and g.stack) then return end
                g.stack:push(ChoiceBox.new(g, function(yes)
                  if not yes then
                    mod.world:queueScript({ { "text", voice.declined } })
                    return
                  end
                  local party = g.save and g.save.party
                  if not party or #party < 2 or party[index] ~= picked then
                    mod.world:queueScript({ { "text", voice.changed } })
                    return
                  end
                  -- Pay first. If the BALL pocket cannot take the reward,
                  -- the Pokemon never leaves the party.
                  if Bag.add(g.save, "SNAG_BALL", n, g.data) ~= true then
                    mod.world:queueScript({ { "text", voice.noRoom } })
                    return
                  end
                  table.remove(party, index)
                  mod.world:queueScript({ { "text", string.format(
                    voice.done, n, n == 1 and "" or "s") } })
                end, { defaultNo = true }))
              end,
            })
          end)
        end,
      })
    end

    -- The Route 36 fence: a professional, and the only one who was ever in
    -- this business for its own sake.
    local ROUTE36_VOICE = {
      invite = "FENCE: I deal in\nspecial POKEMON.\f"
        .. "Show me something\nyou... acquired.",
      lastMon = "FENCE: Not your\nlast POKEMON.\f"
        .. "Come back with\nanother one.",
      -- Three of these were over the 18-column line width and had been
      -- soft-wrapping in game since 0.14.38 (0.14.44).  `quote` overflowed
      -- only for a long nickname, which is why it survived testing: the
      -- name sat after "FENCE: " on the same line, so a 10-character
      -- nickname made 20.  It gets its own box now, the way the broker and
      -- contact voices do.  Wording is otherwise unchanged.
      notSnagged = "FENCE: That one's\nclean.\fI only buy hot\ngoods.",
      quote = "%s...\fI can do %d SNAG\nBALL%s. Deal?",
      declined = "FENCE: Your call.\nI'll be around.",
      changed = "FENCE: Something\nchanged. No deal.",
      noRoom = "FENCE: No room for\nmy payment.\fClear some space.",
      done = "FENCE: Done.\f%d SNAG BALL%s.\nForget we met.",
      valveFull = "FENCE: Your BAG's\nfull. Clear space.",
      valveGive = "FENCE: No BALLs,\nno goods.\f"
        .. "You're no use to\nme like that.\f"
        .. "Here. One SNAG\nBALL. On credit.\f"
        .. "Don't waste it.",
    }

    -- The broker treats every sale as another staff transaction.
    local BROKER_VOICE = {
      invite = "BROKER: Got stock?\nLet's talk terms.",
      lastMon = "BROKER: One left?\nYour last stays.",
      notSnagged = "BROKER: Clean.\nNot on my ledger.",
      quote = "%s.\fBROKER: %d SNAG\nBALL%s. Approve?",
      declined = "BROKER: Held back.\nWe'll revisit.",
      changed = "BROKER: Inventory\nchanged. Again.",
      noRoom = "BROKER: BAG full.\nMake room first.",
      done = "BROKER: Transfer\napproved.\f%d SNAG BALL%s.\nGood work.",
      valveFull = "BROKER: BAG full.\nMake room first.",
      valveGive = "BROKER: No stock,\nno BALLs.\f"
        .. "Advance: one SNAG\nBALL.\f"
        .. "Pay it back in\nresults.",
    }

    -- The contact buys leverage and makes clear that refusal is temporary.
    local CONTACT_VOICE = {
      invite = "CONTACT: Goods?\nShow me. Quietly.",
      lastMon = "CONTACT: Last one?\nNo. Stay useful.",
      notSnagged = "CONTACT: Clean.\nWorthless to me.",
      quote = "%s.\fCONTACT: %d SNAG\nBALL%s. Decide.",
      declined = "CONTACT: Refused.\nFor now.",
      changed = "CONTACT: Changed.\nStart again.",
      noRoom = "CONTACT: BAG full.\nClear it.",
      done = "CONTACT: Accepted.\f%d SNAG BALL%s.\nYou saw nothing.",
      valveFull = "CONTACT: BAG full.\nClear it.",
      valveGive = "CONTACT: Empty?\nPathetic.\f"
        .. "One SNAG BALL.\nA final courtesy.\f"
        .. "Bring me something\nworth my time.",
    }

    -- The foreman speaks like a shipping boss: every sale is cargo moved.
    local FOREMAN_VOICE = {
      invite = "FOREMAN: Cargo?\nI can move it.",
      lastMon = "FOREMAN: Last one?\nKeep your crew.",
      notSnagged = "FOREMAN: Papers on\nthat one. No.",
      quote = "%s.\fFOREMAN: %d SNAG\nBALL%s. Loading?",
      declined = "FOREMAN: Hold it.\nDock stays open.",
      changed = "FOREMAN: Manifest\nchanged. No deal.",
      noRoom = "FOREMAN: BAG full.\nClear deck space.",
      done = "FOREMAN: Shipped.\f%d SNAG BALL%s.\nJob closed.",
      valveFull = "FOREMAN: BAG full.\nClear deck space.",
      valveGive = "FOREMAN: No BALLs?\nNothing to ship.\f"
        .. "One SNAG BALL.\nOff the books.\f"
        .. "Bring me something\nworth shipping.",
    }

    -- Goldenrod contract #1.  The broker introduces the first real choice:
    -- PSYCHIC/NORMAL/BUG.  The choice is durable for this contract and spawns
    -- one real trainer mark elsewhere in the city.  There is no free ball and
    -- no guaranteed catch here: this is the first normal Snag job.
    mod.events:on("world.interacted", function(ev)
      if not ev or ev.kind ~= "none" then return end
      if ev.mapId ~= GOLDENROD_MAP
          and ev.mapId ~= GOLDENROD_CITY_MAP
          and ev.mapId ~= MARK_MAP then return end
      if stage() ~= STAGE_DONE or not rewardClaimed() then return end
      local world = mod.world:overworld()
      local broker = objectNamed(world, GOLDENROD_MAP, BROKER_NAME)
      local clue = objectNamed(world, GOLDENROD_CITY_MAP, CLUE_NAME)
      local mark = objectNamed(world, MARK_MAP, MARK_NAME)
      local isBroker = ev.mapId == GOLDENROD_MAP
          and broker and ev.x == broker.x and ev.y == broker.y
      local isClue = ev.mapId == GOLDENROD_CITY_MAP
          and clue and ev.x == clue.x and ev.y == clue.y
      local isMark = ev.mapId == MARK_MAP
          and mark and ev.x == mark.x and ev.y == mark.y
      if not isBroker and not isClue and not isMark then return end

      local cur = mod.world:current()
      local opposite = { up = "down", down = "up", left = "right", right = "left" }
      local who = isBroker and BROKER_NAME or (isClue and CLUE_NAME or MARK_NAME)
      local whoMap = isBroker and GOLDENROD_MAP
          or (isClue and GOLDENROD_CITY_MAP or MARK_MAP)
      local h = mod.world:npc(whoMap, who)
      if h and cur and cur.facing then pcall(h.face, h, opposite[cur.facing]) end

      if isClue then
        local c = CONTRACTS[contractChoice() or ""]
        if contractStage() == CONTRACT_ACTIVE and c and c.gossip then
          mod.world:queueScript({
            { "text", c.gossip[1] },
            { "text", c.gossip[2] },
          })
        else
          mod.world:queueScript({
            { "text", "Busy city today.\nOdd sights too." },
          })
        end
        return
      end

      if isMark then
        if contractStage() == CONTRACT_DONE then
          local c = CONTRACTS[contractChoice() or ""]
          if c then
            mod.world:queueScript({
              { "text", c.after1 },
              { "text", c.after2 },
            })
          end
        end
        -- Active marks are trainers; Gold owns their interaction before this
        -- kind="none" path, so reaching here means they are currently defanged.
        return
      end

      if contractStage() == CONTRACT_DONE then
        if not contractRewarded() then
          mod.world:queueScript({
            { "text", "BROKER: Good work.\nYour call now." },
            { "text", "Keep it, or bring\nit back to me." },
            { "text", "Five SNAG BALLs.\nYou earned them." },
          }, {
            onDone = function()
              if contractRewarded() then return end
              if not giveSnagBalls(CONTRACT_REWARD_BALLS) then
                mod.world:queueScript({ { "text",
                  "BROKER: Clear your\nBAG. I'll hold it." } })
                return
              end
              setContractRewarded(true)
            end,
          })
        else
          runFenceSale(BROKER_VOICE)
        end
        return
      end

      local chosen = contractChoice()
      if contractStage() == CONTRACT_ACTIVE and chosen then
        local c = CONTRACTS[chosen]
        mod.world:queueScript({
          { "text", "BROKER: Your mark\nis still out." },
          { "text", contractTargetLine(c) },
          { "text", c.clue1 },
          { "text", c.clue2 },
        })
        return
      end

      mod.world:queueScript({
        { "text", "BROKER: I hear\nabout TRAINERS." },
        { "text", "What kind of mark\ndo you want?" },
      }, {
        onDone = function()
          local g = mod.game
          if not (g and g.stack) then return end
          local items = menuItems(CONTRACT_ORDER, CONTRACTS)
          local menu
          menu = ListMenu.new(g, "CHOOSE A LEAD", items, {
            kind = "snag.contract",
            onChoose = function(item, list)
              list:close()
              local key = item and item.value
              local c = key and CONTRACTS[key]
              if not c then return end
              setContractChoice(key)
              setContractStage(CONTRACT_ACTIVE)
              local w = mod.world:overworld()
              if w then ensureContractMark(w) end
              mod.world:queueScript({
                { "text", "BROKER: Good.\nI know someone." },
                { "text", contractTargetLine(c) },
                { "text", c.clue1 },
                { "text", c.clue2 },
              })
            end,
          })
          g.stack:push(menu)
        end,
      })
    end)

    -- Ecruteak contract #2: choose the TRAINER archetype, follow neutral
    -- town gossip, then decide what to steal from a multi-Pokemon party.
    mod.events:on("world.interacted", function(ev)
      if not ev or ev.kind ~= "none" then return end
      if contractStage() ~= CONTRACT_DONE then return end

      local ec = ECRUTEAK_CONTRACTS[ecruteakChoice() or ""]
      local allowed = ev.mapId == ECRUTEAK_MAP or (ec and ev.mapId == ec.map)
      if not allowed then return end

      local world = mod.world:overworld()
      local contact = objectNamed(world, ECRUTEAK_MAP, ECRUTEAK_CONTACT_NAME)
      local witness = objectNamed(world, ECRUTEAK_MAP, ECRUTEAK_WITNESS_NAME)
      local mark = ec and objectNamed(world, ec.map, ECRUTEAK_MARK_NAME)

      local isContact = ev.mapId == ECRUTEAK_MAP
          and contact and ev.x == contact.x and ev.y == contact.y
      local isWitness = ev.mapId == ECRUTEAK_MAP
          and witness and ev.x == witness.x and ev.y == witness.y
      local isMark = ec and ev.mapId == ec.map
          and mark and ev.x == mark.x and ev.y == mark.y
      if not isContact and not isWitness and not isMark then return end

      local cur = mod.world:current()
      local opposite = { up = "down", down = "up", left = "right", right = "left" }
      local who = isContact and ECRUTEAK_CONTACT_NAME
          or (isWitness and ECRUTEAK_WITNESS_NAME or ECRUTEAK_MARK_NAME)
      local whoMap = isContact and ECRUTEAK_MAP
          or (isWitness and ECRUTEAK_MAP or (ec and ec.map))
      local h = whoMap and mod.world:npc(whoMap, who)
      if h and cur and cur.facing then pcall(h.face, h, opposite[cur.facing]) end

      if isWitness then
        if ecruteakStage() == CONTRACT_ACTIVE and ec and ec.gossip then
          mod.world:queueScript({
            { "text", ec.gossip[1] },
            { "text", ec.gossip[2] },
          })
        else
          mod.world:queueScript({
            { "text", "Odd tales today.\nNothing new here." },
          })
        end
        return
      end

      if isMark then
        if ecruteakStage() == CONTRACT_DONE and ec then
          mod.world:queueScript({
            { "text", ec.after1 },
            { "text", ec.after2 },
          })
        end
        return
      end

      if ecruteakStage() == CONTRACT_DONE then
        if not (ecruteakFeePaid() and ecruteakHeistPaid()) then
          local rows = {
            { "text", "CONTACT: Nice.\nYou are moving up." },
          }
          if not ecruteakFeePaid() then
            rows[#rows + 1] = { "text", "Five SNAG BALLs\nfor the job." }
          end
          if not ecruteakHeistPaid() then
            rows[#rows + 1] = { "text", "One more thing.\nHEIST BALL." }
            rows[#rows + 1] = { "text", "Better odds.\nSave it for later." }
          end
          mod.world:queueScript(rows, {
            onDone = function()
              -- Each half claimed independently, so a bag that fills partway
              -- through leaves exactly the unpaid half owed.
              if not ecruteakFeePaid() then
                if not giveSnagBalls(CONTRACT_REWARD_BALLS) then
                  mod.world:queueScript({ { "text",
                    "CONTACT: No room.\nClear your BAG." } })
                  return
                end
                setEcruteakFeePaid(true)
              end
              if not ecruteakHeistPaid() then
                if not giveHeistBalls(1) then
                  mod.world:queueScript({ { "text",
                    "CONTACT: No room\nfor the HEIST BALL." } })
                  return
                end
                setEcruteakHeistPaid(true)
              end
            end,
          })
        else
          runFenceSale(CONTACT_VOICE)
        end
        return
      end

      if ecruteakStage() == CONTRACT_ACTIVE and ec then
        mod.world:queueScript({
          { "text", "CONTACT: Your mark\nis still around." },
          { "text", contractTargetLine(ec) },
          { "text", ec.pitch1 },
          { "text", ec.pitch2 },
          { "text", "Ask around town." },
        })
        return
      end

      mod.world:queueScript({
        { "text", "CONTACT: I heard\nof three marks." },
        { "text", "PERFORMER.\nShould be easy." },
        { "text", "MYSTIC.\nBattles well." },
        { "text", "COLLECTOR.\nGuards his finds." },
        { "text", "What kind of mark\ndo you want?" },
      }, {
        onDone = function()
          local g = mod.game
          if not (g and g.stack) then return end
          local items = menuItems(ECRUTEAK_ORDER, ECRUTEAK_CONTRACTS)
          local menu
          menu = ListMenu.new(g, "CHOOSE A MARK", items, {
            kind = "snag.contract2",
            onChoose = function(item, list)
              list:close()
              local key = item and item.value
              local c = key and ECRUTEAK_CONTRACTS[key]
              if not c then return end
              setEcruteakChoice(key)
              setEcruteakStage(CONTRACT_ACTIVE)
              local w = mod.world:overworld()
              if w then
                ensureEcruteakWitness(w)
                ensureEcruteakMark(w)
              end
              mod.world:queueScript({
                { "text", "CONTACT: Good.\n" .. contractTargetLine(c) },
                { "text", "Ask around town." },
              })
            end,
          })
          g.stack:push(menu)
        end,
      })
    end)

    -- Olivine contract #3: choose WHERE to intercept the shipment. The
    -- foreman pays the completed job first, then becomes a permanent fence.
    mod.events:on("world.interacted", function(ev)
      if not ev or ev.kind ~= "none" then return end
      if ecruteakStage() ~= CONTRACT_DONE
          or not ecruteakFeePaid() or not ecruteakHeistPaid() then return end

      local oc = OLIVINE_CONTRACTS[olivineChoice() or ""]
      local allowed = ev.mapId == OLIVINE_MAP or (oc and ev.mapId == oc.map)
      if not allowed then return end

      local world = mod.world:overworld()
      local contact = objectNamed(world, OLIVINE_MAP, OLIVINE_CONTACT_NAME)
      local witness = objectNamed(world, OLIVINE_MAP, OLIVINE_WITNESS_NAME)
      local mark = oc and objectNamed(world, oc.map, OLIVINE_MARK_NAME)
      local isContact = ev.mapId == OLIVINE_MAP
          and contact and ev.x == contact.x and ev.y == contact.y
      local isWitness = ev.mapId == OLIVINE_MAP
          and witness and ev.x == witness.x and ev.y == witness.y
      local isMark = oc and ev.mapId == oc.map
          and mark and ev.x == mark.x and ev.y == mark.y
      if not isContact and not isWitness and not isMark then return end

      local cur = mod.world:current()
      local opposite = { up = "down", down = "up", left = "right", right = "left" }
      local who = isContact and OLIVINE_CONTACT_NAME
          or (isWitness and OLIVINE_WITNESS_NAME or OLIVINE_MARK_NAME)
      local whoMap = (isContact or isWitness) and OLIVINE_MAP
          or (oc and oc.map)
      local h = whoMap and mod.world:npc(whoMap, who)
      if h and cur and cur.facing then pcall(h.face, h, opposite[cur.facing]) end

      if isWitness then
        if olivineStage() == CONTRACT_ACTIVE and oc and oc.gossip then
          mod.world:queueScript({
            { "text", "Recording for the\nRADIO, from\vGOLDENROD." },
            { "text", oc.gossip[1] },
            { "text", oc.gossip[2] },
          })
        else
          mod.world:queueScript({
            { "text", "Just harbour noise\ntoday. No good." },
          })
        end
        return
      end

      if isMark then
        if olivineStage() == CONTRACT_DONE and oc then
          mod.world:queueScript({
            { "text", oc.after1 },
            { "text", oc.after2 },
          })
        end
        return
      end

      if olivineStage() == CONTRACT_DONE then
        if not (olivineRewarded() and olivineHeistPaid()) then
          local rows = {
            { "text", "FOREMAN: Clean.\nRoute's clear." },
          }
          if not olivineRewarded() then
            rows[#rows + 1] = { "text", "Five SNAG BALLs.\nDock rate." }
          end
          if not olivineHeistPaid() then
            rows[#rows + 1] = { "text", "Three HEIST BALLs.\nHazard pay." }
          end
          rows[#rows + 1] = { "text", "Bring future cargo\nback to me." }
          mod.world:queueScript(rows, {
            onDone = function()
              -- Pay each half independently. An upgraded save whose five-ball
              -- fee was already claimed receives only the three new HEIST
              -- BALLs, and a full pocket cannot duplicate either half.
              if not olivineRewarded() then
                if not giveSnagBalls(CONTRACT_REWARD_BALLS) then
                  mod.world:queueScript({ { "text",
                    "FOREMAN: BAG full.\nClear deck space." } })
                  return
                end
                setOlivineRewarded(true)
              end
              if not olivineHeistPaid() then
                if not giveHeistBalls(3) then
                  mod.world:queueScript({ { "text",
                    "FOREMAN: No room\nfor HEIST BALLs." } })
                  return
                end
                setOlivineHeistPaid(true)
              end
            end,
          })
        else
          runFenceSale(FOREMAN_VOICE)
        end
        return
      end

      if olivineStage() == CONTRACT_ACTIVE and oc then
        mod.world:queueScript({
          { "text", "FOREMAN: Shipment\nstill moving." },
          { "text", contractTargetLine(oc) },
          { "text", oc.lead1 },
          { "text", oc.lead2 },
        })
        return
      end

      mod.world:queueScript({
        { "text", "FOREMAN: Three\nroutes are open." },
        { "text", "WATERFRONT.\nOpen ground." },
        { "text", "THE LIGHTHOUSE.\nQuiet inside." },
        { "text", "GANGWAY.\nTight passage." },
        { "text", "Pick the route.\nMake the grab." },
      }, {
        onDone = function()
          local g = mod.game
          if not (g and g.stack) then return end
          local items = menuItems(OLIVINE_ORDER, OLIVINE_CONTRACTS)
          local menu
          menu = ListMenu.new(g, "CHOOSE A ROUTE", items, {
            kind = "snag.contract3",
            onChoose = function(item, list)
              list:close()
              local key = item and item.value
              local c = key and OLIVINE_CONTRACTS[key]
              if not c then return end
              setOlivineChoice(key)
              setOlivineStage(CONTRACT_ACTIVE)
              local w = mod.world:overworld()
              if w then ensureOlivineMark(w) end
              mod.world:queueScript({
                { "text", "FOREMAN: Good.\n" .. contractTargetLine(c) },
                { "text", "Cover that route." },
                { "text", c.lead1 },
                { "text", c.lead2 },
              })
            end,
          })
          g.stack:push(menu)
        end,
      })
    end)

    mod.events:on("world.interacted", function(ev)
      if not ev or ev.mapId ~= FENCE_MAP or ev.kind ~= "none" then return end
      if stage() ~= STAGE_DONE then return end
      local world = mod.world:overworld()
      local fence = objectNamed(world, FENCE_MAP, FENCE_NAME)
      if not fence or ev.x ~= fence.x or ev.y ~= fence.y then return end

      runFenceSale(ROUTE36_VOICE)
    end)

    -- The auto-start girl's battle is identified by OUR object, not by every
    -- LASS in the game.  This flag scopes the shiny party and guaranteed catch
    -- to this single scripted intro encounter.
    mod.events:on("world.trainer_engaged", function(ev)
      local npc = ev and ev.npc
      local classIx = ev and ev.trainerClass
      local memberIx = ev and ev.partyIndex
      local className = resolveTrainerClassName(classIx)
      local memberName = resolveTrainerMemberName(className, memberIx)
      local world = mod.world:overworld()
      local ctx = {
        game = mod.game, world = world, npc = npc,
        mapId = world and world.map and world.map.id or nil,
        trainerClass = className, classIndex = classIx,
        trainerName = memberName, memberIndex = memberIx,
        trainerEvent = ev and ev.trainerEvent, sight = ev and ev.sight,
      }
      ctx.vip = trainerIsVip(ctx)
      activeTrainer = ctx

      if npc and npc.def and npc.def.name == GIRL_NAME
          and stage() == STAGE_ARMED then
        introBattleActive = true
      elseif npc and npc.def and npc.def.name == MARK_NAME
          and contractStage() == CONTRACT_ACTIVE then
        contractBattleActive = true
      elseif npc and npc.def and npc.def.name == ECRUTEAK_MARK_NAME
          and ecruteakStage() == CONTRACT_ACTIVE then
        ecruteakBattleActive = true
      elseif npc and npc.def and npc.def.name == OLIVINE_MARK_NAME
          and olivineStage() == CONTRACT_ACTIVE then
        olivineBattleActive = true
      end
    end)

    -- Real shiny Gen 2 MEOWTH: the Lake of Rage shiny DV pattern (14/10/10/10),
    -- not a cosmetic sprite override.  A caught mon therefore remains shiny.
    mod.hooks:wrap("trainer.party", function(next_, class, member, party)
      local base = next_()
      if not introBattleActive then return base end
      if class ~= "LASS" and class ~= girlClassIx then return base end
      local data = mod.game and mod.game.data
      local mon = data and Mon.new(data, "MEOWTH", INTRO_LEVEL, {
        dvs = { attack = 14, defense = 10, speed = 10, special = 10 },
      })
      if not mon then return base end
      return { mon }
    end)

    -- Goldenrod contract party substitution.  The carrier supplies a genuine
    -- Gold trainer identity/portrait/money/AI; only the party is replaced.
    mod.hooks:wrap("trainer.party", function(next_, class, member, party)
      local base = next_()
      if not contractBattleActive then return base end
      local key = contractChoice()
      local c = key and CONTRACTS[key]
      local carrier = key and contractCarriers[key]
      if not (c and carrier) then return base end
      if class ~= c.class and class ~= carrier.classIx then return base end
      local data = mod.game and mod.game.data
      local mon = data and Mon.new(data, c.species, c.level)
      if not mon then return base end
      return { mon }
    end)

    -- Ecruteak archetype parties. Unlike Goldenrod, these trainers carry
    -- multiple Pokemon, so the player can inspect/steal something other than
    -- the advertised target and the battle continues after a successful snag.
    mod.hooks:wrap("trainer.party", function(next_, class, member, party)
      local base = next_()
      if not ecruteakBattleActive then return base end
      local key = ecruteakChoice()
      local c = key and ECRUTEAK_CONTRACTS[key]
      local carrier = key and ecruteakCarriers[key]
      if not (c and carrier) then return base end
      if class ~= c.class and class ~= carrier.classIx then return base end
      local data = mod.game and mod.game.data
      if not data then return base end
      local out = {}
      for _, spec in ipairs(c.party or {}) do
        local mon = Mon.new(data, spec.species, spec.level)
        if not mon then return base end
        out[#out + 1] = mon
      end
      return #out > 0 and out or base
    end)

    -- Olivine route parties use real Gold trainer identities, with comparable
    -- three-Pokemon protection regardless of which interception map was chosen.
    mod.hooks:wrap("trainer.party", function(next_, class, member, party)
      local base = next_()
      if not olivineBattleActive then return base end
      local key = olivineChoice()
      local c = key and OLIVINE_CONTRACTS[key]
      local carrier = key and olivineCarriers[key]
      if not (c and carrier) then return base end
      if class ~= c.class and class ~= carrier.classIx then return base end
      local data = mod.game and mod.game.data
      if not data then return base end
      local out = {}
      for _, spec in ipairs(c.party or {}) do
        local mon = Mon.new(data, spec.species, spec.level)
        if not mon then return base end
        out[#out + 1] = mon
      end
      return #out > 0 and out or base
    end)

    -- Intro exception: this ONE SNAG BALL against this ONE shiny MEOWTH is a
    -- guaranteed catch.  Normal Snag Balls everywhere else keep their normal
    -- odds and behavior.
    mod.hooks:wrap("catch.rate", function(next_, ball, mon, def, o)
      if introBattleActive and ball == "SNAG_BALL"
          and type(o) == "table" and o.species == "MEOWTH" then
        return true, 255
      end
      if ball == "HEIST_BALL" and type(o) == "table" then
        local boosted = {}
        for k, v in pairs(o) do boosted[k] = v end
        boosted.catchRate = math.min(255,
          math.floor((tonumber(o.catchRate) or 45) * 2.0))
        return next_(ball, mon, def, boosted)
      end
      return next_(ball, mon, def, o)
    end)

    -- Gold trainer snag mechanic, including the 0.14.21 continuation fix.
    do
      local BattleState = require("src.ui.gen2.BattleState")
      BattleState._snagGoldOriginals = BattleState._snagGoldOriginals or {
        throwBallAtTrainer = BattleState.throwBallAtTrainer,
        useItem = BattleState.useItem,
        advanceQueue = BattleState.advanceQueue,
      }
      local originals = BattleState._snagGoldOriginals

      BattleState.advanceQueue = function(self)
        local event = self.queue and self.queue[1]
        if event and event.kind == "snag-replace" then
          table.remove(self.queue, 1)
          local battle = self.battle
          if battle and battle.enemy then
            local caught = battle.enemy
            local ghost = {}
            for k, v in pairs(caught) do ghost[k] = v end
            ghost.hp = 0
            local replaced = false
            for i, mon in ipairs(battle.enemyParty or {}) do
              if mon == caught then
                battle.enemyParty[i] = ghost
                battle.enemyIndex = i
                replaced = true
                break
              end
            end
            if not replaced then
              local i = battle.enemyIndex or 1
              battle.enemyParty[i] = ghost
              battle.enemyIndex = i
            end
            battle.enemy = ghost
            battle._snagReplacing = true
            battle.over = false
            battle.outcome = nil
            battle:resolveFaints()
            self:pushAll(battle:takeEvents())
            return self:advanceQueue()
          end
          return self:advanceQueue()
        end
        if event and event.kind == "faint" and event.side == "enemy"
            and self.battle and self.battle._snagReplacing then
          table.remove(self.queue, 1)
          self.battle._snagReplacing = nil
          return self:advanceQueue()
        end
        return originals.advanceQueue(self)
      end

      BattleState.throwBallAtTrainer = function(self, itemId)
        if not SNAG_BALL_TIERS[itemId] then
          return originals.throwBallAtTrainer(self, itemId)
        end
        local wasWild = self.battle and self.battle.wild
        if self.battle then self.battle.wild = true end
        local ok, err = pcall(originals.useItem, self, itemId)
        if self.battle then self.battle.wild = wasWild end
        if not ok then return originals.throwBallAtTrainer(self, itemId) end
        if self.ballThrow and self.ballThrow.caught and self.battle
            and self.battle.trainer then
          self.battle.over = false
          self.battle.outcome = nil
          self.queue[#self.queue + 1] = { kind = "snag-replace" }
        end
        return err
      end
    end

    mod.events:on("pokemon.caught", function(payload)
      if not payload or not payload.mon then return end
      if not SNAG_BALL_TIERS[payload.ball] then return end
      local mon = payload.mon
      mon.snagged = true
      mon.snagFrom = (activeTrainer and activeTrainer.trainerClass)
          or (payload.battle and payload.battle.opponentClass) or "trainer"
      mon.snagLevel = mon.level
      mon.snagVip = activeTrainer and activeTrainer.vip == true or false
      -- Explicit false, never nil: nil is how a mon snagged before 0.14.41 is
      -- recognised for the one-time retro-fit at the fence.  A mark's OTHER
      -- party members are fair game but are not the bounty, so only the
      -- advertised species is stamped below.
      mon.snagBounty = false
      if introBattleActive and mon.species == "MEOWTH" and stage() == STAGE_ARMED then
        setStage(STAGE_DONE)
        -- Do not despawn the sailor/girl here.  They remain for the rest of
        -- this Cherrygrove visit and are removed after the player leaves town.
        cleanupPending = false
      end
      if contractBattleActive and contractStage() == CONTRACT_ACTIVE then
        local c = CONTRACTS[contractChoice() or ""]
        if c and mon.species == c.species then
          mon.snagBounty = true
          setContractStage(CONTRACT_DONE)
          contractCleanupPending = false
        end
      end
      if ecruteakBattleActive and ecruteakStage() == CONTRACT_ACTIVE then
        local c = ECRUTEAK_CONTRACTS[ecruteakChoice() or ""]
        if c and mon.species == c.target then
          mon.snagBounty = true
          setEcruteakStage(CONTRACT_DONE)
          ecruteakCleanupPending = false
        end
      end
      if olivineBattleActive and olivineStage() == CONTRACT_ACTIVE then
        local c = OLIVINE_CONTRACTS[olivineChoice() or ""]
        if c and mon.species == c.target then
          mon.snagBounty = true
          setOlivineStage(CONTRACT_DONE)
          olivineCleanupPending = false
        end
      end
    end)

    -- No world mutation during battle teardown.  Defang is only a field write;
    -- physical cleanup happens on the first normal world step afterwards.
    mod.events:on("battle.ended", function()
      local wasIntro = introBattleActive
      local wasContract = contractBattleActive
      local wasEcruteak = ecruteakBattleActive
      local wasOlivine = olivineBattleActive
      activeTrainer = nil

      if wasIntro then
        local world = mod.world:overworld()
        local obj = objectNamed(world, MAP, GIRL_NAME)
        if obj then obj.trainer = nil end
        introBattleActive = false
        if stage() ~= STAGE_DONE then
          setStage(STAGE_NEW)
          cleanupPending = true
        end
      end

      if wasContract then
        local world = mod.world:overworld()
        local obj = objectNamed(world, MARK_MAP, MARK_NAME)
        contractBattleActive = false
        if contractStage() == CONTRACT_DONE then
          -- Keep the mark around, but harmless, for one aftermath conversation.
          if obj then obj.trainer = nil end
        else
          -- A KO/loss is not contract completion. Re-arm on the next normal
          -- world step so the player can retry without losing the chosen lead.
          contractCleanupPending = true
        end
      end

      if wasEcruteak then
        local world = mod.world:overworld()
        local c = ECRUTEAK_CONTRACTS[ecruteakChoice() or ""]
        local obj = c and objectNamed(world, c.map, ECRUTEAK_MARK_NAME)
        ecruteakBattleActive = false
        if ecruteakStage() == CONTRACT_DONE then
          if obj then obj.trainer = nil end
        else
          ecruteakCleanupPending = true
        end
      end

      if wasOlivine then
        local world = mod.world:overworld()
        local c = OLIVINE_CONTRACTS[olivineChoice() or ""]
        local obj = c and objectNamed(world, c.map, OLIVINE_MARK_NAME)
        olivineBattleActive = false
        if olivineStage() == CONTRACT_DONE then
          if obj then obj.trainer = nil end
        else
          olivineCleanupPending = true
        end
      end
    end)

    mod.events:on("world.stepped", function(ev)
      if not cleanupPending or not ev or ev.mapId ~= MAP then return end
      local world = mod.world:overworld()
      if not world then return end
      removeNamed(world, MAP, GIRL_NAME)
      if stage() == STAGE_DONE then
        removeNamed(world, MAP, SAILOR_NAME)
      else
        ensureSailor(world)
      end
      cleanupPending = false
    end)

    mod.events:on("world.stepped", function(ev)
      if not ev then return end
      if ev.mapId ~= GOLDENROD_MAP
          and ev.mapId ~= GOLDENROD_CITY_MAP
          and ev.mapId ~= MARK_MAP then return end
      local world = mod.world:overworld()
      if not world then return end

      -- Reconcile even when installed while already standing on either map.
      if stage() == STAGE_DONE and rewardClaimed() then
        if ev.mapId == GOLDENROD_MAP then ensureBroker(world) end
        if ev.mapId == GOLDENROD_CITY_MAP
            and contractStage() == CONTRACT_ACTIVE then
          ensureClueNpc(world)
        end
        if ev.mapId == MARK_MAP and contractStage() == CONTRACT_ACTIVE then
          ensureContractMark(world)
        end
      end

      if contractCleanupPending and ev.mapId == MARK_MAP then
        if contractStage() == CONTRACT_ACTIVE then
          ensureContractMark(world)
          armContractMark(world)
        end
        contractCleanupPending = false
      end
    end)

    mod.events:on("world.stepped", function(ev)
      if not ev or contractStage() ~= CONTRACT_DONE then return end
      local world = mod.world:overworld()
      if not world then return end
      local c = ECRUTEAK_CONTRACTS[ecruteakChoice() or ""]

      if ev.mapId == ECRUTEAK_MAP then
        ensureEcruteakContact(world)
        if ecruteakStage() == CONTRACT_ACTIVE then
          ensureEcruteakWitness(world)
        end
      end

      if c and ev.mapId == c.map and ecruteakStage() == CONTRACT_ACTIVE then
        ensureEcruteakMark(world)
      end

      if ecruteakCleanupPending and c and ev.mapId == c.map then
        if ecruteakStage() == CONTRACT_ACTIVE then
          ensureEcruteakMark(world)
          armEcruteakMark(world)
        end
        ecruteakCleanupPending = false
      end
    end)

    mod.events:on("world.stepped", function(ev)
      if not ev or ecruteakStage() ~= CONTRACT_DONE
          or not ecruteakFeePaid() or not ecruteakHeistPaid() then return end
      local world = mod.world:overworld()
      if not world then return end
      local c = OLIVINE_CONTRACTS[olivineChoice() or ""]

      if ev.mapId == OLIVINE_MAP then
        ensureOlivineContact(world)
        -- The recordist is only in town while there is a job running; she
        -- packs up once the contract is done, like the other two witnesses.
        if olivineStage() == CONTRACT_ACTIVE then
          ensureOlivineWitness(world)
        else
          removeNamed(world, OLIVINE_MAP, OLIVINE_WITNESS_NAME)
        end
      end
      if c and ev.mapId == c.map and olivineStage() == CONTRACT_ACTIVE then
        ensureOlivineMark(world)
      end

      if olivineCleanupPending and c and ev.mapId == c.map then
        if olivineStage() == CONTRACT_ACTIVE then
          ensureOlivineMark(world)
          armOlivineMark(world)
        end
        olivineCleanupPending = false
      end
    end)

    mod.log:info("Pokemon Snag %s loaded (Gold)", VERSION)
    return
  end

  ----------------------------------------------------------------------
  -- EVERYTHING BELOW THIS LINE IS GEN 1 ONLY.
  --
  -- The `if GEN2` arm above ends in a bare `return` that exits this
  -- entry function, so nothing from here down executes on a Gold boot.
  --
  -- gen2check is a static scanner and cannot see that early return, so
  -- it reports MK402 (`require "src.script.Commands"` has no Gen 2
  -- adapter) and MK409 ("PartyMenu" is a Gen 1 screen id) against lines
  -- below this comment. Those findings are STRUCTURALLY UNREACHABLE on
  -- Gold, not bugs, and gen2check will report them on every release
  -- forever. `games: ["gen1", "gen2"]` in the manifest is accurate.
  --
  -- The one thing that would invalidate this: restructuring away from
  -- the single early-return split. If the `if GEN2` block ever stops
  -- ending in an unconditional `return`, re-verify every finding --
  -- they become real.
  ----------------------------------------------------------------------

  ----------------------------------------------------------------------
  -- quest_system is OPTIONAL as of 0.14.13. It used to be a hard
  -- dependency with an assert here, which meant the whole mod refused to
  -- load without it -- the Snag Ball, the fences, the questline, all of
  -- it -- for a mod that only supplies the JOURNAL ENTRY. Everything
  -- this mod actually does runs on its own save flags; the journal is
  -- presentation.
  --
  -- That mattered more than it looks: quest_system ships as a zip
  -- committed to FAFF0x/gen1recomp with no GitHub releases, so the
  -- launcher cannot auto-update it and a player has to fetch it by hand.
  -- Refusing to boot without it made a hand-installed third-party mod a
  -- hard gate on everything here.
  --
  -- Declared in optional_dependencies rather than dropped entirely,
  -- because that STILL ORDERS THE LOAD -- src/mods/Loader.lua builds a
  -- dependency edge for optional specs too ("optional dependencies order
  -- without requiring anything"), so quest_system is loaded before this
  -- mod whenever it is installed and the lookup below is reliable at
  -- load time rather than needing to wait for game.ready.
  --
  -- Calls are routed through a shim so the four call sites read exactly
  -- as they did. Each one re-reads the export at call time and pcalls
  -- it, so a missing mod, a missing function, or a future API change in
  -- someone else's mod degrades to "no journal entry" instead of taking
  -- the questline down with it.
  ----------------------------------------------------------------------
  local journal = mod.find("quest_system")
  local function journalCall(name)
    return function(...)
      local api = journal and journal.exports
      local fn = api and api[name]
      if type(fn) ~= "function" then return end
      local ok, err = pcall(fn, ...)
      if not ok then
        mod.log:warn("snag_quest: quest_system.%s failed: %s", name, tostring(err))
      end
    end
  end
  local quests = {
    register = journalCall("register"),
    advance  = journalCall("advance"),
    complete = journalCall("complete"),
  }
  if not journal then
    mod.log:info("Quest System not installed; running without a journal entry")
  end

  local QUEST_ID       = "snag_quest.jessies_meowth"
  local FLAG_STARTED   = "MOD_SNAG_QUEST_GIRL_STARTED"
  local FLAG_DONE      = "MOD_SNAG_QUEST_GIRL_DONE"
  local TRAINER_CLASS  = "OPP_SNAG_QUEST_PICNICKER"
  local PARTY_INDEX    = 1
  local MEOWTH_LEVEL   = 8
  -- Intro quest ball economy: exactly one ball to do the job with -- the
  -- catch is guaranteed, so one is genuinely enough -- and a starting
  -- float handed over when MEOWTH is turned in.
  --
  -- 0.14.7 fixed two things here. QUEST_REWARD_BALLS was declared and
  -- then never used: neither success branch had a give_item row, so the
  -- reward was silently ZERO and the player finished the quest with an
  -- empty bag. The quest ball is spent on MEOWTH, so they were left with
  -- no way to snag anything and no way to reach a fence (fences only pay
  -- for snagged Pokemon), i.e. the mod's whole loop was unreachable
  -- without buying a 10,000 ball first. The dialogue made it worse by
  -- saying "keep the spare BALL" about a ball that no longer existed.
  --
  -- The float is 5 rather than 1 because every snag AFTER the quest rolls
  -- normal odds (snagAttempt just calls ctx.vanillaAttempt; the
  -- guaranteed catch is scoped to this quest's own trainer class and
  -- species), so a single ball is one failed roll away from stuck again.
  -- Five is still tight enough that the fences and the marts matter.
  --
  -- NOTE: the success dialogue names this number in words. Change both.
  local QUEST_BALL_COUNT  = 1
  local QUEST_REWARD_BALLS = 5

  -- Snagging mid-trainer-battle: what happens after the catch lands.
  -- Confirmed schema shape from src/mods/ManagerState.lua's
  -- buildOptionRows: a toggle row is { key, type = "toggle", label,
  -- default }, and mod.options:get(key) (confirmed from
  -- src/mods/Loader.lua) always reads the live value -- falling back
  -- to the schema's own default until the player changes it in the
  -- mod manager -- so this is read fresh at the point of use below
  -- rather than cached, and a mid-session toggle takes effect on the
  -- very next snag.
  mod.options:define({
    { key = "continue_battle_after_snag", type = "toggle",
      label = "Continue battle after snag", default = true },
    -- Where new Snag Balls come from after the quest. Confirmed choice-row
    -- shape from src/mods/ManagerState.lua's buildOptionRows: `choices` is
    -- a list of { displayLabel, storedValue } pairs, and the stored value
    -- is what mod.options:get returns.
    { key = "snag_ball_sources", type = "choice",
      label = "Get new Snag Balls",
      choices = { { "BOTH", "both" }, { "MART", "mart" }, { "FENCES", "fences" } },
      default = "both" },
    { key = "dev_replay_meowth_quest", type = "toggle",
      label = "[DEV] Replay intro quest", default = false },
  })
  local function continueBattleAfterSnag()
    return mod.options:get("continue_battle_after_snag") == true
  end
  -- Read live at point of use so switching sources mid-session applies
  -- immediately. Anything other than the three known values is treated as
  -- "both" rather than silently disabling every source.
  local function snagBallSource()
    local v = mod.options:get("snag_ball_sources")
    if v == "mart" or v == "fences" then return v end
    return "both"
  end
  local function martsEnabled()
    local v = snagBallSource()
    return v == "both" or v == "mart"
  end
  local function fencesEnabled()
    local v = snagBallSource()
    return v == "both" or v == "fences"
  end
  -- Dev toggle: when on, the recruiter's dialogue treats the quest as not-done
  -- regardless of FLAG_DONE's real value, dropping straight into the
  -- "started" branch (the turn-in/rematch loop) rather than replaying
  -- the whole intro every time -- enough to re-fight the picnicker and
  -- re-turn-in MEOWTH repeatedly for testing. It doesn't clear
  -- FLAG_STARTED or FLAG_DONE themselves, so turning it back off leaves
  -- the quest exactly as done as it was.
  -- (questDoneForReal itself is defined below hasFlag -- see the note
  -- there; defining it above hasFlag was the 0.9.0 regression.)
  -- ON (default as of 0.7.3, confirmed working by live testing across
  --   0.7.1's freeze fix and 0.7.2's sprite fix) -- the fight continues
  --   with the trainer's next Pokemon: the caught mon is kept, the
  --   trainer sends out their next one, correctly visible, no freeze.
  --   See CHANGELOG.md 0.5.3-0.7.2 for the debugging history.
  --
  -- OFF -- the battle ends immediately as a normal WIN (victory music,
  --   trainer defeat text, prize money) instead of continuing. The
  --   snagged Pokemon is kept either way, since storeCaughtMon's own
  --   Party.add/Boxes.deposit runs before this choice is even made.

  local function hasFlag(game, name) return Flags.get(game.save, name) == true end
  local function setFlag(game, name) Flags.set(game.save, name) end

  -- MUST stay below hasFlag. Lua resolves an undeclared name at compile
  -- time as a GLOBAL lookup, so while this sat ABOVE hasFlag's `local
  -- function` declaration it compiled to a global `hasFlag` that is nil
  -- at runtime: every call threw "attempt to call a nil value", the
  -- script runner caught and swallowed it, and the whole talk script
  -- aborted -- the NPC turned to face the player and no text box ever
  -- appeared. (0.9.0 regression, fixed in 0.9.2.)
  local function questDoneForReal(game)
    return hasFlag(game, FLAG_DONE)
      and mod.options:get("dev_replay_meowth_quest") ~= true
  end

  ----------------------------------------------------------------------
  -- 1. Snag Ball -- item + ball record (Custom Pokeballs' shape,
  --    confirmed field-for-field against src/mods/Schemas.lua's R.items
  --    and R.balls: items take id/name/price/ball/tossable only, no
  --    sellable/pocket field exists).
  ----------------------------------------------------------------------
  local function snagAttempt(ctx)
    return ctx.vanillaAttempt()  -- stock 1x odds -- the value is WHERE it works
  end

  mod.content.balls:register("SNAG_BALL", {
    randMax = 255, hpFactor = 12, wobbleFactor = 255,
    -- Ultra/Master-tier presentation: the fancier toss arc and the
    -- OBJ-palette flicker. Both are real engine fields on the ball
    -- record (confirmed from src/mods/Schemas.lua's R.balls, and from
    -- src/battle/Catching.lua where MASTER_BALL/ULTRA_BALL use exactly
    -- this pair), so this applies for everyone -- it is NOT a
    -- pokeball_colors feature and does not depend on that mod.
    --
    -- Without pokeball_colors: the stock Ultra/Master flicker colours.
    -- With it: the same arc and flicker recoloured to its Team Rocket
    -- palette -- and it's this flicker that makes its complemented-
    -- palette ("f0x") branch reachable for SNAG_BALL at all; with the
    -- plain TOSS_ANIM used before, that branch could never fire here.
    --
    -- NOTE FOR pokeball_colors: snag_quest now owns tossAnim/flicker
    -- for this ball. Per that mod's own coordination rule, don't also
    -- patch them from there or the last-folded op wins silently.
    tossAnim = "ULTRATOSS_ANIM",
    flicker = true,
    attempt = snagAttempt,
  })
  mod.content.items:register("SNAG_BALL", {
    id = "SNAG_BALL", name = "SNAG BALL", price = 10000,
    tossable = true, ball = "SNAG_BALL",
    description = "Steals a POKeMON.\nNormal catch rate.",
  })
  require("src.inventory.ItemEffects").BALLS["SNAG_BALL"] = true

  ----------------------------------------------------------------------
  -- 2. Let SNAG_BALL be thrown at a trainer's Pokemon, and make the
  --    quest's own Meowth shiny on the way in.
  --
  --    Confirmed from src/battle/BattleState.lua: throwBall(ball)
  --    gates on self.kind ~= "wild"; this patches it to run the
  --    engine's own wild-catch body (catchAttempt, ballChain,
  --    storeCaughtMon, ...) verbatim for SNAG_BALL against a trainer,
  --    just without that outer check. self.oppClass is set directly
  --    on the battle instance by BOTH BattleState.newTrainer call
  --    sites (the scripted start_battle command AND normal sight-
  --    triggered engagement), confirmed from source -- it's reliable
  --    everywhere. An earlier draft instead tracked the trainer via
  --    the world.trainer_engaged event, which turned out to fire ONLY
  --    from the sight-triggered path
  --    (src/world/OverworldController.lua) and never from
  --    Commands.start_battle -- which is exactly how this quest's own
  --    grunt fight is started, so the shiny check never once fired.
  --    The quest MEOWTH's shiny DVs are applied when the battle is
  --    CREATED (see the newTrainer wrap in install() below), not at
  --    catch time -- an earlier version set them only as the ball
  --    landed, so the mon fought the whole battle in its normal colours
  --    and only turned shiny once caught. The DVs satisfy
  --    src/pokemon/Stats.lua's real Stats.isShiny check, which is
  --    engine-native and not something the Shiny Pokemon mod owns. If
  --    that mod (id SHINY_POKEMON) is installed, its own
  --    exports.makeShinyDVs is used instead so its visuals recognize
  --    the mon the same way they would any other shiny; if it's not
  --    installed, the Pokemon is still genuinely shiny by data, just
  --    undecorated.
  --
  --    CROSS-AUTHOR BOUNDARY (revised 0.14.8). SHINY_POKEMON is another
  --    author's mod, so ownership cannot be negotiated the way it can
  --    between this project's own mods -- there is no shared exports.owns
  --    to declare, and their internals may change in any release. The
  --    line that matters is not "engine field vs their field", which is
  --    what 0.14.6 got wrong; it is INPUT CONTRACT vs INTERNAL STATE:
  --
  --      write  mon.dvs / mon.stats / mon.hp -- engine-native truth
  --      write  mon.shiny -- their detector reads it off arbitrary mons,
  --             so it is how a mod declares "this one is shiny"
  --      call   exports.makeShinyDVs -- their published API
  --      NEVER  battler.shiny, battler._shinySpriteApplied -- battler-
  --             scoped internals only their own code writes
  --
  --    0.14.6 dropped mon.shiny on the theory that anything not
  --    engine-native was off limits, and the quest MEOWTH lost its
  --    colours on device. Restored in 0.14.8. Same posture as with
  --    pokeball_colors, where this mod registers into exports.colors --
  --    a table that mod exposes for the purpose -- rather than writing
  --    its records directly.
  ----------------------------------------------------------------------
  local function shinyDVs()
    local shinyMod = mod.find("SHINY_POKEMON")
    if shinyMod and shinyMod.exports and shinyMod.exports.makeShinyDVs then
      local ok, dvs = pcall(shinyMod.exports.makeShinyDVs, love.math and love.math.random or math.random)
      if ok and dvs then return dvs end
    end
    -- fallback: engine-native shiny per src/pokemon/Stats.lua's
    -- isShiny (defense/speed/special == 10, attack in a fixed set)
    return { hp = 10, attack = 2, defense = 10, speed = 10, special = 10 }
  end

  local function install(game, deps)
    deps = deps or {}
    local BattleState = deps.battleState or require("src.battle.BattleState")
    local Runtime = deps.runtime or require("src.mods.Runtime")
    local Strings = deps.strings or require("src.core.Strings")
    local Stats = deps.stats or require("src.pokemon.Stats")

    -- HOT-RELOAD SAFETY (0.9.4). This used to guard with a plain
    -- `if BattleState._snagQuestWrapped then return end` sentinel, which
    -- was wrong in a way that silently ate mod updates: the sentinel
    -- lives on the ENGINE MODULE TABLE, and Lua's module cache persists
    -- for the whole game process. Reloading or re-enabling the mod
    -- without fully restarting the game meant install() saw the sentinel
    -- left by the PREVIOUS version, returned immediately, and left that
    -- previous version's wrapped functions live -- so a freshly-updated
    -- mod appeared to change nothing at all.
    --
    -- Instead: stash the true originals once, then always rebuild the
    -- wrappers from those originals. Re-running install() now replaces
    -- the previous wrapper rather than skipping (no stacking, since we
    -- never wrap a wrapper) and a mod update takes effect without a
    -- restart.
    BattleState._snagQuestOriginals = BattleState._snagQuestOriginals or {
      throwBall = BattleState.throwBall,
      newTrainer = BattleState.newTrainer,
    }
    local originals = BattleState._snagQuestOriginals
    BattleState._snagQuestWrapped = mod.exports.version

    -- Make the quest grunt's MEOWTH shiny for the WHOLE battle, not
    -- just at the moment it's caught.
    --
    -- Confirmed from src/battle/BattleState.lua's newTrainer: it builds
    -- self.enemyParty by running Pokemon.new per slot and then
    -- OVERWRITING each mon's dvs with the fixed trainerDvs constant
    -- (recomputing stats and hp from it), and only after that does
    -- self.enemy = makeBattler(..., self.enemyParty[1], ...). So the
    -- DVs have to be replaced after newTrainer has finished, not via
    -- the trainer.party hook -- that hook fires earlier (on the party
    -- DEFINITION, before any mon exists) and its work would just be
    -- overwritten by the trainerDvs assignment.
    --
    -- makeBattler holds a reference to the same mon table rather than
    -- copying it, so patching the mon here is visible through
    -- battle.enemy.mon too -- which is what the sprite/palette code
    -- reads. This runs synchronously inside the newTrainer call, before
    -- the battle has drawn a single frame.
    local vanillaNewTrainer = originals.newTrainer
    BattleState.newTrainer = function(g, oppClass, partyIndex)
      local battle = vanillaNewTrainer(g, oppClass, partyIndex)
      if oppClass == TRAINER_CLASS and battle and battle.enemyParty then
        for _, mon in ipairs(battle.enemyParty) do
          if mon.species == "MEOWTH" then
            mon.dvs = shinyDVs()
            mon.stats = Stats.calc(g.data.pokemon[mon.species], mon.level, mon.dvs)
            mon.hp = mon.stats.hp
            -- mon.shiny is the Shiny Pokemon mod's INPUT MARKER, and this
            -- mod is expected to set it. Restored in 0.14.8 after 0.14.6
            -- removed it and the quest MEOWTH lost its colours on device
            -- (the name marker still drew, so detection was fine; the
            -- recolour bake was not happening).
            --
            -- 0.14.6's reasoning was half right and the conclusion was
            -- wrong. `mon.shiny` is genuinely not an engine field --
            -- nothing in src/ or data/ reads or writes it, and the
            -- engine's own truth is Stats.isShiny(mon.dvs), which the
            -- DVs above already satisfy. But "not an engine field" does
            -- not make it private to that mod. Their detector READS it
            -- off arbitrary Pokemon:
            --     isShinyMon(mon) = mon.shiny or Stats.isShiny(mon.dvs)
            -- A field another mod reads as input is part of its input
            -- contract, not its internal state -- so setting it is how a
            -- mod is supposed to say "this one is shiny", and it is the
            -- documented integration point for exactly this.
            --
            -- The fields that ARE theirs alone stay untouched:
            -- battler.shiny and battler._shinySpriteApplied, both
            -- underscore/battler-scoped and written only by their own
            -- ensureShinyBattler. This mod never writes those, and the
            -- 0.14.6 note about not patching around their missing
            -- newTrainer path still stands.
            --
            -- Verified against SHINY_POKEMON 1.0.8.
            mon.shiny = true
          end
        end
      end
      return battle
    end

    local vanillaThrowBall = originals.throwBall
    BattleState.throwBall = function(self, ball)
      if not (ball == "SNAG_BALL" and self.kind == "trainer") then
        return vanillaThrowBall(self, ball)
      end
      -- verbatim copy of BattleState:throwBall's wild-catch body,
      -- reached without the self.kind == "wild" check
      self:sayAuto(self:romText("_ItemUseText001", "%s used\n%s!",
        self.game.save.player.name, self.data.items[ball].name))
      self:act(function()
        require("src.core.Sound").play(self.data, "Ball_Toss")
        if self.ghost or self.noCatch then
          self:animNext(self:tossAnimFor(ball), true, nil, ball)
          self:sayNext(Strings("It dodged the\nthrown BALL!"))
          self:sayNext(Strings("This POKéMON\ncan't be caught!"))
          self:act(function()
            self:executeAction(self.enemy, self.player, self:enemyAction())
          end)
          self:queueResidual(self.player, self.enemy)
          self:act(function() self:endOfTurn() end)
          return
        end
        self.lastBall = ball
        local caught, shakes = self:catchAttempt(ball)
        -- Guaranteed catch, but ONLY for the intro quest's Meowth.
        -- Scoped to this mod's own trainer class (OPP_SNAG_QUEST_
        -- PICNICKER), which nothing else in the game or this mod ever
        -- uses, plus a species check -- so no ordinary snag anywhere
        -- else is affected. `true, 3` is exactly what the engine's own
        -- guaranteed-catch path returns (Catching.lua's autoCatch
        -- branch and both of stockAttempt's success returns), so the
        -- ball animation plays the normal three-wobble catch rather
        -- than anything special-cased.
        if self.oppClass == TRAINER_CLASS and self.enemy.mon.species == "MEOWTH" then
          caught, shakes = true, 3
        end
        Runtime.emit("battle.ball_thrown", {
          battle = self, ball = ball, caught = caught, shakes = shakes,
        })
        self.nextInsert = (self.nextInsert or 0) + 1
        table.insert(self.queue, self.nextInsert, { wait = 20 })
        self:ballChain(self:tossAnimFor(ball), caught, shakes, ball)
        if caught then
          -- (the quest MEOWTH's shiny DVs are set at battle creation
          -- in the newTrainer wrap above, so they're already on the mon
          -- being caught here -- nothing to do at catch time)
          self.enemy.mon.snagged = true
          self.enemy.mon.snagFrom = self.oppClass
          self.enemy.mon.snagLevel = self.enemy.mon.level
          -- A persistent marker, not just an event-time signal. Ball ==
          -- SNAG_BALL on the pokemon.caught event (emitted by
          -- storeCaughtMon below) is enough for another mod to react
          -- to a snag AS IT HAPPENS, but storeCaughtMon's own stampOT
          -- call immediately overwrites OT with the player -- so a
          -- snagged mon becomes data-identical to a wild catch the
          -- moment the battle ends, with no way to identify it again
          -- later (a save reload, a trade, a ribbon page opened
          -- afterward). Party.add/Boxes.deposit (confirmed from
          -- src/pokemon/Party.lua and src/pokemon/Boxes.lua) both just
          -- table.insert the same mon reference, no copy, so this
          -- field rides along into the party/box exactly as set here,
          -- for the life of the Pokemon.
          self:actNext(function()
            require("src.core.Sound").play(self.data, "Caught_Mon")
          end)
          self:sayNext(Strings("All right!\n%s was\ncaught!", self.enemy.name))
          self:act(function()
            self:storeCaughtMon()
            -- storeCaughtMon (confirmed from src/battle/BattleState.lua)
            -- always ends the battle -- correct for a wild encounter,
            -- where there's only ever one mon, but wrong for snagging
            -- ONE of a trainer's several: the fight should continue with
            -- their next living Pokemon, exactly like a normal faint
            -- does. self:onFaint(battler) is the real, only entry point
            -- into that path (confirmed from source: every faint goes
            -- through it, and it does its own setup -- fainted/
            -- faintQueued flags, the battle.fainted event, faint sound/
            -- slide queueing -- before its own tail end calls
            -- self:enemyMonFainted() for a non-player battler). Calling
            -- enemyMonFainted() directly, skipping that setup, crashed
            -- when the trainer tried to switch: this fix routes through
            -- onFaint properly instead. storeCaughtMon's own battle-
            -- ending flags are cleared first so onFaint's own eventual
            -- result/afterQueue decision is the one that sticks. The
            -- caught mon is pulled out of self.enemyParty by reference
            -- first so the next-mon scan can't pick the same mon back
            -- up (it's still sitting in the player's own party at this
            -- point, at full HP -- reusing that same table object as
            -- the enemy's "fainted" mon would zero the player's copy
            -- too, so it's removed from the roster instead of zeroed).
            if self.kind == "trainer" then
              for i, mon in ipairs(self.enemyParty) do
                if mon == self.enemy.mon then
                  table.remove(self.enemyParty, i)
                  break
                end
              end
              if not continueBattleAfterSnag() then
                -- Stable path: end the fight as a proper win rather
                -- than storeCaughtMon's own "caught" ending. The
                -- Pokemon is already in the party/box by now, and a
                -- "win" result routes through the normal victory
                -- sequence the overworld expects from a trainer
                -- battle (money, defeat text, endBattleText) instead
                -- of a wild-catch ending a trainer fight never
                -- normally produces.
                self.result = "win"
                self.afterQueue = "finish"
                return
              end
              -- storeCaughtMon set result="caught"/afterQueue="finish"
              -- to end the battle; both are cleared so the faint path's
              -- own decision is the one that sticks. afterQueue must
              -- become "menu", NOT nil: enemyMonFainted's switch exit
              -- returns early without setting it (the normal caller,
              -- endOfTurn, has already done so), while its victory exit
              -- sets "finish" itself -- so nil left the queue draining
              -- into neither branch. That fix was correct as far as it
              -- went, but did not resolve the freeze on its own.
              self.result = nil
              self.afterQueue = "menu"
              -- THE STRUCTURAL FIX (0.7.1), from live testing that
              -- finally isolated the freeze: it only happens when a
              -- player mon LEVELS UP from the snag, and even without a
              -- level-up the replacement mon comes out with no sprite.
              -- Root cause: in a real faint the enemy mon's hp is 0 by
              -- the time the faint pipeline runs, and everything
              -- downstream (the faint anim chain, the send-out grow-in,
              -- awardExp's level-up HUD rows) is built on that. Our
              -- caught mon still had FULL hp -- and worse, it's the
              -- same table now sitting in the player's party, so the
              -- pipeline was reading (and risking writes to) the
              -- player's own new Pokemon. Swapping the enemy battler's
              -- mon for a shallow CLONE with hp = 0 makes the pipeline
              -- see exactly what a real faint looks like, and fully
              -- decouples the player's copy from everything the rest
              -- of the battle does.
              local caughtMon = self.enemy.mon
              local ghost = {}
              for k, v in pairs(caughtMon) do ghost[k] = v end
              ghost.hp = 0
              self.enemy.mon = ghost
              if self.enemy.shownHP ~= nil then self.enemy.shownHP = 0 end
              -- Seamlessness: onFaint emits a "<mon> fainted!" line,
              -- which is wrong for a capture. That row is queued
              -- synchronously inside onFaint via self:sayNext, so
              -- swapping sayNext just for the duration of that call
              -- drops exactly that one message and nothing else.
              local realSayNext = self.sayNext
              rawset(self, "sayNext", function(selfRef, text)
                if type(text) == "string" and text:find("fainted!", 1, true) then
                  return
                end
                return realSayNext(selfRef, text)
              end)
              local ok, err = pcall(function() self:onFaint(self.enemy) end)
              -- THE SPRITE FIX (0.7.2): the catch animation hides the
              -- enemy pic (ballChain -> SE_HIDE_ENEMY_MON_PIC sets
              -- self.enemyHidden = true; the draw at the bottom of
              -- BattleState.lua renders the enemy only when NOT
              -- enemyHidden). A wild catch ends the battle right there,
              -- so vanilla never needs to clear it -- and a faint never
              -- sets it, which is why faint-switches always rendered
              -- fine. Queue the unhide as a row of our own: rows queued
              -- here land AFTER everything onFaint just queued, so it
              -- runs once the new mon's send-out has begun -- and as a
              -- bonus, the ghost's queued faint slide plays while the
              -- pic is still hidden, so there's no weird visual of the
              -- just-caught mon sliding away.
              if ok then
                self:act(function() self.enemyHidden = false end)
              end
              -- restore by REMOVING the instance-level override so the
              -- class method on the metatable takes over again, rather
              -- than leaving a permanent instance copy of it behind
              rawset(self, "sayNext", nil)
              if not ok then
                -- never let a cosmetic wrapper strand the battle: if
                -- anything above threw, fall back to ending the fight
                -- cleanly rather than idling in "messages" forever
                mod.log:warn("snag_quest: faint handoff failed (%s); ending battle",
                  tostring(err))
                self.result = "win"
                self.afterQueue = "finish"
              end
            end
          end)
        else
          self:sayNext(self:ballMissMessage(shakes))
          self:act(function()
            self:executeAction(self.enemy, self.player, self:enemyAction())
          end)
          self:queueResidual(self.player, self.enemy)
          self:act(function() self:endOfTurn() end)
        end
      end)
    end
  end
  mod.events:on("game.ready", function(payload)
    if payload and payload.game then install(payload.game) end
  end)

  ----------------------------------------------------------------------
  -- 3. Sell Snag Balls in marts, once the quest is done and the
  --    "Sell Snag Balls in marts" option is on (default ON).
  --
  --    Confirmed pattern from Custom Pokeballs' own shipped source:
  --    a mart's stock is a plain array of item ids read off
  --    Data:textEntry(mapLabel, textConst).mart, and
  --    mod.content.text_pointers:patch(mapId, { [const] = { mart =
  --    { __append = ids } } }) is how a mod normally extends a shelf.
  --    That's a static, always-on append, though -- there's no
  --    per-save condition built into it. To gate this on quest
  --    completion and the option toggle, this wraps Data:textEntry
  --    itself (the plain lookup function every mart-opening code path
  --    calls, confirmed from src/core/Data.lua and both of its real
  --    callers in src/world/OverworldController.lua and
  --    src/script/Commands.lua) and appends SNAG_BALL to a COPY of the
  --    entry only when the condition holds -- the underlying data
  --    table is never mutated, so this is fully reversible if the
  --    option gets turned back off mid-save.
  --
  --    SNAG_BALL_MARTS is the exact same mart list Custom Pokeballs
  --    stocks GREAT_BALL/ULTRA_BALL at -- "the same rules as custom
  --    balls" the way Snag Balls were asked to follow.
  ----------------------------------------------------------------------
  local SNAG_BALL_MARTS = {
    CeladonMart2F = { "TEXT_CELADONMART2F_CLERK1" },
    LavenderMart = { "TEXT_LAVENDERMART_CLERK" },
    SaffronMart = { "TEXT_SAFFRONMART_CLERK" },
    FuchsiaMart = { "TEXT_FUCHSIAMART_CLERK" },
    CinnabarMart = { "TEXT_CINNABARMART_CLERK" },
    IndigoPlateauLobby = { "TEXT_INDIGOPLATEAULOBBY_CLERK" },
  }

  local currentGameRef = nil
  mod.events:on("game.ready", function(payload)
    if payload and payload.game then currentGameRef = payload.game end
  end)

  local function sellSnagBallsUnlocked()
    return currentGameRef ~= nil
      and martsEnabled()
      and hasFlag(currentGameRef, FLAG_DONE)
  end

  do
    local Data = require("src.core.Data")
    if not Data._snagQuestMartWrapped then
      Data._snagQuestMartWrapped = true
      local vanillaTextEntry = Data.textEntry
      Data.textEntry = function(self, mapLabel, textConst)
        local entry = vanillaTextEntry(self, mapLabel, textConst)
        local consts = SNAG_BALL_MARTS[mapLabel]
        if entry and entry.mart and consts then
          local matches = false
          for _, c in ipairs(consts) do
            if c == textConst then matches = true break end
          end
          if matches and sellSnagBallsUnlocked() then
            local copy = {}
            for k, v in pairs(entry) do copy[k] = v end
            local martCopy = {}
            for i, id in ipairs(entry.mart) do martCopy[i] = id end
            martCopy[#martCopy + 1] = "SNAG_BALL"
            copy.mart = martCopy
            return copy
          end
        end
        return entry
      end
    end
  end

  ----------------------------------------------------------------------
  -- 3b. The fence: the Game Corner gambler who buys snagged Pokemon
  --     for Snag Balls. Vendor NPC is the real
  --     TEXT_GAMECORNER_MIDDLE_AGED_MAN2 (map GAME_CORNER, both
  --     confirmed from data/scripts/flavor/game_corner.lua +
  --     story3.lua) -- canonically the gambler whose whole vanilla
  --     line is "Darn! I need more coins for the POKeMON I want!", so
  --     a man that desperate for a Pokemon fencing yours is barely
  --     even a retcon. His vanilla 20-coins handout is preserved via
  --     base_talk until the Meowth quest is done.
  --
  --     Payout (deliberately conservative, hard cap 5):
  --       1 base
  --       +1 level >= 25, +1 more level >= 45  (snagLevel, i.e. the
  --          level it was STOLEN at -- training it up after the fact
  --          doesn't raise the price)
  --       +1 rare species (catchRate <= 45; field name confirmed from
  --          src/battle/Catching.lua's targetDef.catchRate)
  --       +1 VIP provenance (snagFrom is the rival, a gym leader, the
  --          Elite Four, or Giovanni; class ids confirmed from
  --          data/scripts/victories.lua / ai_classes.lua)
  ----------------------------------------------------------------------
  local VIP_CLASSES = {
    OPP_RIVAL1 = true, OPP_RIVAL2 = true, OPP_RIVAL3 = true,
    OPP_BROCK = true, OPP_MISTY = true, OPP_LT_SURGE = true,
    OPP_ERIKA = true, OPP_KOGA = true, OPP_SABRINA = true,
    OPP_BLAINE = true, OPP_GIOVANNI = true,
    OPP_LORELEI = true, OPP_BRUNO = true, OPP_AGATHA = true,
    OPP_LANCE = true,
  }

  local function snagPayout(game, mon)
    return computeSnagPayout(game, mon, VIP_CLASSES)
  end

  mod.content.commands:register("snag_quest:sell_snagged", {
    foreground = true,
    fn = function(ctx)
      local Screens = require("src.ui.Screens")
      local Commands = require("src.script.Commands")
      local party = ctx.save.party
      local runner = ctx.runner

      -- never let the fence empty the party
      if #party < 2 then
        ctx.lastCheck = false
        return
      end

      local picked
      Screens.push(ctx.game, "PartyMenu", {
        pickOnly = true,
        onCancel = function() runner:resume() end,
        onSwitch = function(mon) picked = mon; runner:resume() end,
      })
      runner:yield()

      if not picked or picked.snagged ~= true then
        ctx.lastCheck = false
        return
      end

      local n = snagPayout(ctx.game, picked)
      local name = picked.nickname or ctx.game.data.pokemon[picked.species].name
      Commands.ask(ctx, string.format(
        "Heh... that\n%s.\fHot goods, right?\nI can\vtell. For that\vone:\v%d SNAG\vBALL%s.\fDeal?",
        name, n, n == 1 and "" or "s"))
      if not ctx.lastCheck then
        return
      end

      local slot
      for i, mon in ipairs(party) do
        if mon == picked then slot = i break end
      end
      if not slot then
        ctx.lastCheck = false
        return
      end
      table.remove(party, slot)
      Commands.give_item(ctx, "SNAG_BALL", n, false)
      ctx.lastCheck = true
    end,
  })

  ----------------------------------------------------------------------
  -- The merchant system. Every fence shares one script shape; a town
  -- only supplies its own map, text constant(s), badge gate and lines.
  --
  -- Badge gate: badges live in the save inventory keyed by badge id
  -- (confirmed from src/inventory/Badges.lua -- Badges.itemFor(entry)
  -- is entry.item or entry.id, and Badges.count reads
  -- save.inventory[thatKey]), so a specific badge is a plain inventory
  -- lookup. nil badge = no badge requirement.
  --
  -- Every merchant also requires the Meowth quest to be done: before
  -- that the player has no Snag Balls, no snagged Pokemon, and no
  -- reason to know the word "snag" -- so pre-quest they just say their
  -- ordinary vanilla line via base_talk, same as pre-badge.
  ----------------------------------------------------------------------
  -- 0.14.1: test the badge by TRUTHINESS, not `> 0`.
  --
  -- This used to read `(inv[badgeId] or 0) > 0`, which assumes the stored
  -- value is a number. Every badge test in the engine instead just checks
  -- whether the key is set -- Badges.count (src/inventory/Badges.lua),
  -- the gate guard at OverworldController:1561, the gym statue at :2067,
  -- data/scripts/flavor/viridian_city.lua. This mod was the only place
  -- comparing numerically.
  --
  -- If the value is anything non-numeric, `value > 0` raises "attempt to
  -- compare <type> with number". The script runner catches that, the talk
  -- aborts before its first text row, and the NPC turns to face the player
  -- and says nothing -- reported on device against 0.14.0 for BOTH
  -- badge-gated fences (PEWTER, VERMILION) while both ungated ones
  -- (CELADON, the recruiter) were fine. That split is exactly this row:
  -- it is the only command the failing scripts run that the working ones
  -- don't.
  --
  -- Truthiness matches the engine everywhere and removes the throw site
  -- whatever the stored value turns out to be.
  mod.content.commands:register("snag_quest:check_badge", function(ctx, badgeId)
    local inv = ctx.save and ctx.save.inventory
    ctx.lastCheck = (inv and inv[badgeId]) and true or false
  end)

  -- Fences answer to BOTH the quest gate and the "Get new Snag Balls"
  -- source setting -- the questline's own dialogue deliberately does not, so
  -- setting sources to MART never breaks the questline itself.
  mod.content.commands:register("snag_quest:check_fence_open", function(ctx)
    ctx.lastCheck = questDoneForReal(ctx.game) and fencesEnabled()
  end)

  -- Concatenate row chunks into one flat script. Used to splice fenceRows
  -- into a script that also has other branches (the recruiter's).
  local function concatRows(...)
    local out = {}
    for _, chunk in ipairs({ ... }) do
      for _, row in ipairs(chunk) do out[#out + 1] = row end
    end
    return out
  end

  -- The transaction itself, as script rows: offer, pick, pay or decline.
  --
  -- Factored out of registerMerchant in 0.14.0 so the Nugget Bridge
  -- recruiter can be a fence too. He CANNOT go through registerMerchant:
  -- he already owns a talk entry for his own text constant (the whole
  -- questline), and two contributions for one map+constant do not merge
  -- -- buildView takes a single winner per TEXT constant
  -- (src/script/MapScripts.lua) and drops the loser silently. So the
  -- rows are shared instead of the registration, and his questline
  -- script splices them into its own post-quest branch.
  --
  -- `tag` suffixes the labels so two copies can coexist in one script:
  -- ScriptRunner.validate rejects a duplicate label outright, and
  -- scanLabels would otherwise resolve every jump to the first copy.
  --
  -- spec = { intro, refuse, sold }
  local function fenceRows(spec, tag)
    local soldLabel = "snagsold_" .. tag
    local doneLabel = "snagdone_" .. tag
    return {
      { "show_text", spec.intro },
      { "snag_quest:sell_snagged" },
      { "jump_if_true", soldLabel },
      -- covers cancel / refusal / non-snagged pick / would-empty-the-
      -- party alike with one catch-all line
      { "show_text", spec.refuse },
      { "jump", doneLabel },

      { "label", soldLabel },
      { "show_text", spec.sold },

      { "label", doneLabel },
    }
  end

  -- spec = { map, texts = { ... }, badge = "BOULDERBADGE" or nil,
  --          intro, refuse, sold, fallback }
  local function registerMerchant(spec)
    local talk = {}
    for _, textConst in ipairs(spec.texts) do
      local rows = {
        { "snag_quest:check_fence_open" },
        { "jump_if_false", "base" },
      }
      if spec.badge then
        rows[#rows + 1] = { "snag_quest:check_badge", spec.badge }
        rows[#rows + 1] = { "jump_if_false", "base" }
      end
      for _, row in ipairs(fenceRows(spec, "merchant")) do
        rows[#rows + 1] = row
      end
      local tail = {
        { "jump", "end" },

        { "label", "base" },
        -- A vanilla NPC falls back to its own original dialogue. A
        -- mod-spawned NPC has no vanilla line to fall back TO -- so
        -- spec.fallback supplies one, otherwise base_talk would find
        -- nothing and the NPC would just turn and say nothing (the
        -- classic swallowed-script-error signature, but for a benign
        -- reason).
        spec.fallback
          and { "show_text", spec.fallback }
          or  { "snag_quest:base_talk", spec.map, textConst },
        { "label", "end" },
      }
      for _, row in ipairs(tail) do rows[#rows + 1] = row end
      talk[textConst] = rows
    end
    mod.content.map_scripts:register(spec.map, { talk = talk, priority = 500 })
  end

  -- CELADON -- the Game Corner gambler.
  --
  -- Two text constants for one physical NPC: this coin-giver has a
  -- DIFFERENT internal name depending on which base game the data was
  -- built from -- confirmed straight from
  -- data/scripts/flavor/game_corner.lua's own comment: "Yellow keeps
  -- all three giveaways with the same events and amounts but renames
  -- the objects and their text labels: ... CLERK2 ->
  -- MIDDLE_AGED_MAN2 ... The Red/Blue keys above never match [in
  -- Yellow]". Registering only MIDDLE_AGED_MAN2 (Yellow's name) meant
  -- this never fired at all on a Red/Blue save. Both are covered now.
  -- No badge gate: the Game Corner is already deep enough in.
  --
  -- VOICE (0.14.0): the fences are deliberately NOT one organization.
  -- The sailor and the Nugget Bridge recruiter are TEAM ROCKET; the
  -- gambler and the Pewter man are independents who happen to buy stolen
  -- goods. The opener below says so out loud -- he clocks who you work
  -- for and makes a point of not working for them -- so the black market
  -- reads wider than one gang and Rocket membership isn't the only
  -- reason anyone deals with you.
  registerMerchant({
    map = "GAME_CORNER",
    texts = { "TEXT_GAMECORNER_MIDDLE_AGED_MAN2", "TEXT_GAMECORNER_CLERK2" },
    badge = nil,
    intro = "Heh. I know that\nlook.\fROCKET's new\nerrand runner.\fRelax -- I don't\nwork for them.\vI just like what\vfalls off their\vtrucks.\fGot something\nfor me?",
    refuse = "No deal? Fine,\nfine.\fBut only POKeMON\nwith...\va certain history.\vYou know the kind.",
    sold = "Heh heh...\npleasure\vdoing business.\fBring me more like\nthat\vand we'll talk\vagain.",
  })

  -- PEWTER -- the man who explains that traded Pokemon disobey without
  -- badges. Map and text constant read off the RUNNING game with the
  -- NPC Inspector dev tool rather than guessed:
  -- PEWTER_NIDORAN_HOUSE / TEXT_PEWTERNIDORANHOUSE_MIDDLE_AGED_MAN.
  -- (He shares the Nidoran's house; the engine's own flavor script for
  -- that map defines only TEXT_PEWTERNIDORANHOUSE_NIDORAN, so this NPC
  -- is unscripted in the base game and nothing is being overridden.)
  -- Gated on the BOULDERBADGE so he stays vanilla until Brock is beaten.
  --
  -- YELLOW: verified. The NPC Inspector was run on a real Yellow save
  -- and reported the SAME map id and text constant as Red, so one
  -- entry covers both. Worth noting for future merchants: the Yellow
  -- object renames are per-map (the Game Corner coin-giver is renamed;
  -- this NPC and TEXT_VIRIDIANCITY_GIRL are not), so a rename must be
  -- checked per NPC rather than assumed either way.
  --
  -- VOICE (0.14.0): rewritten to make him the mod's blunt collector
  -- rather than a criminal -- indifference, not villainy. He is the
  -- best-matched NPC in the mod precisely because his VANILLA line is
  -- about traded Pokemon disobeying without badges, and this mod's whole
  -- premise is the direct answer to it; the intro now states that
  -- contradiction and says he wants specimens, not accomplices. Like the
  -- gambler he is an independent, not TEAM ROCKET -- hence the opening
  -- disclaimer about who you run with.
  registerMerchant({
    map = "PEWTER_NIDORAN_HOUSE",
    texts = { "TEXT_PEWTERNIDORANHOUSE_MIDDLE_AGED_MAN" },
    badge = "BOULDERBADGE",
    intro = "I don't care who\nyou run with.\vI care about the\vPOKeMON.\fA traded one won't\nobey without\vBADGES.\fA stolen one obeys\nanybody.\vThat shouldn't be\vtrue.\fI'd like more of\nthem to study.",
    refuse = "No? Suit yourself.\fThe offer stands,\nif\vyou come by\vsomething\vwith an\vinteresting\vpast.",
    sold = "Fascinating. No\nBADGES,\vno hesitation.\fBring me another\nand\vI'll pay the same.",
  })

  ----------------------------------------------------------------------
  -- VERMILION -- the sailor guarding the S.S. ANNE gangway (0.14.0).
  --
  -- Both of the risky details here were checked against the engine
  -- source before this was written, not assumed:
  --
  -- 1. data/scripts/story.lua's M.VERMILION_CITY gives this sailor BOTH
  --    a `talk` entry AND an `onStep` trigger, and the onStep is the one
  --    that matters for boarding: standing on cell (18,30) facing down
  --    runs the S.S. TICKET check and walks the player back up without
  --    one. That hook is a separate key on the same contribution and is
  --    NOT touched by registering a talk -- MapScripts merges talk per
  --    TEXT constant and chains onStep independently
  --    (src/script/MapScripts.lua buildView), so taking over the talk
  --    path leaves boarding the ship exactly as it was.
  -- 2. The engine's own comment on that block reads "The sailor himself
  --    never hides" -- confirmed still true in the source in this repo.
  --    He persists after the ship departs, which is the whole reason he
  --    can be a permanent fence rather than a window that closes.
  --
  -- His base talk is a ROW LIST, not a Lua handler -- which is what
  -- forced the base_talk fix further down this file. Before the
  -- pre-badge path would have thrown on calling a table.
  --
  -- THUNDERBADGE-gated (badge id confirmed from data/scripts/gyms.lua
  -- and victories.lua). That gate also orders the fiction for free: the
  -- badge is behind LT.SURGE, LT.SURGE is behind the S.S. ANNE, so by
  -- the time he starts buying, the ship has sailed and his vanilla
  -- ticket dialogue has nothing left to do anyway.
  --
  -- YELLOW: verified (0.14.3). Checked against the engine's own symbol
  -- tables, tools/rom_manifest.json and tools/rom_manifest_yellow.json:
  -- maps.VERMILION_CITY.objects carries
  -- { name = "VERMILIONCITY_SAILOR1", text = "TEXT_VERMILIONCITY_SAILOR1" }
  -- in BOTH, so this NPC is not one of Yellow's per-map renames and one
  -- entry covers both versions. (The same pass re-confirmed the Route 24
  -- recruiter and the Pewter man as identical, and the Game Corner
  -- coin-giver as genuinely renamed -- which is why that one alone
  -- registers two constants.)
  --
  -- VOICE: Rocket, like the recruiter -- a dock hand who moves cargo and
  -- has stopped counting it. Deliberately a different register from the
  -- two independents above.
  ----------------------------------------------------------------------
  registerMerchant({
    map = "VERMILION_CITY",
    texts = { "TEXT_VERMILIONCITY_SAILOR1" },
    badge = "THUNDERBADGE",
    intro = "So you're the new\none.\fWord came down the\ndocks before you\vdid.\fForty crates on\nthe manifest.\vI counted\vthirty-eight.\fThat's how this\nworks. You stop\vcounting.\fGot something\naboard nobody\vlogged?",
    refuse = "Then don't waste\nmy shift, rookie.\fCome back when\nyou're carrying\vsomething without\vpaperwork.",
    sold = "No name, no\ntrainer, no\vquestions.\fManifest says it\nwas never here.\v...Tell your boss\vthe docks are\vstill quiet.",
  })

  ----------------------------------------------------------------------
  -- Sprite probing for the mod's own spawned NPCs.
  --
  -- (0.14.0 removed the Cerulean fence that this helper was first written
  -- for -- see the CHANGELOG. The Route 24 recruiter stand-in below still
  -- spawns, and still needs it.)
  --
  -- An unknown sprite id makes NPC.new assert, and that assert is
  -- SWALLOWED inside an event handler -- the NPC simply never appears,
  -- with no error anywhere. So probe for one that actually exists
  -- instead of hardcoding, and prefer the Rocket look if present.
  local function rocketSprite(game)
    local sprites = game and game.data and game.data.sprites
    if not sprites then return nil end
    local candidates = {
      "SPRITE_ROCKET", "SPRITE_ROCKET_GRUNT", "SPRITE_BLACK_HAIR_BOY_1",
      "SPRITE_GENTLEMAN", "SPRITE_MIDDLE_AGED_MAN",
    }
    for _, id in ipairs(candidates) do
      if sprites[id] then return id end
    end
    -- last resort: any sprite at all, so he's at least visible and
    -- talkable while the right id gets sorted out
    for id in pairs(sprites) do return id end
    return nil
  end

  ----------------------------------------------------------------------
  -- 4. Turn the Meowth in. Confirmed pattern lifted directly from the
  --    engine's own Commands.trade (src/script/Commands.lua): push a
  --    pickOnly PartyMenu, yield the script coroutine, resume on pick
  --    or cancel. Any MEOWTH in the party qualifies, not just a
  --    specifically-tagged one -- if the player already had a
  --    different Meowth, that one works too.
  ----------------------------------------------------------------------
  mod.content.commands:register("snag_quest:turn_in_meowth", {
    foreground = true,
    fn = function(ctx)
      local Screens = require("src.ui.Screens")
      local party = ctx.save.party
      local runner = ctx.runner
      local picked
      Screens.push(ctx.game, "PartyMenu", {
        pickOnly = true,
        onCancel = function() runner:resume() end,
        onSwitch = function(mon) picked = mon; runner:resume() end,
      })
      runner:yield()
      if not picked or picked.species ~= "MEOWTH" then
        ctx.lastCheck = false
        return
      end
      local slot
      for i, mon in ipairs(party) do
        if mon == picked then slot = i break end
      end
      if slot then table.remove(party, slot) end
      ctx.lastCheck = true
    end,
  })

  mod.content.commands:register("snag_quest:complete", function(ctx)
    setFlag(ctx.game, FLAG_DONE)
    quests.advance(QUEST_ID, 1)
    quests.complete(QUEST_ID)
  end)

  ----------------------------------------------------------------------
  -- 5. The quest's own trainer -- one Meowth, nothing else on their
  --    team (mod.content.trainers:register's confirmed shape: id,
  --    name, basePic, baseMoney, parties -- only level/species per
  --    slot, per Schemas.lua's R.trainers).
  ----------------------------------------------------------------------
  -- Confirmed real Gen 1 sprite/data id: pokered's internal constant
  -- for this class is JR_TRAINER_F (localized as "Picnicker" starting
  -- in later games; the pokered disassembly this engine is built on
  -- predates that rename). basePic borrows the real class's sprite;
  -- name is just our own flavor string.
  mod.content.trainers:register(TRAINER_CLASS, {
    id = TRAINER_CLASS, name = "PICNICKER", basePic = "OPP_JR_TRAINER_F", baseMoney = 30,
    parties = { { { species = "MEOWTH", level = MEOWTH_LEVEL } } },
  })

  ----------------------------------------------------------------------
  -- 6. The quest, registered into Quest System.
  ----------------------------------------------------------------------
  quests.register({
    id          = QUEST_ID,
    title       = "Introduction to Thievery",
    source      = "Pokemon Snag",
    description = "A TEAM ROCKET recruiter has a first assignment for you: the boss wants the oddly-coloured MEOWTH a PICNICKER is holding.",
    objective   = function(game)
      if hasFlag(game, FLAG_DONE) then return "MEOWTH is home safe." end
      -- 0.14.0: was "back to the girl in Viridian City" -- left over from
      -- the pre-0.13.0 Jessie opening, and wrong since the quest moved to
      -- the Nugget Bridge recruiter. Viridian is untouched now.
      if hasFlag(game, FLAG_STARTED) then return "Bring a MEOWTH back to the TEAM ROCKET recruiter at the end of NUGGET BRIDGE." end
      return "Beat the TEAM ROCKET recruiter at the end of NUGGET BRIDGE, then hear him out."
    end,
    location = "Route 24",
    reward   = "5 SNAG BALLs, and people who'll trade you more",
    status   = function(game)
      if hasFlag(game, FLAG_DONE) then return "completed" end
      if hasFlag(game, FLAG_STARTED) then return "active" end
      return "available"
    end,
    progress = { current = 0, total = 1 },
    -- Markers are registered for BOTH of the recruiter's forms (0.14.9).
    -- Only the vanilla object was listed before, so once BILL hid it the
    -- journal pointed at an NPC that is no longer on the map -- and that
    -- is the majority case, since every player eventually passes BILL.
    -- The stand-in carries this mod's own text key, so it needs its own
    -- entries. Listing a constant whose object is absent is harmless:
    -- the other pair simply never resolves, the same way registering
    -- both the Red/Blue and Yellow names of a renamed NPC is harmless.
    markers = {
      { map = "ROUTE_24", text = "TEXT_ROUTE24_COOLTRAINER_M1", kind = "available",
        when = function(game)
          return not hasFlag(game, FLAG_STARTED)
        end },
      { map = "ROUTE_24", text = "TEXT_ROUTE24_COOLTRAINER_M1", kind = "turnin",
        when = function(game)
          return hasFlag(game, FLAG_STARTED) and not hasFlag(game, FLAG_DONE)
        end },
      { map = "ROUTE_24", text = "TEXT_SNAG_ROUTE24_ROCKET", kind = "available",
        when = function(game)
          return not hasFlag(game, FLAG_STARTED)
        end },
      { map = "ROUTE_24", text = "TEXT_SNAG_ROUTE24_ROCKET", kind = "turnin",
        when = function(game)
          return hasFlag(game, FLAG_STARTED) and not hasFlag(game, FLAG_DONE)
        end },
    },
  })

  ----------------------------------------------------------------------
  -- 7. Dialogue: the Nugget Bridge recruiter, taken over only AFTER
  --    he has been beaten. Everything before that -- the NUGGET, the
  --    recruitment pitch, the battle -- stays vanilla, reached through
  --    base_talk.
  ----------------------------------------------------------------------
  -- Hand a talk back to whatever the engine would have done with it.
  --
  -- MapScripts.baseTalk returns the BASE contribution's talk value for
  -- this constant, and that value has three possible shapes -- confirmed
  -- from OverworldState:showMapText (src/world/OverworldController.lua),
  -- which is the single funnel every NPC talk goes through:
  --
  --   function  a Lua talk handler; called with (game, ow, npc, onDone).
  --             The Game Corner coin-giver is one of these
  --             (data/scripts/flavor/game_corner.lua's coinGiver).
  --   table     a { "command", ... } row list, run by the ScriptRunner.
  --             The Vermilion sailor is one of these (data/scripts/
  --             story.lua M.VERMILION_CITY.talk).
  --   nil       no ported script at all; showMapText falls through to
  --             Game.data:resolveText(mapLabel, textConst) and shows the
  --             plain ROM text. The Pewter man is one of these -- the
  --             engine's flavor script for his map defines only the
  --             NIDORAN.
  --
  -- Until 0.14.0 this handled ONLY the function shape: a row list was
  -- called as if it were a function (error -> swallowed by the runner ->
  -- the NPC turns to face you and says nothing) and nil returned early
  -- with no text at all. That mattered from 0.14.0 on because the
  -- Vermilion sailor's base talk is the S.S. ANNE ticket check, and
  -- because it silently ate the Pewter man's vanilla line for every
  -- player who had not yet earned the BOULDERBADGE.
  --
  -- NOTE: registering a talk for a constant means showMapText's own
  -- resolveText fallback is never reached -- our rows win outright -- so
  -- reproducing all three shapes here is the only way a gated-off branch
  -- can look untouched.
  local function baseTalkCommand(ctx, mapId, textId)
    local base = MapScripts.baseTalk(mapId, textId)
    if type(base) == "function" then
      local runner = ctx.runner
      base(ctx.game, ctx.overworld, ctx.npc, function() runner:resume() end)
      runner:yield()
      return
    end
    if type(base) == "table" then
      -- ScriptRunner:exec is a plain synchronous row loop on the CURRENT
      -- coroutine (src/script/ScriptRunner.lua), so blocking rows inside
      -- the base script yield and resume on our own runner exactly as
      -- they would have if the engine had dispatched them itself. The
      -- base rows are indexed from 1 of their OWN list, so vanilla's
      -- hand-numbered jump targets still resolve.
      ctx.runner:exec(base, ctx)
      return
    end
    -- No ported script: show the ROM text the engine would have shown.
    -- Commands.show_text resolves an object TEXT_ constant through
    -- ctx.overworld.map.def.label when it isn't a bare text key
    -- (confirmed from src/script/Commands.lua), which is exactly
    -- showMapText's own fallback.
    --
    -- Resolve FIRST and only speak if something came back. show_text's
    -- last resort is `text = textId`, i.e. it prints whatever string it
    -- was handed -- fine for the hand-ported scripts that pass literal
    -- dialogue, but here textId is a TEXT_ constant, so an unresolvable
    -- one would put the raw "TEXT_PEWTERNIDORANHOUSE_MIDDLE_AGED_MAN"
    -- in a dialogue box. showMapText's own miss path prints nothing and
    -- just logs, so staying silent is what vanilla would have done.
    local data = ctx.game and ctx.game.data
    if not data then return end
    local resolved = data.text and data.text[textId]
    if not resolved and ctx.overworld then
      resolved = data:resolveText(ctx.overworld.map.def.label, textId)
    end
    if not resolved then return end
    require("src.script.Commands").show_text(ctx, textId)
  end
  mod.content.commands:register("snag_quest:base_talk", { foreground = true, fn = baseTalkCommand })

  -- Custom check instead of a raw check_flag row, so the dev toggle can
  -- override what "done" means for dialogue-branching purposes without
  -- touching FLAG_DONE itself (see questDoneForReal above).
  mod.content.commands:register("snag_quest:check_quest_done", function(ctx)
    ctx.lastCheck = questDoneForReal(ctx.game)
  end)

  -- Was this trainer already beaten? Confirmed from the engine's own
  -- Route 24 script (data/scripts/story4.lua): it branches on
  -- ow:trainerDefeated(npc), and the same overworld/npc are on ctx.
  mod.content.commands:register("snag_quest:check_defeated", function(ctx)
    local ow, npc = ctx.overworld, ctx.npc
    ctx.lastCheck = (ow and npc and ow:trainerDefeated(npc)) and true or false
  end)

  ----------------------------------------------------------------------
  -- The recruiter at the end of Nugget Bridge (ROUTE_24).
  --
  -- Vanilla (data/scripts/story4.lua): first talk hands over the NUGGET,
  -- asks "would you like to join TEAM ROCKET?", then battles you --
  -- and IGNORES the answer, replying "Arrgh! You are not convinced?"
  -- either way. After he's beaten he just laments his dreams of Team
  -- Rocket forever.
  --
  -- All of that is left completely untouched: until he's defeated, this
  -- delegates straight to the vanilla handler via base_talk. The mod
  -- only takes over his POST-DEFEAT line, which vanilla wastes on a
  -- one-liner. Beating him is the interview; the offer comes after.
  --
  -- That also solves "what if I say no": he is talkable forever once
  -- beaten, so declining just leaves the offer open. Come back and
  -- talk again.
  ----------------------------------------------------------------------
  -- The recruiter's own fence lines (0.14.0).
  --
  -- He is the fourth fence, and the only one who is not registered
  -- through registerMerchant -- see the note on fenceRows for why he
  -- can't be. Design decisions, deliberate:
  --   * NO badge gate. Finishing the first job IS the credential, and in
  --     practice this lands later than CASCADEBADGE anyway.
  --   * Standard payout, no VIP bonus of his own -- snagPayout is
  --     unchanged and he pays exactly what the other three pay.
  -- He replaces the CASCADEBADGE-gated Cerulean grunt that 0.13.1 spawned
  -- in CERULEAN_CITY; that NPC is gone as of this version.
  --
  -- These rows go in the post-quest branch, so they compose with the
  -- questline instead of overwriting it: pre-quest he still recruits,
  -- mid-quest he still takes the MEOWTH and re-arms the PICNICKER
  -- rematch, and only the "done" branch changes. The Celadon hint that
  -- used to live in that branch is GONE rather than kept alongside --
  -- with him buying, sending the player to another city to sell was
  -- redundant. The MART hint still stands in when fences are switched
  -- off, so the branch never points at a closed door.
  local RECRUITER_FENCE = {
    intro = "The boss remembers\ngood work.\fI'm still posted\nhere. I still pay.\vCarrying anything\vthat isn't yours?",
    refuse = "Nothing? Then get\nback out there.\fThe BALLs don't\nrestock\vthemselves.",
    sold = "Good. I'll log it\nas never arriving.\fKeep this up and\nthe boss learns\vyour name.",
  }
  local DONE_MART_HINT = "The boss remembers\ngood work.\fThe bigger MARTS\nstock SNAG BALLs\vnow, if you can\vafford them."

  local ROUTE24_TALK = concatRows({
    { "snag_quest:check_defeated" },
    { "jump_if_false", "vanilla" },

    { "snag_quest:check_quest_done" },
    { "jump_if_true", "done" },
    { "check_flag", FLAG_STARTED },
    { "jump_if_true", "started" },

    { "ask", "Hah! You floored\nme.\fTEAM ROCKET could\nuse\vsomeone who hits\vlike\vthat.\f...I'm serious.\nStill interested?" },
    { "jump_if_false", "declined" },
    { "set_flag", FLAG_STARTED },
    { "give_item", "SNAG_BALL", QUEST_BALL_COUNT, false },
    { "show_text", "Then consider the\ninterview passed.\fFirst mission,\nstraight\vfrom the boss.\fThere's a\nPICNICKER near\vhere with a MEOWTH\vthat\vcame out... wrong.\vWrong colour.\fThe boss wants to\nsee it.\fHere. One SNAG\nBALL.\vDon't ask where we\vget\vthem." },
    { "start_battle", "trainer", TRAINER_CLASS, PARTY_INDEX },
    { "jump", "started" },

    { "label", "started" },
    { "show_text", "Well? Where's the\nMEOWTH?" },
    { "snag_quest:turn_in_meowth" },
    { "jump_if_true", "success" },
    { "ask", "No MEOWTH, no\npromotion.\fWant another crack\nat\vthat PICNICKER?" },
    { "jump_if_false", "end" },
    { "give_item", "SNAG_BALL", QUEST_BALL_COUNT, false },
    { "show_text", "Another BALL.\nThese\varen't free, you\vknow." },
    { "start_battle", "trainer", TRAINER_CLASS, PARTY_INDEX },
    { "jump", "started" },

    { "label", "success" },
    { "show_text", "...That's the one.\fLook at the colour\non it.\vThe boss will want\vto see this\vpersonally." },
    -- The reward. 0.14.7: this give_item did not exist, so the payout was
    -- zero -- see the QUEST_BALL_COUNT note at the top of the file. The
    -- count is named in words in the line below; keep the two in step.
    { "give_item", "SNAG_BALL", QUEST_REWARD_BALLS, false },
    { "show_text", "First mission,\nclean work.\fThe boss pays\nhis people.\fTake these. Five\nSNAG BALLs.\vThey don't come\vcheap, so don't\vwaste them.\fAnd word gets\naround.\vCertain people\vwill trade you\vmore of them...\vif you bring them\vthe right kind of\vPOKeMON." },
    -- Sets up the sprite change (0.14.5). This branch is on the VANILLA
    -- recruiter only, and it is the last thing he says before BILL removes
    -- him for good -- so the grunt standing in his spot afterwards, in
    -- actual TEAM ROCKET colours, reads as him keeping his word rather
    -- than as a different NPC appearing from nowhere.
    --
    -- It cannot go on the stand-in: by then the change has already
    -- happened, and the stand-in's own lines are written as a different
    -- grunt regardless. Deliberately placed AFTER the mission is turned
    -- in rather than at recruitment, so it lands as a parting beat.
    { "show_text", "One more thing.\nMy bridge shift is\vdone.\fI can finally get\nout of these\vcivilian clothes.\fYou'll know me\nwhen you see me." },
    { "snag_quest:complete" },
    { "jump", "end" },

    { "label", "done" },
    { "snag_quest:check_fence_open" },
    { "jump_if_false", "done_mart" },
  }, fenceRows(RECRUITER_FENCE, "recruiter"), {
    { "jump", "end" },

    { "label", "done_mart" },
    { "show_text", DONE_MART_HINT },
    { "jump", "end" },

    { "label", "declined" },
    { "show_text", "Heh. Think it\nover.\fI'm not going\nanywhere." },
    { "jump", "end" },

    { "label", "vanilla" },
    { "snag_quest:base_talk", "ROUTE_24", "TEXT_ROUTE24_COOLTRAINER_M1" },
    { "label", "end" },
  })

  mod.content.map_scripts:register("ROUTE_24", {
    talk = { TEXT_ROUTE24_COOLTRAINER_M1 = ROUTE24_TALK },
    priority = 500,
  })

  ----------------------------------------------------------------------
  -- Keeping the recruiter around.
  --
  -- The vanilla recruiter is NOT removed by beating him -- he stays and
  -- laments his dreams of Team Rocket. What removes him is BILL:
  -- data/scripts/story.lua hides ROUTE24_COOLTRAINER_M1 permanently on
  -- EVENT_LEFT_BILLS_HOUSE_AFTER_HELPING (leaving Bill's house with the
  -- S.S. Ticket), which is vanilla Gen 1 behaviour and has nothing to do
  -- with the battle.
  --
  -- That leaves two populations: players who still have him, and players
  -- past Bill for whom he is gone forever -- including anyone who never
  -- fought him, since he has no trainer header and sight never engages
  -- him. So once the vanilla object is hidden, this mod spawns its own
  -- Rocket in the same spot, permanently, with its own text key.
  --
  -- The stand-in does NOT require beating him: that fight is either
  -- already done or no longer possible. He is otherwise the same
  -- contact -- mission giver, turn-in, and post-quest hint -- and is a
  -- natural home for a future fence.
  ----------------------------------------------------------------------
  local ROUTE24_ROCKET = {
    map   = "ROUTE_24",
    name  = "SNAG_ROUTE24_ROCKET",
    text  = "TEXT_SNAG_ROUTE24_ROCKET",
    -- His vanilla tile. story4.lua's onStep fires when the player stands
    -- on (10,15) "in front of the recruiter", so he stands at (10,14).
    -- Nudge if he ends up misplaced.
    x = 10,
    y = 14,
    facing = "DOWN",
  }

  local function route24RocketWanted(game)
    -- only once vanilla has removed its own copy, so the two never
    -- coexist and the original keeps its nugget/battle content
    return game and game.save and game.save.flags
      and game.save.flags.EVENT_LEFT_BILLS_HOUSE_AFTER_HELPING == true
  end

  local function ensureRoute24Rocket(game)
    if not (game and mod.world and mod.world.spawnNpc) then return end
    if not route24RocketWanted(game) then return end
    if mod.world.npc then
      local existing = mod.world:npc(ROUTE24_ROCKET.map, ROUTE24_ROCKET.name)
      if existing then return end
    end
    local sprite = rocketSprite(game)
    if not sprite then return end
    mod.world:spawnNpc(ROUTE24_ROCKET.map, {
      name = ROUTE24_ROCKET.name,
      sprite = sprite,
      x = ROUTE24_ROCKET.x,
      y = ROUTE24_ROCKET.y,
      movement = "STAY",
      range = ROUTE24_ROCKET.facing,
      text = ROUTE24_ROCKET.text,
    })
    mod.log:info("spawned Route 24 recruiter stand-in at %d,%d",
      ROUTE24_ROCKET.x, ROUTE24_ROCKET.y)
  end

  local function safeEnsureRoute24(game)
    local ok, err = pcall(ensureRoute24Rocket, game)
    if not ok then
      mod.log:warn("snag_quest: Route 24 spawn failed: %s", tostring(err))
    end
  end

  mod.events:on("map.entered", function(payload)
    safeEnsureRoute24((payload and payload.game) or currentGameRef)
  end)
  mod.events:on("game.ready", function(payload)
    local game = payload and payload.game
    if game then safeEnsureRoute24(game) end
  end)

  -- Same script as the vanilla takeover, minus the beat-him-first gate.
  --
  -- He is a fence in BOTH forms on purpose. These two objects are the
  -- same character -- which one the player meets depends only on whether
  -- BILL has hidden the vanilla one yet -- so a player pre-BILL who
  -- finishes the quest gets the same buyer a player post-BILL does. Only
  -- making the stand-in a fence would have left the pre-BILL recruiter
  -- pointing at CELADON for a service he himself provides three steps
  -- later.
  local ROUTE24_STANDIN_TALK = concatRows({
    { "snag_quest:check_quest_done" },
    { "jump_if_true", "done" },
    { "check_flag", FLAG_STARTED },
    { "jump_if_true", "started" },

    { "ask", "...You're the one\nwho\vcame over the\vbridge.\fTEAM ROCKET's been\nwatching. We could\vuse\vsomeone like you.\vInterested?" },
    { "jump_if_false", "declined" },
    { "set_flag", FLAG_STARTED },
    { "give_item", "SNAG_BALL", QUEST_BALL_COUNT, false },
    { "show_text", "Then here's your\nfirst\vjob, straight from\vthe\vboss.\fThere's a\nPICNICKER near\vhere with a MEOWTH\vthat\vcame out... wrong.\vWrong colour.\fThe boss wants to\nsee it.\fHere. One SNAG\nBALL.\vDon't ask where we\vget\vthem." },
    { "start_battle", "trainer", TRAINER_CLASS, PARTY_INDEX },
    { "jump", "started" },

    { "label", "started" },
    { "show_text", "Well? Where's the\nMEOWTH?" },
    { "snag_quest:turn_in_meowth" },
    { "jump_if_true", "success" },
    { "ask", "No MEOWTH, no\npromotion.\fWant another crack\nat\vthat PICNICKER?" },
    { "jump_if_false", "end" },
    { "give_item", "SNAG_BALL", QUEST_BALL_COUNT, false },
    { "show_text", "Another BALL.\nThese\varen't free, you\vknow." },
    { "start_battle", "trainer", TRAINER_CLASS, PARTY_INDEX },
    { "jump", "started" },

    { "label", "success" },
    { "show_text", "...That's the one.\fLook at the colour\non it.\vThe boss will want\vto see this\vpersonally." },
    -- Same reward as the vanilla recruiter's branch (0.14.7); it was
    -- missing here too. Count named in words below -- keep in step.
    { "give_item", "SNAG_BALL", QUEST_REWARD_BALLS, false },
    { "show_text", "First job, clean\nwork.\fThe boss pays\nhis people.\fTake these. Five\nSNAG BALLs.\vThey don't come\vcheap, so don't\vwaste them.\fAnd word gets\naround.\vCertain people\vwill trade you\vmore of them...\vif you bring them\vthe right kind of\vPOKeMON." },
    { "snag_quest:complete" },
    { "jump", "end" },

    { "label", "done" },
    { "snag_quest:check_fence_open" },
    { "jump_if_false", "done_mart" },
  }, fenceRows(RECRUITER_FENCE, "standin"), {
    { "jump", "end" },

    { "label", "done_mart" },
    { "show_text", DONE_MART_HINT },
    { "jump", "end" },

    { "label", "declined" },
    { "show_text", "Heh. Think it\nover.\fI'm not going\nanywhere." },
    { "label", "end" },
  })

  mod.content.map_scripts:register(ROUTE24_ROCKET.map, {
    talk = { [ROUTE24_ROCKET.text] = ROUTE24_STANDIN_TALK },
    priority = 500,
  })

  ----------------------------------------------------------------------
  -- Cross-mod contract. Declared in code rather than in a handoff note,
  -- so another mod can check it at runtime instead of a human relaying
  -- a message between two agents that both go stale.
  --
  -- OWNS: everything about the SNAG_BALL record -- its registration,
  -- catch behaviour, tossAnim and flicker. Another mod patching those
  -- fields will fight this one silently (last folded op wins), so
  -- read `owns` below and back off rather than patching.
  --
  -- OPEN: the colour. pokeball_colors keys its palette off ball id and
  -- exposes `exports.colors` for exactly this, so this mod registers
  -- its OWN colour there instead of that mod hardcoding an entry for
  -- us. That inverts the dependency: renaming, recolouring or adding a
  -- second ball here needs no change there, ever.
  ----------------------------------------------------------------------
  mod.exports.owns = {
    balls = { SNAG_BALL = { "tossAnim", "flicker", "attempt", "record" } },
    monFields = { "snagged", "snagFrom", "snagLevel" },
  }
  -- Team Rocket colours: near-black body, red "R" accent.
  mod.exports.ballColors = {
    SNAG_BALL = { body = { 40, 36, 40 }, accent = { 216, 48, 40 } },
  }

  mod.events:on("game.ready", function()
    -- Registered on game.ready, not at load: mod.find can't see a mod
    -- that hasn't loaded yet, and load order between two independent
    -- mods isn't guaranteed either way. By game.ready both exist, and
    -- this still lands well before anything draws a ball.
    local pbc = mod.find("pokeball_colors")
    if not (pbc and pbc.exports and pbc.exports.colors) then return end
    for ballId, colour in pairs(mod.exports.ballColors) do
      -- Only fill a gap; never clobber a colour that mod already ships
      -- (its entry and ours are the same palette today, and if a future
      -- version of theirs deliberately differs, theirs should win).
      if pbc.exports.colors[ballId] == nil then
        pbc.exports.colors[ballId] = colour
        mod.log:info("registered %s colour with pokeball_colors", ballId)
      end
    end
  end)

  mod.log:info("Pokemon Snag %s loaded", VERSION)
end
