-- gift_jingle.lua -- a gift line that ends in the vanilla item jingle and holds the box until it ends.
--
-- MASTER: gen1recomp-work/exchange/shared/gift_jingle.lua (owner: the Checker, REQUESTS 547).
-- Copy this file into your mod BYTE FOR BYTE (e.g. lib/gift_jingle.lua). Never edit your copy; ask the
-- Checker to change the master. Rule: exchange/decisions/2026-11-07-gifts-play-the-vanilla-jingle.md.
--
-- WHAT IT DOES (engine v0.4.0, read 2026-11-10)
--   Vanilla Crystal's gift (engine/src/script/gen2/Vm.lua:676-711, World:specialSound World.lua:2574):
--   the received line types out, then Sfx_Item plays (Sfx_GetTm for a TM/HM), the music ducks under it
--   (Sound.lua FANFARES / GEN2_JINGLES), the box waits for the sound to finish, then for A.
--   Red does the same with Get_Item1 / Get_Key_Item (engine/src/script/Commands.lua:250-292).
--   An API 2 mod cannot get this through queueScript: the Gen 2 "text" verb calls World:showText, which
--   takes no sound options (engine/src/world/gen2/WorldAPI.lua:666). So this file does what the engine's
--   own API 3 path does on Gen 2 (engine/src/mods/UnifiedScripts.lua:722-739): it pushes one TextBox
--   armed with TextBox.soundOpts (engine/src/render/TextBox.lua:231-243). Your WORDING is never changed.
--   Gen 3 has a different text path; there the line shows through queueScript with no jingle.
--
-- USE
--   local Gift = <load this file the way your mod loads its other files>
--   -- before (Johto-Quest-Pack/fair_fight.lua:443-445):
--   --   if not Bag.add(save(),"GREAT_BALL",1,mod.game.data) then return say({"Make room in your\nBAG. I'll hold it."}) end
--   --   set("follow_done",true)
--   --   say({"You receive\na GREAT BALL!"})
--   -- after:
--   if not Gift.give(mod,"GREAT_BALL",1,"You receive\na GREAT BALL!",{onDone=next}) then
--     return say({"Make room in your\nBAG. I'll hold it."}) end      -- full bag: nothing added, no jingle
--   set("follow_done",true)
--
-- API
--   Gift.give(mod, itemId, count, line, opts) -> true | false, why
--     Adds count x itemId to the bag (src.inventory.Bag.add). If the bag refuses, returns false, "bag"
--     with NOTHING added, nothing shown and no jingle: show your own full-bag line, keep your flag unset.
--     On success shows `line` (your words; \n and \f as usual, last page gets the jingle) and returns true.
--   Gift.say(mod, itemId, line, opts) -> true | false, why
--     The same line + jingle WITHOUT touching the bag: for a mod that already added the item itself.
--   opts (all optional):
--     onDone = function()   called once, after the jingle and the player's A press
--     onBox  = function(box) called with the pushed TextBox (e.g. to attach a speaker portrait)
--     sound  = "Sfx_Name"   a different jingle, if the gift is not an ordinary item
--   It never sets your flags, never takes money, and only gives what you name.
--
-- Exempt from the rule: shop purchases (vanilla marts play no gift jingle) and full-bag hand-backs.
local Gift = { VERSION = 1 }

local Bag = require("src.inventory.Bag")
local TextBox = require("src.render.TextBox")

local Runtime = require("src.mods.Runtime")

-- mod.generation is set by the loader for every mod (engine/src/mods/Loader.lua:1455)
local function generation(mod)
  if mod.generation then return mod.generation end
  local data = mod.game and mod.game.data
  return (data and data.audio and data.audio.sfx and data.audio.sfx.Sfx_Item) and 2 or 1
end

-- The engine's own choice of jingle for this item, per generation (see the header for the sources).
function Gift.jingleFor(mod, itemId)
  local data = mod.game and mod.game.data
  local def = data and data.items and data.items[itemId]
  local sfx = data and data.audio and data.audio.sfx
  if sfx and sfx.Sfx_Item then
    return (def and def.pocket == "TM_HM") and "Sfx_GetTm" or "Sfx_Item"
  end
  return (def and def.keyItem) and "Get_Key_Item" or "Get_Item1"
end

local function once(fn)
  local done = false
  return function(...)
    if done then return end
    done = true
    if fn then return fn(...) end
  end
end

function Gift.say(mod, itemId, line, opts)
  opts = opts or {}
  local game = mod and mod.game
  local finish = once(opts.onDone)
  if type(line) ~= "string" or line == "" then return false, "no line" end
  local ow = mod.world and mod.world.overworld and mod.world:overworld()
  if generation(mod) == 3 or not (game and game.stack and ow) then
    -- no shared TextBox here: the mod's line, plainly, so the gift is still announced
    local ok, err = mod.world:queueScript({ { "text", line } }, { onDone = function() finish() end })
    return ok and true or false, err
  end
  local sound = opts.sound or Gift.jingleFor(mod, itemId)
  local options = TextBox.soundOpts(game, sound, { waitButton = true })
  ow.textbox = true
  local box = TextBox.new(game, line, function()
    ow.textbox = nil
    finish()
  end, options)
  game.stack:push(box)
  if opts.onBox then opts.onBox(box) end
  return true
end

function Gift.give(mod, itemId, count, line, opts)
  local game = mod and mod.game
  local save = game and game.save
  if not (save and Bag.add(save, itemId, count or 1, game.data)) then return false, "bag" end
  local ok, err = Gift.say(mod, itemId, line, opts)
  -- the item is in the bag either way: a failed box must not read as "not given"
  if not ok then Runtime.reportError(mod.id, "GIFT LINE NOT SHOWN\n" .. tostring(err)) end
  return true
end

return Gift
