# RetroPie-input-selection
A script to let the user choose the controllers to use for RetroArch players 1-4. It shows several user-friendly dialog boxes to perform this task.

This was made for use with RetroPie [https://retropie.org.uk/].

This repository contains the following files:
- jslist.c
- input_selection.sh
- install.sh


## Installation
It's pretty simple to install. Perform these commands on your RetroPie bash prompt:
```
git clone https://github.com/meleu/RetroPie-input-selection
cd RetroPie-input-selection
sh install.sh
```

After that you are ready to use it via RetroPie menu in emulationstation (or via `input_selection.sh` command at the bash prompt).

*OBS.*: The "Parse Gamelists Only" option must be off to let the input_selection be shown in RetroPie menu. [Start button on emulationstation -> Other Settings -> Parse Gamelists Only]. This is the default, so if you didn't change it, don't worry. 


## Known Issues
Due to the dynamic nature of bluetooth connections, there are some problems that can happen. Examples:
- If you configure a bluetooth controller as Player 1, and somehow lose the connection during a game, it'll be annoying to exit RetroArch (connect to RetroPie via ssh and kill RetroArch process. If your raspi isn't connected, :( I think you'll have to unplug your power supply.).
- If you restart your raspi or change the joystick list order (adding/removing devices), you have to run `input_selection.sh` again.


## Changelog

*2016-05-23*: Show the current config and give the chance to keep it or not. Also show the configurations made at the end of the process and give the chance to accept it or not.

*2016-05-22*: Added joystick and RetroPie menu support.

*2016-05-21*: This is the very first version. Please give me feedback if problems occur.


## Files Description
### jslist.c
It's a small program to list all the joysticks available on the system and their respective index. The output format is:
`index:Joystick Name`

Example:
```
Example:
[prompt]$ jslist
0:Twin USB Joystick
1:Twin USB Joystick
2:ipega Extending Game Controller
3:8Bitdo Zero Game Pad
```
jslist returns a non-zero value if no joystick found.


### input_selection.sh
It's a bash script to let the user choose the controllers to use for RetroArch players 1-4, showing several user-friendly dialog boxes to perform this task. It relies on the output of the jslist.c to work properly.


### install.sh
A bash script to perform the following tasks:
- create `$HOME/bin` directory.
- compile jslist.c and put the executable in `$HOME/bin` directory.
- put input_selection.sh in `$HOME/bin` directory.
- certifies that `$HOME/bin` is in your PATH.
- create a symbolic link to `$HOME/bin/input_selection.sh` named `$HOME/RetroPie/retropiemenu/input_selection.sh`. This will add input_selection to your RetroPie menu in emulationstation.
