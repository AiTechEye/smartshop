local pos_to_string = minetest.pos_to_string
local table_insert = table.insert

local api = smartshop.api
local util = smartshop.util

local escape_texture = util.escape_texture
local is_near_player = util.is_near_player

local has_node_entity_queue = smartshop.has.node_entity_queue

local debug = false
local debug_cache = {}

local entities_by_pos = {}

function api.record_entity(pos, obj)
	local spos = pos_to_string(pos)
	local entities_at_pos = entities_by_pos[spos] or {}
	table_insert(entities_at_pos, obj)
	entities_by_pos[spos] = entities_at_pos
end

function api.clear_entities(pos)
	local spos = pos_to_string(pos)
	local entities_at_pos = entities_by_pos[spos] or {}
	for i = 1, #entities_at_pos do
		local obj = entities_at_pos[i]
		obj:remove()
	end
	entities_by_pos[spos] = nil
end

local function get_image_from_tile(tile)
	if type(tile) == "string" then
		return tile
	elseif type(tile) == "table" then
		local image_name
		if type(tile.image) == "string" then
			image_name = tile.image
		elseif type(tile.name) == "string" then
			image_name = tile.name
		end
		if image_name then
			local animation = tile.animation
			if (
				animation and
				animation.type == "vertical_frames" and
				animation.aspect_w and
				animation.aspect_h
			) then
				return ("smartshop_animation_mask.png^[resize:%ix%i^[mask:%s"):format(
					animation.aspect_w,
					animation.aspect_h,
					image_name
				)
			elseif (
				animation and
				animation.type == "sheet_2d" and
				animation.frames_w and
				animation.frames_h
			) then
				return ("%s^[sheet:%ix%i:0,0"):format(
					image_name,
					animation.frames_w,
					animation.frames_h
				)
			else
				return image_name
			end
		end
	end
	return "unknown_node.png"
end

local function get_image_cube(tiles)
	if #tiles == 6 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1]),
			get_image_from_tile(tiles[6]),
			get_image_from_tile(tiles[3])
		)
	elseif #tiles == 4 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1]),
			get_image_from_tile(tiles[4]),
			get_image_from_tile(tiles[3])
		)
	elseif #tiles == 3 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1]),
			get_image_from_tile(tiles[3]),
			get_image_from_tile(tiles[3])
		)
	elseif #tiles >= 1 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1]),
			get_image_from_tile(tiles[1]),
			get_image_from_tile(tiles[1])
		)
	end
	return "unknown_node.png"
end

local function is_normal_node(def)
	local drawtype = def.drawtype
	return (def.type == "node" and (
		drawtype == "normal" or
		drawtype == "allfaces" or
		drawtype == "allfaces_optional" or
		drawtype == "glasslike" or
		drawtype == "glasslike_framed" or
		drawtype == "glasslike_framed_optional" or
		drawtype == "liquid"
	))
end

local get_image_memo = {}

function api.get_image(item)
	local cached = get_image_memo[item]
	if cached then
		return cached
	end

	if not item or item == "" then
		get_image_memo[item] = "blank.png"
		return "blank.png"
	end

	local def = minetest.registered_items[item]
	if not def then
		get_image_memo[item] = "unknown_node.png"
		return "unknown_node.png"
	end

	local image
	local tiles = def.tiles or def.tile_images
	local inventory_image = def.inventory_image

	if inventory_image and inventory_image ~= "" then
		if type(inventory_image) == "string" then
			image = inventory_image

		elseif type(inventory_image) == "table" and #inventory_image == 1 and type(inventory_image[1]) == "string" then
			image = inventory_image[1]

		else
			smartshop.log("warning", "could not decode inventory image for %s", item)
			image = "unknown_node.png"
		end

	elseif tiles then
		if type(tiles) == "string" then
			image = tiles

		elseif type(tiles) == "table" then
			if is_normal_node(def) then
				image = get_image_cube(tiles)
			else
				image = get_image_from_tile(tiles[1])
			end
		end
	end

	if (debug or not image or image == "" or image == "unknown_node.png") and not debug_cache[item] then
		smartshop.log("warning", "definition for %s", item)
		for key, value in pairs(def) do
			smartshop.log("warning", "    %q = %q", key, dump(value))
		end
		debug_cache[item] = true
	end

	local image = image or "unknown_node.png"
	get_image_memo[item] = image
	return image
end

function api.get_quad_image(items)
	local images = {}
	for i = 1, 4 do
		local image = api.get_image(items[i])
		if image == "unknown_node.png" then
			image = "blank.png"
		end
		table_insert(images, escape_texture(image .. "^[resize:32x32"))
	end
	return ("[combine:68x68:1,1=%s:1,36=%s:36,1=%s:36,36=%s"):format(unpack(images))
end

function api.is_complicated_drawtype(drawtype)
	return (
		drawtype == "fencelike" or
		drawtype == "raillike" or
		drawtype == "nodebox" or
		drawtype == "mesh"
	)
end

function api.get_image_type(shop, index)
	if not shop:can_exchange(index) then
		return "none"
	end

	local item_name = shop:get_give_stack(index):get_name()

	local def = minetest.registered_items[item_name]
	if not def or item_name == "" then
		return "none"
	elseif def.inventory_image and def.inventory_image ~= "" then
		return "sprite"
	elseif api.is_complicated_drawtype(def.drawtype) then
		return "wielditem"
	else
		return "sprite"
	end
end

