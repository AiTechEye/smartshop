minetest.register_node("smartshop:node", {
    tiles = {"[combine:16x16^[noalpha^[colorize:#FFF:255"}
})

minetest.register_tool("smartshop:tool", {inventory_image = "[combine:16x16^[noalpha^[colorize:#000:255"})
minetest.register_craftitem("smartshop:gold", {inventory_image = "[combine:16x16^[noalpha^[colorize:#FF0:255"})

minetest.register_craftitem("smartshop:currency_1", {inventory_image = "[combine:16x16^[noalpha^[colorize:#222:255"})
minetest.register_craftitem("smartshop:currency_2", {inventory_image = "[combine:16x16^[noalpha^[colorize:#444:255"})
minetest.register_craftitem("smartshop:currency_5", {inventory_image = "[combine:16x16^[noalpha^[colorize:#666:255"})
minetest.register_craftitem("smartshop:currency_10", {inventory_image = "[combine:16x16^[noalpha^[colorize:#888:255"})
minetest.register_craftitem("smartshop:currency_20", {inventory_image = "[combine:16x16^[noalpha^[colorize:#AAA:255"})
minetest.register_craftitem("smartshop:currency_50", {inventory_image = "[combine:16x16^[noalpha^[colorize:#CCC:255"})
minetest.register_craftitem("smartshop:currency_100", {inventory_image = "[combine:16x16^[noalpha^[colorize:#EEE:255"})

if not smartshop.has.currency then
	smartshop.dofile("compat", "currency")
end
