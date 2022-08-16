-- this will allow us to more easily extend behavior e.g. interacting directly w/ inventory bags

local class = smartshop.util.class

--------------------

local inv_class = smartshop.inv_class
local player_inv_class = class(inv_class)
smartshop.player_inv_class = player_inv_class

--------------------

function player_inv_class:_init(player)
	self.player = player
	self.name = player:get_player_name()
	inv_class._init(self, player:get_inventory())
end

function smartshop.api.get_player_inv(player)
	return player_inv_class(player)
end

--------------------

function player_inv_class:contains_item(stack)
	return inv_class.contains_item(self, stack, true)
end

function player_inv_class:remove_item(stack)
	return inv_class.remove_item(self, stack, true)
end

function player_inv_class:get_count(stack, kind)
	return inv_class.get_count(self, stack, true)
end

function player_inv_class:get_all_counts()
	return inv_class.get_all_counts(self, true)
end
