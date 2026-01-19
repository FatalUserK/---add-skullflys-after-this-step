dofile_once("data/scripts/lib/mod_settings.lua")

--- note for anyone viewing this file:
---mod assets are not loaded on the main menu, which means we can't split our work into more than one file or use custom libs or sprites
---just wanted to justify why this file is (as of last updating this comment) 1453 lines

local mod_id = "parallel_parity"
mod_settings_version = 1

local function get_setting_id(name)
	return mod_id .. "." .. name
end

local mods_are_loaded = #ModGetActiveModIDs() > 0

local languages = { --translation keys
	["English"] = "en",
	["русский"] = "ru",
	["Português (Brasil)"] = "ptbr",
	["Español"] = "eses",
	["Deutsch"] = "de",
	["Français"] = "frfr",
	["Italiano"] = "it",
	["Polska"] = "pl",
	["简体中文"] = "zhcn",
	["日本語"] = "jp",
	["한국어"] = "ko",
}
local langs_in_order = { --do this cuz key-indexed tables wont keep this order
	"en",
	"ru",
	"ptbr",
	"eses",
	"de",
	"frfr",
	"it",
	"pl",
	"zhcn",
	"jp",
	"ko",
}

local current_language = languages[GameTextGetTranslatedOrNot("$current_language")]


--To add translations, add them below the same way English (en) languages have been added.
--Translation Keys can be seen in the `languages` table above
local translation_strings = {
	add_at_every_step = {
		en = "-- add skullflys after every step",
	},
	entity = {
		en = "-- add custom entity after this step",
		en_desc = "sorry, the text box is kinda shoddily made, might fix at some point idk",
		invalid_entity_menu = {
			en_desc = "INVALID ENTITY\nIn the main menu we can only check against vanilla data, modded entities cannot be detected unless you are in a run.",
		},
		invalid_entity_game = {
			en_desc = "INVALID ENTITY",
		},
	},
	start_with_radar = {
		en = "-- start with skullfly radar after this step",
	},
}

--TRANSLATOR NOTE! you dont have to worry about `translation_credit_data`, i can handle this myself
-- just please provide the colour value you would like your name to be as well as the translation for "[your translation] by [you]"
local translation_credit_data = {}

local offset_amount = 15
local keyboard_state = 0
local focused_element = ""
local TimeLocal = {}

local function update_time()
	TimeLocal.year,TimeLocal.month,TimeLocal.day,TimeLocal.hour,TimeLocal.minute,TimeLocal.second,TimeLocal.jussi,TimeLocal.mammi = GameGetDateAndTimeLocal()
end
update_time()

--#region TEXT INPUT NONSENSE:
local keycodes = {
	backspace = 42,
	mouse_left = 1,
	enter = 88,
	return_key = 40,
	left = 80,
	right = 79,
	delete = 76,
	shift_l = 225,
	shift_r = 229,
	ctrl_l = 224,
	ctrl_r = 228,
	a = 4,
	v = 25,
	x = 27,
}

local keycodes_lookup = {
	[4] = "a",
	[5] = "b",
	[6] = "c",
	[7] = "d",
	[8] = "e",
	[9] = "f",
	[10] = "g",
	[11] = "h",
	[12] = "i",
	[13] = "j",
	[14] = "k",
	[15] = "l",
	[16] = "m",
	[17] = "n",
	[18] = "o",
	[19] = "p",
	[20] = "q",
	[21] = "r",
	[22] = "s",
	[23] = "t",
	[24] = "u",
	[25] = "v",
	[26] = "w",
	[27] = "x",
	[28] = "y",
	[29] = "z",
	[30] = "1",
	[31] = "2",
	[32] = "3",
	[33] = "4",
	[34] = "5",
	[35] = "6",
	[36] = "7",
	[37] = "8",
	[38] = "9",
	[39] = "0",
	[42] = "", --backspace
	[44] = " ",
	[45] = "-",
	[46] = "=",
	[54] = ",",
	[55] = ".",
	[56] = "/",
}

