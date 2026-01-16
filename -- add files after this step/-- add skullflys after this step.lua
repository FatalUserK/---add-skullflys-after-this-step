function AddSkullflys(x, y)
	-- add skullflys after this step
	math.randomseed(x, y + StatsGetValue("world_seed"))
	for i = 1, math.random(1,3), 1 do
		EntityLoadCameraBound("ENTITY", x, y-i+5)
	end
end