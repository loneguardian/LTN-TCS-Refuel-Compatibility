require "util"

-- parameters (to be changed to settings)
local refuel_station_name = "TestStation [virtual-signal=refuel-signal]"
local refuel_station_inactivity_condition_timeout = 300 -- ticks

-- detect debug
local debug = (__DebugAdapter and true) or false

-- local variables
--local getDeliveryStart -- key: train ID, value: started (tick)
local trains = {} -- key: "unique" ID, value: LuaTrain

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

    -- create new entry with LuaTrain
    trains[event.train.id] = event.train

    if debug then print(
        "on_train_created(): train dictionary updated. Old IDs:",
        event.old_train_id_1,
        event.old_train_id_2,
        "New ID",
        event.train.id
    ) end
end

--[[ dispatcher updates firing too frequently, ideal event will be a train specific event when a new delivery is scheduled

local function on_dispatcher_updated(event)
    -- event received, check if new delivery
    local isNewDelivery = false
    local d = event.deliveries
    
    for k, v in pairs(d) do

        isNewDelivery = false

        if getDeliveryStart[k] then
            -- train ID exist
            -- check `started`
            if d[k].started > getDeliveryStart[k] then
                --event tick is higher than existing -> new delivery
                isNewDelivery = true
            end
        else
            -- new train ID
            isNewDelivery = true
        end

        if isNewDelivery then
            getDeliveryStart[k] = d[k].started
            if debug then print(on_dispatcher_updated(): event.tick, "new d", k, d[k].started) end
        end
    end
        -- check train ID, if not exist then true
        -- check started, if larger than existing dictionary value then true
        -- store train ID with current started value

    -- if new delivery then add another station to end of schedule
end
]]--

local function registerEvents()
    if remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_delivery_pickup_complete"), on_delivery_pickup_complete)
        --script.on_event(remote.call("logistic-train-network", "on_dispatcher_updated"), on_dispatcher_updated)
    end

    script.on_configuration_changed(on_configuration_changed)
    script.on_event(defines.events.on_train_created, on_train_created)
end

script.on_load(function ()
    registerEvents()

    initialiseTrains()
    --getDeliveryStart = global.getDeliveryStart
end)

script.on_init(function ()
    registerEvents()

    initialiseTrains()
    --global.getDeliveryStart = {}
    --getDeliveryStart = global.getDeliveryStart
end)