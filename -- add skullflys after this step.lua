function AddSkullflys(x, y)
    print("-- add skullflys after this step")
    -- add skullflys after this step
    math.randomseed(x, y + StatsGetValue("world_seed"))
    for i = 1, math.random(1,3), 1 do
        EntityLoadCameraBound("data/entities/animals/crypt/skullfly.xml", x, y-i)
    end
end