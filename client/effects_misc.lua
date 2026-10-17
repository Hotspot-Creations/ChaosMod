local register = ChaosMod.register
local function position() return GetEntityCoords(PlayerPedId()) end
local function vehicle() return ChaosMod.playerVehicle() end
local function randomOffset(radius)
    local p = position()
    return vector3(p.x + math.random(-radius, radius),
        p.y + math.random(-radius, radius), p.z)
end

register('miscNightVision', function(ctx)
    SetNightvision(true)
    ctx:cleanup(function() SetNightvision(false) end)
end)
register('miscHeatVision', function(ctx)
    SetSeethrough(true)
    ctx:cleanup(function() SetSeethrough(false) end)
end)
register('miscBlackout', function(ctx)
    ctx:thread(0, function() SetArtificialLightsState(true) end)
    ctx:cleanup(function() SetArtificialLightsState(false) end)
end)
register('miscNoHUD', function(ctx)
    ctx:thread(0, function() HideHudAndRadarThisFrame() end)
end)
register('miscNoRadar', function(ctx)
    local wasVisible = not IsRadarHidden()
    ctx:thread(0, function() DisplayRadar(false) end)
    ctx:cleanup(function() DisplayRadar(wasVisible) end)
end)
register('miscForceFP', function(ctx)
    local oldPed = GetFollowPedCamViewMode()
    local oldVeh = GetFollowVehicleCamViewMode()
    ctx:thread(0, function()
        SetFollowPedCamViewMode(4)
        SetFollowVehicleCamViewMode(4)
        DisableControlAction(0, 0, true)
    end)
    ctx:cleanup(function()
        SetFollowPedCamViewMode(oldPed)
        SetFollowVehicleCamViewMode(oldVeh)
    end)
end)

register('miscDVD', function(ctx)
    local x, y, dx, dy = 0.10, 0.10, 0.0025, 0.0023
    local w, h = 0.34, 0.34
    ctx:thread(0, function()
        x, y = x + dx, y + dy
        if x <= 0 or x + w >= 1 then dx = -dx end
        if y <= 0 or y + h >= 1 then dy = -dy end
        -- Black outside a moving window, like an old bouncing DVD overlay.
        DrawRect(0.5, y / 2.0, 1.0, y, 0, 0, 0, 255)
        DrawRect(0.5, (1.0 + y + h) / 2.0, 1.0, 1.0 - y - h, 0, 0, 0, 255)
        DrawRect(x / 2.0, 0.5, x, 1.0, 0, 0, 0, 255)
        DrawRect((1.0 + x + w) / 2.0, 0.5, 1.0 - x - w, 1.0, 0, 0, 0, 255)
    end)
end)

register('miscPortraitMode', function(ctx)
    local width = 0
    ctx:thread(0, function()
        width = math.min(0.33, width + 0.006)
        DrawRect(width / 2, 0.5, width, 1.0, 0, 0, 0, 255)
        DrawRect(1.0 - width / 2, 0.5, width, 1.0, 0, 0, 0, 255)
    end)
end)

register('miscPwned', function(ctx)
    local sf = RequestScaleformMovie('HACKING_MESSAGE')
    local untilTime = GetGameTimer() + Config.ModelLoadTimeoutMs
    while ctx.active and not HasScaleformMovieLoaded(sf) and GetGameTimer() < untilTime do Wait(50) end
    if not ctx.active then return end
    if HasScaleformMovieLoaded(sf) then
        BeginScaleformMovieMethod(sf, 'SET_DISPLAY')
        ScaleformMovieMethodAddParamInt(5)
        ScaleformMovieMethodAddParamPlayerNameString('C H A O S   M O D')
        ScaleformMovieMethodAddParamPlayerNameString('')
        ScaleformMovieMethodAddParamInt(45)
        ScaleformMovieMethodAddParamInt(203)
        ScaleformMovieMethodAddParamInt(134)
        ScaleformMovieMethodAddParamBool(false)
        EndScaleformMovieMethod()
        ctx:thread(0, function()
            HideHudAndRadarThisFrame()
            DrawScaleformMovieFullscreen(sf, 255, 255, 255, 255, 0)
        end)
    end
    ctx:cleanup(function() SetScaleformMovieAsNoLongerNeeded(sf) end)
end)

