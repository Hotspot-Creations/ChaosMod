ChaosMod = {}
local handlers = {}
local active
local lastToken = -1
local PREFIX = '^5[ChaosMod]^7 '

local function debugLog(message)
    if Config.Debug or GetConvar('chaosmod_debug', 'false') == 'true' then
        print(PREFIX .. tostring(message))
    end
end

local function message(content)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName('~p~ChaosMod~s~: ' .. tostring(content))
    EndTextCommandThefeedPostTicker(false, false)
    if Config.UseChatMessages and GetResourceState('chat') == 'started' then
        TriggerEvent('chat:addMessage', {args = {'ChaosMod', tostring(content)}})
    end
end

RegisterNetEvent('chaosmod:client:message', message)

RegisterNetEvent('chaosmod:client:state', function(state)
    if Config.UI and Config.UI.Enabled then
        SendNUIMessage({type = 'state', state = state})
    end
end)


local function stopActive()
    local ctx = active
    if not ctx then return end
    active = nil
    ctx.active = false
    for index = #ctx.cleanups, 1, -1 do
        local ok, err = pcall(ctx.cleanups[index])
        if not ok then print(PREFIX .. 'Cleanup failed: ' .. tostring(err)) end
    end
    debugLog('Ended ' .. ctx.id)
end

local Methods = {}
Methods.__index = Methods
function Methods:cleanup(fn)
    self.cleanups[#self.cleanups + 1] = fn
end

function Methods:thread(interval, callback)
    CreateThread(function()
        while self.active do
            local ok, err = pcall(callback)
            if not ok then
                print(PREFIX .. 'Effect ' .. self.id .. ' tick failed: ' .. tostring(err))
                if active == self then stopActive() end
                return
            end
            Wait(math.max(0, interval or 0))
        end
    end)
end

function Methods:model(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local deadline = GetGameTimer() + Config.ModelLoadTimeoutMs
    while self.active and not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(50) end
    if not self.active or not HasModelLoaded(hash) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end
    self:cleanup(function() SetModelAsNoLongerNeeded(hash) end)
    return hash
end

function Methods:ptfx(name)
    RequestNamedPtfxAsset(name)
    local deadline = GetGameTimer() + Config.ModelLoadTimeoutMs
    while self.active and not HasNamedPtfxAssetLoaded(name) and GetGameTimer() < deadline do Wait(50) end
    if not self.active or not HasNamedPtfxAssetLoaded(name) then
        RemoveNamedPtfxAsset(name)
        return false
    end
    self:cleanup(function() RemoveNamedPtfxAsset(name) end)
    return true
end

function Methods:entity(entity, typeName)
    if not entity or entity == 0 then return entity end
    self.entities = self.entities + 1
    if self.entities > Config.MaxSpawnedEntities then
        if DoesEntityExist(entity) then DeleteEntity(entity) end
        return nil
    end
    self:cleanup(function()
        if not DoesEntityExist(entity) then return end
        if typeName == 'vehicle' then
            if not Config.CleanupSpawnedVehicles then return end
            for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(entity)) - 2 do
                if not IsVehicleSeatFree(entity, seat) then return end
            end
        end
        if NetworkGetEntityIsNetworked(entity) and not NetworkHasControlOfEntity(entity) then
            NetworkRequestControlOfEntity(entity)
            if not NetworkHasControlOfEntity(entity) then return end
        end
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end)
    return entity
end

function ChaosMod.register(id, callback)
    if handlers[id] then error('Duplicate client effect handler: ' .. id) end
    handlers[id] = callback
end

function ChaosMod.nearby(poolName, limit, callback)
    local center = GetEntityCoords(PlayerPedId())
    local count = 0
    for _, ent in ipairs(GetGamePool(poolName)) do
        if DoesEntityExist(ent) and #(GetEntityCoords(ent) - center) < Config.NearbyRadius then
            count = count + 1
            if count > limit then break end
            callback(ent)
        end
    end
end

function ChaosMod.playerVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
    return veh
end

function ChaosMod.playerOrVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    return veh ~= 0 and veh or ped
end

local function startEffect(id, duration, token, payload)
    local def = ChaosModEffectsById[id]
    local handler = handlers[id]
    if not def or not handler then
        print(PREFIX .. 'Missing effect: ' .. tostring(id))
        return
    end
    if type(token) ~= 'number' or token <= lastToken then return end
    lastToken = token
    stopActive()
    local ctx = setmetatable({id = id, duration = duration, data = payload or {},
        active = true, cleanups = {}, entities = 0}, Methods)
    active = ctx
    if Config.AnnounceEffects then
        message(def.name .. ' - ' .. def.description)
    end
    if Config.UI and Config.UI.Enabled then
        SendNUIMessage({type = 'announce', name = def.name, description = def.description})
    end
    local ok, err = pcall(handler, ctx)
    if not ok then
        print(PREFIX .. 'Effect ' .. id .. ' failed: ' .. tostring(err))
        stopActive()
        return
    end
    if duration <= 0 then
        stopActive()
    else
        CreateThread(function()
            Wait(duration)
            if active == ctx then stopActive() end
        end)
    end
end

RegisterNetEvent('chaosmod:client:start', startEffect)

RegisterNetEvent('chaosmod:client:stop', function()
    stopActive()
    if Config.UI and Config.UI.Enabled then
        SendNUIMessage({type = 'stop'})
    end
end)


AddEventHandler('onClientResourceStart', function(name)
    if name == GetCurrentResourceName() then
        CreateThread(function()
            Wait(500)
            if Config.UI and Config.UI.Enabled then
                SendNUIMessage({
                    type = 'setup',
                    ui = {
                        enabled = true,
                        title = Config.UI.Title,
                        accent = Config.UI.Accent,
                        widthPx = Config.UI.WidthPx,
                        topPx = Config.UI.TopPx,
                        showWhenPaused = Config.UI.ShowWhenPaused,
                        showAnnouncements = Config.UI.ShowAnnouncements,
                        announcementMs = Config.UI.AnnouncementMs,
                    }
                })
            else
                SendNUIMessage({type = 'hide'})
            end
            Wait(750)
            TriggerServerEvent('chaosmod:server:ready')
        end)
    end
end)

AddEventHandler('onClientResourceStop', function(name)
    if name == GetCurrentResourceName() then
        stopActive()
        SendNUIMessage({type = 'hide'})
    end
end)
