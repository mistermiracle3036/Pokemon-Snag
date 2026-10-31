-- Embeddable credits screen. Copy this file unchanged into each mod.
-- Increment on every library change, including drawing/layout changes.
-- v3 (2026-10-12): sections (PEOPLE / POKEMON / OTHER, LEFT/RIGHT) list one
-- name per row; A opens that artist's page (made, commissioned, in). Entry
-- fields `sections` and `commissions` are additive: v2 copies ignore them.
local LIB_VERSION = 3
local SECTIONS = {
  { id = "people", label = "PEOPLE" },
  { id = "pokemon", label = "POKEMON" },
  { id = "other", label = "OTHER" },
}
local ROW_ID = "credits:book"
local Credits = {}

function Credits.attach(mod, initialEntries)
  local Font = mod.ui.Font
  local registered, registrationOrder = {}, {}
  local contributions = setmetatable({}, { __mode = "k" })
  local syncRow
  local VISIBLE, TOP, STEP = 10, 24, 10

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
  local function copyEntry(entry)
    if type(entry) ~= "table" or not optionalString(entry.artist)
      or not entry.artist:find("%S") then return nil end
    local result = { artist = entry.artist, works = {}, mods = {}, commissions = {},
      sections = {}, source = optionalString(entry.source), note = optionalString(entry.note) }
    union(result.works, entry.works)
    union(result.mods, entry.mods)
    union(result.commissions, entry.commissions)
    union(result.sections, entry.sections)
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
    local entries, byArtist = {}, {}
    local function add(list)
      for _, entry in ipairs(list) do
        local existing = byArtist[entry.artist]
        if existing then
          union(existing.works, entry.works)
          union(existing.mods, entry.mods)
          union(existing.commissions, entry.commissions)
          union(existing.sections, entry.sections)
          existing.source = existing.source or entry.source
          existing.note = existing.note or entry.note
        else
          local copy = copyEntry(entry)
          entries[#entries + 1], byArtist[copy.artist] = copy, copy
        end
      end
    end
    add(copyEntries(rawEntries))
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
  local function prefix(text)
    local spans = Font.split(text)
    local count = math.min(18, Font.spansFitting(spans, 144))
    return count > 0 and spans[count].to or 0
  end
  local function wrap(rows, text, artistIndex)
    text = display(text):match("^%s*(.-)%s*$")
    while #text > 0 do
      local cut = prefix(text)
      -- A custom glyph wider than the whole panel cannot supply a line.
      if cut == 0 then break end
      if cut < #text then
        local space = text:sub(1, cut + 1):match("^.*() ")
        if space and space > 1 then cut = space - 1 end
      end
      rows[#rows + 1] = { text = text:sub(1, cut), artist = artistIndex }
      text = text:sub(cut + 1):gsub("^%s+", "")
    end
  end
  -- One artist's page: their name, what they made, what was commissioned
  -- from them, which installed mods ship it, and any required credit line.
  local function buildPage(entry)
    local rows = {}
    local function block(label, values)
      if #values == 0 then return end
      if #rows > 0 then rows[#rows + 1] = { blank = true } end
      if label then rows[#rows + 1] = { text = label } end
      wrap(rows, table.concat(values, ", "))
    end
    wrap(rows, entry.artist)
    block("MADE:", entry.works)
    block("COMMISSIONED:", entry.commissions)
    block("IN:", entry.mods)
    if entry.note then block(nil, { entry.note }) end
    return rows
  end
  -- Entries by section, in SECTIONS order; empty sections are not shown. An
  -- entry with no (or no known) section is PEOPLE, so v2-era data still lists.
  local function tabsFor(entries)
    local tabs = {}
    for _, section in ipairs(SECTIONS) do
      local list = {}
      for _, entry in ipairs(entries) do
        local known, wanted = false, false
        for _, id in ipairs(entry.sections) do
          for _, s in ipairs(SECTIONS) do if s.id == id then known = true end end
          if id == section.id then wanted = true end
        end
        if wanted or (not known and section.id == "people") then list[#list + 1] = entry end
      end
      if #list > 0 then
        tabs[#tabs + 1] = { label = section.label, entries = list, cursor = 1, top = 1 }
      end
    end
    return tabs
  end
  local function fit(text)
    text = display(text)
    return text:sub(1, prefix(text))
  end
  local function open(game, rawEntries)
    local entries = mergedEntries(rawEntries)
    local tabs = tabsFor(entries)
    local state = { isOpaque = true, tab = 1, page = nil, offset = 0 }
    function state:update(_dt)
      local input = game.input
      if self.page then
        if input:wasPressed("b") then self.page, self.offset = nil, 0
        elseif input:wasPressed("up") then self.offset = math.max(0, self.offset - 1)
        elseif input:wasPressed("down") then
          self.offset = math.min(math.max(0, #self.page - VISIBLE), self.offset + 1)
        end
        return
      end
      local tab = tabs[self.tab]
      if input:wasPressed("b") then game.stack:pop()
      elseif not tab then return
      elseif input:wasPressed("left") and #tabs > 1 then
        self.tab = (self.tab - 2) % #tabs + 1
      elseif input:wasPressed("right") and #tabs > 1 then
        self.tab = self.tab % #tabs + 1
      elseif input:wasPressed("up") then
        tab.cursor = math.max(1, tab.cursor - 1)
        if tab.cursor < tab.top then tab.top = tab.cursor end
      elseif input:wasPressed("down") then
        tab.cursor = math.min(#tab.entries, tab.cursor + 1)
        if tab.cursor >= tab.top + VISIBLE then tab.top = tab.cursor - VISIBLE + 1 end
      elseif input:wasPressed("a") then
        self.page, self.offset = buildPage(tab.entries[tab.cursor]), 0
      end
    end
    -- Trainer Journey's rule/rightText/header idiom, using public surfaces:
    -- ModUI exposes Font and Theme, but does not expose Gen 2 Chrome.
    local function rule(y)
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.rectangle("fill", 4, y, 152, 1)
    end
    local function rightText(text, y)
      Font.draw(text, 156 - Font.width(text), y)
    end
    -- the arrows are charmap codes, not text: ← $DF, → $EB (charmap.asm)
    local LEFT_ARROW, RIGHT_ARROW = 0xDF, 0xEB
    local function drawPage(rows)
      Font.draw("CREDITS", 4, 4)
      local pages = math.max(1, math.ceil(#rows / VISIBLE))
      rightText(tostring(math.floor(state.offset / VISIBLE) + 1) .. "/" .. pages, 4)
      rule(17)
      for i = 1, VISIBLE do
        local row = rows[state.offset + i]
        if row and row.text then Font.draw(row.text, 4, TOP + (i - 1) * STEP) end
      end
      rule(127)
      Font.draw("B:BACK", 4, 136)
    end
    local function drawIndex()
      local tab = tabs[state.tab]
      if not tab then
        Font.draw("CREDITS", 4, 4)
        rule(17); rule(127)
        Font.draw("B:CLOSE", 4, 136)
        return
      end
      if #tabs > 1 then
        Font.drawCode(LEFT_ARROW, 4, 4)
        Font.draw(tab.label, 12, 4)
        Font.drawCode(RIGHT_ARROW, 12 + Font.width(tab.label), 4)
        rightText(tostring(state.tab) .. "/" .. #tabs, 4)
      else
        Font.draw(tab.label, 4, 4)
      end
      rule(17)
      for i = 1, VISIBLE do
        local entry = tab.entries[tab.top + i - 1]
        if entry then
          local y = TOP + (i - 1) * STEP
          Font.draw(fit(entry.artist), 12, y)
          if tab.top + i - 1 == tab.cursor then Font.drawCode(mod.ui.Theme.cursor, 4, y) end
        end
      end
      rule(127)
      Font.draw("A:OPEN", 4, 136)
      rightText(tostring(tab.cursor) .. "/" .. #tab.entries, 136)
    end
    function state:draw()
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 0, 0, 160, 144)
      love.graphics.setColor(0, 0, 0, 1)
      if self.page then drawPage(self.page) else drawIndex() end
      love.graphics.setColor(1, 1, 1, 1)
    end
    game.stack:push(state)
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
