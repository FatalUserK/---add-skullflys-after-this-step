local nxml = dofile_once("mods/-- add skullflys after this step/luanxml/nxml.lua")

local biome_scripts = {}
for biome_data in nxml.parse_file("data/biome/_biomes_all.xml"):each_child() do
    if biome_data.attr.biome_filename == nil then goto continue end
    for topology in nxml.parse_file(biome_data.attr.biome_filename):each_of("Topology") do
        if topology.attr.lua_script then biome_scripts[topology.attr.lua_script] = true end
    end
    ::continue::
end



for filepath, _ in pairs(biome_scripts) do
    local script = ModTextFileGetContent(filepath)
    if not script:find("%-%- add skullflys after this step") then goto continue end

    script = script:gsub("%-%- add skullflys after this step[%s\n]*{", "-- add skullflys after this step\n{ skullflys = true,")
    script = script:gsub("%-%- add skullflys after this step[%s\n]*}", "-- add skullflys after this step\nskullflys = true}")

    --if string.find(filepath, "hills") then print(script) end

    ModTextFileSetContent(filepath, script)
    ::continue::
end



local function escape(str)
	return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
end

local dir_helpers_path = "data/scripts/director_helpers.lua"
local dir_helpers = ModTextFileGetContent(dir_helpers_path)

local gsub_targets = {
    "function spawn(what, x, y, rand_x, rand_y)\n",
    "function spawn2(what, x, y, rand_x, rand_y)\n",
    "function random_from_table( what, x, y )\n",
}

for key, target in pairs(gsub_targets) do
    dir_helpers = dir_helpers:gsub(escape(target), target .. "\n    if what.skullflys true then print('aaaaaaaaaaaaaaaaaaaaaaaaaaa') AddSkullflys(x, y) end\n")
end
dir_helpers:gsub(escape("for i,v in ipairs(what) do\n"), "for i,v in ipairs(what) do\n    if v.skullflys then AddSkullflys(x, y) end\n")

ModTextFileSetContent(dir_helpers_path, dir_helpers)

--print(ModTextFileGetContent("data/scripts/biomes/coalmine.lua"))
print("-----------------------------------------------------------")
print(ModTextFileGetContent(dir_helpers_path))