register('miscRollCredits', function(ctx)
    SetCreditsActive(true)
    PlayEndCreditsMusic(true)
    ctx:cleanup(function()
        SetCreditsActive(false)
        PlayEndCreditsMusic(false)
    end)
end)

register('miscPause', function(ctx)
    ctx:thread(0, function() SetControlNormal(0, 199, 1.0) end)
end)

register('miscIntenseMusic', function(ctx)
    PrepareMusicEvent('AW_LOBBY_MUSIC_START')
    TriggerMusicEvent('AW_LOBBY_MUSIC_START')
    ctx:cleanup(function() CancelMusicEvent('AW_LOBBY_MUSIC_START') end)
end)

register('miscOilLeak', function(ctx)
    ctx:thread(1200, function()
        if not vehicle() then return end
        local p = position()
        local found, z = GetGroundZFor_3dCoord(p.x, p.y, p.z + 2.0, false)
        if found then AddPetrolDecal(p.x, p.y, z, 1.8, 1.8, 1.0) end
    end)
end)

register('miscOneBullet', function(ctx)
    ctx:thread(120, function()
        local p = PlayerPedId()
        if not IsPedArmed(p, 6) then return end
        local success, weapon = GetCurrentPedWeapon(p, true)
        if not success or weapon == joaat('WEAPON_UNARMED') then return end
        local loaded, rounds = GetAmmoInClip(p, weapon)
        if loaded and rounds > 1 then SetAmmoInClip(p, weapon, 1) end
    end)
end)

register('miscMidasTouch', function(ctx)
    local originals = {}
    ctx:thread(800, function()
        local veh = vehicle()
        if veh and not originals[veh] then originals[veh] = {GetVehicleColours(veh)} end
        if veh then SetVehicleColours(veh, 158, 158) end
        ChaosMod.nearby('CVehicle', Config.MaxNearbyVehicles, function(other)
            if IsEntityTouchingEntity(PlayerPedId(), other) then
                if not originals[other] then originals[other] = {GetVehicleColours(other)} end
                SetVehicleColours(other, 158, 158)
            end
        end)
    end)
    ctx:cleanup(function()
        for veh, c in pairs(originals) do
            if DoesEntityExist(veh) then SetVehicleColours(veh, c[1], c[2]) end
        end
    end)
end)

register('miscLowPoly', function(ctx)
    ctx:thread(0, function() OverrideLodscaleThisFrame(0.04) end)
end)

register('miscInvertVelocity', function()
    ChaosMod.nearby('CVehicle', Config.MaxNearbyVehicles, function(ent)
        local v = GetEntityVelocity(ent)
        SetEntityVelocity(ent, -v.x, -v.y, -v.z)
    end)
    ChaosMod.nearby('CPed', Config.MaxNearbyPeds, function(ent)
        local v = GetEntityVelocity(ent)
        SetEntityVelocity(ent, -v.x, -v.y, -v.z)
    end)
end)

register('miscUTurn', function()
    for _, pool in ipairs({'CVehicle', 'CPed'}) do
        local max = pool == 'CVehicle' and Config.MaxNearbyVehicles or Config.MaxNearbyPeds
        ChaosMod.nearby(pool, max, function(ent)
            local heading = GetEntityHeading(ent)
            local v = GetEntityVelocity(ent)
            SetEntityHeading(ent, heading + 180.0)
            SetEntityVelocity(ent, -v.x, -v.y, v.z)
        end)
    end
end)

