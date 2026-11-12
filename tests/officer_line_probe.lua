-- The officer in ELM's LAB mentions SNAG BALLs (0.17.24). Runs the REAL F.officerLine from main.lua
-- against the game's own text table, when a cache is given, and against a small copy otherwise.
-- usage, from the repo root: luajit tests/officer_line_probe.lua [path/to/data/generated/text.lua]
local f = assert(io.open("main.lua", "rb")); local src = f:read("*a"); f:close()
local a = assert(src:find('    F.OFFICER_ADD = "Thefts', 1, true), "block start")
local b = assert(src:find("    -- game.ready, and again on entering the lab", a, true), "block end")
local F = assert(loadstring("local F = {}\n" .. src:sub(a, b - 1) .. "\nreturn F\n"))()

local fails = 0
local function check(label, got, want)
  if got ~= want then fails = fails + 1; print("FAIL " .. label .. "\n   got  " .. tostring(got) .. "\n   want " .. tostring(want)) end
end

local VANILLA = "I heard a POK\195\169MON\nwas stolen here\226\128\166\fI was just getting\nsome information\vfrom PROF.ELM.\f"
  .. "Apparently, it was\na young male with\vlong, red hair\226\128\166\fWhat?\fYou battled a\ntrainer like that?\f"
  .. "Did you happen to\nget his name?{DONE}"
local text = { ["1e:60f0"] = VANILLA, other = "I heard about a\ncraftsman who\fmakes custom BALLS" }
if arg[1] then
  text = assert(loadfile(arg[1]))()
  check("the cache's officer text is the one this probe knows", text["1e:60f0"], VANILLA)
end
local before = text["1e:60f0"]
check("found and changed", F.officerLine(text), true)
local after = text["1e:60f0"]
check("first page kept, two pages added, the rest kept",
  after, "I heard a POK\195\169MON\nwas stolen here\226\128\166\fThefts are way up\nall over JOHTO.\fIt started with\nthose SNAG BALLs.\f"
    .. before:sub(#"I heard a POK\195\169MON\nwas stolen here\226\128\166\f" + 1))
check("second call changes nothing", F.officerLine(text) and text["1e:60f0"], after)
local changed = 0
for k, v in pairs(text) do if type(v) == "string" and v:find("SNAG BALLs", 1, true) then changed = changed + 1 end end
check("exactly one text mentions SNAG BALLs", changed, 1)
for page in F.OFFICER_ADD:gmatch("([^\f]+)\f") do
  local rows = 0
  for row in (page .. "\n"):gmatch("(.-)\n") do
    rows = rows + 1
    check("row fits 18: " .. row, #row <= 18, true)
  end
  check("two rows: " .. page, rows, 2)
end
check("no officer text: reports false", F.officerLine({ x = "hello" }), false)
check("no table: reports false", F.officerLine(nil), false)
print(fails == 0 and "ALL PASS" or "FAILED")
os.exit(fails == 0 and 0 or 1)
