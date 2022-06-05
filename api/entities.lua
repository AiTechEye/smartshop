
local pos_to_string = minetest.pos_to_string

local api = smartshop.api
local util = smartshop.util

local escape_texture = util.escape_texture

local debug = false
local debug_cache = {}

local entities_by_pos = {}

function api.record_entity(pos, obj)
	local spos = pos_to_string(pos)
	local entities_at_pos = entities_by_pos[spos] or {}
	table.insert(entities_at_pos, obj)
	entities_by_pos[spos] = entities_at_pos
end

function api.clear_entities(pos)
	local spos = pos_to_string(pos)
	local entities_at_pos = entities_by_pos[spos] or {}
	for _, obj in ipairs(entities_at_pos) do
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
			if (
				tile.animation and
				tile.animation.type == "vertical_frames" and
				tile.animation.aspect_w and
				tile.animation.aspect_h
			) then
				return ("smartshop_animation_mask.png^[resize:%ix%i^[mask:%s"):format(
					tile.animation.aspect_w,
					tile.animation.aspect_h,
					image_name
				)
			elseif (
				tile.animation and
				tile.animation.type == "sheet_2d" and
				tile.animation.frames_w and
				tile.animation.frames_h
			) then
				return ("%s^[sheet:%ix%i:0,0"):format(
					image_name,
					tile.animation.frames_w,
					tile.animation.frames_h
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

function api.get_image(item)
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
			if ((not def.type or def.type == "node") and
				(not def.drawtype or
					def.drawtype == "normal" or
					def.drawtype == "allfaces" or
					def.drawtype == "allfaces_optional" or
					def.drawtype == "glasslike" or
					def.drawtype == "glasslike_framed" or
					def.drawtype == "glasslike_framed_optional" or
					def.drawtype == "liquid")
			) then
				image = get_image_cube(tiles)
			else
				image = get_image_from_tile(tiles[1])
			end
		end
	end

	if (debug or not image or image == "" or image == "unknown_node.png") and not debug_cache[item] then
		smartshop.log("warning", "definition for %s", item)
		for key, value in pairs(def) do
			smartshop.log("warning", "    %q = %q", key, minetest.serialize(value))
		end
		debug_cache[item] = true
	end

	return image or "unknown_node.png"
end

function api.get_quad_image(items)
	local images = {}
	for i = 1, 4 do
		local image = api.get_image(items[i])
		if image == "unknown_node.png" then
			image = "blank.png"
		end
		table.insert(images, escape_texture(image .. "^[resize:32x32"))
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

function api.update_entities(shop)
	-- TODO https://github.com/fluxionary/minetest-smartshop/issues/32
	shop:clear_entities()

	local seen = {}
	local empty_count = 0
	local sprite_count = 0
	local entity_types = {}
	local last_sprite_index
	for index = 1, 4 do
		local item = shop:get_give_stack(index):get_name()
		local image_type = api.get_image_type(shop, index)
		table.insert(entity_types, image_type)
		if seen[item] or image_type == "none" then
			empty_count = empty_count + 1
		elseif image_type == "sprite" then
			sprite_count = sprite_count + 1
			last_sprite_index = index
		end
		seen[item] = true
	end

	-- luacheck: push ignore 542
	if empty_count == 4 then
		-- just remove any entities
		-- luacheck: pop

	elseif empty_count == 3 and sprite_count == 1 then
		local obj = smartshop.entities.add_single_upright_sprite(shop, last_sprite_index)
		if obj then
			api.record_entity(shop.pos, obj)
		end

	elseif (sprite_count + empty_count) == 4 then
		local obj = smartshop.entities.add_quad_upright_sprite(shop)
		if obj then
			api.record_entity(shop.pos, obj)
		end

	else
		for index, image_type in pairs(entity_types) do
			local obj
			if image_type == "sprite" then
				obj = smartshop.entities.add_single_sprite(shop, index)
			elseif image_type == "wielditem" then
				obj = smartshop.entities.add_single_wielditem(shop, index)
			end
			if obj then
				api.record_entity(shop.pos, obj)
			end
		end
	end
end
