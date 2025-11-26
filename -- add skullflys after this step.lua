local setting = tostring(ModSettingGet("skullflys.cusom_entity"))
local target_entity = ModDoesFileExist(setting) and setting or "data/entities/animals/crypt/skullfly.xml"
function AddSkullflys(x, y)
    -- add skullflys after this step
    math.randomseed(x, y + StatsGetValue("world_seed"))
    for i = 1, math.random(1,3), 1 do
        EntityLoadCameraBound(target_entity, x, y-i+5)
    end
end