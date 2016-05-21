# RetroPie-input-selection
A script to let the user choose the controllers to use for players 1-4 in RetroArch. It shows several user-friendly dialog boxes to perform this task.

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

## File Description
### jslist.c
It's a small program to list all the joysticks available on the system and their respective index. The output format is:
index:Joystick Name

Example:
```Example:
[prompt]$ jslist
0:Twin USB Joystick
1:Twin USB Joystick
2:ipega Extending Game Controller
3:8Bitdo Zero Game Pad
```
jslist returns a non-zero value if no joystick found.


### input_selection.sh
It's a bash script to let the user choose the controllers to use for players 1-4 in RetroArch. It relies on the output of the jslist.c to work properly.


### install.sh
A bash script to perform the following tasks:
- create `$HOME/bin` directory.
- compile jslist.c and put the executable in `$HOME/bin` directory.
- put input_selection.sh in `$HOME/bin` directory.
- certifies that `$HOME/bin` is in your PATH.
