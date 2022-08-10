local getDeliveryStart = {} -- key: train ID, value: started (tick)

local on_dispatcher_updated = function(event)
    print("TCS LTN Bridge: dispatcher updated")

    -- event received check if new delivery

        -- check train ID, if not exist then true
        -- check started, if larger than existing dictionary value then true
        -- store train ID with current started value

    -- if new delivery then add another station to end of schedule
end

script.on_init(function ()
    if remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_dispatcher_updated"), on_dispatcher_updated)
    end

    -- global strings
    global.refuel_station_name = "TestStation [virtual-signal=refuel-signal]"
    global.refuel_station_inactivity_condition_timeout = 300 -- ticks

    print("INIT fired")
end)