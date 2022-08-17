-- parameters (to be changed to settings)
local setting_refuel_station_name = "TestStation [virtual-signal=refuel-signal]"
local setting_refuel_station_inactivity_condition_timeout = 300 -- ticks

-- debug detection
local debug = (__DebugAdapter and true) or false

-- require
local util = require "util"

-- localise table functions
local table = {
    deepcopy = util.table.deepcopy,
    insert = table.insert
}

-- local variables
local wait_condition = {
    compare_type = "and",
    type = "inactivity",
    ticks = setting_refuel_station_inactivity_condition_timeout
}

local refuel_station_record = {
    station = setting_refuel_station_name,
    wait_conditions = {wait_condition}
}

-- handlers
local function on_configuration_changed(event)
    -- remove obsolete globals
    global.getDeliveryStart = nil
    global.trainById = nil
end

local function on_delivery_pickup_complete(event)
    if debug then print("on_delivery_pickup_complete():", event.tick, "pickup complete", event.train_id) end

    -- insert new stop for train announcing delivery_pickup_complete
    local t = event.train

    if t.valid then
        local sch = table.deepcopy(t.schedule)
        
        table.insert(sch.records, refuel_station_record)

        t.schedule = sch
    end
end

-- register handlers
script.on_configuration_changed(on_configuration_changed)

local function registerCondEvents()
    if remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_delivery_pickup_complete"), on_delivery_pickup_complete)
    end
end

script.on_load(function ()
    registerCondEvents()
end)

script.on_init(function ()
    registerCondEvents()
end)