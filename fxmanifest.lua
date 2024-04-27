fx_version 'cerulean'
game 'gta5'

author 'Atiya'
description 'Locker Confiscation System'
version '2.0.4'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua'
}
client_script 'client/*.lua'
server_script 'server/*.lua'

dependencies {
    'yarn',
  }

  lua54 'yes'
