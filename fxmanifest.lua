fx_version 'cerulean'
game 'gta5'

lua54 'yes'

description 'Core Scoreboard'
author 'ChrisNewmanDev'
version '1.0.0'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/img/server-logo.png',
}

dependency '/assetpacks'