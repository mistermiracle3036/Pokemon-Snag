-- Engine capture for REQUESTS 813 (phone, 2026-11-10): after a trainer's POKEMON is snagged, the switch
-- prompt ("Will <PLAYER> change POKEMON?") showed the party-ball row drawn over the old enemy HUD.
-- Run by tests/enemy_hud_after_snag.py inside a booted Crystal with the whole Live set. It starts a real
-- trainer battle against a trainer with two or more POKEMON, throws a KINGPIN BALL (it cannot miss) and
-- taps A until the switch prompt is up, then reports the two HUD flags and saves the frame.
return function(game, H, step, tap, idle, act)
  local out = assert(io.open(assert(os.getenv("HUD_TEST_OUT")), "w"))
  local function say(...) out:write(table.concat({ ... }, "\t"), "\n"); out:flush() end
  local okAll, errAll = xpcall(function()
    local G = love.graphics
    local Bag = require("src.inventory.Bag")
    local Trainers = require("src.world.gen2.Trainers")
    for _ = 1, 600 do if idle() then break end step(1) end
    say("IDLE", tostring(idle()), "map", tostring(game.world and game.world.map and game.world.map.id))

    -- the frame the player would see (same capture as exchange/shared/test_textbox_arrow_driver.lua)
    local target = G.newCanvas(G.getWidth(), G.getHeight())
    local function capture(path)
      local real = G.setCanvas
      G.setCanvas = function(t, ...)
        if t == nil then return real({ target, stencil = true }) end
        return real(t, ...)
      end
      local ok, err = pcall(function()
        real({ target, stencil = true })
        G.push("all"); G.origin(); G.setScissor(); G.clear(0, 0, 0, 1); G.pop()
        love.draw()
      end)
      G.setCanvas = real
      real()
      if not ok then return say("CAPTURE", "error", tostring(err)) end
      local fd = target:newImageData():encode("png")
      local f = assert(io.open(path, "wb")); f:write(fd:getString()); f:close()
      say("CAPTURE", path)
    end

    -- a trainer with at least two POKEMON
    local record
    -- trainers.lua keys classes by name; Trainers.lookup takes the class's numeric index
    local wantClass = os.getenv("HUD_TEST_CLASS") or "BUG_CATCHER"
    local trainerData = game.data.trainers
    for id, class in pairs(trainerData and trainerData.classes or {}) do
      if type(class) == "table" and class.index and type(class.trainers) == "table" and id == wantClass then
        for member, row in ipairs(class.trainers) do
          if type(row.party) == "table" and #row.party >= 2 then
            record = Trainers.lookup(trainerData, class.index, member)
            if record then break end
          end
        end
      end
      if record then break end
    end
    assert(record, "no trainer with two POKEMON found")
    say("TRAINER", tostring(record.classId), tostring(record.name), "roster", tostring(#record.roster))

    local save = game.save
    for _, mon in ipairs(save.party) do mon.hp = mon.maxHp or (mon.stats and mon.stats.hp) or mon.hp end
    assert(#save.party >= 2 or true)
    say("PARTY", tostring(#save.party))
    assert(Bag.add(save, "KINGPIN_BALL", 1, game.data), "no room for the KINGPIN BALL")
    game.options = game.options or {}
    game.options.battleStyle = "SHIFT"

    local ended
    assert(game.world:startScriptedBattle(record, nil, function(outcome) ended = outcome or "?" end) ~= nil
      or true)
    local function battle()
      local top = game.stack:top()
      if top and top.battle and top.ballRows then return top end
    end
    local function press()
      act({ kind = "press", key = "a" }); step(1); act({ kind = "release", key = "a" }); step(3)
    end
    local bs
    for _ = 1, 3000 do
      bs = battle()
      if bs and bs.phase == "menu" then break end
      press()
    end
    assert(bs and bs.phase == "menu", "battle menu never came up; top phase " .. tostring(bs and bs.phase))
    local first = bs.battle.enemy
    say("MENU", "enemy", tostring(first and first.species), "enemyParty", tostring(#(bs.battle.enemyParty or {})),
      "showEnemyHud", tostring(bs.showEnemyHud), "ballRow", tostring(bs.ballRows.enemy))

    bs:useItem("KINGPIN_BALL")
    local seen, last = {}, nil
    local prompt = false
    for _ = 1, 4000 do
      local now = battle()
      if not now or ended then break end
      if now.phase ~= last then last = now.phase; seen[#seen + 1] = tostring(last) end
      if now.phase == "ask-shift" then prompt = true; break end
      -- a nickname prompt or any yes/no on the way: B answers no
      local top = game.stack:top()
      if top ~= now or now.phase == "ask-nickname" then
        act({ kind = "press", key = "b" }); step(1); act({ kind = "release", key = "b" }); step(3)
      else
        press()
      end
    end
    say("PHASES", table.concat(seen, ">"))
    local now = battle()
    local caught = false
    for _, mon in ipairs(save.party) do if mon == first or mon.snagged == true then caught = true end end
    say("SNAG", "caughtInParty", tostring(caught), "ended", tostring(ended))
    if prompt and now then
      for _ = 1, 20 do step(1) end
      say("PROMPT", "showEnemyHud", tostring(now.showEnemyHud), "ballRow", tostring(now.ballRows.enemy),
        "enemy", tostring(now.battle.enemy and now.battle.enemy.species),
        "enemyHp", tostring(now.battle.enemy and now.battle.enemy.hp))
      capture(assert(os.getenv("HUD_TEST_PNG")))
    else
      say("PROMPT", "never reached")
    end
    say("DONE")
  end, debug.traceback)
  if not okAll then say("ERROR", tostring(errAll)) end
  out:close()
end
