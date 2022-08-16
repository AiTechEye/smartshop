local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

smartshop = {
	version = os.time({year = 2022, month = 8, day = 16}),
	fork = "fluxionary",

	modname = modname,
	modpath = modpath,

	S = S,

	log = function(level, messagefmt, ...)
		return minetest.log(level, ("[%s] %s"):format(modname, messagefmt:format(...)))
	end,

	--[[
		convenience for player/name checking and i18n
	]]
	chat_send_player = function(player, message, ...)
		local player_name
		if type(player) == "userdata" then
			player_name = player:get_player_name()
		else
			player_name = player
		end
		minetest.chat_send_player(player_name, ("[%s] %s"):format(modname, S(message, ...)))
	end,
	chat_send_all = function(message, ...)
		minetest.chat_send_all(("[%s] %s"):format(modname, S(message, ...)))
	end,

	has = {
		currency = minetest.get_modpath("currency"),
		default = minetest.get_modpath("default"),
		mesecons = minetest.get_modpath("mesecons"),
		mesecons_mvps = minetest.get_modpath("mesecons_mvps"),
		node_entity_queue = minetest.get_modpath("node_entity_queue"),
		petz = minetest.get_modpath("petz"),
		pipeworks = minetest.get_modpath("pipeworks"),
		tubelib = minetest.get_modpath("tubelib"),
	},

	dofile = function(...)
		dofile(table.concat({modpath, ...}, DIR_DELIM) .. ".lua")
	end,
}

smartshop.dofile("settings")
smartshop.dofile("resources")
smartshop.dofile("util")
smartshop.dofile("fake_inventory")
smartshop.dofile("api", "init")
smartshop.dofile("nodes", "init")
smartshop.dofile("entities", "init")
smartshop.dofile("compat", "init")

smartshop.dofile("crafting")
smartshop.dofile("aliases")

if smartshop.settings.enable_tests then
	smartshop.dofile("tests", "init")
end

--------------------------------
smartshop.dofile = nil  -- no need to export this, not sure whether it's dangerous
