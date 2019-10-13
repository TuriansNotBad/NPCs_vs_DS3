# NPCs vs DS3
My attempt at creating custom npcs capable of beating some parts of dark souls 3.

Emevd scripts are edited to make sure triggers happen based on the NPC instead of the player entity, selecting specific targets for the NPC (something which is unfortunately not available in the lua scripts), also used to listen for TAE events which I use to communicate everything about the attack timings.
Lua scripts contain all of the AI decision making logic.
Msb edits add waypoints for the AI.
