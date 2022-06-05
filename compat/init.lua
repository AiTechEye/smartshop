smartshop.compat = {}

smartshop.dofile("compat", "old_smartshops")

if smartshop.has.currency then
	smartshop.dofile("compat", "currency")
end

if smartshop.has.mesecons then
	smartshop.dofile("compat", "mesecons")
end

if smartshop.has.mesecons_mvps then
	smartshop.dofile("compat", "mesecons_mvps")
end

if smartshop.has.pipeworks then
	smartshop.dofile("compat", "pipeworks")
end

if smartshop.has.tubelib then
	smartshop.dofile("compat", "tubelib")
end
