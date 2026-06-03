fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'BLDR'
description 'Underground Street Racing System'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}
client_scripts {
    'client/nui.lua',
    'client/radio.lua',
    'client/main.lua',
    'client/race.lua',
    'client/police.lua'
}
server_scripts { 'server/*.lua' }

ui_page 'web/dist/index.html'
files { 'web/dist/**/*' }

dependencies { 'ox_lib' }
