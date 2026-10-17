local register = ChaosMod.register

register('vehicleBreakDoors', function()
    local veh = ChaosMod.playerVehicle()
    if not veh then return end
    for door = 0, 5 do SetVehicleDoorBroken(veh, door, false) end
end)

register('popVehicleTyres', function()
    local veh = ChaosMod.playerVehicle()
    if not veh then return end
    for tyre = 0, 7 do SetVehicleTyreBurst(veh, tyre, true, 1000.0) end
end)

register('vehicle30Max', function(ctx)
    local affected = {}
    ctx:thread(250, function()
        local veh = ChaosMod.playerVehicle()
        if veh then
            affected[veh] = true
            SetVehicleMaxSpeed(veh, 13.4112) -- 30 MPH in m/s
        end
    end)
    ctx:cleanup(function()
        for veh in pairs(affected) do
            if DoesEntityExist(veh) then SetVehicleMaxSpeed(veh, 0.0) end
        end
    end)
end)

register('vehicleCinematicCam', function(ctx)
    ctx:thread(0, function()
        if ChaosMod.playerVehicle() then
            SetCinematicModeActive(true)
            DisableControlAction(0, 80, true)
            DisableControlAction(0, 0, true)
        end
    end)
    ctx:cleanup(function() SetCinematicModeActive(false) end)
end)

local colours = {
    goldenTraffic = 99, greenTraffic = 50, orangeTraffic = 41,
    chromeTraffic = 120, redTraffic = 27
}
for id, colour in pairs(colours) do
    register(id, function(ctx)
        local original = {}
        ctx:thread(1500, function()
            ChaosMod.nearby('CVehicle', Config.MaxNearbyVehicles, function(veh)
                if original[veh] == nil then
                    local primary, secondary = GetVehicleColours(veh)
                    original[veh] = {primary, secondary}
                end
                SetVehicleColours(veh, colour, colour)
            end)
        end)
        ctx:cleanup(function()
            for veh, pair in pairs(original) do
                if DoesEntityExist(veh) then SetVehicleColours(veh, pair[1], pair[2]) end
            end
        end)
    end)
end

local vehicleModels = {
    spawnAdder = 'adder', spawnBus = 'bus',
    spawnTug = 'tug', spawnLuxor = 'luxor'
}
for id, modelName in pairs(vehicleModels) do
    register(id, function(ctx)
        local hash = ctx:model(modelName)
        if not hash then return end
        local playerPed = PlayerPedId()
        local pos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 7.0, 0.0)
        local veh = CreateVehicle(hash, pos.x, pos.y, pos.z + 1.0,
            GetEntityHeading(playerPed), false, false)
        if veh == 0 then return end
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleOnGroundProperly(veh)
        SetVehicleEngineOn(veh, true, true, false)
        ctx:entity(veh, 'vehicle')
        -- Warp only on a clear seat, and do not pull somebody out of an existing car.
        if not IsPedInAnyVehicle(playerPed, false) then
            TaskWarpPedIntoVehicle(playerPed, veh, -1)
        end
    end)
end
