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
local setting_refuel_station_name = settings.global["ltntcsr-refuel-station-name"].value
local setting_refuel_station_inactivity_condition_timeout = settings.global["ltntcsr-refuel-station-inactivity-condition-timeout"].value * 60

local trainById

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
local function checkLtnSetting()
    local s = settings.global["ltn-dispatcher-requester-delivery-reset"]

    local isResetAtRequester = s.value
    local settingName = game.mod_setting_prototypes["ltn-dispatcher-requester-delivery-reset"].localised_name

    if debug then print("LTN setting isResetAtRequester:", isResetAtRequester) end

    if isResetAtRequester then
        game.print({"console-message.ltn-setting-warning", settingName})
    end
end

local function updateTrainById()
    local t
    
    trainById = {}

    for _, f in pairs(game.forces) do
        t = f.get_trains()

        for i = 1, #t do
            trainById[t[i].id] = t[i]
        end
    end
end

-- handlers
local function on_configuration_changed(event)
    updateTrainById()
    checkLtnSetting()
end

local function on_delivery_pickup_complete(event)
    if debug then print("on_delivery_pickup_complete():", event.tick, "pickup complete", event.train_id) end

    if not trainById then updateTrainById() end

    -- insert new stop for train announcing delivery_pickup_complete
    local t = trainById[event.train_id]

    if t.valid then
        local sch = table.deepcopy(t.schedule)
        
        table.insert(sch.records, refuel_station_record)

        t.schedule = sch
    end
end

local function on_setting_changed(event)
    local settingName = event.setting

    if settingName == "ltn-dispatcher-requester-delivery-reset" then
        checkLtnSetting()
    elseif settingName == "ltntcsr-refuel-station-name" then
        setting_refuel_station_name = settings.global[settingName].value
        refuel_station_record.station = setting_refuel_station_name
    elseif settingName == "ltntcsr-refuel-station-inactivity-condition-timeout" then
        setting_refuel_station_inactivity_condition_timeout = settings.global[settingName].value * 60
        wait_condition.ticks = setting_refuel_station_inactivity_condition_timeout
    end
end

-- register handlers
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events["on_runtime_mod_setting_changed"], on_setting_changed)

local function registerCondEvents()
    if remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_delivery_pickup_complete"), on_delivery_pickup_complete)
    end
end

script.on_load(function ()
    registerCondEvents()
end)

-- init
script.on_init(function ()
    registerCondEvents()
    updateTrainById()
    checkLtnSetting()
end)