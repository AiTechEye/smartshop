smartshop.api = {}

smartshop.dofile("api", "inv_class")
smartshop.dofile("api", "node_class")
smartshop.dofile("api", "shop_class")
smartshop.dofile("api", "storage_class")
smartshop.dofile("api", "player_inv_class")
smartshop.dofile("api", "tmp_inv_class")
smartshop.dofile("api", "tmp_shop_inv_class")

smartshop.dofile("api", "formspec")

smartshop.dofile("api", "purchase_mechanics")
smartshop.dofile("api", "storage_linking")

smartshop.dofile("api", "entities")

function smartshop.api.is_shop(pos)
	if not pos then return end
	local node_name = minetest.get_node(pos).name
	for _, name in ipairs(smartshop.shop_node_names) do
		if name == node_name then
			return true
		end
	end
	return false
end

function smartshop.api.is_storage(pos)
	if not pos then return end
	local node_name = minetest.get_node(pos).name
	for _, name in ipairs(smartshop.storage_node_names) do
		if name == node_name then
			return true
		end
	end
	return false
end

--[[
	TODO: i'm not certain whether memoizing the returned objects is worth doing or not.
          also it'd require clearing the memo when a node is destroyed.
]]
function smartshop.api.get_object(pos)
	if not pos then return end
	local obj
	if smartshop.api.is_shop(pos) then
		obj = smartshop.shop_class:new(pos)
	elseif smartshop.api.is_storage(pos) then
		obj = smartshop.storage_class:new(pos)
	end
	return obj
end
