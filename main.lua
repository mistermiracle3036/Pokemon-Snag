-- Team Rocket: Snag Quest -- "Jessie's Meowth"
--
-- The girl in Viridian City (TEXT_VIRIDIANCITY_GIRL, next to the
-- sleeping man blocking the road) is Grandpa's granddaughter -- yes,
-- THAT grandpa, the OLD MAN who teaches new trainers to catch Pokemon
-- once you have the Pokedex. His SNAG BALLS are his own invention, so
-- he never fluffs the catching demo in front of a trainee -- and she
-- can't believe he wastes them on whatever WEEDLE or RATTATA wanders
-- by. A grunt nearby has swiped one of the Pokemon he was saving --
-- an unusually marked MEOWTH -- and she wants it back.
--
-- Gate: EVENT_GOT_POKEDEX. Confirmed from the engine's own
-- data/scripts/story.lua: this single flag is what both gives you the
-- Pokedex AND swaps the sleeping man out for the walking one at the
-- same onEnter call (Commands.hide_object the sleeper, show_object
-- the walker) -- there's no separate "he got up" flag in the real
-- game, the two conditions the story asked for are one and the same
-- here.
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
  local journal = assert(mod.find("quest_system"), "Quest System is required")
  local quests = journal.exports

  local QUEST_ID       = "snag_quest.jessies_meowth"
  local FLAG_STARTED   = "MOD_SNAG_QUEST_GIRL_STARTED"
  local FLAG_DONE      = "MOD_SNAG_QUEST_GIRL_DONE"
  local TRAINER_CLASS  = "OPP_SNAG_QUEST_GRUNT"
  local PARTY_INDEX    = 1
  local MEOWTH_LEVEL   = 8
  local UNLOCK_BALL_COUNT = 5

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
      label = "Continue battle after snag", default = false },
    { key = "sell_snag_balls_in_marts", type = "toggle",
      label = "Sell Snag Balls in marts (after quest)", default = true },
  })
  local function continueBattleAfterSnag()
    return mod.options:get("continue_battle_after_snag") == true
  end
  -- OFF (default) -- the battle ends immediately as a normal WIN
  --   (victory music, trainer defeat text, prize money). Stable, and
  --   the snagged Pokemon is kept, because storeCaughtMon's own
  --   Party.add/Boxes.deposit has already run by that point.
  --
  -- ON (experimental) -- the fight continues with the trainer's next
  --   Pokemon. This is the nicer behaviour and what "seamless" really
  --   wants, but as of 0.5.6 it still FREEZES for at least some
  --   battles: the enemy HUD keeps showing the snagged mon, no next
  --   sprite appears, and the message box sits empty forever. Current
  --   best lead (not confirmed): enemyMonFainted runs awardExp()
  --   before the switch, which can queue a level-up StatBox via
  --   uiNext -- a row that blocks the queue until its pushed screen
  --   pops. That matches an empty, never-advancing box and a player
  --   mon that was in level-up range. Three earlier fixes to this path
  --   (calling enemyMonFainted directly, forcing battleStyle "set",
  --   and the afterQueue="menu" fix) each looked right from source and
  --   each still froze, so this stays opt-in rather than the default.

  local function hasFlag(game, name) return Flags.get(game.save, name) == true end
  local function setFlag(game, name) Flags.set(game.save, name) end

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
    tossAnim = "TOSS_ANIM",
    attempt = snagAttempt,
  })
  mod.content.items:register("SNAG_BALL", {
    id = "SNAG_BALL", name = "SNAG BALL", price = 10000,
    tossable = true, ball = "SNAG_BALL",
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
    if BattleState._snagQuestWrapped then return end
    BattleState._snagQuestWrapped = true

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
    local vanillaNewTrainer = BattleState.newTrainer
    BattleState.newTrainer = function(g, oppClass, partyIndex)
      local battle = vanillaNewTrainer(g, oppClass, partyIndex)
      if oppClass == TRAINER_CLASS and battle and battle.enemyParty then
        for _, mon in ipairs(battle.enemyParty) do
          if mon.species == "MEOWTH" then
            mon.dvs = shinyDVs()
            mon.stats = Stats.calc(g.data.pokemon[mon.species], mon.level, mon.dvs)
            mon.hp = mon.stats.hp
            -- the data-truth check is Stats.isShiny(mon.dvs), which the
            -- DVs above already satisfy; mon.shiny is the cached flag
            -- the Shiny Pokemon mod's own visuals read, set here the
            -- same way that mod sets it at its own hook points
            mon.shiny = true
          end
        end
      end
      return battle
    end

    local vanillaThrowBall = BattleState.throwBall
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
      and mod.options:get("sell_snag_balls_in_marts") == true
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
  mod.content.trainers:register(TRAINER_CLASS, {
    id = TRAINER_CLASS, name = "ROCKET GRUNT", basePic = "OPP_ROCKET", baseMoney = 30,
    parties = { { { species = "MEOWTH", level = MEOWTH_LEVEL } } },
  })

  ----------------------------------------------------------------------
  -- 6. The quest, registered into Quest System.
  ----------------------------------------------------------------------
  quests.register({
    id          = QUEST_ID,
    title       = "Grandpa's Meowth",
    source      = "Snag Quest",
    description = "A grunt swiped a Pokemon Grandpa was saving for his catching demos. Get it back to his granddaughter in Viridian City.",
    objective   = function(game)
      if hasFlag(game, FLAG_DONE) then return "MEOWTH is home safe." end
      if hasFlag(game, FLAG_STARTED) then return "Bring a MEOWTH back to the girl in Viridian City." end
      return "Talk to the girl in Viridian City, once you have the Pokedex."
    end,
    location = "Viridian City",
    reward   = "Unlocks the SNAG BALL for permanent use",
    status   = function(game)
      if hasFlag(game, FLAG_DONE) then return "completed" end
      if hasFlag(game, FLAG_STARTED) then return "active" end
      return "available"
    end,
    progress = { current = 0, total = 1 },
    markers = {
      { map = "VIRIDIAN_CITY", text = "TEXT_VIRIDIANCITY_GIRL", kind = "available",
        when = function(game)
          return hasFlag(game, "EVENT_GOT_POKEDEX") and not hasFlag(game, FLAG_STARTED)
        end },
      { map = "VIRIDIAN_CITY", text = "TEXT_VIRIDIANCITY_GIRL", kind = "turnin",
        when = function(game)
          return hasFlag(game, FLAG_STARTED) and not hasFlag(game, FLAG_DONE)
        end },
    },
  })

  ----------------------------------------------------------------------
  -- 7. Dialogue: the real TEXT_VIRIDIANCITY_GIRL, repurposed via
  --    map_scripts (Team Rocket Returns' pattern), gated the same way
  --    her own vanilla line already is -- EVENT_GOT_POKEDEX -- via a
  --    base_talk fallback for the pre-Pokedex case so her original
  --    "hasn't had his coffee" line is untouched.
  ----------------------------------------------------------------------
  local function baseTalkCommand(ctx, mapId, textId)
    local base = MapScripts.baseTalk(mapId, textId)
    if not base then return end
    local runner = ctx.runner
    base(ctx.game, ctx.overworld, ctx.npc, function() runner:resume() end)
    runner:yield()
  end
  mod.content.commands:register("snag_quest:base_talk", { foreground = true, fn = baseTalkCommand })

  local GIRL_TALK = {
    { "check_flag", "EVENT_GOT_POKEDEX" },
    { "jump_if_false", "base" },
    { "check_flag", FLAG_DONE },
    { "jump_if_true", "done" },
    { "check_flag", FLAG_STARTED },
    { "jump_if_true", "started" },

    { "ask", "Grandpa's finally had his\ncoffee, so he's out giving\nhis catching lesson again.\fHe built those SNAG BALLS\nhimself, you know -- so he\nnever fumbles a catch in\nfront of a trainee.\fAnd what does he use them\non? Whatever WEEDLE or\nRATTATA happens by! What\na waste.\fA grunt swiped one of the\nPokemon he was saving --\ncan you get it back?" },
    { "jump_if_false", "declined" },
    { "set_flag", FLAG_STARTED },
    { "give_item", "SNAG_BALL", UNLOCK_BALL_COUNT, false },
    { "show_text", "Take a few of his SNAG\nBALLS. Bring MEOWTH back\nsafe, okay?" },
    { "start_battle", "trainer", TRAINER_CLASS, PARTY_INDEX },
    { "jump", "started" },

    -- Reusable loop for every later visit: try the turn-in first (this
    -- covers a Meowth caught just now, an older stray Meowth, or one
    -- from a completely different catch), and only offer a rematch
    -- against the grunt if that comes up empty.
    { "label", "started" },
    { "snag_quest:turn_in_meowth" },
    { "jump_if_true", "success" },
    { "ask", "Still no MEOWTH? Want\nanother shot at that\ngrunt?" },
    { "jump_if_false", "end" },
    { "start_battle", "trainer", TRAINER_CLASS, PARTY_INDEX },
    { "jump", "started" },

    { "label", "success" },
    { "show_text", "There you are! Come here,\nyou." },
    { "show_text", "...Huh. Its coloring looks\na little unique, doesn't\nit? Never mind that.\fI think we'll be friends\nfor a long time." },
    { "snag_quest:complete" },
    { "jump", "end" },

    { "label", "done" },
    { "show_text", "Thanks again for MEOWTH." },
    { "jump", "end" },

    { "label", "declined" },
    { "show_text", "Oh... okay. Let me know\nif you change your mind." },
    { "jump", "end" },

    { "label", "base" },
    { "snag_quest:base_talk", "VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GIRL" },
    { "label", "end" },
  }

  mod.content.map_scripts:register("VIRIDIAN_CITY", {
    talk = { TEXT_VIRIDIANCITY_GIRL = GIRL_TALK },
    priority = 500,
  })

  mod.exports.version = "0.7.0"
  mod.log:info("Snag Quest loaded")
end