register('miscEarthquake', function(ctx)
    ctx:thread(700, function()
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.15)
        ChaosMod.nearby('CVehicle', Config.MaxNearbyVehicles, function(ent)
            ApplyForceToEntity(ent, 1, math.random(-20, 20) + 0.0,
                math.random(-20, 20) + 0.0, 7.0, 0, 0, 0, 0,
                false, true, true, false, true)
        end)
        ChaosMod.nearby('CPed', Config.MaxNearbyPeds, function(ent)
            if ent ~= PlayerPedId() and not IsPedAPlayer(ent) then
                SetPedToRagdoll(ent, 1500, 1500, 0, false, false, false)
            end
        end)
    end)
    ctx:cleanup(function() StopGameplayCamShaking(true) end)
end)

register('miscFireworks', function(ctx)
    local asset = 'proj_indep_firework_v2'
    if not ctx:ptfx(asset) then return end
    local names = {'scr_firework_indep_ring_burst_rwb', 'scr_firework_indep_spiral_burst_rwb'}
    ctx:thread(900, function()
        local p = randomOffset(70)
        UseParticleFxAssetNextCall(asset)
        StartParticleFxNonLoopedAtCoord(names[math.random(#names)], p.x, p.y,
            p.z + math.random(25, 70), 0, 0, 0, 1.3, false, false, false)
    end)
end)

register('miscAirstrike', function(ctx)
    ctx:thread(1100, function()
        local p = randomOffset(45)
        local ok, z = GetGroundZFor_3dCoord(p.x, p.y, p.z + 100.0, false)
        AddExplosion(p.x, p.y, ok and z or p.z, 2, 1.5, true, false, 0.6)
    end)
end)

local weather = {
    weatherExtraSunny = 'EXTRASUNNY', weatherThunder = 'THUNDER',
    weatherFoggy = 'FOGGY', weatherNeutral = 'NEUTRAL', weatherXMAS = 'XMAS'
}
local function applyWeather(ctx, name)
    SetOverrideWeather(name)
    ctx:cleanup(function() ClearOverrideWeather() end)
end
for id, weatherName in pairs(weather) do
    register(id, function(ctx) applyWeather(ctx, weatherName) end)
end
register('weatherRandom', function(ctx)
    local choices = {'CLEAR', 'EXTRASUNNY', 'CLOUDS', 'OVERCAST', 'RAIN',
        'CLEARING', 'THUNDER', 'SMOG', 'FOGGY', 'XMAS', 'SNOWLIGHT', 'BLIZZARD'}
    ctx:thread(2500, function() SetOverrideWeather(choices[math.random(#choices)]) end)
    ctx:cleanup(function() ClearOverrideWeather() end)
end)

register('miscOrangeBall', function(ctx)
    local model = ctx:model('prop_juicestand')
    if not model then return end
    local p = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 5.0, 0.0)
    local object = CreateObject(model, p.x, p.y, p.z, false, false, false)
    if object == 0 or not ctx:entity(object) then return end
    ActivatePhysics(object)
    ApplyForceToEntity(object, 1, 0.0, -8.0, 1.0, 0, 0, 0, 0,
        false, true, true, false, true)
end)

register('miscSuperStunt', function(ctx)
    local model = ctx:model('prop_mp_ramp_03')
    if not model then return end
    local p = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 8.0, 0.0)
    local ramp = CreateObject(model, p.x, p.y, p.z, false, false, false)
    if ramp == 0 or not ctx:entity(ramp) then return end
    SetEntityHeading(ramp, GetEntityHeading(PlayerPedId()))
    PlaceObjectOnGroundProperly(ramp)
    FreezeEntityPosition(ramp, true)
end)

register('miscMeteorRain', function(ctx)
    local models = {'prop_test_boulder_01', 'prop_test_boulder_02',
        'prop_test_boulder_03', 'prop_test_boulder_04'}
    local loaded = {}
    for _, name in ipairs(models) do
        local hash = ctx:model(name)
        if hash then loaded[#loaded + 1] = hash end
    end
    if #loaded == 0 then return end
    ctx:thread(1500, function()
        if ctx.entities >= Config.MaxSpawnedEntities then return end
        local p = randomOffset(65)
        local hash = loaded[math.random(#loaded)]
        local obj = CreateObject(hash, p.x, p.y, p.z + math.random(30, 60), false, false, false)
        if obj ~= 0 and ctx:entity(obj) then
            ActivatePhysics(obj)
            ApplyForceToEntity(obj, 1, 0, 0, -50.0, 0, 0, 0, 0,
                false, true, true, false, true)
        end
    end)
end)

register('miscWhaleRain', function(ctx)
    local hash = ctx:model('a_c_humpback')
    if not hash then return end
    ctx:thread(1800, function()
        if ctx.entities >= Config.MaxSpawnedEntities then return end
        local p = randomOffset(65)
        local whale = CreatePed(28, hash, p.x, p.y, p.z + math.random(35, 55),
            math.random(0, 359) + 0.0, false, false)
        if whale ~= 0 and ctx:entity(whale) then
            SetEntityHealth(whale, 0)
            ActivatePhysics(whale)
        end
    end)
end)

register('miscTotalChaos', function(ctx)
    SetOverrideWeather('THUNDER')
    local nextSteer = 0
    ctx:thread(650, function()
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15)
        ChaosMod.nearby('CVehicle', Config.MaxNearbyVehicles, function(v)
            if v ~= vehicle() then
                ApplyForceToEntity(v, 1, math.random(-20, 20) + 0.0, 1.0, 5.0,
                    0, 0, 0, 0, false, true, true, false, true)
            end
        end)
    end)
    ctx:thread(50, function()
        local v = vehicle()
        if v and GetGameTimer() > nextSteer then
            SetVehicleSteerBias(v, math.random(-70, 70) / 100.0)
            nextSteer = GetGameTimer() + math.random(200, 450)
        end
    end)
    ctx:cleanup(function()
        ClearOverrideWeather()
        StopGameplayCamShaking(true)
        local v = vehicle()
        if v then SetVehicleSteerBias(v, 0.0) end
    end)
end)

register('miscXMarksTheSpot', function(ctx)
    local entity = ChaosMod.playerOrVehicle()
    local original = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    ctx:thread(0, function()
        DrawMarker(27, original.x, original.y, original.z - 1.0,
            0, 0, 0, 0, 0, 0,
            1.2, 1.2, 1.2, 255, 30, 30, 220,
            false, true, 2, false, nil, nil, false)
    end)
    ctx:cleanup(function()
        if DoesEntityExist(entity) then
            SetEntityCoords(entity, original.x, original.y, original.z, false, false, false, false)
            SetEntityHeading(entity, heading)
        end
    end)
end)

register('miscGetTowed', function(ctx)
    local towHash = ctx:model('towtruck')
    local driverHash = ctx:model('ig_tonya')
    if not towHash or not driverHash then return end

    local p = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 12.0, 0.0)
    local heading = GetEntityHeading(PlayerPedId())
    local tow = CreateVehicle(towHash, p.x, p.y, p.z + 0.5, heading, false, false)
    if tow == 0 or not ctx:entity(tow) then return end
    SetVehicleOnGroundProperly(tow)
    local driver = CreatePed(4, driverHash, p.x, p.y, p.z, heading, false, false)
    if driver == 0 or not ctx:entity(driver) then return end
    SetPedIntoVehicle(driver, tow, -1)
    SetVehicleEngineOn(tow, true, true, false)

    local ownVehicle = ChaosMod.playerVehicle()
    if ownVehicle and ownVehicle ~= tow then
        AttachVehicleToTowTruck(tow, ownVehicle, false, 0.0, 0.0, 0.0)
        ctx:cleanup(function()
            if DoesEntityExist(tow) and DoesEntityExist(ownVehicle) then
                DetachVehicleFromTowTruck(tow, ownVehicle)
            end
        end)
    end
    TaskVehicleDriveWander(driver, tow, 14.0, 786603)
end)
