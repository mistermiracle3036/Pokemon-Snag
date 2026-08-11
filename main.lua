-- Pokemon Snag -- "Introduction to Thievery"
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
  local journal = assert(mod.find("quest_system"), "Quest System is required")
  local quests = journal.exports

  local QUEST_ID       = "snag_quest.jessies_meowth"
  local FLAG_STARTED   = "MOD_SNAG_QUEST_GIRL_STARTED"
  local FLAG_DONE      = "MOD_SNAG_QUEST_GIRL_DONE"
  local TRAINER_CLASS  = "OPP_SNAG_QUEST_PICNICKER"
  local PARTY_INDEX    = 1
  local MEOWTH_LEVEL   = 8
  -- Intro quest ball economy: exactly one ball to do the job with
  -- (the catch is guaranteed, so one is genuinely enough), and exactly
  -- one more as the reward for handing MEOWTH over -- so you finish
  -- the quest holding a single Snag Ball and have to earn any more
  -- from the fence or the marts.
  local QUEST_BALL_COUNT  = 1
  local QUEST_REWARD_BALLS = 1

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
    local n = 1
    local lv = mon.snagLevel or mon.level or 1
    if lv >= 25 then n = n + 1 end
    if lv >= 45 then n = n + 1 end
    local def = game.data.pokemon[mon.species]
    if def and def.catchRate and def.catchRate <= 45 then n = n + 1 end
    if mon.snagFrom and VIP_CLASSES[mon.snagFrom] then n = n + 1 end
    if n > 5 then n = 5 end
    return n
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
    reward   = "A SNAG BALL, and someone who'll sell you more",
    status   = function(game)
      if hasFlag(game, FLAG_DONE) then return "completed" end
      if hasFlag(game, FLAG_STARTED) then return "active" end
      return "available"
    end,
    progress = { current = 0, total = 1 },
    markers = {
      { map = "ROUTE_24", text = "TEXT_ROUTE24_COOLTRAINER_M1", kind = "available",
        when = function(game)
          return not hasFlag(game, FLAG_STARTED)
        end },
      { map = "ROUTE_24", text = "TEXT_ROUTE24_COOLTRAINER_M1", kind = "turnin",
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
    { "show_text", "First mission,\nclean work.\fKeep the spare\nBALL.\fAnd word gets\naround.\vCertain people\vwill trade you\vmore of them...\vif you bring them\vthe right kind of\vPOKeMON." },
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
    { "show_text", "First job, clean\nwork.\fKeep the spare\nBALL.\fAnd word gets\naround.\vCertain people\vwill trade you\vmore of them...\vif you bring them\vthe right kind of\vPOKeMON." },
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

  mod.exports.version = "0.14.5"
  mod.log:info("Pokemon Snag %s loaded", mod.exports.version)
end
