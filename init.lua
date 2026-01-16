---@type nxml
local nxml = dofile_once("mods/-- add skullflys after this step/luanxml/nxml.lua")
ModSettingSet("skullflys.add_at_every_step", true)


ModTextFileSetContent("data/translations/common.csv",
	(ModTextFileGetContent("data/translations/common.csv") .. "\n" ..
	ModTextFileGetContent("mods/-- add skullflys after this step/-- add translations after this step.csv") .. "\n")
		:gsub("\r", "")
		:gsub("\n\n+", "\n"
	)
)

ModLuaFileAppend("data/scripts/perks/perk_list.lua", "mods/-- add skullflys after this step/-- add files after this step/-- add perks after this step.lua")


local entity = tostring(ModSettingGet("skullflys.entity"))
if not ModDoesFileExist(entity) then
	entity = "data/entities/animals/crypt/skullfly.xml"
end

for xml in nxml.edit_file(entity) do --add tag for radar perk
	xml.attr.tags = xml.attr.tags and xml.attr.tags .. ",skullfly" or "skullfly"
end

print(entity)

ModTextFileSetContent("mods/-- add skullflys after this step/-- add files after this step/-- add skullflys after this step.lua",
	ModTextFileGetContent("mods/-- add skullflys after this step/-- add files after this step/-- add skullflys after this step.lua")
		:gsub("ENTITY", tostring(entity)
	)
)



local biome_scripts = {}
for biome_data in nxml.parse_file("data/biome/_biomes_all.xml"):each_child() do
	if biome_data.attr.biome_filename == nil then goto continue end
	for topology in nxml.parse_file(biome_data.attr.biome_filename):each_of("Topology") do
		if topology.attr.lua_script then biome_scripts[topology.attr.lua_script] = true end
	end
	::continue::
end

local add_skullflys_at_every_step = ModSettingGet("skullflys.add_at_every_step")
local prepend_skullflys_at_every_step =
[[RegisteredFunctions = {}
local Old_RegSpawnFunc = RegisterSpawnFunction
RegisterSpawnFunction = function(x, y)
	RegisteredFunctions[x] = y
	Old_RegSpawnFunc(x, y)
end
--RSF DOCUMENTED

]]

for filepath, _ in pairs(biome_scripts) do
	local script = ModTextFileGetContent(filepath)

	if add_skullflys_at_every_step then
		if not script:find("%-%- RSF DOCUMENTED") then script = prepend_skullflys_at_every_step .. script end
		ModLuaFileAppend(filepath, "mods/-- add skullflys after this step/-- add files after this step/-- append skullflys after every step.lua")
	else
		if not (script:find("%-%- add skullflys after this step")) then goto continue end

		script = script:gsub("%-%- add skullflys after this step[%s\n]*{", "-- add skullflys after this step\n{ skullflys = true,")
		script = script:gsub("%-%- add skullflys after this step[%s\n]*}", "-- add skullflys after this step\nskullflys = true}")
	end

	ModTextFileSetContent(filepath, script)
	::continue::
end



local function escape(str)
	return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
end

local dir_helpers_path = "data/scripts/director_helpers.lua"
local dir_helpers = ModTextFileGetContent(dir_helpers_path)

local gsub_targets = {
	"function spawn(what, x, y, rand_x, rand_y)",
	"function spawn2(what, x, y, rand_x, rand_y)",
	"function random_from_table( what, x, y )",
}

local gsub_targets_append = add_skullflys_at_every_step and "\n	AddSkullflys(x, y)" or "\n	if what.skullflys then AddSkullflys(x, y) end"
for key, target in pairs(gsub_targets) do
	dir_helpers = dir_helpers:gsub(escape(target), target .. gsub_targets_append)
end

dir_helpers = dir_helpers:gsub(escape("for i,v in ipairs(what) do"), "for i,v in ipairs(what) do\n	if v.skullflys or add_skullflys_at_every_step then AddSkullflys(x, y) end")

local prepend =
[[dofile_once("mods/-- add skullflys after this step/-- add files after this step/-- add skullflys after this step.lua")
]]
ModTextFileSetContent(dir_helpers_path, prepend .. dir_helpers)

--print(ModTextFileGetContent("data/scripts/biomes/coalmine.lua"))
print("-----------------------------------------------------------")
--print(ModTextFileGetContent(dir_helpers_path))