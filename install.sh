#!/usr/bin/env bash
# install.sh
##############
# A bash script to perform the following tasks:
# - create $HOME/bin directory.
# - compile jslist.c and put the executable in $HOME/bin directory.
# - put input_selection.sh in $HOME/bin directory.
# - certifies that $HOME/bin is in your PATH.
# - create a symbolic link to $HOME/bin/input_selection.sh named
#   $HOME/RetroPie/retropiemenu/input_selection.sh
#
# TODO: - edit /opt/retropie/configs/all/emulationstation/gamelists/retropie/gamelist.xml
#         to add an input_selection.sh description

echo -n "Checking if \"$HOME/bin\" exists, creating it if doesn't..."
[[ -d "$HOME/bin" ]] || mkdir "$HOME/bin"
echo " OK!"

echo -n "Compiling \"jslist.c\" and putting it in \"$HOME/bin\"..."
gcc jslist.c -o "$HOME/bin/jslist" $(sdl2-config --cflags --libs) || {
    echo -e "\nSomething wrong with the compilation process. Aborting..."
    exit 1
}
echo " OK!"

echo -n "Putting \"input_selection.sh\" in \"$HOME/bin\"..."
cp input_selection.sh "$HOME/bin/input_selection.sh" || {
    echo -e "\nUnable to put \"input_selection.sh\" in \"$HOME/bin\". Aborting."
    exit 1
}
echo " OK!"

echo -n "Certifying that \"$HOME/bin\" is in your PATH..."
echo "$PATH" | grep -q "$HOME/bin" || {
    export PATH="$HOME/bin:$PATH"
    grep -q '^ *PATH="$HOME/bin:$PATH"' "$HOME/.profile" \
    || echo PATH="$HOME/bin:$PATH" >> "$HOME/.profile";

}
echo " OK!"

echo -n "Creating a symbolic link to show input_selection.sh in RetroPie menu..."
ln -sf \
  "$HOME/bin/input_selection.sh" \
  "$HOME/RetroPie/retropiemenu/input_selection.sh"
echo " OK!"

