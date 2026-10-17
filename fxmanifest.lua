fx_version 'cerulean'
game 'gta5'

author 'Hotspot Creations'
description 'Standalone FiveM ChaosMod with live-safe mode and synchronized countdown HUD'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

shared_scripts {
    'config.lua',
    'shared/effects.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/effects_player.lua',
    'client/effects_vehicle.lua',
    'client/effects_misc.lua'
}
