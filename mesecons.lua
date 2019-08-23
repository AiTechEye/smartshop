if smartshop.settings.has_mesecon then
    function smartshop.send_mesecon(pos)
        mesecon.receptor_on(pos)
        minetest.get_node_timer(pos):start(1)
    end

    if mesecon.register_mvps_stopper then
        mesecon.register_mvps_stopper("smartshop:shop")
        mesecon.register_mvps_stopper("smartshop:shop_full")
        mesecon.register_mvps_stopper("smartshop:shop_empty")
        mesecon.register_mvps_stopper("smartshop:shop_used")
        mesecon.register_mvps_stopper("smartshop:shop_admin")
        mesecon.register_mvps_stopper("smartshop:wifistorage")
    end
else
    function smartshop.send_mesecon() end
end

