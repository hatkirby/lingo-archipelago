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
- OUT / OUT in the Wheelbarrow Hallway
- UNDISTRACTED / UNDISTRACTED in the Wheelbarrow Hallway
- CLOCKWISE / COUNTERCLOCKWISE in the Welcome Back Area
- RAINY / RAINBOW in the rainbow room next to The Undeterred (blue room)
- PARANOID / PARANOID in the Directional Gallery
- WADED + WEE / WARTS in the Directional Gallery
- YOU / \[your name\] in Champion's Rest

These may change in the future.

**Note**: In the second room, you ordinarily only have to solve HI / HIGH to open the door. This is modified in the randomizer so that you have to solve both puzzles to receive a location check.

### Is my progress saved locally?

Lingo autosaves your progress every time you solve a puzzle. The randomizer generates a savefile name based on your Multiworld seed and slot number, so you should be able to seamlessly switch between multiworlds and even slots within a multiworld.

If you play the base game again, you will see one or more save files with a long name that begins with "zzAP_". These are the saves for your multiworlds. They can be safely deleted after you have completed the associated multiworld. It is not recommended to load these save files outside of the randomizer.

A connection to Archipelago is required to resume playing a multiworld. This is because the set of items you have received is not stored locally. This may be changed in the future.

### How do I solve the YOU puzzle in Champion's Rest?

The solution to this puzzle is set to your slot name.

### What about wall snipes?

"Wall sniping" refers to the fact that you are able to solve puzzles on the other side of opaque walls. This feature is
not affected by randomization, but you are almost never required to perform a wall snipe. The exceptions to this are:

* In the Courtyard, there is a row of four puzzles that say FIRST, SECOND, THIRD, and FOURTH. FOURTH is behind an opaque
  wall, but its existence can be inferred from the others. Solving this puzzle while standing in the Courtyard is in
  logic.
    * As an aside, this snipe is different from the others in that it is possible to see the face of the panel by going
      through the nearby door (if it is open), entering the area from the roof, or entering the area through a painting
      using painting shuffle. Solving the panel in either of those ways is not in logic (particularly in the painting
      shuffle case, where you may not have access to the Courtyard itself).
* In the maze outside The Lab, there is a hidden OPEN puzzle within a wall that ordinarily opens the entrance to lab.
  Its existence can be inferred from the nearby black puzzles with the solutions "OPEN" and "BEHIND". Solving this
  puzzle while standing in the OPEN BEHIND room is in logic.
* In the hallway outside The Undeterred (blue room), there is a row of doors that reveal numbered puzzles. These puzzles
  number from one to nine. There is also a zero puzzle hidden behind a wall. Its existence can be inferred from the
  presence of the other numbers. ZERO is actually behind both a black wall and a white door. The white door opens after
  all of the NINEs have been collected (or upon receiving the appropriate item, in door shuffle mode), revealing the
  black wall. Solving the ZERO puzzle through the black wall is in logic, but solving it while the white door is still
  present is not in logic.

Any other snipe is considered out of logic. This includes sniping The Bearer's MIDDLE while standing outside The Bold,
sniping The Colorful without opening all of the color doors, and sniping WELCOME from next to WELCOME BACK.

Because these puzzles are invisible to the player, they are not affected by panel shuffling. Additionally, they are all
white puzzles, so they are not affected by color shuffling.
