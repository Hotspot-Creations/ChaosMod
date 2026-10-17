local PREFIX = '^5[ChaosMod]^7 '
local enabled = Config.Enabled == true
local paused = false
local pauseAt = nil
local recent = {}
local queuedId = nil
local active = nil
local sequence = 0
local lastStartedAt = GetGameTimer()

math.randomseed(os.time())

local function log(message)
    print(PREFIX .. tostring(message))
end

local function debugLog(message)
    if Config.Debug or GetConvar('chaosmod_debug', 'false') == 'true' then
        log('DEBUG: ' .. tostring(message))
    end
end

local function reply(src, message)
    if src == 0 then
        log(message)
    else
        TriggerClientEvent('chaosmod:client:message', src, message)
    end
end

local function isAllowed(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.AdminAce)
end

local function intervalMs()
    local value = GetConvarInt('chaosmod_eventtimer', Config.IntervalMs)
    return math.max(5000, math.min(3600000, math.floor(tonumber(value) or 120000)))
end

local function playable(def)
    return def ~= nil
        and Config.DisabledEffects[def.id] ~= true
        and (not Config.LiveSafeMode or Config.LiveSafeEffects[def.id] == true)
        and (Config.AllowDestructiveEffects or not def.destructive)
        and (Config.WeatherEffects or def.category ~= 'Weather')
end

local function resolveId(requested)
    if type(requested) ~= 'string' then return nil end
    for _, def in ipairs(ChaosModEffects) do
        if def.id:lower() == requested:lower() then return def.id end
    end
    return nil
end

local function record(id)
    table.insert(recent, 1, id)
    local history = math.max(0, math.min(100, math.floor(tonumber(Config.RecentHistory) or 5)))
    while #recent > history do table.remove(recent) end
end

