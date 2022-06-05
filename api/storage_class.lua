local S = smartshop.S
local api = smartshop.api
local class = smartshop.util.class

--------------------

local node_class = smartshop.node_class
local storage_class = class(node_class)
smartshop.storage_class = storage_class

--------------------

function storage_class:get_title()
	if not self.meta:get("title") then
		self:set_title("storage@%s", self:get_pos_as_string())
	end
	return self.meta:get_string("title")
end

function storage_class:set_title(format, ...)
	self.meta:set_string("title", format:format(...))
	self.meta:mark_as_private("title")
end

--------------------

function storage_class:initialize_metadata(player)
	node_class.initialize_metadata(self, player)

    local player_name
    if type(player) == "string" then
        player_name = player
    else
        player_name = player:get_player_name()
    end

	self:set_infotext(S("External storage by: @1", player_name))
	self:set_title("storage@%s", self:get_pos_as_string())
end

function storage_class:initialize_inventory()
	node_class.initialize_inventory(self)

	local inv = self.inv
	inv:set_size("main", 60)
end

--------------------

function storage_class:show_formspec(player)
	if not self:can_access(player) then
		return
	end

	local player_name = player:get_player_name()
	local formspec = api.build_storage_formspec(self)
	local formname = ("smartshop:%s"):format(self:get_pos_as_string())

	minetest.show_formspec(player_name, formname, formspec)
end

function storage_class:receive_fields(player, fields)
	local changed = false
	if fields.private then
	    self:set_private(fields.private == "true")
		changed = true
	end

	if fields.title then
		self:set_title(fields.title)
		changed = true
    end

	if changed then
		self:show_formspec(player)
	end
end

