local register = ChaosMod.register
local function ped() return PlayerPedId() end
local function subject() return ChaosMod.playerOrVehicle() end

register('playerHealAndArmour', function()
    SetEntityHealth(ped(), GetEntityMaxHealth(ped()))
    SetPedArmour(ped(), 200)
end)

register('playerIgnite', function(ctx)
    local entity = subject()
    StartEntityFire(entity)
    ctx:cleanup(function() if DoesEntityExist(entity) then StopEntityFire(entity) end end)
end)

register('playerLaunchUp', function()
    local ent = subject()
    if ent == ped() then SetPedToRagdoll(ent, 3000, 3000, 0, false, false, false) end
    local velocity = GetEntityVelocity(ent)
    SetEntityVelocity(ent, velocity.x, velocity.y, 65.0)
end)

register('playerGiveWeapons', function()
    local weapons = {
        'WEAPON_DAGGER', 'WEAPON_BAT', 'WEAPON_KNIFE', 'WEAPON_CROWBAR',
        'WEAPON_GOLFCLUB', 'WEAPON_HATCHET', 'WEAPON_MACHETE', 'WEAPON_NIGHTSTICK',
        'WEAPON_PISTOL', 'WEAPON_PISTOL_MK2', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL',
        'WEAPON_PISTOL50', 'WEAPON_SNSPISTOL', 'WEAPON_HEAVYPISTOL', 'WEAPON_REVOLVER',
        'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_SMG_MK2', 'WEAPON_ASSAULTSMG',
        'WEAPON_COMBATPDW', 'WEAPON_MACHINEPISTOL', 'WEAPON_MINISMG',
        'WEAPON_PUMPSHOTGUN', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN',
        'WEAPON_BULLPUPSHOTGUN', 'WEAPON_HEAVYSHOTGUN', 'WEAPON_AUTOSHOTGUN',
        'WEAPON_ASSAULTRIFLE', 'WEAPON_ASSAULTRIFLE_MK2', 'WEAPON_CARBINERIFLE',
        'WEAPON_CARBINERIFLE_MK2', 'WEAPON_ADVANCEDRIFLE', 'WEAPON_SPECIALCARBINE',
        'WEAPON_SPECIALCARBINE_MK2', 'WEAPON_BULLPUPRIFLE', 'WEAPON_COMPACTRIFLE',
        'WEAPON_MG', 'WEAPON_COMBATMG', 'WEAPON_GUSENBERG', 'WEAPON_SNIPERRIFLE',
        'WEAPON_HEAVYSNIPER', 'WEAPON_MARKSMANRIFLE', 'WEAPON_RPG',
        'WEAPON_GRENADELAUNCHER', 'WEAPON_MINIGUN', 'WEAPON_HOMINGLAUNCHER',
        'WEAPON_GRENADE', 'WEAPON_STICKYBOMB', 'WEAPON_MOLOTOV', 'WEAPON_FIREWORK',
    }
    for _, name in ipairs(weapons) do
        local hash = joaat(name)
        if IsWeaponValid(hash) then GiveWeaponToPed(ped(), hash, 250, false, false) end
    end
end)

register('playerGravity', function(ctx)
    ctx:thread(0, function() SetGravityLevel(1) end)
    ctx:cleanup(function() SetGravityLevel(0) end)
end)

register('playerKeepWalking', function(ctx)
    ctx:thread(0, function()
        SetControlNormal(0, 32, 1.0)
        SetControlNormal(0, 71, 1.0)
        DisableControlAction(0, 72, true)
        DisableControlAction(0, 76, true)
    end)
end)

register('playerDrunk', function(ctx)
    local clipset = 'MOVE_M@DRUNK@VERYDRUNK'
    RequestAnimSet(clipset)
    local deadline = GetGameTimer() + Config.ModelLoadTimeoutMs
    while ctx.active and not HasAnimSetLoaded(clipset) and GetGameTimer() < deadline do Wait(50) end
    if not ctx.active then return end
    if HasAnimSetLoaded(clipset) then SetPedMovementClipset(ped(), clipset, 1.0) end
    SetPedIsDrunk(ped(), true)
    ShakeGameplayCam('DRUNK_SHAKE', 1.2)
    ctx:thread(300, function()
        local veh = ChaosMod.playerVehicle()
        if veh then SetVehicleSteerBias(veh, math.random(-50, 50) / 100.0) end
    end)
    ctx:cleanup(function()
        SetPedIsDrunk(ped(), false)
        ResetPedMovementClipset(ped(), 0.0)
        RemoveAnimSet(clipset)
        StopGameplayCamShaking(true)
        local veh = ChaosMod.playerVehicle()
        if veh then SetVehicleSteerBias(veh, 0.0) end
    end)
end)

