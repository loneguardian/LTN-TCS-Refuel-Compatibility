-- require
require "util"

-- parameters (to be changed to settings)
local refuel_station_name = "TestStation [virtual-signal=refuel-signal]"
local refuel_station_inactivity_condition_timeout = 300 -- ticks

-- debug detection
local debug = (__DebugAdapter and true) or false

-- local variables
local trains = {} -- key: "unique" train ID, value: LuaTrain object

local wait_condition = {
    compare_type = "and",
    type = "inactivity",
    ticks = refuel_station_inactivity_condition_timeout
}

local refuel_station_record = {
    station = refuel_station_name,
    wait_conditions = {wait_condition}
}

-- local functions
local function initialiseTrains()

    local trainArray

    for _, v in pairs(game.forces) do
        trainArray = v.get_trains()

        for _, v in ipairs(trainArray) do
            trains[v.id] = v
        end

    end

    if debug then print("initialiseTrains(): initialised train dictionary") end
end

-- handlers
local function on_configuration_changed(event)
    -- remove obsolete globals
    global.getDeliveryStart = nil
    global.trains = nil
end

local function on_delivery_pickup_complete(event)
    if debug then print("on_delivery_pickup_complete():", event.tick, "pickup complete", event.train_id) end

    local t = trains[event.train_id]

    if t.valid then
        local sch = table.deepcopy(t.schedule)
        
        table.insert(sch.records, refuel_station_record)

        t.schedule = sch
    end
end

local function on_train_created(event)
    -- clear old IDs in dictionary
    if event.old_train_id_1 then trains[event.old_train_id_1] = nil end
    if event.old_train_id_2 then trains[event.old_train_id_2] = nil end

    -- create new entry
    trains[event.train.id] = event.train

    if debug then print(
        "on_train_created(): train dictionary updated. Old IDs:",
        event.old_train_id_1,
        event.old_train_id_2,
        "New ID",
        event.train.id
    ) end
end

local function registerEvents()
    if remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_delivery_pickup_complete"), on_delivery_pickup_complete)
    end

    script.on_configuration_changed(on_configuration_changed)
    script.on_event(defines.events.on_train_created, on_train_created)
end

script.on_load(function ()
    registerEvents()

    initialiseTrains()
end)

script.on_init(function ()
    registerEvents()

    initialiseTrains()
end)