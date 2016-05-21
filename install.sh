#!/usr/bin/env bash
# install.sh
##############
# A bash script to perform the following tasks:
# - create $HOME/bin directory.
# - compile jslist.c and put the executable in $HOME/bin directory.
# - put input_selection.sh in $HOME/bin directory.
# - certifies that $HOME/bin is in your PATH.

echo "Checking if \"$HOME/bin\" exists, creating it if doesn't..."
[ -d "$HOME/bin" ] || mkdir "$HOME/bin";

echo "Compiling \"jslist.c\" and putting it in \"$HOME/bin\"..."
gcc jslist.c -o jslist $(sdl2-config --cflags --libs) || {
    echo "Something wrong with compilation process. Aborting..."
    exit 1
}

echo "Putting \"input_selection.sh\" in \"$HOME/bin\"..."
cp input_selection.sh "$HOME/bin/input_selection.sh"

echo "Certifying that \"$HOME/bin\" is in your PATH..."
echo "$PATH" | grep -q "$HOME/bin" || {
    export PATH="$HOME/bin:$PATH"
    grep -q '^ *PATH="$HOME/bin:$PATH"' "$HOME/.profile" ||
        echo PATH="$HOME/bin:$PATH" >> "$HOME/.profile";

}
