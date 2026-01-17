table.insert(perk_list, {
	id = "SCAN_SKULLFLYS_AFTER_THIS_STEP",
	ui_name = "$add_skullfly_radar_name_after_this_step",
	ui_description = "$add_skullfly_radar_desc_after_this_step",
	ui_icon = "mods/-- add skullflys after this step/-- add files after this step/-- add skullfly radar after this step/-- add icon for this perk.png",
	perk_icon = "mods/-- add skullflys after this step/-- add files after this step/-- add skullfly radar after this step/-- add sprite for this perk.png",
	stackable = false,
	func = function(perk, taker, perk_name, times_taken)
		EntityAddComponent2(taker, "LuaComponent", {
			_tags = "perk_component",
			script_source_file = "mods/-- add skullflys after this step/-- add files after this step/-- add skullfly radar after this step/-- scan skullflys after this step.lua",
		} )
	end,
})