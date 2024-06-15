
# Confiscation Locker for QBCore - FiveM

* Made by Atiya

* Discord: atiya.

* Github: [MAtiyaaa](https://github.com/MAtiyaaa)

* [Join the Discord](https://discord.gg/GyeRexYR35)
  

# Description

> Simple drag-and-drop

> Police don't have to get spammed with 911 calls anymore. The police can simply open the player's locker and place their items in there.

> Auto-confiscation for jail or hospital check-ins, certain items specified in config will be removed from their inventory and placed in their locker. [Optional]

> A police officer can use the command or input menu to store the items of a player in a locker and can use another command to lock and unlock the locker for a certain period of time.

> The player can go receive their items at the location you choose in the config, after the specified period in the lock command (if used)

> QB-Inventory compatibility added by iOx

> Formerly known as `qb-policelockers`

  

# Dependencies

* [QBCore](https://github.com/qbcore-framework)

* [ox_lib by oxerextended](https://github.com/overextended/ox_lib)

* [oxmysql by overextended](https://github.com/overextended/oxmysql) (Only If you're using qb-inventory AND plan on using the auto-confiscation feature)

* [QB-Inventory](https://github.com/qbcore-framework/qb-inventory)

*  **OR**

* [ox_inventory by overextended](https://github.com/overextended/ox_inventory)

* BELOW IS OPTIONAL, SET CONFIG TO **3D TEXT** IF YOU ARE NOT USING EITHER ONE

* [QB-Target](https://github.com/qbcore-framework/qb-target)

*  **OR**

* [OX_Target by overextended](https://github.com/overextended/ox_target)

  

# Installation

* Literally a drag and drop but this is for those who aren't as familiar.

* Add `qb-confiscation` to your resources folder

* Ensure `qb-confiscation`, or the folder it's in

* Enjoy!

  

# Optional Installation

* This is for if you want auto-confiscation and for items to go into the locker after going to jail or the hospital.

  

* For [QB-Ambulancejob](https://github.com/qbcore-framework/qb-ambulancejob)

* Open `main.lua` in the server folder of `qb-ambulancejob`

* Find `RegisterNetEvent('hospital:server:SendToBed', function(bedId, isRevive)`

* Add `TriggerEvent('qb-confiscation:confiscateItems', src)` at the end

  

* For [QB-Policejob](https://github.com/qbcore-framework/qb-policejob)

* Open `main.lua` in the server folder of `qb-policejob`

* Find `RegisterNetEvent('police:server:JailPlayer', function(playerId, time)`

* Add `TriggerEvent('qb-confiscation:confiscateItems', playerId)` directly before `TriggerClientEvent('police:client:SendToJail', OtherPlayer.PlayerData.source, time)`