register('flipCamera', function(ctx)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, false)
    ctx:thread(0, function()
        local pos = GetGameplayCamCoord()
        local rot = GetGameplayCamRot(2)
        SetCamParams(cam, pos.x, pos.y, pos.z, rot.x, rot.y + 180.0, rot.z,
            GetGameplayCamFov(), 0, 1, 1, 2)
    end)
    ctx:cleanup(function()
        RenderScriptCams(false, true, 500, true, false)
        SetCamActive(cam, false)
        DestroyCam(cam, false)
    end)
end)

register('clonePlayer', function(ctx)
    local playerPed = ped()
    local clone = ClonePed(playerPed, GetEntityHeading(playerPed), false, false)
    if clone == 0 then return end
    if not ctx:entity(clone) then return end
    SetPedSuffersCriticalHits(clone, false)
    GiveWeaponToPed(clone, GetSelectedPedWeapon(playerPed), 120, false, true)
    local friendly = math.random(2) == 1
    if friendly then
        SetPedAsGroupMember(clone, GetPlayerGroup(PlayerId()))
        TaskFollowToOffsetOfEntity(clone, playerPed, 1.0, -1.0, 0.0, 3.0, -1, 1.0, true)
    else
        SetPedCombatAbility(clone, 2)
        TaskCombatPed(clone, playerPed, 0, 16)
    end
end)

register('playerPoof', function(ctx)
    local nextExplosion = 0
    ctx:thread(100, function()
        if GetGameTimer() < nextExplosion then return end
        local aiming, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
        if not aiming or not entity or entity == 0 then return end
        if not (IsEntityAPed(entity) or IsEntityAVehicle(entity)) then return end
        if entity == subject() or IsEntityDead(entity) then return end
        nextExplosion = GetGameTimer() + 500
        local pos = GetEntityCoords(entity)
        AddExplosion(pos.x, pos.y, pos.z, 2, 2.0, true, false, 0.5)
    end)
end)

local locations = {
    teleportLSIA = vector3(-1388.6, -3111.61, 13.94),
    teleportMaze = vector3(-75.7, -818.62, 326.16),
    teleportFort = vector3(-2360.30, 3244.83, 92.90),
    teleportChilliad = vector3(501.77, 5604.85, 797.91),
    teleportSky = vector3(935.0, 3800.0, 2300.0)
}

local function teleportTo(destination)
    local ent = subject()
    SetEntityCoords(ent, destination.x, destination.y, destination.z, false, false, false, false)
end

for id, target in pairs(locations) do
    register(id, function() teleportTo(target) end)
end

register('teleportFake', function(ctx)
    local ent = subject()
    local original = GetEntityCoords(ent)
    local heading = GetEntityHeading(ent)
    local list = {'teleportLSIA', 'teleportMaze', 'teleportFort', 'teleportChilliad', 'teleportSky'}
    teleportTo(locations[list[math.random(#list)]])
    ctx:cleanup(function()
        -- Do not move an entity that has since been deleted/replaced.
        if DoesEntityExist(ent) then
            SetEntityCoords(ent, original.x, original.y, original.z, false, false, false, false)
            SetEntityHeading(ent, heading)
        end
    end)
end)

register('playerSwap', function(ctx)
    local destination = ctx.data.destination
    if destination and type(destination.x) == 'number' then teleportTo(destination) end
end)

register('fiveStars', function()
    SetPlayerWantedLevel(PlayerId(), 5, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
end)

register('addTwoStars', function()
    local id = PlayerId()
    SetPlayerWantedLevel(id, math.min(5, GetPlayerWantedLevel(id) + 2), false)
    SetPlayerWantedLevelNow(id, false)
end)

register('neverWanted', function(ctx)
    ctx:thread(300, function()
        SetPlayerWantedLevel(PlayerId(), 0, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
    end)
end)