local function check_update_entities(shop, expected_types)
	local pos = shop.pos
	local spos = pos_to_string(pos)
	local ents = entities_by_pos[spos] or {}

	if #ents ~= #expected_types then
		return false
	end

	if #ents == 0 then
		return true
	end

	local get_image = api.get_image

	for i = 1, #ents do
		local obj = ents[i]
		local entity = obj:get_luaentity()
		if not entity then
			return false
		end
		local expected_type = expected_types[i]
		local type = expected_type[1]
		local index_arg = expected_type[2]
		if type == "single_upright_sprite" then
			if entity.name ~= "smartshop:single_upright_sprite" then
				return false
			end
			local expected_item = shop:get_give_stack(index_arg):get_name()
			if entity.item ~= expected_item then
				local texture = get_image(expected_item)
				obj:set_properties({textures = {texture}})
				entity.item = expected_item
			end

		elseif type == "quad_upright_sprite" then
			if entity.name ~= "smartshop:quad_upright_sprite" then
				return false
			end

			local items = entity.items
			local expected_items = {}
			local all_expected = true

			for index = 1, 4 do
				local expected_item
				if shop:can_exchange(index) then
					expected_item = shop:get_give_stack(index):get_name()
				else
					expected_item = ""
				end
				all_expected = all_expected and items[i] == expected_item
				table_insert(expected_items, expected_item)
			end

			if not all_expected then
				local texture = api.get_quad_image(expected_items)
				obj:set_properties({textures = {texture}})
				entity.items = expected_items
			end

		elseif type == "single_sprite" then
			if entity.name ~= "smartshop:single_sprite" then
				return false
			end
			if entity.index ~= index_arg then
				return false
			end
			local expected_item = shop:get_give_stack(index_arg):get_name()
			if entity.item ~= expected_item then
				local texture = get_image(expected_item)
				obj:set_properties({textures = {texture}})
				entity.item = expected_item
			end

		elseif type == "single_wielditem" then
			if entity.name ~= "smartshop:single_wielditem" then
				return false
			end
			if entity.index ~= index_arg then
				return false
			end
			local expected_item = shop:get_give_stack(index_arg):get_name()
			if entity.item ~= expected_item then
				obj:set_properties({wield_item = expected_item})
				entity.item = expected_item
			end
		end
	end

	return true
end

function api.update_entities(shop)
	local pos = shop.pos
	if not is_near_player(pos) then
		shop:clear_entities()
		return
	end

	local get_image_type = api.get_image_type

	local seen = {}
	local empty_count = 0
	local sprite_count = 0
	local entity_types = {}
	local last_sprite_index

	for index = 1, 4 do
		local item = shop:get_give_stack(index):get_name()
		local image_type = get_image_type(shop, index)
		table_insert(entity_types, image_type)

		if seen[item] or image_type == "none" then
			empty_count = empty_count + 1

		elseif image_type == "sprite" then
			sprite_count = sprite_count + 1
			last_sprite_index = index
		end

		seen[item] = true
	end

	local entities_to_add = {}

	if empty_count == 3 and sprite_count == 1 then
		table_insert(entities_to_add, {"single_upright_sprite", last_sprite_index})

	elseif (sprite_count + empty_count) == 4 then
		table_insert(entities_to_add, {"quad_upright_sprite"})

	else
		for index, image_type in pairs(entity_types) do
			if image_type == "sprite" then
				table_insert(entities_to_add, {"single_sprite", index})

			elseif image_type == "wielditem" then
				table_insert(entities_to_add, {"single_wielditem", index})
			end
		end
	end

	if check_update_entities(shop, entities_to_add) then
		return
	end

	shop:clear_entities()

	if #entities_to_add == 0 then
		return
	end

	local entities = smartshop.entities
	local record_entity = api.record_entity

	if has_node_entity_queue then
		local queue = node_entity_queue.queue

		for i = 1, #entities_to_add do
			local entity_to_add = entities_to_add[i]
			local type = entity_to_add[1]
			local index = entity_to_add[2]

			queue:push_back(function()
				local obj
				if type == "single_upright_sprite" then
					obj = entities.add_single_upright_sprite(shop, index)

				elseif type == "quad_upright_sprite" then
					obj = entities.add_quad_upright_sprite(shop)

				elseif type == "single_sprite" then
					obj = entities.add_single_sprite(shop, index)

				elseif type == "single_wielditem" then
					obj = entities.add_single_wielditem(shop, index)
				end

				if obj then
					record_entity(pos, obj)
				end
			end)
		end
	else
		for i = 1, #entities_to_add do
			local entity_to_add = entities_to_add[i]
			local type = entity_to_add[1]
			local index = entity_to_add[2]

			local obj
			if type == "single_upright_sprite" then
				obj = entities.add_single_upright_sprite(shop, index)

			elseif type == "quad_upright_sprite" then
				obj = entities.add_quad_upright_sprite(shop)

			elseif type == "single_sprite" then
				obj = entities.add_single_sprite(shop, index)

			elseif type == "single_wielditem" then
				obj = entities.add_single_wielditem(shop, index)
			end

			if obj then
				record_entity(pos, obj)
			end
		end
	end
end


function api.entity_activator(pos, node, active_object_count, active_object_count_wider)
	local spos = minetest.pos_to_string(pos, 0)
	error([[
		check if we're deactivated, and reactivate
	]])
end

minetest.register_abm({
	label = "Shop Entity Initializer",
	nodenames = {"group:smartshop"},
	interval = 1,
	chance = 1,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if util.is_near_player(pos) then
			api.entity_activator(pos, node, active_object_count, active_object_count_wider)
		end
	end,
})
