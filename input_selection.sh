#!/usr/bin/env bash
# input_selection.sh
#####################
# Let the user choose what controller to use for Player 1-4.
#
# This program relies on the output of the jslist program. The jslist is
# a small program I wrote to detect and list the joysticks connected to the
# system and their respective indexes. The output format of jslist is
# index:Joystick Name
#
# Example:
# [prompt]$ jslist
# 0:Twin USB Joystick
# 1:Twin USB Joystick
# 2:ipega Extending Game Controller
# 3:8Bitdo Zero Game Pad
# 
#
# TODO:
#      - show the current config (with the joystick names) before start
#        and let the user quit.
#      - [robustness] verify if the "#include ...input-selection.cfg" line
#        is before any input_playerN_joypad_index in the retroarch.cfg.
#
# meleu, 2016/05


rootdir="/opt/retropie"
configdir="$rootdir/configs"

js_list_file="/tmp/jslist-$$"
temp_file="${js_list_file}_d"
retroarchcfg="$configdir/all/retroarch.cfg"
inputcfg="$configdir/all/input-selection.cfg"


# borrowed code from runcommand.sh ############################################
# The joy2key.py aren't documented, so I don't know how to use it... :(
function start_joy2key() {
    # if joy2key.py is installed run it with cursor keys for axis,
    # and enter + tab for buttons 0 and 1
    __joy2key_dev=$(ls -1 /dev/input/js* 2>/dev/null | head -n1)
    if [[ -f "$rootdir/supplementary/runcommand/joy2key.py" && -n "$__joy2key_dev" ]] && ! pgrep -f joy2key.py >/dev/null; then
        "$rootdir/supplementary/runcommand/joy2key.py" "$__joy2key_dev" 1b5b44 1b5b43 1b5b41 1b5b42 0a 09 &
        __joy2key_pid=$!
    fi
}

function stop_joy2key() {
    if [[ -n "$__joy2key_pid" ]]; then
        kill -INT "$__joy2key_pid"
    fi
}
# end of the borrowed code from runcommand.sh #################################


start_joy2key

# checking if the "#include ..." line is in the retroarch.cfg
grep -q \
  "^#include \"$configdir/all/input-selection.cfg\"$"\
  $retroarchcfg || {
      dialog \
        --title "Error" \
        --yesno \
"Your retroarch.cfg isn't properly configured to work with this method of \
input selection. You need to put the following line on your \"$retroarchcfg\" \
(preferably at the beginning)\
\n\n#include \"$configdir/all/input-selection.cfg\"\n\n\
Do you want me to put it at the beginning of the retroarch.cfg now?\
\n(if you choose \"No\", I will stop now)" \
        0 0 || {
            stop_joy2key
            exit 1;
        }

      # Putting the "#include ..." at the beginning line of retroarch.cfg
      sed -i "1i\
# $(date +%Y-%m-%d): The following line was added to allow input selection\n\
#include \"$configdir/all/input-selection.cfg\"\n" $retroarchcfg
} # end of failed grep

# if the input-selection.cfg doesn't exist, create it with default values
[[ -f "$inputcfg" ]] || {
    cat << _EOF_ > $inputcfg
# This file is used to choose what controller to use for each player.
input_player1_joypad_index = "0"
input_player2_joypad_index = "1"
input_player3_joypad_index = "2"
input_player4_joypad_index = "3"
_EOF_
}

# checking if jslist is on the PATH
which jslist > /dev/null || {
    dialog --title "Fail!" --msgbox "\"jslist\" not found!" 5 40 
    stop_joy2key
    exit 1
}

# the jslist returns a non-zero value if it doesn't find any joystick
jslist > $temp_file || {
    dialog --title "Fail!" --msgbox "No joystick found. :(" 5 40 
    rm -f $temp_file
    stop_joy2key
    exit 1
}

# This obscure command searches for duplicated joystick names and puts
# a sequential number at the end of the repeated ones
# credit goes to fedorqui (http://stackoverflow.com/users/1983854/fedorqui)
awk -F: 'FNR==NR {count[$2]++; next}
         count[$2]>1 {$0=$0 OFS "#"++times[$2]}
         1' $temp_file $temp_file > $js_list_file

# No need for this file anymore
rm -f $temp_file

temp_file="/tmp/jstmp-$$"

for i in $(seq 1 4); do
    # Obtaining the joystick list with the format
    # index "Joystick Name"
    # to use as dialog menu options
    dialogOptions=$(sed 's/:\(.*\)/ "\1"/' $js_list_file)

    echo "$dialogOptions" |
    xargs dialog \
        --title "Input selection" \
        --menu "Which controller you want to use for Player $i?" \
        0 0 0 2> $temp_file

    js_index=$(cat $temp_file)

    # Here is the magic! Change the input_playerX_joypad_index in retroarch.cfg
    sed "s/^input_player${i}_joypad_index.*/input_player${i}_joypad_index = \"$js_index\"/" $inputcfg > $temp_file

    mv $temp_file $inputcfg
done

stop_joy2key
rm -f $js_list_file 