local uppercase_lookup = {
	["a"] = "A",
	["b"] = "B",
	["c"] = "C",
	["d"] = "D",
	["e"] = "E",
	["f"] = "F",
	["g"] = "G",
	["h"] = "H",
	["i"] = "I",
	["j"] = "J",
	["k"] = "K",
	["l"] = "L",
	["m"] = "M",
	["n"] = "N",
	["o"] = "O",
	["p"] = "P",
	["q"] = "Q",
	["r"] = "R",
	["s"] = "S",
	["t"] = "T",
	["u"] = "U",
	["v"] = "V",
	["w"] = "W",
	["x"] = "X",
	["y"] = "Y",
	["z"] = "Z",
	["1"] = "!",
	["2"] = "\"",
	["3"] = "£",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["/"] = "?",
	[","] = "<",
	["."] = ">",
	["-"] = "_",
	["="] = "+",
}
--#endregion

--translations are separated for translators' convenience
local settings = {
	{
		id = "add_at_every_step",
		value_default = false,
		value_recommended = false,
	},
	{
		id = "entity",
		type = "text_input",
		value_default = "data/entities/animals/crypt/skullfly.xml",
		auto_ajust_size = true,
		validator = function(self) return ModDoesFileExist(self.current_text) end,
		invalid_msg = {
			id = mods_are_loaded and "invalid_entity_game" or "invalid_entity_menu"
		},
		c = {
			r = .75,
			g = .75,
			b = .75,
		},
	}, --need to make text thingy
	{
		id = "start_with_radar",
		value_default = false,
		value_recommended = true,
	},
	{
		id = "translation_credit",
		type = "tl_credit",
	} and nil, --this can exist when someone actually is crazy enough to translate this mod lmao
}



-- some of this code is p nasty, flee all ye of weak heart

function ModSettingsGuiCount()
	return 1
end

