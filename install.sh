#!/usr/bin/env bash
# install.sh
##############
# A bash script to perform the following tasks:
# - delete the old "RetroPie-input-selection" scheme if it's installed.
# - compile jslist.c and put the executable in 
#   /opt/retropie/supplementary/ directory.
# - put joystick_selection.sh in $HOME/RetroPie/retropiemenu/ directory.
# - create a gamelist.xml entry for joystick_selection.sh
#


# removing the old input-selection scheme...
############################################
rm -f \
  "$HOME/bin/jslist" \
  "$HOME/bin/input_selection.sh" \
  "$HOME/RetroPie/retropiemenu/input_selection.sh" \

[[ -f "/opt/retropie/configs/all/input-selection.cfg" ]] &&
  mv -f "/opt/retropie/configs/all/input-selection.cfg" \
        "/opt/retropie/configs/all/joystick-selection.cfg"

sudo sed -i 's/input-selection/joystick-selection/' \
  "/opt/retropie/configs/all/retroarch.cfg"

rmdir "$HOME/bin" 2>/dev/null
############################################


echo -n "Compiling \"jslist.c\" and putting it in \"/opt/retropie/supplementary/\"..."
sudo gcc jslist.c \
  -o "/opt/retropie/supplementary/jslist" $(sdl2-config --cflags --libs) || {
    echo -e "\nSomething wrong with the compilation process. Aborting..."
    exit 1
}
echo " OK!"


echo -n "Putting \"joystick_selection.sh\" in \"$HOME/RetroPie/retropiemenu/\"..."
cp joystick_selection.sh "$HOME/RetroPie/retropiemenu/joystick_selection.sh" || {
    echo -e "\nUnable to put \"joystick_selection.sh\" in \"$HOME/RetroPie/retropiemenu/\". Aborting."
    exit 1
}
echo " OK!"


echo -n "Creating a gamelist.xml entry for joystick_selection.sh..."
gamelistxml="/opt/retropie/configs/all/emulationstation/gamelists/retropie/gamelist.xml"

grep -q "<path>./joystick_selection.sh</path>" "$gamelistxml" && {
    echo " OK!!"
    exit 0
}

gamelist_info='\
	<game>\
		<path>.\/joystick_selection.sh<\/path>\
		<name>Joystick Selection<\/name>\
		<desc>Select which joystick to use for RetroArch players 1-4.<\/desc>\
		<image><\/image>\
	<\/game>'

sudo sed -i.bak "/<\/gameList>/ s/.*/${gamelist_info}\n&/" "$gamelistxml" || {
    echo "Warning: Unable to edit \"$gamelistxml\"."
    exit 1
}
echo " OK!"
