#!/usr/bin/env bash
# install.sh
##############
# A bash script to perform the following tasks:
# - delete the old "RetroPie-input-selection" scheme if it's installed.
# - compile jslist.c.
# - put jsfuncs.sh and the compiled jsfuncs in
#   /opt/retropie/supplementary/joystick-selection directory.
# - put joystick_selection.sh in $HOME/RetroPie/retropiemenu/ directory.
# - create a gamelist.xml entry for joystick_selection.sh
#


# checking paths
[[ -d "/opt/retropie/" ]] && [[ -d "$HOME/RetroPie/retropiemenu/" ]] || {
    echo "*** Error: it seems that you installed RetroPie in some unusual directories." >&2
    echo "Currently this joystick-selection tool only works for RetroPie with default paths." >&2
    echo "Aborting..."
    exit 1
}


# removing the old selection scheme...
############################################
sudo rm -f \
  "$HOME/bin/jslist" \
  "$HOME/bin/input_selection.sh" \
  "$HOME/RetroPie/retropiemenu/input_selection.sh" \
  "/opt/retropie/configs/all/input-selection.cfg" \
  "/opt/retropie/configs/all/joystick-selection.cfg" \
  "/opt/retropie/supplementary/jslist"

sudo sed -i '
    /^#.*The following line was added to allow joystick selection/d
    /#include "\/opt\/retropie\/configs\/all\/joystick-selection.cfg"/d
    /#include "\/opt\/retropie\/configs\/all\/input-selection.cfg"/d
  ' "/opt/retropie/configs/all/retroarch.cfg"

rmdir "$HOME/bin" 2>/dev/null
############################################

install_dir="/opt/retropie/supplementary/joystick-selection"
sudo mkdir -p "$install_dir"

echo -n "Compiling \"jslist.c\" and putting it in \"$install_dir\"..."
sudo gcc jslist.c \
  -o "$install_dir/jslist" $(sdl2-config --cflags --libs) || {
    echo -e "\nSomething wrong with the compilation process. Aborting..."
    exit 1
}
echo " OK!"

echo -n "Putting \"jsfuncs.sh\" in \"$install_dir\"..."
sudo cp jsfuncs.sh "$install_dir" || {
    echo -e "\nUnable to put \"jsfuncs.sh\" in \"$install_dir\". Aborting."
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
gamelistxml="$HOME/RetroPie/retropiemenu/gamelist.xml"
[[ -f "$gamelistxml" ]] || {
    cp "/opt/retropie/configs/all/emulationstation/gamelists/retropie/gamelist.xml" \
      "$gamelistxml"
}

grep -q "<path>./joystick_selection.sh</path>" "$gamelistxml" && {
    echo " OK!!"
    exit 0
}

gamelist_info='\
	<game>\
		<path>.\/joystick_selection.sh<\/path>\
		<name>Joystick Selection<\/name>\
		<desc>Select which joystick to use for RetroArch players 1-4 (global or system specific).<\/desc>\
		<image><\/image>\
	<\/game>'

sudo sed -i.bak "/<\/gameList>/ s/.*/${gamelist_info}\n&/" "$gamelistxml" || {
    echo "Warning: Unable to edit \"$gamelistxml\"."
    exit 1
}
echo " OK!"