local screen_w,screen_h
local tlcr_data_ordered = {}
function ModSettingsUpdate(init_scope, is_init)
	current_language = languages[GameTextGetTranslatedOrNot("$current_language")]
	update_time()

	local dummy_gui = not is_init and GuiCreate()
	local description_start_pos
	local arbitrary_description_buffer = 11
	if dummy_gui then
		GuiStartFrame(dummy_gui)
		screen_w,screen_h = GuiGetScreenDimensions(dummy_gui)

		--[[ source for magic number -160 below
		local inner_gui_width = 342
		local category_offset = 3
		local mod_setting_offset = 3
		local mod_setting_desc_offset = 5
		local start_pos_offset = (inner_gui_width * -.5) + category_offset + mod_setting_offset + mod_setting_desc_offset
		--]]

		description_start_pos = (screen_w * .5) - 160
	end


	if dummy_gui and (#translation_credit_data > 0) then
		tlcr_data_ordered = {}
		local max_len = 0
		for _, lang in ipairs(langs_in_order) do
			if translation_credit_data[lang] then
				tlcr_data_ordered[#tlcr_data_ordered+1] = translation_credit_data[lang]
				tlcr_data_ordered[#tlcr_data_ordered].highlighted = lang == current_language
				tlcr_data_ordered[#tlcr_data_ordered].translator.offset = GuiGetTextDimensions(dummy_gui, tlcr_data_ordered[#tlcr_data_ordered].text) + 4
				local curr_x = GuiGetTextDimensions(dummy_gui, tlcr_data_ordered[#tlcr_data_ordered].text .. tlcr_data_ordered[#tlcr_data_ordered].translator[1]) + 4
				if curr_x > max_len then max_len = curr_x end
			end
		end
		tlcr_data_ordered.size = {max_len, 13 * #tlcr_data_ordered}
	end



	local function update_translations_and_path(input_settings, input_translations, path, recursion)
		recursion = recursion or 0
		path = path or ""
		input_settings = input_settings or settings
		input_translations = input_translations or translation_strings
		for _, setting in pairs(input_settings) do
			setting.path = mod_id .. "." .. path .. setting.id
			setting.type = setting.type or type(setting.value_default)
			setting.text_offset_x = setting.text_offset_x or 0

			for k, v in pairs(setting) do
				if type(v) == "table" and v[1] and v[1].id then
					update_translations_and_path(v, input_translations[setting.id], path .. (not setting.not_path and (setting.id .. ".") or ""), recursion + 1)
				end
			end


			if not dummy_gui then goto continue end

			if input_translations[setting.id] then
				setting.name = input_translations[setting.id][current_language] or input_translations[setting.id].en or setting.id
				if input_translations[setting.id].en_desc and not input_translations[setting.id][current_language] then --if there is english translation but no other translation
					setting.description = input_translations[setting.id].en_desc .. string.format("\n(Missing %s translation)", GameTextGetTranslatedOrNot("$current_language"))
				else
					setting.description = input_translations[setting.id][current_language .. "_desc"]
				end
			else
				setting.name = setting.id
			end

			if setting.description then
				setting._description_lines = {}
				local line_length_max = screen_w - description_start_pos - arbitrary_description_buffer - (recursion * offset_amount)
				local max_line_length = 0
				for line in string.gmatch(setting.description, '([^\n]+)') do
					local line_w = GuiGetTextDimensions(dummy_gui, setting.description or "")
					if line_w > line_length_max then
						local split_lines = {}
						local current_line = ""
						for word in line:gmatch("%S+") do
							local test_line = (current_line == "") and word or current_line .. " " .. word
							local test_line_w = GuiGetTextDimensions(dummy_gui, test_line)
							if test_line_w > line_length_max then
								split_lines[#split_lines + 1] = current_line
								current_line = word
							else
								if test_line_w > max_line_length then max_line_length = test_line_w end
								current_line = test_line
							end
						end
						-- Add the last line if it's not empty
						if current_line ~= "" then split_lines[#split_lines + 1] = current_line end

						local a = #setting._description_lines
						for i, split_line in ipairs(split_lines) do
							setting._description_lines[a+i] = split_line
						end
					else
						if line_w > max_line_length then max_line_length = line_w end
						setting._description_lines[#setting._description_lines+1] = line
					end

					setting.desc_w = max_line_length
					setting.desc_h = (#setting._description_lines * 13) - 1
				end
			end

			setting.w,setting.h = GuiGetTextDimensions(dummy_gui, setting.name or "")
			if setting.icon then setting.icon_w,setting.icon_h = GuiGetImageDimensions(dummy_gui, setting.icon) end

			::continue::
		end
	end
	update_translations_and_path(settings)

	local function set_defaults(setting)
		if setting.type == "group" then
			for i, item in ipairs(setting.items) do
				set_defaults(item)
			end
		else
			if setting.value_default ~= nil and ModSettingGet(setting.path) == nil then
				ModSettingSet(setting.path, setting.value_default)
			end
			if setting.dependents then
				set_defaults(setting.dependents)
				for i, item in ipairs(setting.dependents) do
					set_defaults(item)
				end
			end
		end
	end
	local function save_setting(setting)
		if setting.items == "group" then
			for i, item in ipairs(setting.items) do
				save_setting(item)
			end
		elseif setting.id ~= nil and setting.scope ~= nil and setting.scope >= init_scope then
			local next_value = ModSettingGetNextValue(setting.path)
			if next_value ~= nil then
				ModSettingSet(setting.path, next_value)
			end
			if setting.dependents then
				for i, item in ipairs(setting.dependents) do
					save_setting(item)
				end
			end
		end
	end
	for i, setting in ipairs(settings) do
		set_defaults(setting)
		save_setting(setting)
	end

	ModSettingSet(get_setting_id("_version"), mod_settings_version)
	if dummy_gui then GuiDestroy(dummy_gui) end
end


----Rendering:
local mouse_is_valid

local max_id = 0
local function create_id()
	max_id = max_id + 1
	return max_id
end


local function reset_settings_to_default(group, target, default_value)
	target = target or "value_default"
	for _, setting in ipairs(group) do
		local target_value = setting[target]
		if target_value == nil and type(default_value) == type(setting.value_default) then
			target_value = default_value
		end
		if target_value ~= nil then
			ModSettingSet(setting.path, target_value) else --print(setting.path .. " DOES NOT HAVE A DEFAULT FOR " .. target)
		end

		if setting.items then
			reset_settings_to_default(setting.items, target, default_value)
		end
		if setting.dependents then
			reset_settings_to_default(setting.dependents, target, default_value)
		end
	end
end

---Draws a tooltip at desired position
---@param gui gui
---@param setting table pass entire setting rather than raw text to take advantage of prebaked description string size
---@param x number
---@param y number
---@param sprite string? custom 9piece sprite
local function DrawTooltip(gui, setting, x, y, sprite)
	local text_size = {setting.desc_w, setting.desc_h}
	sprite = sprite or "data/ui_gfx/decorations/9piece0_gray.png"
	GuiLayoutBeginLayer(gui)
	GuiZSetForNextWidget(gui, -200)
	GuiImageNinePiece(gui, create_id(), x, y, text_size[1]+10, text_size[2]+2, 1, sprite)
	for i,line in ipairs(setting._description_lines) do
		GuiZSetForNextWidget(gui, -210)
		GuiText(gui, x + 5, y + 1 + (i-1)*13, line)
	end --GuiText doesnt work by itself ig, newlines put next on the same line for some reason? idk.
	GuiLayoutEndLayer(gui)
end

---Create boolean setting
---@param gui gui
---@param x_offset number indentation as a result of child settings
---@param setting table setting data
---@param c number[] colour data
local function BoolSetting(gui, x_offset, setting, c)
	c = c or {
		r = 1,
		g = 1,
		b = 1,
	}
	local is_disabled
	if setting.requires and not ModSettingGet(setting.requires.id) == setting.requires.value then
		is_disabled = true
	end

	local value = ModSettingGet(setting.path)

	GuiText(gui, x_offset, 0, "")
	local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
	GuiImageNinePiece(gui, create_id(), x, y, 19+setting.w, setting.h, 0)
	local guiPrev = {GuiGetPreviousWidgetInfo(gui)}

	local clicked, rclicked, highlighted
	if guiPrev[3] and mouse_is_valid then
		highlighted = true
		if setting.hover_func then setting.hover_func() end
		if InputIsMouseButtonJustDown(1) then clicked = true end
		if InputIsMouseButtonJustDown(2) then rclicked = true end
		if (clicked or rclicked) and is_disabled then
			GamePlaySound("ui", "ui/button_denied", 0, 0)
			clicked = false
			rclicked = false
		end
		c = {
			r = 1,
			g = 1,
			b = .7,
		}
	end

	if is_disabled then --dim if disabled
		c = {
			r = c.r * .5,
			g = c.g * .5,
			b = c.b * .5,
		}
	end


	GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
	GuiColorSetForNextWidget(gui, c.r, c.g, c.b, 1)
	GuiText(gui, x_offset + 19, 0, setting.name)

	if highlighted and setting.description then DrawTooltip(gui, setting, x, y+12) end
	GuiColorSetForNextWidget(gui, c.r, c.g, c.b, 1)

	local toggle_icon = ""
	if is_disabled then toggle_icon = "(X)"
	else toggle_icon = value == true and "(*)" or "(  )" end
	GuiText(gui, x_offset, 0, toggle_icon)

	if clicked then
		GamePlaySound("ui", "ui/button_click", 0, 0)
		ModSettingSet(setting.path, not value)
	end
	if rclicked then
		GamePlaySound("ui", "ui/button_click", 0, 0)
		if keyboard_state == 1 then
			ModSettingSet(setting.path, setting.value_recommended)
		elseif keyboard_state == 2 then
			ModSettingSet(setting.path, false)
		elseif keyboard_state == 3 then
			ModSettingSet(setting.path, true)
		else --if 0
			ModSettingSet(setting.path, setting.value_default)
		end
	end
end

local cursor_pos = 0
local function TextBox(gui, setting, x_offset, y_offset, c)
	local box_w = setting.text_box_width
	local box_h = setting.text_box_height
	local currently_selected = focused_element == setting.path
	local box_sprite = currently_selected and setting.text_box_selected_sprite or setting.text_box_unselected_sprite
	local text = setting.current_text
	local text_w,text_h = GuiGetTextDimensions(gui, text)
	box_w = math.max(text_w + 8, box_w)
	local text_c = setting.text_c or {r=1,g=1,b=1}
	if not currently_selected then
		text_c = setting.text_unselected_c or {
			r = math.min((text_c.r + .2)*.5, 1),
			g = math.min((text_c.g + .2)*.5, 1),
			b = math.min((text_c.b + .2)*.5, 1),
		}
	end

	GuiText(gui, x_offset, 0, "")
	local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
	local box_x = x + x_offset
	local box_y = y + y_offset
	GuiImageNinePiece(gui, create_id(), box_x, box_y, box_w-4, box_h-4, 1, box_sprite)
	local guiPrev = {GuiGetPreviousWidgetInfo(gui)}

	local hovered,clicked,rclicked
	if guiPrev[3] and mouse_is_valid then
		hovered = true
		clicked = InputIsMouseButtonJustDown(1)
		rclicked = InputIsMouseButtonJustDown(2)
		GuiImageNinePiece(gui, create_id(), box_x-1, box_y-1, box_w-2, box_h-2, 1, "data/ui_gfx/1px_white.png")
	end

	if clicked then
		focused_element = setting.path
		GamePlaySound("ui", "ui/button_select", 0, 0)
	end

	if rclicked then
		setting.current_text = setting.value_default
		text = setting.current_text
		GamePlaySound("ui", "ui/button_select", 0, 0)
	end

	GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
	GuiColorSetForNextWidget(gui, text_c.r, text_c.g, text_c.b, 1)
	GuiText(gui, x_offset+1, y_offset, text)

	if setting.validator and not setting:validator() then
		local err_x = x_offset + box_w + 1
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
		GuiImage(gui, create_id(), err_x, 1, "data/ui_gfx/mods_newer.png", 1, 1)
		local _,_,err_hovered = GuiGetPreviousWidgetInfo(gui)
		if err_hovered and setting.invalid_msg then
			local msg = mods_are_loaded and "invalid_entity_game" or "invalid_entity_menu"
			--DrawTooltip(gui, setting.invalid_msg)
		end
	end

	if currently_selected then
		if TimeLocal.second % 2 == 0 then
			GuiZSetForNextWidget(gui, -40)
			GuiColorSetForNextWidget(gui, 2, 2,2,4)
			GuiImageNinePiece(gui, create_id(), box_x + 2 + text_w, box_y + 2, 1, box_h-8, 1, "data/ui_gfx/1px_white.png")
		end

		local str = ""
		local key_pressed
		for id, symbol in pairs(keycodes_lookup) do
			if InputIsKeyJustDown(id) then
				str = str .. symbol
				key_pressed = true
			end
		end
		if key_pressed then
			if keyboard_state == 1 then
				str = str:upper()
				local new_str = ""
				for char in str:gmatch(".") do
					new_str = new_str .. (uppercase_lookup[char] or char)
				end
				str = new_str
			end

			text = text .. str

			if InputIsKeyJustDown(42) then
				text = text:sub(1, -2)
			end

			setting.current_text = text
			ModSettingSet(setting.path, text)
		end
	end

	GuiText(gui, 0, 0, " ", box_h/12)
end

local function draw_translation_credits(gui, x, y)
	GuiLayoutBeginLayer(gui)
	GuiZSetForNextWidget(gui, -200)
	GuiImageNinePiece(gui, create_id(), x, y, tlcr_data_ordered.size[1]+10, tlcr_data_ordered.size[2]+2, 1, "data/ui_gfx/decorations/9piece0_gray.png")
	for i,tl in ipairs(tlcr_data_ordered) do
		if tl.highlighted then
			GuiColorSetForNextWidget(gui, 236/255, 236/255, 67/255, 1)
		end

		local pos_x,pos_y = x + 5, y + 2 + (i-1)*13
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
		GuiZSetForNextWidget(gui, -210)
		GuiText(gui, pos_x, pos_y , tl.text)
		local c = tl.translator
		GuiColorSetForNextWidget(gui, c.r, c.g, c.b, 1)
		GuiZSetForNextWidget(gui, -210)
		GuiText(gui, pos_x + tl.translator.offset, pos_y, tl.translator[1])
	end --GuiText doesnt work by itself ig, newlines put next on the same line for some reason? idk.
	GuiLayoutEndLayer(gui)
end

function ModSettingsGui(gui, in_main_menu)
	GuiLayoutBeginLayer(gui)
	local x_orig,y_orig = (screen_w*.5) - 171.5, 49+.5
	GuiZSetForNextWidget(gui, 1000)
	GuiImageNinePiece(gui, create_id(), x_orig, y_orig, 340-1, 251-1, 0, "") --"data/temp/edge_c2_0.png", for debugging
	mouse_is_valid = ({GuiGetPreviousWidgetInfo(gui)})[3]
	--GuiZSetForNextWidget(gui, 1000)
	--GuiImageNinePiece(gui, create_id(), x_orig, y_orig, 1, 1, 1, "data/temp/edge_c2_1.png") --"data/temp/edge_c2_0.png", for debugging
	GuiLayoutEndLayer(gui)

	update_time()

	keyboard_state = 0
	if InputIsKeyDown(225) or InputIsKeyDown(229) then
		keyboard_state = 1
	end
	if InputIsKeyDown(224) or InputIsKeyDown(228) then
		keyboard_state = keyboard_state + 2
	end

	if InputIsMouseButtonJustDown(1) then
		focused_element = ""
	end


	local function RenderModSettingsGui(gui, in_main_menu, _settings, offset, parent_is_disabled, recursion)
		recursion = recursion or 0
		offset = offset or 0
		_settings = _settings or settings

		for _, setting in ipairs(_settings) do

			local render_setting
			if type(setting.render_condition) == "function" then
				render_setting = setting.render_condition() --stupid fuckin bullshit, needing me to use functions, lua should just update conditions in real-time :(
			else
				render_setting = setting.render_condition ~= false
			end
			if render_setting then
				local setting_is_disabled = parent_is_disabled or (setting.requires and not ModSettingGet(setting.requires.id) == setting.requires.value)
				if setting.type == "group" then
					local c = setting.c and {
						r = setting.c.r,
						g = setting.c.g,
						b = setting.c.b,
					} or {
						r = .4,
						g = .4,
						b = .75,
					}

					local collapse_icon
					if setting.collapsed then
						collapse_icon = "data/ui_gfx/button_fold_open.png"
					else
						collapse_icon = "data/ui_gfx/button_fold_close.png"
					end
					if setting_is_disabled then
						c.r = c.r * .5
						c.g = c.g * .5
						c.b = c.b * .5
					end

					GuiText(gui, offset, 0, "")
					local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)

					--GuiOptionsAddForNextWidget(gui, GUI_OPTION.ForceFocusable)
					GuiImageNinePiece(gui, create_id(), x, y, setting.w, setting.h, 0)
					if ({GuiGetPreviousWidgetInfo(gui)})[3] and mouse_is_valid then --check if element was clicked
						c.r = math.min((c.r * 1.2)+.05, 1)
						c.g = math.min((c.g * 1.2)+.05, 1)
						c.b = math.min((c.b * 1.2)+.05, 1)
						if InputIsMouseButtonJustDown(1) then
							GamePlaySound("ui", "ui/button_click", 0, 0)
							setting.collapsed = not setting.collapsed
						end
					end

					GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
					GuiColorSetForNextWidget(gui, c.r, c.g, c.b, 1)
					GuiImage(gui, create_id(), offset, 0, collapse_icon, 1, 1, 1)


					GuiColorSetForNextWidget(gui, c.r, c.g, c.b, 1)
					GuiText(gui, offset+10, 0, setting.name)
					if setting.description then
						GuiTooltip(gui, setting.description, "")
					end

					--i think recursion just works here
					if setting.collapsed ~= true then RenderModSettingsGui(gui, in_main_menu, setting.items, offset + offset_amount, setting_is_disabled, recursion) end
				elseif setting.type == "boolean" then
					BoolSetting(gui, offset, setting, {
						r = .7^recursion,
						g = .7^recursion,
						b = .7^recursion,
					})

				elseif setting.type == "note" then
					local c = setting.c and {
						r = setting.c.r,
						g = setting.c.g,
						b = setting.c.b,
					} or {
						r = .7,
						g = .7,
						b = .7,
					}

					GuiText(gui, offset, 0, "")
					local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)

					--GuiOptionsAddForNextWidget(gui, GUI_OPTION.ForceFocusable)
					GuiImageNinePiece(gui, create_id(), x, y, setting.w+(setting.icon_w or 0)+(setting.text_offset_x or 0), setting.h, 0)
					local guiPrev = {GuiGetPreviousWidgetInfo(gui)}

					if guiPrev[3] and mouse_is_valid and setting.description then
						c.r = math.min((c.r * 1.2)+.05, 1)
						c.g = math.min((c.g * 1.2)+.05, 1)
						c.b = math.min((c.b * 1.2)+.05, 1)
						DrawTooltip(gui, setting, x, y+12)
					end

					if setting.icon then
						GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
						GuiImage(gui, create_id(), (setting.icon_offset_x or 0) + offset, setting.icon_offset_y or 0, setting.icon, 1, 1, 1)
					end
					GuiColorSetForNextWidget(gui, c.r, c.g, c.b, 1)
					GuiText(gui, (setting.icon_w or 0) + setting.text_offset_x + offset, 0, setting.name)
				elseif setting.type == "text_input" then
					local c = setting.c and {
						r = setting.c.r,
						g = setting.c.g,
						b = setting.c.b,
					} or {
						r = .7,
						g = .7,
						b = .7,
					}

					GuiText(gui, offset, 0, "")
					local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)

					--GuiOptionsAddForNextWidget(gui, GUI_OPTION.ForceFocusable)
					GuiImageNinePiece(gui, create_id(), x, y, setting.w+(setting.icon_w or 0)+(setting.text_offset_x or 0), setting.h, 0)
					local guiPrev = {GuiGetPreviousWidgetInfo(gui)}

					if guiPrev[3] and mouse_is_valid and setting.description then
						c.r = math.min((c.r * 1.2)+.05, 1)
						c.g = math.min((c.g * 1.2)+.05, 1)
						c.b = math.min((c.b * 1.2)+.05, 1)
						DrawTooltip(gui, setting, x, y+12)
					end
					GuiColorSetForNextWidget(gui, c.r, c.g, c.b, 1)
					GuiText(gui, (setting.icon_w or 0) + setting.text_offset_x + offset, 0, setting.name)

					TextBox(gui, setting, offset, 1)
				elseif setting.type == "reset_button" then
					GuiText(gui, 0, 0, "")
					local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
					GuiImageNinePiece(gui, create_id(), x, y, setting.w, setting.h, 0)
					local guiPrev = {GuiGetPreviousWidgetInfo(gui)}


					local c = setting.c or {
						r = 1,
						g = 1,
						b = 1,
					}
					if guiPrev[3] and mouse_is_valid then
						c = setting.highlight_c or {
							r = math.min((c.r * 1.2)+.05, 1),
							g = math.min((c.g * 1.2)+.05, 1),
							b = math.min((c.b * 1.2)+.05, 1),
						}
						DrawTooltip(gui, setting, x, y+12)
						if InputIsMouseButtonJustUp(1) then
							if setting.click_func then
								setting.click_func()
							end
							GamePlaySound("ui", "ui/button_click", 0, 0)
							reset_settings_to_default(settings, setting.reset_target, setting.reset_target_default)
						end
					end

					--GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
					GuiColorSetForNextWidget(gui, c.r, c.g, c.b, 1)
					GuiText(gui, (setting.icon_w or 0) + setting.text_offset_x, 0, setting.name)

				elseif setting.type == "tl_credit" then
					GuiText(gui, 0, 0, "")
					local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
					GuiImageNinePiece(gui, create_id(), x, y, setting.w, setting.h, 0)
					local guiPrev = {GuiGetPreviousWidgetInfo(gui)}

					local c = {
						r = 0.21,
						g = 0.5,
						b = 0.21,
					}
					if guiPrev[3] and mouse_is_valid then
						c.r = math.min((c.r * 1.2)+.05, 1)
						c.g = math.min((c.g * 1.2)+.05, 1)
						c.b = math.min((c.b * 1.2)+.05, 1)
						draw_translation_credits(gui, x, y+12)
					end

					--GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
					GuiColorSetForNextWidget(gui, c.r, c.g, c.b, 1)
					GuiText(gui, (setting.icon_w or 0) + setting.text_offset_x, 0, setting.name)
				end

				if setting.dependents then
					RenderModSettingsGui(gui, in_main_menu, setting.dependents, offset + offset_amount, setting_is_disabled, recursion + 1)
				end
			end
		end
	end

	RenderModSettingsGui(gui, in_main_menu)
end


--this is just here to stop vsc from pestering me about undefined globals

MOD_SETTING_SCOPE_NEW_GAME = MOD_SETTING_SCOPE_NEW_GAME --`0` - setting change (that is the value that's visible when calling ModSettingGet()) is applied after a new run is started
MOD_SETTING_SCOPE_RUNTIME_RESTART = MOD_SETTING_SCOPE_RUNTIME_RESTART --`1` - setting change is applied on next game exe restart
MOD_SETTING_SCOPE_RUNTIME = MOD_SETTING_SCOPE_RUNTIME --`2` - setting change is applied immediately
MOD_SETTING_SCOPE_ONLY_SET_DEFAULT = MOD_SETTING_SCOPE_ONLY_SET_DEFAULT --`3` - this tells us that no changes should be applied. shouldn't be used in mod setting definition.
GUI_OPTION = GUI_OPTION