local api = smartshop.api

local table_insert = table.insert

local get_objects_in_area = minetest.get_objects_in_area

local escape_texture = smartshop.util.escape_texture
local memoize1 = smartshop.util.memoize1

local v_add = vector.add
local v_sub = vector.subtract

local debug = false
local debug_cache = {}

-- i wanted to cache these, but see
-- https://github.com/minetest/minetest/blob/8bf1609cccba24e2516ecb98dbf694b91fe697bf/doc/lua_api.txt#L6824-L6829
function api.get_entities(pos)
	local objects = {}

	for _, obj in ipairs(get_objects_in_area(v_sub(pos, 0.5), v_add(pos, 0.5))) do
		local ent = obj:get_luaentity()
		if ent and ent.name:sub(1, 10) == "smartshop:" then
			if not ent.pos then
				obj:remove()

			elseif vector.equals(ent.pos, pos) then
				table.insert(objects, obj)
			end
		end
	end

	return objects
end

function api.clear_entities(pos)
	for _, obj in ipairs(get_objects_in_area(v_sub(pos, 0.5), v_add(pos, 0.5))) do
		local ent = obj:get_luaentity()

		if ent then
			local ent_pos = ent.pos
			if ent.name:sub(1, 10) == "smartshop:" and ((not ent_pos) or vector.equals(ent_pos, pos)) then
				obj:remove()
			end
		end
	end
end

local function is_vertical_frames(animation)
	return (
		animation.type == "vertical_frames" and
		animation.aspect_w and
		animation.aspect_h
	)
end

local function get_single_frame(animation, image_name)
	return ("smartshop_animation_mask.png^[resize:%ix%i^[mask:%s"):format(
		animation.aspect_w,
		animation.aspect_h,
		image_name
	)
end

local function is_sheet_2d(animation)
	return (
		animation.type == "sheet_2d" and
		animation.frames_w and
		animation.frames_h
	)
end

local function get_sheet_2d(animation, image_name)
	return ("%s^[sheet:%ix%i:0,0"):format(
		image_name,
		animation.frames_w,
		animation.frames_h
	)
end

local get_image_from_tile = memoize1(function(tile)
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
			if animation then
				if is_vertical_frames(animation) then
					return get_single_frame(animation, image_name)

				elseif is_sheet_2d(animation) then
					return get_sheet_2d(animation, image_name)
				end
			end

			return image_name
		end
	end

	return "unknown_node.png"
end)

local function get_image_cube(tiles)
	if #tiles == 6 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or ""),
			get_image_from_tile(tiles[6] or ""),
			get_image_from_tile(tiles[3] or "")
		)

	elseif #tiles == 4 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or ""),
			get_image_from_tile(tiles[4] or ""),
			get_image_from_tile(tiles[3] or "")
		)

	elseif #tiles == 3 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or ""),
			get_image_from_tile(tiles[3] or ""),
			get_image_from_tile(tiles[3] or "")
		)

	elseif #tiles >= 1 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or ""),
			get_image_from_tile(tiles[1] or ""),
			get_image_from_tile(tiles[1] or "")
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

api.get_image = memoize1(function(item)
	if not item or item == "" then
		return "blank.png"
	end

	local def = minetest.registered_items[item]

	if not def then
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
		local parts = {("could not determine image for displaying %q.\ndefinition:"):format(item)}

		for key, value in pairs(def) do
			table.insert(parts, ("    %q = %q"):format(key, dump(value)))
		end

		smartshop.log("warning", table.concat(parts, "\n"))

		debug_cache[item] = true
	end

	return image or "unknown_node.png"
end)

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

function api.get_expected_entities(shop)
	local get_image_type = api.get_image_type

	local seen = {}
	local empty_count = 0
	local sprite_count = 0
	local entity_types = {}
	local last_sprite_index

	for index = 1, 4 do
		if shop:can_exchange(index) then
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
	end

	local expected_entities = {}

	if empty_count == 3 and sprite_count == 1 then
		table_insert(expected_entities, {"single_upright_sprite", last_sprite_index})

	elseif (sprite_count + empty_count) == 4 then
		table_insert(expected_entities, {"quad_upright_sprite"})

	else
		for index, image_type in pairs(entity_types) do
			if image_type == "sprite" then
				table_insert(expected_entities, {"single_sprite", index})

			elseif image_type == "wielditem" then
				table_insert(expected_entities, {"single_wielditem", index})
			end
		end
	end

	return expected_entities
end

local function check_update_objects(shop, expected_types)
	local pos = shop.pos
	local ents = api.get_entities(pos)

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

	local expected_entities = api.get_expected_entities(shop)

	if check_update_objects(shop, expected_entities) then
		return
	end

	api.clear_entities(pos)

	if #expected_entities == 0 then
		return
	end

	local entities = smartshop.entities

	for i = 1, #expected_entities do
		local type, index = unpack(expected_entities[i])

		entities.add_entity(shop, type, index)
	end
end
