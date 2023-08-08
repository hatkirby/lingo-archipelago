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

## Running from source

The randomizer is almost ready to run from source. The only step that is required is to compile the LL1.yaml datafile into gamedata.gd, which needs to be played in the Archipelago folder. The generate_gamedata.rb script in the util folder can do this for you. The first argument is the path to the datafile, and the second argument is the path to the output file.

## Features

There are a couple of modes of randomization currently available, and you can pick and choose which ones you would like to use.

- **Door shuffle**: There are many doors in the game, which are opened by completing a set of panels. With door shuffle on, the doors become items and only open up once you receive the corresponding item. The panel sets that would ordinarily open the doors become locations.
- **Color shuffle**: There are ten different colours of puzzle in the game, each representing a different mechanic. With color shuffle on, you would start with only access to white puzzles. Puzzles of other colours will require you to receive an item in order to solve them (e.g. you can't solve any red puzzles until you receive the "Red" item).
- **Panel shuffle**: Panel shuffling replaces the puzzles on each panel with different ones. So far, the only mode of panel shuffling is "rearrange" mode, which simply shuffles the already-existing puzzles from the base game onto different panels.
- **Painting shuffle**: This randomizes the appearance of the paintings in the game, as well as which of them are warps, and the locations that they warp you to. It is the equivalent of an entrance randomizer in another game.

## Frequently Asked Questions

### What are location checks in this game?

Puzzle sets that ordinarily open doors in the base game are almost always location checks, even if you do not have door shuffle on. Achievement panels (ones starting with "THE", including "THE END") are also checks. There are also a few other panels that are location checks:

- THE EYES / THEY SEE in Crossroads
- HIDE / SEEK (x4) in Hedge Maze
- OUT / OUT in the Wheelbarrow Hallway
- UNDISTRACTED / UNDISTRACTED in the Wheelbarrow Hallway
- CLOCKWISE / COUNTERCLOCKWISE in the Welcome Back Area
- RAINY / RAINBOW in the rainbow room next to The Undeterred (blue room)
- PARANOID / PARANOID in the Directional Gallery
- WADED + WEE / WARTS in the Directional Gallery
- YOU / \[your name\] in Champion's Rest

These may change in the future.

**Note**: In the second room, you ordinarily only have to solve HI / HIGH to open the door. This is modified in the randomizer so that you have to solve both puzzles to receive a location check.

LEVEL 2 (the panel that unlocks Level 2) is a check. If Level 2 is selected as your victory condition, you will be required to solve the provided number of puzzles before you can get access to the LEVEL 2 panel. If Level 2 is not your victory condition, the LEVEL 2 room is automatically available as soon as you reach Second Room.

### Is my progress saved locally?

Lingo autosaves your progress every time you solve a puzzle. The randomizer generates a savefile name based on your Multiworld seed and slot number, so you should be able to seamlessly switch between multiworlds and even slots within a multiworld.

The exception to this is different rooms created from the same multiworld seed. The client is unable to tell rooms in a seed apart (this is a limitation of the Archipelago API), so the client will use the same save file for the same slot in different rooms on the same seed. You can work around this by manually moving or removing the save file from the level1 save file directory.

If you play the base game again, you will see one or more save files with a long name that begins with "zzAP_". These are the saves for your multiworlds. They can be safely deleted after you have completed the associated multiworld. It is not recommended to load these save files outside of the randomizer.

A connection to Archipelago is required to resume playing a multiworld. This is because the set of items you have received is not stored locally. This may be changed in the future.

### How do I solve the YOU puzzle in Champion's Rest?

The solution to this puzzle is set to your slot name.

### What about wall snipes?

"Wall sniping" refers to the fact that you are able to solve puzzles on the other side of opaque walls. This randomizer
does not change how wall snipes work, but it will never require the use of them. There are three puzzles from the base
game that you would ordinarily be expected to wall snipe. The randomizer moves these panels out of the wall or otherwise
reveals them so that a snipe is not necessary.

Because of this, all wall snipes are considered out of logic. This includes sniping The Bearer's MIDDLE while standing
outside The Bold, sniping The Colorful without opening all of the color doors, and sniping WELCOME from next to WELCOME
BACK.

### What about the pilgrimage?

The intended method of reaching the Pilgrim Room in the base game is known as "doing a pilgrimage". It involves entering
each sunwarp in order without using any non-painting warps in between. This is difficult to map out properly in AP logic,
so we only consider one specific path through the map to be the canonical pilgrimage route. Accessing the Pilgrim Room by
pilgrimage is only in logic if this specific route is available to you:

* From the Starting Room, proceed through the Second Room and into the Hub Room. Enter the first sunwarp.
* From the Crossroads, use the front tower entrance (the one nearest The Discerning; not the one next to Sword/Words). Go
  through the Hot Crusts Door and enter the second sunwarp.
* Enter the third sunwarp immediately after.
* Proceed past The Initiated and through the shortcut door back to the Hub Room. Go through the shortcut door to the
  tower's first floor and enter the fourth sunwarp.
* Use the shortcut to the Directional Gallery (the one outside The Undeterred; not the one further down the hallway where
  the Number Hunt is), pass through the Salt Pepper Door, and return to the Hub Room. Use the nearby entrance to the
  Crossroads and proceed to the fifth sunwarp.
* Use the door that takes you to The Steady, and then the one that takes you to The Bearer, and then the one that takes you
  to The Initiated. Return to the Hub Room once more, and enter The Tenacious via the shortcut that opens upon solving the
  palindromes. Use the top-right door to access the area Outside the Agreeable, and enter the final sunwarp.

This route can be seen [starting at 2:47 in this video](https://youtu.be/8GfuDRRswdA?t=167). Note that this will almost
never be required if door shuffle is enabled, as one of the other entrances to the room will usually be available sooner.
