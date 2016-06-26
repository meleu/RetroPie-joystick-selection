# RetroPie-joystick-selection
A script to let the user choose the controllers to use for RetroArch players 1-4. It shows several user-friendly dialog boxes to perform this task.

This was made for use with RetroPie [https://retropie.org.uk/].

This repository contains the following files:
- jslist.c
- joystick_selection.sh (former input_selection.sh)
- install.sh


## Installation
It's pretty simple to install. Perform these commands on your RetroPie bash prompt:
```
git clone https://github.com/meleu/RetroPie-joystick-selection
cd RetroPie-joystick-selection
bash install.sh
```

After that you are ready to use it via RetroPie menu in emulationstation.


## Known Issues
Due to the dynamic nature of bluetooth connections, there are some issues that can happen. Examples:
- If you configure a bluetooth controller as Player 1, and somehow lose the connection during a game, it'll be annoying to exit RetroArch (connect to RetroPie via ssh and kill RetroArch process. If your raspi isn't on the LAN, :( I think you'll have to unplug your power supply.).
- If the joystick list order changes (adding/removing devices), your configuration changes too. So you have to run `joystick_selection.sh` again.


## Changelog

**2016-06-26**: now the install.sh creates a `gamelist.xml` entry for `joystick_selection.sh`.

**2016-06-25**: 1) Added an initial dialog menu. 2) Renamed the file `input_selection.sh` for `joystick_selection.sh` for a better description of what it does. 3) The files is no more at `$HOME/bin`, the jslist is at `/opt/retropie/supplementary` and joystick_selection.sh is directly at `$HOME/RetroPie/retropiemenu/`

**2016-05-23**: Show the current config and give the chance to keep it or not. Also show the configurations made at the end of the process and give the chance to accept it or not.

**2016-05-22**: Added joystick and RetroPie menu support.

**2016-05-21**: This is the very first version. Please give me feedback if problems occur.


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


### joystick_selection.sh (former input_selection.sh)
It's a bash script to let the user choose the controllers to use for RetroArch players 1-4, showing several user-friendly dialog boxes to perform this task. It relies on the output of the jslist.c to work properly.


### install.sh
A bash script to perform the following tasks:
- delete the old "RetroPie-input-selection" scheme if it's installed.
- compile `jslist.c` and put the executable in `/opt/retropie/supplementary/` directory.
- put `joystick_selection.sh` in `$HOME/RetroPie/retropiemenu/` directory.
- create a `gamelist.xml` entry for `joystick_selection.sh`.
