-- luacheck: globals mesecon

local S = smartshop.S

local table_copy = table.copy

--------------------

local function mesecons_override(itemstring)
    local def = minetest.registered_nodes[itemstring]
	local groups = table_copy(def.groups or {})
	local on_timer = def.on_timer
	groups.mesecon = 2
	minetest.override_item(itemstring, {
		groups = groups,
		on_timer = function(pos, elapsed)
			if on_timer then
				on_timer(pos, elapsed)
			end
			mesecon.receptor_off(pos)
		end
	})
end

for _, variant in ipairs(smartshop.shop_node_names) do
	mesecons_override(variant)
end

for _, variant in ipairs(smartshop.storage_node_names) do
	mesecons_override(variant)
end

--------------------

smartshop.api.register_on_purchase(function(player, shop, i)
	local pos = shop.pos
    mesecon.receptor_on(pos)
    minetest.get_node_timer(pos):start(1)
end)

--------------------

local mesein_descriptions = {
	S("Don't send"),
	S("Incoming"),
	S("Outgoing"),
	S("Both"),
}

local old_build_storage_formspec = smartshop.api.build_storage_formspec
function smartshop.api.build_storage_formspec(storage)
	local fs_parts = {old_build_storage_formspec(storage)}

	local mesein = storage:get_mesein()
	local description = mesein_descriptions[mesein + 1]

	table.insert(fs_parts, ("button[0,7;2,1;mesesin;%s]"):format(description))
	table.insert(fs_parts, ("tooltip[mesesin;%s]"):format(S("When to send a mesecons signal")))

	return table.concat(fs_parts, "")
end

--------------------

local shop_class = smartshop.shop_class

function shop_class:set_state(value)
	self.meta:set_int("state", value)
	self.meta:mark_as_private("state")
end

local old_shop_initialize_metadata = shop_class.initialize_metadata

function shop_class:initialize_metadata(player)
	old_shop_initialize_metadata(self, player)

	self:set_state(0)  -- is this actually needed by mesecons, or what?
end

--------------------

local storage_class = smartshop.storage_class

function storage_class:get_mesein()
	return self.meta:get_int("mesein")
end

function storage_class:set_mesein(value)
	self.meta:set_int("mesein", value)
	self.meta:mark_as_private("mesein")
end

function storage_class:toggle_mesein()
	local mesein = self:get_mesein()
	mesein = (mesein + 1) % 4
	self:set_mesein(mesein)
end

local old_storage_initialize_metadata = storage_class.initialize_metadata
function storage_class:initialize_metadata(player)
	old_storage_initialize_metadata(self, player)
	self:set_mesein(0)
end

local old_storage_receive_fields = storage_class.receive_fields
function storage_class:receive_fields(player, fields)
	if fields.mesesin then
		self:toggle_mesein()
		self:show_formspec(player)
	else
		old_storage_receive_fields(player, fields)
	end
end


