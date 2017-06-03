# Extended Speed Meter Plugin

This is a sourcemod plugin that tracks the maximum velocity on different maps. [Forum link](https://forums.alliedmods.net/showthread.php?t=270630)

# About

This plugin will display the current speed of the player in the HUD text. Players can then see the highest speeds in the current game with a command. When the map changes this plugin will save all those highest speeds. Players will be able to view the highest speeds ever achieved on the current map with a command. Also players will be able to view the highest speeds ever achieved on all maps on the server. Finally players are able to view all their personal speedrecords and ranks on all maps. Admins are able to manage the speedrecords (reset/delete). Players can also use a help menu to find more information about the commands.

This plugin can compile without errors or warnings in my environment. However it does not compile through the forum since it needs SMLib and Colors.

This plugin is a copy of the original [Advanced Speed Meter](https://forums.alliedmods.net/showthread.php?t=143765) with added functionality, more convars, cleaner code (imo), translations and more future-proof (removed the warnings that the original approved plugin displays). It's also active.

I made this plugin because I wanted a server that I play on to keep track of my speedrecords. After finding out that the original plugin was inactive, I started exploring the great Sourcemod community. Since I'm a developper I could easily find out how everything worked and started building upon the original plugin. I worked about 6 days on this plugin, tested it and released it. After a week of having this plugin on the server that I play on, I fixed a few bugs and added a few features. I don't think there's more that can be added to this plugin so version 1.3 is a stable final version for now. Feel free to leave feedback and suggestions.

# Feature list

* Display current speed in HUD
* View all current speedrecords of the current players on the current map
* View all speedrecords on the current map (with an optional menu to view details of the records)
* View all speedrecords on all maps (with an optional menu to view details of the records)
* View your personal speedrecords and ranks on all maps, in a menu
* Help menu with information on the commands
* Help message every 4 minutes (can be changed/disabled in cfg)
* Admin menu to manage (reset/delete) speedrecords
* Optional integration in the sourcemod !admin menu

* Lots of customisation
* All text in translations
* Translations in Danish, Dutch, English, French and German (thanks to TaiwananCat, PG24 and Phatso)

# CVAR/Command list

**CVARS**

```
// This sets how many records should be printed in chat
// Default: "3"
sm_extendedspeedmeter_amountofprintedrecords "3"

// This sets how many records should be shown in the topspeedmap menu (0: unlimited)
// Default: "0"
sm_extendedspeedmeter_amountofrecordsintopspe edmap "0"

// This sets how many records should be shown in the topspeedtop menu
// Default: "10"
sm_extendedspeedmeter_amountofrecordsintopspe edtop "10"

// This sets per how many seconds an info message for help should be printed in chat (0: disabled)
// Default: "240"
sm_extendedspeedmeter_amountofsecondsinfohelp printinterval "240"

// Check if the hint sound is precached? (enabling this will make this plugin try to stop the UI/hint.wav, a spamming sound that notifies a player that a hint is displayed) This plugin will enable this automatically for TF2 and CSS. If the game doesn't supp
// Default: "0" Minimum: "0.000000" Maximum: "1.000000"
sm_extendedspeedmeter_checksoundprecache "0"

// This sets which database config should be used to store the topspeed table in (check addons/sourcemod/configs/databases.cfg)
// Default: "default"
sm_extendedspeedmeter_databaseconfigname "default"

// Enables or Disables <pluginname> (1=Enable|0=Disable)
// Default: "1" Minimum: "0.000000"
sm_extendedspeedmeter_enable "1"

// Display the highest topspeeds of the current game at the end of the game?
// Default: "1" Minimum: "0.000000" Maximum: "1.000000"
sm_extendedspeedmeter_showgametopspeeds "1"

// Display a message when the highest topspeed of the current map is beaten? (automatically disabled for new clients for spam reasons with new maps)
// Default: "1" Minimum: "0.000000" Maximum: "1.000000"
sm_extendedspeedmeter_shownewtopspeedmapmessa ge "1"

// Display the highest topspeeds of the current round at the end of the round?
// Default: "1" Minimum: "0.000000" Maximum: "1.000000"
sm_extendedspeedmeter_showroundtopspeeds "1"

// Display a menu to view all the highest topspeeds of the current map?
// Default: "1" Minimum: "0.000000" Maximum: "1.000000"
sm_extendedspeedmeter_showtopspeedmapmenu "1"

// Display a menu to view all the highest topspeeds across all maps?
// Default: "1" Minimum: "0.000000" Maximum: "1.000000"
sm_extendedspeedmeter_showtopspeedtopmenu "1"

// Should spectators be able to see the speed of the one they are spectating?
// Default: "1" Minimum: "0.000000" Maximum: "1.000000"
sm_extendedspeedmeter_showtospecs "1"

// Display topspeeds with the value 0?
// Default: "0" Minimum: "0.000000" Maximum: "1.000000"
sm_extendedspeedmeter_showzerotopspeeds "0"

// This sets how often the display is redrawn (this is the display tick rate).
// Default: "0.2"
sm_extendedspeedmeter_tick "0.2"

// Unit of measurement of speed (0=kilometers per hour, 1=miles per hour, 2=units per second, 3=meters per second)
// Default: "0" Minimum: "0.000000" Maximum: "3.000000"
sm_extendedspeedmeter_unit "0"
```

**Commands**

* !topspeed / !topspeeds - View all speedrecords of the current players on the current map
* !topspeedmap - View the highest speedrecords of all players on the current map
* !topspeedtop - View the highest speedrecords of all players on all maps
* !topspeedpr - View your highest speedrecords and rankings on all maps
* !topspeedhelp - View a menu containing the above information

**Admin Commands**
* !listtopspeed - Dumps all current speedrecords information of the current players in the console
* !topspeedadmin - View the admin menu for this plugin
* !admin > Speed meter Commands - View the admin menu for this plugin
* !topspeedreset - View the menu to reset a speedrecord
* !topspeedresetall - Reset all current speedrecords
* !topspeeddelete - View the menu to delete a previous speedrecord on this map
* !topspeeddeleteall - Delete all previous speedrecords on this map
* !topspeeddeletedifferent - View the menu to delete a previous speedrecord on a different map
* !topspeeddeletedifferentall - View the menu to delete all previous speedrecords on a different map

# Installation instructions

* Extract .zip in your mod folder.
* The cfg file in cfg/sourcemod will automatically be created and adjusted for the current game.
* Make sure the "default" database is set up in /addons/sourcemod/configs/databases.cfg (the database string can be changed in the cfg file)

# Dependencies

* [SMLib](https://forums.alliedmods.net/showthread.php?t=148387) (included in .zip)
* [Colors](https://forums.alliedmods.net/showthread.php?t=96831) (included in .zip)
* Sourcemod 1.6.2+
* Sourcemod Admin menu (optional)

# Verified working games

* Counter Strike: Source
* Counter Strike: Global Offensive
* Day of Defeat: Source
* Half-Life 2: Deathmatch
* Left 4 Dead 2
* Team Fortress 2

# Possible problems

* "SV_StartSound: UI/hint.wav not precached (0)" errors in TF2 or CS:S, set sm_extendedspeedmeter_checksoundprecache to 0 in the cfg file.
* Spamming hint sounds in TF2 or CS:S, use "sv_hudhint_sound 0". Please comment if you're having problems in a different game.

