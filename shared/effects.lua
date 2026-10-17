-- Register effects in a deterministic order. IDs match The-Neco/ChaosMod where possible.
ChaosModEffects = {}
ChaosModEffectsById = {}
local function add(id, name, description, category, destructive, duration)
    assert(not ChaosModEffectsById[id], 'Duplicate effect: ' .. id)
    local item = {id = id, name = name, description = description,
        category = category, destructive = destructive or false, duration = duration}
    ChaosModEffects[#ChaosModEffects + 1] = item
    ChaosModEffectsById[id] = item
end

-- Players
add('clonePlayer', 'Clone Player', 'A suspicious twin appears', 'Player', true)
add('playerDrunk', 'Drunk', 'Your movement becomes unsteady', 'Player')
add('flipCamera', 'Turtle Mode', 'Your camera flips upside-down', 'Player')
add('playerGiveWeapons', 'Give Weapons', 'You get a wild collection of weapons', 'Player', true)
add('playerGravity', 'Low Gravity', 'Gravity takes a break', 'Player')
add('playerHealAndArmour', 'Health + Armour', 'Full health and armour', 'Player')
add('playerIgnite', 'Ignite Player', 'Time to feel the heat', 'Player', true)
add('playerKeepWalking', 'Stuck W Key', 'You cannot stop moving forward', 'Player')
add('playerLaunchUp', 'Launch Up', 'The sky is the limit', 'Player', true)
add('playerPoof', 'Deadly Aim', 'Targets explode under your aim', 'Player', true)
add('playerSwap', 'Swap Positions', 'Players exchange locations', 'Player', true, 0)
add('teleportLSIA', 'TP LSIA', 'Trip to the airport', 'Player', true, 0)
add('teleportMaze', 'TP Maze Tower', 'Enjoy the view', 'Player', true, 0)
add('teleportFort', 'TP Fort Zancudo', 'Welcome to the base', 'Player', true, 0)
add('teleportChilliad', 'TP Mount Chiliad', 'Up the mountain', 'Player', true, 0)
add('teleportSky', 'TP Heaven', 'Going up', 'Player', true, 0)
add('teleportFake', 'Fake TP', 'Where did everybody go?', 'Player', true, 7000)
add('fiveStars', 'Five Stars', 'Maximum wanted level', 'Player', true, 0)
add('addTwoStars', '+2 Stars', 'More police attention', 'Player', true, 0)
add('neverWanted', 'Never Wanted', 'Your wanted level disappears', 'Player')
-- Vehicles
add('vehicle30Max', '30 MPH Limit', 'Try to drive faster now', 'Vehicles')
add('vehicleBreakDoors', 'Break Doors', 'Vehicle doors fall off', 'Vehicles', true, 0)
add('popVehicleTyres', 'Burst Tyres', 'All your tyres give up', 'Vehicles', true, 0)
add('vehicleCinematicCam', 'Cinematic Camera', 'Hollywood driving experience', 'Vehicles')
for _, spec in ipairs({
    {'goldenTraffic', 'Golden Traffic'}, {'greenTraffic', 'Green Traffic'},
    {'orangeTraffic', 'Orange Traffic'}, {'chromeTraffic', 'Chrome Traffic'},
    {'redTraffic', 'Red Traffic'},
}) do add(spec[1], spec[2], 'Traffic changes colour', 'Vehicles') end
for _, spec in ipairs({
    {'spawnAdder', 'Spawn Adder'}, {'spawnBus', 'Spawn Bus'},
    {'spawnTug', 'Spawn Tug'}, {'spawnLuxor', 'Spawn Luxor'},
}) do add(spec[1], spec[2], 'A surprise vehicle arrives', 'Vehicles', true, 20000) end
-- Miscellaneous
add('miscAirstrike', 'Airstrike', 'Take cover', 'Misc', true)
add('miscBlackout', 'Blackout', 'The lights go out', 'Misc')
add('miscDVD', 'DVD Screensaver', 'A bouncing screen effect', 'Misc')
add('miscEarthquake', 'Earthquake', 'Hold on to something', 'Misc', true)
add('miscFireworks', 'Fireworks', 'Sky full of colour', 'Misc')
add('miscForceFP', 'Forced First Person', 'The camera is stuck in first person', 'Misc')
add('miscGetTowed', 'Get Towed', 'An unexpected tow truck appears', 'Misc', true, 12000)
add('miscHeatVision', 'Heat Vision', 'Thermal vision activates', 'Misc')
add('miscIntenseMusic', 'Intense Music', 'The stakes just increased', 'Misc')
add('miscInvertVelocity', 'Invert Velocity', 'Reverse momentum', 'Misc', true, 0)
add('miscLowPoly', 'Low Render Distance', 'Potato graphics activated', 'Misc')
add('miscMeteorRain', 'Meteor Rain', 'Look up', 'Misc', true)
add('miscMidasTouch', 'Midas Touch', 'Turn vehicles gold', 'Misc')
add('miscNightVision', 'Night Vision', 'Lights out, goggles on', 'Misc')
add('miscNoHUD', 'No HUD', 'Your HUD disappears', 'Misc')
add('miscNoRadar', 'No Radar', 'Your minimap disappears', 'Misc')
add('miscOilLeak', 'Oil Leak', 'Your car has sprung a leak', 'Misc')
add('miscOneBullet', 'One Shot', 'Only one bullet per magazine', 'Misc')
add('miscOrangeBall', 'Orange Ball', 'Something rolls into your path', 'Misc', true, 7000)
add('miscPause', 'Pause Game', 'An unexpected pause', 'Misc', false, 1000)
add('miscPortraitMode', 'Portrait Mode', 'Cinema in portrait', 'Misc')
add('miscPwned', 'PWNED', 'A cryptic screen takes over', 'Misc')
add('miscRollCredits', 'Roll Credits', 'And that is a wrap', 'Misc', false, 12000)
add('miscSuperStunt', 'Super Stunt', 'A stunt ramp appears', 'Misc', true, 12000)
add('miscTotalChaos', 'Total Chaos', 'Anything can happen', 'Misc', true)
add('miscUTurn', 'U-Turn', 'Everybody turns around', 'Misc', true, 0)
for _, spec in ipairs({
    {'weatherExtraSunny', 'Extra Sunny'}, {'weatherThunder', 'Thunder'},
    {'weatherFoggy', 'Foggy'}, {'weatherNeutral', 'Neutral'},
    {'weatherXMAS', 'XMAS'}, {'weatherRandom', 'Random Weather'},
}) do add(spec[1], spec[2], 'Temporary weather change', 'Weather') end
add('miscWhaleRain', 'Whale Rain', 'Whales are falling out of the sky', 'Misc', true)
add('miscXMarksTheSpot', 'X Marks the Spot', 'Return to where you started', 'Misc', true, 10000)
