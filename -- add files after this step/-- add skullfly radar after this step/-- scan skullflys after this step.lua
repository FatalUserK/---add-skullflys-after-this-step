local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform( entity_id )
pos_y = pos_y - 4 -- offset to middle of character

local range = 600
local indicator_distance = 35

local function is_in_camera_bounds(x, y, padding)
	local left, up, w, h = GameGetCameraBounds()
	return x >= left - padding and y >= up - padding and x <= left + w + padding and y <= up + h + padding
end

-- ping nearby enemies
for _,enemy_id in ipairs(EntityGetInRadiusWithTag(pos_x, pos_y, range, "skullfly")) do
	local enemy_x, enemy_y = EntityGetFirstHitboxCenter(enemy_id)
    if not (enemy_x and enemy_y) then
        enemy_x,enemy_y = EntityGetTransform(enemy_id)
    end
	local dir_x = enemy_x - pos_x
	local dir_y = enemy_y - pos_y
	local distance = math.sqrt(dir_x ^ 2 + dir_y ^ 2)

	local indicator_x = 0
	local indicator_y = 0

	if is_in_camera_bounds(enemy_x, enemy_y, -4) then
		indicator_x = enemy_x
		indicator_y = enemy_y - 3
	else
		-- position radar indicators around character
	    if distance ~= 0 then
	        dir_x = dir_x / distance
	        dir_y = dir_y / distance
        end
		indicator_x = pos_x + dir_x * indicator_distance
		indicator_y = pos_y + dir_y * indicator_distance
	end

	-- display sprite based on proximity
	if distance > range * 0.8 then
		GameCreateSpriteForXFrames("mods/-- add skullflys after this step/-- add files after this step/-- add skullfly radar after this step/-- add.png", indicator_x, indicator_y, true, 0, 0, 1, true)
	elseif distance > range * 0.5 then
		GameCreateSpriteForXFrames("mods/-- add skullflys after this step/-- add files after this step/-- add skullfly radar after this step/skullflys after.png", indicator_x, indicator_y, true, 0, 0, 1, true)
	else
		GameCreateSpriteForXFrames("mods/-- add skullflys after this step/-- add files after this step/-- add skullfly radar after this step/this step.png", indicator_x, indicator_y, true, 0, 0, 1, true)
	end
end
