if smartshop.settings.has_mesecon then
    function smartshop.send_mesecon(pos)
        mesecon.receptor_on(pos)
        minetest.get_node_timer(pos):start(1)
    end
else
    function smartshop.send_mesecon(pos) end
end

