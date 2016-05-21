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
#      - if jslist is not in the PATH, download it from github, compile it,
#        and put it in $HOME/bin directory.
#
# meleu, 2016/05/21


jsListFile="/tmp/jslist-$$"
tempFile="${jsListFile}_d"
retroarchcfg="/opt/retropie/configs/all/retroarch.cfg"
inputcfg="/opt/retropie/configs/all/input-selection.cfg"

# checking if the "#include ..." line is in the retroarch.cfg
grep -q '^#include "/opt/retropie/configs/all/input-selection.cfg"$' $retroarchcfg || {
    dialog \
      --title "Error" \
      --yesno \
"Your retroarch.cfg isn't properly configured to work with this method of \
input selection. You need to put the following line on your \"$retroarchcfg\" \
(preferably at the beginning)\
\n\n#include \"/opt/retropie/configs/all/input-selection.cfg\"\n\n\
Do you want me to put it at the beginning of the retroarch.cfg now?\
\n(if you choose \"No\", I will stop now)" \
      0 0 || exit 1;

    # Put the "#include ..." at the beginning line of retroarch.cfg
    sed -i "1i\
# $(date +%Y-%m-%d): The following line was added to allow input selection\n\
#include \"/opt/retropie/configs/all/input-selection.cfg\"\n" $retroarchcfg
}

# if the input-selection.cfg doesn't exist, create it with default values
[ -f "$inputcfg" ] || {
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
    dialog --title 'Fail!' --msgbox '"jslist" not found!' 5 40 
    exit 1
}

# the jslist returns a non-zero value if it fails or doesn't find any joystick
jslist > $tempFile || {
    dialog --title "Fail!" --msgbox "No joystick found. :(" 5 40 
    rm -f $tempFile
    exit 1
}


# This obscure command searches for duplicated joystick names and puts
# a sequential number at the end of the repeated ones
# credit goes to fedorqui (http://stackoverflow.com/users/1983854/fedorqui)
awk -F: 'FNR==NR {count[$2]++; next}
         count[$2]>1 {$0=$0 OFS "#"++times[$2]}
         1' $tempFile $tempFile > $jsListFile

# No need for this file anymore
rm -f $tempFile

tempFile="/tmp/jstmp-$$"

for i in $(seq 1 4); do
    # Obtaining the joystick list with the format
    # index "Joystick Name"
    # to use as dialog menu options
    dialogOptions=$(sed 's/:\(.*\)/ "\1"/' $jsListFile)

    echo "$dialogOptions" |
    xargs dialog \
        --title "Input selection" \
        --menu "Which controller you want to use for \"Player $i\"?" \
        0 0 0 2> $tempFile

    jsIndex=$(cat $tempFile)

    # Here is the magic! Change the input_playerX_joypad_index in retroarch.cfg
    sed "s/^input_player${i}_joypad_index.*/input_player${i}_joypad_index = \"$jsIndex\"/" $inputcfg > $tempFile

    mv $tempFile $inputcfg
done

rm -f $jsListFile 
