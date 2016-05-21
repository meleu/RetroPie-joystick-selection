# RetroPie-input-selection
A script to let the user choose the controllers for players 1-4

This was made for use with RetroPie [https://retropie.org.uk/].

This repository consistis of two programs: jslist.c and input_selection.sh

## jslist.c
It's a small program to list all the joysticks available on the system and their respective index.


## input_selection.sh
It's a bash script to let the user choose the controllers for players 1-4. It relies on the output of the jslist.c to work properly.
