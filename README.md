# Lingo Archipelago Client
[Archipelago](https://archipelago.gg/) is an open-source project that supports randomizing a number of different games and combining them into one cooperative experience. Items from each game are hidden in other games. For more information about Archipelago, you can look at their website.

This is a project that modifies the game [Lingo](https://lingothegame.com/) so that it can be played as part of an Archipelago multiworld game.

## Installation

1. Download the Lingo Archipelago Randomizer from [the releases page](https://github.com/hatkirby/lingo-archipelago/releases).
2. Open up Lingo, go to settings, and click View Game Data. This should open up a folder in Windows Explorer.
3. Unzip the contents of the randomizer into the "maps" folder.
4. Installation complete! You may have to click Return to go back to the main menu and then click Settings again in
   order to get the randomizer to show up in the level selection list.

## Joining a Multiworld game

1. Launch Lingo
2. Click on Settings, and then Level. Choose Archipelago from the list.
3. Start a new game. Leave the name field blank (anything you type in will be ignored).
4. Enter the Archipelago address, slot name, and password into the fields.
5. Press Connect.
6. Enjoy!

To continue an earlier game, you can perform the exact same steps as above. You do not have to re-select Archipelago in
the level selection screen if you were using Archipelago the last time you launched the game.

In order to play the base game again, simply return to the level selection screen and choose Level 1 (or whatever else
you want to play). The randomizer will not affect gameplay unless you launch it by starting a new game while it is
selected in the level selection screen, so it is safe to play the game normally while the client is installed.

**Note**: Running the randomizer modifies the game's memory. If you want to play the base game after playing the randomizer,
you need to restart Lingo first.

## Running fron source

The randomizer is almost ready to run from source. The only step that is required is to compile the LL1.yaml datafile into gamedata.gd, which needs to be played in the Archipelago folder. The generate_gamedata.rb script in the util folder can do this for you. The first argument is the path to the datafile, and the second argument is the path to the output file.
