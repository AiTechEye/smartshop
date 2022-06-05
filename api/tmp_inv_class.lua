
local remove_detached_inventory = minetest.remove_detached_inventory

local class = smartshop.util.class
local clone_tmp_inventory = smartshop.util.clone_tmp_inventory

--------------------

local inv_class = smartshop.inv_class
local tmp_inv_class = class(inv_class)
smartshop.tmp_inv_class = tmp_inv_class

--------------------

function tmp_inv_class:__new(inv)
	self.name = "smartshop:tmp_" .. minetest.serialize(inv:get_location())
	inv_class.__new(self, clone_tmp_inventory(self.name, inv))
end

function tmp_inv_class:destroy()
	remove_detached_inventory(self.name)
	self.inv = nil
end
