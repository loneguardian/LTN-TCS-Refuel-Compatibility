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

-- event IDs
local on_train_created = defines.events.on_train_created

-- local variables
local trainById -- global - key: "unique" train ID, value: LuaTrain object

local wait_condition = {
    compare_type = "and",
    type = "inactivity",
    ticks = setting_refuel_station_inactivity_condition_timeout
}

local refuel_station_record = {
    station = setting_refuel_station_name,
    wait_conditions = {wait_condition}
}

-- local functions
local function initialiseTrainById()
    global.trainById = {}

    trainById = global.trainById

    local trainArray

    for _, f in pairs(game.forces) do
        trainArray = f.get_trains()

        for _, t in ipairs(trainArray) do
            trainById[t.id] = t
        end

    end

    if debug then print("updateTrainById(): initialised train dictionary") end
end

local function updateTrainById(event)
    if not event then return end
        
    if event.name == on_train_created then
        -- update trainById dictionary
        -- clear old IDs in dictionary
        if event.old_train_id_1 then trainById[event.old_train_id_1] = nil end
        if event.old_train_id_2 then trainById[event.old_train_id_2] = nil end

        -- create new entry
        trainById[event.train.id] = event.train

        if debug then
            print(
                "updateTrainById(): by on_train_created. Old IDs:",
                event.old_train_id_1,
                event.old_train_id_2,
                "New ID",
                event.train.id
            )
        end
    end

    -- TODO: to handle train ID that got deleted? (currently not necessary but probably good if we can find an event to remove invalid trains)
end

-- handlers
local function on_configuration_changed(event)
    -- remove obsolete globals
    global.getDeliveryStart = nil
    
    initialiseTrainById()
end

local function on_delivery_pickup_complete(event)
    if debug then print("on_delivery_pickup_complete():", event.tick, "pickup complete", event.train_id) end

    -- insert new stop for train announcing delivery_pickup_complete
    local t = event.train_id and trainById[event.train_id]

    if t.valid then
        local sch = table.deepcopy(t.schedule)
        
        table.insert(sch.records, refuel_station_record)

        t.schedule = sch
    end
end

local function on_train_created(event)
    updateTrainById(event)
end

local function registerEvents()
    script.on_configuration_changed(on_configuration_changed)

    script.on_event(defines.events.on_train_created, on_train_created)

    if remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_delivery_pickup_complete"), on_delivery_pickup_complete)
    end
end

script.on_load(function ()
    registerEvents()

    -- localise globals
    trainById = global.trainById
end)

script.on_init(function ()
    registerEvents()

    initialiseTrainById()
end)