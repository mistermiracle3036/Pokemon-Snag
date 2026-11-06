-- Check-row word probe. Extracts the REAL ListMenu shim from main.lua and
-- runs it against a stub Trainer Journey that records the rows it is given.
-- REQUESTS 512 regression test: a row's `action` reaches Journey (contract
-- check-row-word), and every Snag menu row whose label is over 8 letters
-- carries one, so Journey never cuts it to its first word.
-- usage, from the repo root: luajit tests/check_row_word_probe.lua [main.lua]
local mainPath = arg[1] or "main.lua"
local f = assert(io.open(mainPath, "rb")); local src = f:read("*a"); f:close()

local function section(first, last)
  local a = assert(src:find(first, 1, true), first)
  local b = assert(src:find(last, a + #first, true), last)
  return src:sub(a, b - 1)
end

local fails = 0
local function check(label, got, want)
  if got ~= want then
    fails = fails + 1
    print(("FAIL %s: got %s, want %s"):format(label, tostring(got), tostring(want)))
  else
    print("ok   " .. label)
  end
end

-- 1. The shim hands action through.
local shim = section("    local function tjChoiceApi()",
  "    -- The YES/NO confirmations, the same way")
local seen
local api = { dialogue_ui_version = 3,
  makeCheckMenu = function(_, opts) seen = opts.rows; return {} end }
local env = setmetatable({
  mod = { find = function() return { exports = { trainer_journey = api } } end },
  RawListMenu = { new = function() return "raw" end },
}, { __index = _G })
local fn = assert(loadstring(shim .. "\nreturn ListMenu")); setfenv(fn, env)
local ListMenu = fn()
ListMenu.new({}, "T", { { action = "TOOL", label = "THE TOOL?", value = "tool",
  reply = "What is this tool?" } }, {})
check("action reaches Journey", seen and seen[1] and seen[1].action, "TOOL")
check("label still reaches Journey", seen and seen[1] and seen[1].label, "THE TOOL?")

-- 2. Every literal menu row with a long label has a word of 8 letters or fewer.
local long, rows = 0, 0
for line in src:gmatch("[^\n]+") do
  local label = line:match('{ *[^}]-label = "([^"]+)", value = ')
  if label and line:find("reply = ", 1, true) then
    rows = rows + 1
    local action = line:match('action = "([^"]+)"')
    if #label > 8 then
      long = long + 1
      check("'" .. label .. "' has a word", action ~= nil, true)
    end
    if action then check("'" .. action .. "' fits 8", #action <= 8, true) end
  end
end
check("menu rows found", rows >= 20, true)
check("long labels found", long >= 9, true)

if fails > 0 then print(fails .. " FAILED"); os.exit(1) end
print("ALL PASS")
