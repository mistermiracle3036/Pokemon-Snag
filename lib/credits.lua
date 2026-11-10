-- Embeddable credits screen. Copy this file unchanged into each mod.
-- Increment on every library change, including drawing/layout changes.
-- v3 (2026-10-12): sections (PEOPLE / POKEMON / OTHER, LEFT/RIGHT) list one
-- name per row; A opens that artist's page (made, commissioned, in). Entry
-- fields `sections` and `commissions` are additive: v2 copies ignore them.
-- v4 (2026-11-10, REQUESTS 680; developer's pick "B and can it include Battle
-- portrait and maybe all of the mods they are used in if you click on the
-- sprite"): one ARTIST a page, their name large and each character on its own
-- row with its walking sprite; LEFT/RIGHT turns artists, UP/DOWN moves, A opens
-- the CHARACTER page (battle portrait, who made the walker and who made the
-- portrait -- CRYSTAL where the game's own art is used -- and USED IN, the mods
-- that ship it), B goes back. Entry fields `used` and `characters` are additive
-- (exchange/credits_table.py writes them): v3 copies ignore them, and an entry
-- without them still lists its works by name. No button hints on screen.
-- Art is never shipped here: it is read from the mods that ship it, found by
-- the paths the generator recorded (mods/<id>/<path>) or by file name among the
-- sprites those mods registered. Art that is not installed shows the name alone.
local LIB_VERSION = 4
local ROW_ID = "credits:book"
local CRYSTAL = "CRYSTAL"
local Credits = {}

function Credits.attach(mod, initialEntries)
  local Font = mod.ui.Font
  local registered, registrationOrder = {}, {}
  local contributions = setmetatable({}, { __mode = "k" })
  local syncRow

  local function optionalString(value)
    return type(value) == "string" and value ~= "" and value or nil
  end
  local function union(target, values)
    local seen = {}
    for _, value in ipairs(target) do seen[value] = true end
    if type(values) == "table" then
      for _, value in ipairs(values) do
        if optionalString(value) and not seen[value] then
          target[#target + 1], seen[value] = value, true
        end
      end
    end
  end
  -- A character record (credits_table.py): name, credit (the exact credit
  -- text, e.g. "Lass (RBY) (as Suzie)"), walk / front file names, pal,
  -- walkBy / battleBy ("CRYSTAL" = the game's own art), battleClass, used
  -- (short mod names) and files = { [modId] = { walk = path, front = path } }.
  local function copyCharacter(c)
    if type(c) ~= "table" or not optionalString(c.credit) then return nil end
    local copy = { credit = c.credit, name = optionalString(c.name) or c.credit,
      walk = optionalString(c.walk), front = optionalString(c.front),
      walkBy = optionalString(c.walkBy), battleBy = optionalString(c.battleBy),
      battleClass = optionalString(c.battleClass),
      pal = type(c.pal) == "number" and c.pal or nil, used = {}, files = {} }
    union(copy.used, c.used)
    if type(c.files) == "table" then
      for id, f in pairs(c.files) do
        if optionalString(id) and type(f) == "table" then
          copy.files[id] = { walk = optionalString(f.walk), front = optionalString(f.front),
            walkColour = f.walkColour == true, frontColour = f.frontColour == true }
        end
      end
    end
    return copy
  end
  local function mergeCharacters(target, values)
    if type(values) ~= "table" then return end
    for _, c in ipairs(values) do
      local copy = copyCharacter(c)
      if copy then
        local existing = target[copy.credit]
        if existing then
          union(existing.used, copy.used)
          for id, f in pairs(copy.files) do existing.files[id] = existing.files[id] or f end
          for _, k in ipairs({ "walk", "front", "walkBy", "battleBy", "battleClass", "pal" }) do
            if existing[k] == nil then existing[k] = copy[k] end
          end
        else
          target[copy.credit] = copy
        end
      end
    end
  end
  local function characterList(map)
    local list = {}
    for _, c in pairs(map) do list[#list + 1] = c end
    table.sort(list, function(a, b) return a.credit < b.credit end)
    return list
  end
  local function copyEntry(entry)
    if type(entry) ~= "table" or not optionalString(entry.artist)
      or not entry.artist:find("%S") then return nil end
    local result = { artist = entry.artist, works = {}, mods = {}, commissions = {},
      sections = {}, used = {}, source = optionalString(entry.source),
      note = optionalString(entry.note) }
    union(result.works, entry.works)
    union(result.mods, entry.mods)
    union(result.commissions, entry.commissions)
    union(result.sections, entry.sections)
    union(result.used, entry.used)
    local map = {}
    mergeCharacters(map, entry.characters)
    result.characters = characterList(map)
    return result
  end

  local function copyEntries(entries)
    local copies = {}
    if type(entries) == "table" then
      for _, entry in ipairs(entries) do
        local copy = copyEntry(entry)
        if copy then copies[#copies + 1] = copy end
      end
    end
    return copies
  end
  local baked = copyEntries(initialEntries)

  -- Owns this API and transient registrations, no save fields. Copy callers'
  -- tables so later mutation cannot change the next book unexpectedly.
  local function registerCredits(modId, entries)
    if not optionalString(modId) or type(entries) ~= "table" then return false end
    local copies = {}
    for _, entry in ipairs(entries) do
      local copy = copyEntry(entry)
      if copy then copies[#copies + 1] = copy end
    end
    if not registered[modId] then registrationOrder[#registrationOrder + 1] = modId end
    registered[modId] = copies
    -- Refresh a menu already assembled but not yet selected. Open screens
    -- retain their own snapshot, matching the runtime API in 0.1.0.
    for row in pairs(contributions) do syncRow(row) end
    return true
  end
  local function mergedEntries(rawEntries)
    local entries, byArtist, chars = {}, {}, {}
    for _, entry in ipairs(copyEntries(rawEntries)) do
      local existing = byArtist[entry.artist]
      if existing then
        union(existing.works, entry.works)
        union(existing.mods, entry.mods)
        union(existing.commissions, entry.commissions)
        union(existing.sections, entry.sections)
        union(existing.used, entry.used)
        existing.source = existing.source or entry.source
        existing.note = existing.note or entry.note
      else
        entries[#entries + 1], byArtist[entry.artist] = entry, entry
        chars[entry] = {}
      end
      mergeCharacters(chars[byArtist[entry.artist]], entry.characters)
    end
    for _, entry in ipairs(entries) do
      entry.charactersBy = chars[entry]
    end
    table.sort(entries, function(a, b)
      local al, bl = a.artist:lower(), b.artist:lower()
      if al == bl then return a.artist < b.artist end
      return al < bl
    end)
    return entries
  end
  local function display(text)
    text = text:gsub("%%", " percent "):gsub("%+", " plus "):gsub("%s+", " ")
    local out = {}
    for _, span in ipairs(Font.split(text)) do
      out[#out + 1] = span.code and text:sub(span.from, span.to) or "?"
    end
    return table.concat(out)
  end
  local function prefixFitting(text, width)
    local spans = Font.split(text)
    local count = Font.spansFitting(spans, width)
    return count > 0 and spans[count].to or 0
  end
  local function fit(text, width)
    text = display(text)
    return text:sub(1, prefixFitting(text, width or 144))
  end
  local function wrap(text, width)
    local lines = {}
    text = display(text):match("^%s*(.-)%s*$")
    while #text > 0 do
      local cut = prefixFitting(text, width)
      -- A custom glyph wider than the whole panel cannot supply a line.
      if cut == 0 then break end
      if cut < #text then
        local space = text:sub(1, cut + 1):match("^.*() ")
        if space and space > 1 then cut = space - 1 end
      end
      lines[#lines + 1] = text:sub(1, cut)
      text = text:sub(cut + 1):gsub("^%s+", "")
    end
    return lines
  end

  -- ---- art: read from the mods that ship it, never from this mod ----------
  -- Mods are siblings of this one (mod.path is "mods/<id>"). Every image goes
  -- through the engine's own loader, src.render.Assets.image -- the one
  -- SpriteRenderer uses for every mod-registered walker and BattleState for
  -- every mod trainer front, by these same mods/<id>/<path> paths, on the
  -- phone. NEVER hand a path to love.graphics.newImage / love.image.newImageData
  -- here: on the phone love.filesystem cannot see mod files (REQUESTS 129;
  -- tests/no_love_path_loads.lua). Whether a file is coloured comes from the
  -- generator (walkColour / frontColour), so no pixel is ever read here.
  local function engine(name)
    local ok, module = pcall(require, name)
    return ok and module or nil
  end
  local base = (type(mod.path) == "string" and mod.path:match("^(.*/)[^/]*$")) or "mods/"
  local images, reported = {}, {}
  local function report(message)
    if reported[message] then return end
    reported[message] = true
    local Runtime = engine("src.mods.Runtime")
    if Runtime and Runtime.reportError then pcall(Runtime.reportError, mod.id, "CREDITS ART\n" .. message) end
  end
  local function image(path)
    if images[path] == nil then
      local Assets = engine("src.render.Assets")
      local ok, img = false, nil
      if Assets and Assets.image then ok, img = pcall(Assets.image, path) end
      images[path] = ok and img or false
      if not (ok and img) then report(tostring(path) .. "\n" .. tostring(img)) end
    end
    return images[path] or nil
  end
  local function installed(id)
    if type(mod.find) ~= "function" then return true end
    local ok, found = pcall(mod.find, id)
    return ok and found ~= nil
  end
  local function shipped(c, role)
    local ids = {}
    for id in pairs(c.files) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
      local f = c.files[id]
      local rel = f[role]
      if rel and installed(id) then
        local path = base .. id .. "/" .. rel
        if image(path) then return path, f[role .. "Colour"] == true end
      end
    end
  end
  local function paletted(colors, colour, body)
    local Gbc = engine("src.render.GbcPalette")
    if colors and Gbc and not (colour and Gbc.mode == "gbc") and Gbc.available() then
      Gbc.with(colors, body)
    else
      body()
    end
  end

  local function open(game, rawEntries)
    local entries = mergedEntries(rawEntries)
    local data = game.data or {}
    local Palettes = engine("src.world.gen2.Palettes")
    local SpriteRenderer = engine("src.render.SpriteRenderer")
    -- file name -> a registered sprite drawing that file, so art a mod moved
    -- since the table was generated is still found
    local registeredByFile
    local function registeredSprite(file)
      if not registeredByFile then
        registeredByFile = {}
        for _, def in pairs(data.gen2Sprites or {}) do
          local ok, path = pcall(SpriteRenderer and SpriteRenderer.imagePath or error, def)
          if ok and type(path) == "string" then
            local name = path:match("([^/]+)$")
            if name and path:sub(1, #base) == base and not registeredByFile[name] then
              registeredByFile[name] = { path = path, colour = def.trueColor == true }
            end
          end
        end
      end
      local found = registeredByFile[file]
      if found then return found.path, found.colour end
    end
    local function objColors(pal)
      if not (Palettes and data.gen2Palettes) then return nil end
      local ok, colors = pcall(Palettes.spritePalette, data.gen2Palettes, "DAY", { paletteId = pal or 0 })
      if not (ok and type(colors) == "table" and colors[1]) then return nil end
      -- OBJ colour 0 is transparent on the hardware; on this white page it is
      -- white (the palette's own entry 0 drew a tinted square behind the sprite)
      local copy = { { 255, 255, 255 } }
      for i = 2, #colors do copy[i] = colors[i] end
      return copy
    end
    local function walkerPath(c)
      if not c.walk then return nil end
      local path, colour = shipped(c, "walk")
      if path then return path, colour end
      return registeredSprite(c.walk)
    end
    local function drawWalker(c, x, y)
      local path, colour = walkerPath(c)
      local img = path and image(path)
      if not img then return false end
      local quad = love.graphics.newQuad(0, 0, 16, 16, img:getDimensions())
      love.graphics.setColor(1, 1, 1, 1)
      paletted(not colour and objColors(c.pal) or nil, colour, function()
        love.graphics.draw(img, quad, x, y)
      end)
      love.graphics.setColor(0, 0, 0, 1)
      return true
    end
    local function drawPortrait(c, x, y)
      local path, colors, colour
      if c.battleBy == CRYSTAL and c.battleClass then
        -- the battle intro's own lookup (BattleState.trainerArt) and colours
        local hud = data.gen2MenuGfx and data.gen2MenuGfx.battleHud
        path = hud and hud.trainerPics and hud.trainerPics[c.battleClass]
        if Palettes and Palettes.trainerColors then
          colors = Palettes.trainerColors(data.gen2Palettes, c.battleClass)
        end
        colour = false
      elseif c.front then
        path, colour = shipped(c, "front")
        -- TODO/CONFIRM: a four-grey custom portrait has no class palette of
        -- its own; it takes its character's overworld colours here.
        colors = not colour and objColors(c.pal) or nil
      end
      local img = path and image(path)
      if not img then return false end
      love.graphics.setColor(1, 1, 1, 1)
      paletted(colors, colour, function() love.graphics.draw(img, x, y) end)
      love.graphics.setColor(0, 0, 0, 1)
      return true
    end

    -- One artist's rows: each work (a character when the generator recorded
    -- one), then what was commissioned from them, then any required credit
    -- line, verbatim. Only works and commissions can be opened.
    local function rowsFor(entry)
      local rows = {}
      local by = entry.charactersBy or {}
      local function add(work)
        local c = by[work]
        rows[#rows + 1] = { text = c and c.name or work, work = work, character = c }
      end
      -- Several embedded copies each add their slice, so sort what is shown
      -- by the name on the row.
      local function sorted(list)
        local copy = {}
        for i, w in ipairs(list) do copy[i] = w end
        table.sort(copy, function(a, b)
          local an = (by[a] and by[a].name or a):lower()
          local bn = (by[b] and by[b].name or b):lower()
          if an == bn then return a < b end
          return an < bn
        end)
        return copy
      end
      -- "via <pack>: a, b, c" (art that came through a pack) is a heading and
      -- one row per item, so no credited word is cut off at the row's edge
      local plain, packs = {}, {}
      for _, work in ipairs(entry.works) do
        local pack, items = work:match("^(via [^:]+):%s*(.+)$")
        if pack then packs[#packs + 1] = { pack = pack, items = items } else plain[#plain + 1] = work end
      end
      for _, work in ipairs(sorted(plain)) do add(work) end
      for _, p in ipairs(packs) do
        for _, line in ipairs(wrap(p.pack .. ":", 144)) do rows[#rows + 1] = { text = line, heading = true } end
        for item in p.items:gmatch("[^,]+") do add((item:gsub("^%s+", ""):gsub("%s+$", ""))) end
      end
      if #entry.commissions > 0 then
        rows[#rows + 1] = { text = "COMMISSIONED/", heading = true }
        for _, work in ipairs(sorted(entry.commissions)) do add(work) end
      end
      for _, row in ipairs(rows) do
        if row.character and row.character.walk then rows.walkers = true end
      end
      if entry.note then
        for _, line in ipairs(wrap(entry.note, 144)) do rows[#rows + 1] = { text = line, heading = true } end
      end
      return rows
    end
    local pages = {}
    for i, entry in ipairs(entries) do
      pages[i] = { entry = entry, rows = rowsFor(entry), cursor = 1, top = 1 }
      local first = 1
      while pages[i].rows[first] and pages[i].rows[first].heading do first = first + 1 end
      pages[i].cursor = pages[i].rows[first] and first or 1
    end
    local VISIBLE, ROW_TOP, ROW_STEP = 6, 40, 16
    local NAME_X = 32 -- the name column on a page with walkers (16x16 at x 8)
    local USED_VISIBLE = 8
    local state = { isOpaque = true, artist = 1, detail = nil, usedTop = 0 }

    local function selectable(row) return row and not row.heading end
    local function move(page, delta)
      local i = page.cursor + delta
      while page.rows[i] and not selectable(page.rows[i]) do i = i + delta end
      if not selectable(page.rows[i]) then return end
      page.cursor = i
      if page.cursor < page.top then page.top = page.cursor end
      if page.cursor >= page.top + VISIBLE then page.top = page.cursor - VISIBLE + 1 end
      -- keep a heading above the first row in view when scrolling back up
      while page.top > 1 and page.rows[page.top - 1].heading and page.cursor - (page.top - 1) < VISIBLE do
        page.top = page.top - 1
      end
    end
    local function detailFor(page)
      local row = page.rows[page.cursor]
      if not selectable(row) then return nil end
      local c = row.character
      local used = {}
      if c and #c.used > 0 then union(used, c.used)
      elseif #page.entry.used > 0 then union(used, page.entry.used)
      else
        for _, m in ipairs(page.entry.mods) do used[#used + 1] = m:upper() end
      end
      return { row = row, character = c, artist = page.entry.artist, used = used }
    end

    function state:update(_dt)
      local input = game.input
      if self.detail then
        local rows = math.ceil(#self.detail.used / 2)
        if input:wasPressed("b") then self.detail, self.usedTop = nil, 0
        elseif input:wasPressed("up") then self.usedTop = math.max(0, self.usedTop - 1)
        elseif input:wasPressed("down") then
          self.usedTop = math.min(math.max(0, rows - self.detail.usedRows), self.usedTop + 1)
        end
        return
      end
      local page = pages[self.artist]
      if input:wasPressed("b") then game.stack:pop()
      elseif not page then return
      elseif input:wasPressed("left") and #pages > 1 then self.artist = (self.artist - 2) % #pages + 1
      elseif input:wasPressed("right") and #pages > 1 then self.artist = self.artist % #pages + 1
      elseif input:wasPressed("up") then move(page, -1)
      elseif input:wasPressed("down") then move(page, 1)
      elseif input:wasPressed("a") then
        self.detail, self.usedTop = detailFor(page), 0
      end
    end

    local function rule(y)
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.rectangle("fill", 0, y, 160, 1)
    end
    local function rightText(text, y)
      Font.draw(text, 160 - 8 - Font.width(text), y)
    end
    local function big(text, x, y)
      love.graphics.push()
      love.graphics.translate(x, y)
      love.graphics.scale(2, 2)
      Font.draw(text, 0, 0)
      love.graphics.pop()
    end
    local function drawArtist()
      local page = pages[state.artist]
      Font.draw("ARTIST", 8, 4)
      if not page then return end
      rightText(tostring(state.artist) .. "/" .. #pages, 4)
      -- The name as written (attribution stays exact); 2x when it fits,
      -- else the ordinary size on the same line.
      local name = display(page.entry.artist)
      if Font.width(name) * 2 <= 144 then big(name, 8, 14)
      else
        local lines = wrap(name, 144)
        for i = 1, math.min(2, #lines) do Font.draw(lines[i], 8, 14 + (i - 1) * 8 + (#lines == 1 and 4 or 0)) end
      end
      rule(34)
      for i = 1, VISIBLE do
        local index = page.top + i - 1
        local row = page.rows[index]
        if row then
          local y = ROW_TOP + (i - 1) * ROW_STEP
          if row.heading then
            Font.draw(fit(row.text, 144), 8, y)
          else
            if index == page.cursor then Font.drawCode(mod.ui.Theme.cursor, 0, y) end
            local textX = page.rows.walkers and NAME_X or 8
            if row.character and row.character.walk then drawWalker(row.character, 8, y - 4) end
            Font.draw(fit(row.text, math.min(144, 160 - textX)), textX, y)
          end
        end
      end
      if page.top + VISIBLE <= #page.rows then
        Font.drawCode(mod.ui.Theme.moreArrow or 0xEE, 152, ROW_TOP + (VISIBLE - 1) * ROW_STEP + 8)
      end
    end
    local function drawDetail()
      local d = state.detail
      local c = d.character
      local name = (c and c.name or d.row.work):upper()
      local hasPortrait = c and drawPortrait(c, 4, 4)
      local x = hasPortrait and 64 or 8
      local width = 160 - 8 - x
      -- a work with no character record is shown in full (up to five lines)
      local nameLines = wrap(c and name or d.row.work, width)
      local y = 8
      for i = 1, math.min(c and 2 or 5, #nameLines) do Font.draw(nameLines[i], x, y); y = y + 8 end
      y = y + 8
      local lineX = x
      if c and c.walk and drawWalker(c, x, y) then lineX = x + 20 end
      local lineW = 160 - 8 - lineX
      local function credit(label, who)
        Font.draw(label, lineX, y); y = y + 8
        for _, line in ipairs(wrap(who, lineW)) do
          if y > 56 then break end
          Font.draw(line, lineX, y); y = y + 8
        end
        y = y + 8
      end
      if c and (c.walkBy or c.battleBy) then
        if c.walkBy then credit("WALK/", c.walkBy) end
        if c.battleBy then credit("BATTLE/", c.battleBy) end
      else
        credit("ART/", d.artist)
      end
      rule(64); rule(66)
      y = 72
      -- The exact credit text when it is not the name: a stand-in sheet is
      -- credited as the sheet the artist drew ("Lass (RBY) (as Suzie)").
      if c and d.row.work:upper() ~= name then
        for _, line in ipairs(wrap(d.row.work, 144)) do Font.draw(line, 8, y); y = y + 8 end
        y = y + 8
      end
      Font.draw("USED IN/", 8, y); y = y + 16
      local rows = math.max(1, math.floor((144 - y) / 16) + ((144 - y) % 16 >= 8 and 1 or 0))
      d.usedRows = math.min(rows, USED_VISIBLE / 2)
      for r = 1, d.usedRows do
        for col = 1, 2 do
          local m = d.used[(state.usedTop + r - 1) * 2 + col]
          if m then Font.draw(fit(m, 72), col == 1 and 8 or 88, y + (r - 1) * 16) end
        end
      end
      if (state.usedTop + d.usedRows) * 2 < #d.used then
        Font.drawCode(mod.ui.Theme.moreArrow or 0xEE, 152, y + (d.usedRows - 1) * 16)
      end
    end
    function state:draw()
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 0, 0, 160, 144)
      love.graphics.setColor(0, 0, 0, 1)
      if self.detail then drawDetail() else drawArtist() end
      love.graphics.setColor(1, 1, 1, 1)
    end
    game.stack:push(state)
    return state
  end
  -- Each row owns one flat shared list. Remember only our contribution's
  -- object identities, so re-running a hook or runtime registration replaces
  -- our entries without removing another embedded copy's entries.
  syncRow = function(row)
    local shared = row.creditsEntries
    local previous = contributions[row] or {}
    for i = #shared, 1, -1 do
      if previous[shared[i]] then table.remove(shared, i) end
    end
    local owned = {}
    local function append(entries)
      for _, entry in ipairs(copyEntries(entries)) do
        shared[#shared + 1], owned[entry] = entry, true
      end
    end
    append(baked)
    for _, id in ipairs(registrationOrder) do append(registered[id]) end
    contributions[row] = owned
  end

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local rows = next(game, items)
    if type(rows) ~= "table" then return rows end
    local row
    for _, candidate in ipairs(rows) do
      if candidate.id == ROW_ID then row = candidate; break end
    end
    if not row then
      row = { id = ROW_ID, label = "CREDITS",
        desc = { "Artists and", "their work" }, creditsEntries = {} }
      rows[#rows + 1] = row
    end
    if not row.creditsLib or row.creditsLib < LIB_VERSION then
      row.creditsLib = LIB_VERSION
      row.onSelect = function()
        local top = game.stack:top()
        if top and top.items and top.onClose then top:close() end
        -- Read the shared list at selection, after every hook has appended.
        if not game.stack:top() then open(game, row.creditsEntries) end
      end
    end
    syncRow(row)
    return rows
  end)
  -- Optional return used by Credits Book to preserve its runtime API.
  -- Ordinary embedding callers only need attach(mod, theirEntries).
  return registerCredits
end

return Credits