local function candidates()
    local available, fresh = {}, {}
    local players = GetPlayers()
    for _, def in ipairs(ChaosModEffects) do
        if playable(def) and (def.id ~= 'playerSwap' or #players >= 2) then
            available[#available + 1] = def.id
            local previouslyUsed = false
            for _, previous in ipairs(recent) do
                if previous == def.id then previouslyUsed = true break end
            end
            if not previouslyUsed then fresh[#fresh + 1] = def.id end
        end
    end
    return #fresh > 0 and fresh or available
end

local function swapDestinations(players)
    local origins, playerIds, destinations = {}, {}, {}
    for _, id in ipairs(players) do
        local src = tonumber(id)
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            local p = GetEntityCoords(ped)
            origins[src] = {x = p.x, y = p.y, z = p.z}
            playerIds[#playerIds + 1] = src
        end
    end
    for i = #playerIds, 2, -1 do
        local j = math.random(i)
        playerIds[i], playerIds[j] = playerIds[j], playerIds[i]
    end
    for i = 1, #playerIds - 1, 2 do
        local a, b = playerIds[i], playerIds[i + 1]
        destinations[a], destinations[b] = origins[b], origins[a]
    end
    return destinations
end

local function effectiveNow()
    return paused and pauseAt or GetGameTimer()
end

local function snapshot()
    local now = GetGameTimer()
    local nextIn = math.max(0, intervalMs() - (effectiveNow() - lastStartedAt))
    local current = nil
    if active and active.endsAt and active.endsAt > now then
        local def = ChaosModEffectsById[active.id]
        current = {
            id = active.id,
            name = def and def.name or active.id,
            description = def and def.description or '',
            remainingMs = active.endsAt - now,
            durationMs = active.duration,
            token = active.token,
        }
    end
    return {
        enabled = enabled,
        paused = paused,
        intervalMs = intervalMs(),
        untilNextMs = nextIn,
        active = current,
        queued = queuedId ~= nil,
    }
end

local function sync(target)
    TriggerClientEvent('chaosmod:client:state', target, snapshot())
end

local function stopActive()
    if not active then return end
    active = nil
    TriggerClientEvent('chaosmod:client:stop', -1)
end

local function startEffect(id)
    local def = ChaosModEffectsById[id]
    if not playable(def) then return false, 'Unknown or disabled effect.' end
    local players = GetPlayers()
    if #players == 0 and Config.SkipWhenEmpty then return false, 'No online players.' end
    if id == 'playerSwap' and #players < 2 then return false, 'Swap requires two players.' end

    stopActive()
    local duration = def.duration
    if duration == nil then duration = Config.EffectDurationMs end
    duration = math.max(0, math.min(120000, math.floor(tonumber(duration) or 12000)))
    local now = GetGameTimer()
    sequence = sequence + 1
    if duration > 0 then
        active = {id = id, token = sequence, duration = duration, endsAt = now + duration}
    end
    lastStartedAt = now
    if paused then pauseAt = now end
    local destinations = id == 'playerSwap' and swapDestinations(players) or {}
    log(('Triggered %s (%s) for %d player(s).'):format(def.name, id, #players))

    for _, playerId in ipairs(players) do
        local src = tonumber(playerId)
        TriggerClientEvent('chaosmod:client:start', src, id, duration, sequence,
            {destination = destinations[src]})
    end
    record(id)
    sync(-1)
    return true
end

local function queueRandom()
    if queuedId then
        local nextId = queuedId
        queuedId = nil
        local ok = startEffect(nextId)
        if ok then return end
    end
    local possible = candidates()
    if #possible == 0 then
        debugLog('No effects allowed. Check Config.LiveSafeEffects / DisabledEffects.')
        return
    end
    startEffect(possible[math.random(#possible)])
end

local function listEffects(src)
    local ids = {}
    for _, def in ipairs(ChaosModEffects) do
        if playable(def) then ids[#ids + 1] = def.id end
    end
    reply(src, ('%d effects enabled:'):format(#ids))
    for i = 1, #ids, 7 do
        local part = {}
        for j = i, math.min(#ids, i + 6) do part[#part + 1] = ids[j] end
        reply(src, table.concat(part, ', '))
    end
end

local function command(src, args)
    if not isAllowed(src) then
        reply(src, 'Permission denied. Required ACE: ' .. Config.AdminAce)
        return
    end
    local sub = tostring(args[1] or 'help'):lower()
    if sub == 'list' then
        listEffects(src)
    elseif sub == 'next' or sub == 'force' then
        local id = resolveId(args[2])
        if not playable(id and ChaosModEffectsById[id]) then
            reply(src, 'Unknown or disabled ID. Run /chaos list.')
            return
        end
        if sub == 'next' then
            queuedId = id
            reply(src, id .. ' is queued for the next automatic event.')
            sync(-1)
        else
            local ok, reason = startEffect(id)
            reply(src, ok and (id .. ' triggered server-wide.') or reason)
        end
    elseif sub == 'pause' then
        if not paused then
            paused = true
            pauseAt = GetGameTimer()
        end
        reply(src, 'Automatic timer paused; active effect finishes normally.')
        sync(-1)
    elseif sub == 'resume' then
        if paused then
            lastStartedAt = lastStartedAt + (GetGameTimer() - pauseAt)
            paused = false
            pauseAt = nil
        end
        reply(src, 'Automatic timer resumed.')
        sync(-1)
    elseif sub == 'stop' then
        stopActive()
        reply(src, 'Current effect stopped for all players.')
        sync(-1)
    elseif sub == 'on' then
        enabled = true
        paused = false
        pauseAt = nil
        lastStartedAt = GetGameTimer()
        reply(src, 'Automatic chaos enabled; countdown restarted.')
        sync(-1)
    elseif sub == 'off' then
        enabled = false
        paused = false
        pauseAt = nil
        queuedId = nil
        stopActive()
        reply(src, 'Automatic chaos OFF; any current effect stopped.')
        sync(-1)
    elseif sub == 'status' then
        local s = snapshot()
        reply(src, ('enabled=%s paused=%s interval=%dms next=%dms active=%s queued=%s'):format(
            tostring(enabled), tostring(paused), s.intervalMs, s.untilNextMs,
            s.active and s.active.id or 'none', queuedId or 'none'))
    else
        reply(src, '/chaos list | force <id> | next <id> | pause | resume | stop | status | on | off')
    end
end

RegisterCommand('chaos', command, false)
RegisterCommand('ChaosMod:ForceNext', function(src, args)
    command(src, {'next', args[1]})
end, false)

-- Join/reload sync: joining players receive the active, *timed* effect only.
-- No server event accepts a client-selected effect ID.
RegisterNetEvent('chaosmod:server:ready', function()
    local src = source
    sync(src)
    if active and active.endsAt > GetGameTimer() then
        if active.id ~= 'playerSwap' then
            TriggerClientEvent('chaosmod:client:start', src, active.id,
                active.endsAt - GetGameTimer(), active.token, {})
        end
    end
end)

CreateThread(function()
    local syncAt = 0
    log(('HSC_ChaosMod v1.0.0 live edition ready (%d effects registered).'):format(#ChaosModEffects))
    while true do
        Wait(500)
        local now = GetGameTimer()
        local players = GetPlayers()
        if active and active.endsAt <= now then
            active = nil
            sync(-1)
        end
        if enabled and not paused and (not Config.SkipWhenEmpty or #players > 0) then
            if now - lastStartedAt >= intervalMs() then
                lastStartedAt = now
                queueRandom()
            end
        elseif Config.SkipWhenEmpty and #players == 0 and enabled and not paused then
            lastStartedAt = now
        end
        local refreshMs = math.max(1000, math.floor(tonumber(Config.UI.RefreshMs) or 5000))
        if now >= syncAt then
            if #players > 0 then sync(-1) end
            syncAt = now + refreshMs
        end
    end
end)
