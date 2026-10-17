Config = {}

-- LIVE SERVER DEFAULTS. Events affect every connected player (no opt-in).
Config.Enabled = true
Config.IntervalMs = 120000            -- One global effect every 2 minutes (starts-to-starts)
Config.EffectDurationMs = 30000      -- Timed effects last 30 seconds
Config.SkipWhenEmpty = true
Config.RecentHistory = 5
Config.AdminAce = 'chaosmod.admin'
Config.Debug = false

-- LiveSafeMode uses ONLY the IDs listed below for both random and manual triggers.
-- Set false to use the full catalog, subject to the remaining safety filters.
-- These are visual/audio effects; no weapons, teleporting, damage or driving interference.
Config.LiveSafeMode = false
Config.LiveSafeEffects = {
    miscFireworks = true,
    miscNightVision = true,
    miscHeatVision = true,
    miscBlackout = true,
    miscPortraitMode = true,
    miscIntenseMusic = true,
}
Config.AllowDestructiveEffects = true
Config.WeatherEffects = false        -- Keep your existing vSync/qb-weathersync in control
Config.DisabledEffects = {           -- Further remove IDs from rotation AND admin force
    -- ['miscDVD'] = true,
}

-- Resource/performance caps (primarily for advanced/full-catalog mode)
Config.MaxNearbyVehicles = 12
Config.MaxNearbyPeds = 12
Config.NearbyRadius = 70.0
Config.MaxSpawnedEntities = 5
Config.ModelLoadTimeoutMs = 4000
Config.CleanupSpawnedVehicles = true

-- Announcements
Config.AnnounceEffects = false        -- Native GTA feed; disabled because the overlay announces effects
Config.UseChatMessages = false       -- Requires a running 'chat' resource

-- Compact, non-interactive countdown at the top of every player's screen.
-- UI is 100% local NUI (HTML/CSS/JS); no framework dependency or mouse focus.
Config.UI = {
    Enabled = true,
    Title = 'CHAOS MODE',
    Accent = '#ef4444',
    WidthPx = 420,
    TopPx = 24,
    ShowAnnouncements = true,        -- Brief effect card when an effect begins
    AnnouncementMs = 4200,
    ShowWhenPaused = true,           -- False hides the widget when paused or disabled
    RefreshMs = 5000,               -- Server state resync interval (min 1000)
}
