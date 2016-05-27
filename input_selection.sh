#!/usr/bin/env bash
# input_selection.sh
#####################
# Let the user choose what controller to use for RetroArch Player 1-4.
#
# This program relies on the output of the jslist program.
#
# See the description at https://github.com/meleu/RetroPie-input-selection
# 
#
# TODO:
#      - [robustness] alert the user if the Player 1 has no joystick.
#      - [robustness] verify if the "#include ...input-selection.cfg" line
#        is before any input_playerN_joypad_index in the retroarch.cfg.
#      - [robustness] verify if the input-selection.cfg has all the 4
#        input_playerN_joypad_index; if don't, create a default file.
#
# meleu, 2016/05

configdir="/opt/retropie/configs"

user="$SUDO_USER"
[[ -z "$user" ]] && user=$(id -un)
home="$(eval echo ~$user)"

jslist_exe="$home/bin/jslist"

js_list_file="/tmp/jslist-$$"
temp_file="${js_list_file}_deleteme"
retroarchcfg="$configdir/all/retroarch.cfg"
inputcfg="$configdir/all/input-selection.cfg"


# borrowed code from runcommand.sh
# The joy2key.py aren't documented, so I needed to borrow this code
###############################################################################
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
# end of the borrowed code from runcommand.sh
###############################################################################


###############################################################################
# Checking the following:
#   - if retroarch.cfg has the "#include" line for input-selection.cfg, in
#     failure case let the user decide if we can add it to the file.
#   - if input-selection.cfg exists, create it if doesn't.
#   - if jslist exists and is executable
#
function check_files() {
    start_joy2key
    # checking if the "#include ..." line is in the retroarch.cfg
    grep -q "^#include \"$inputcfg\"$" "$retroarchcfg" || {
        dialog \
          --title "Error" \
          --yesno \
"Your retroarch.cfg isn't properly configured to work with this method of \
input selection. You need to put the following line on your \"$retroarchcfg\" \
(preferably at the beginning)\
\n\n#include \"$inputcfg\"\n\n\
Do you want me to put it at the beginning of the retroarch.cfg now?\
\n(if you choose \"No\", I will stop now)" \
          0 0 || {
            stop_joy2key
            exit 1;
        }

          # Putting the "#include ..." at the beginning line of retroarch.cfg
          sed -i "1i\
# $(date +%Y-%m-%d): The following line was added to allow input selection\n\
#include \"$inputcfg\"\n" "$retroarchcfg"
    } # end of failed grep

    # if the input-selection.cfg doesn't exist or is empty, create it with
    # default values
    [[ -s "$inputcfg" ]] || {
        cat << _EOF_ > "$inputcfg"
# This file is used to choose what controller to use for each player.
input_player1_joypad_index = "0"
input_player2_joypad_index = "1"
input_player3_joypad_index = "2"
input_player4_joypad_index = "3"
_EOF_
    } # end of failed inputcfg
    chown $user.$user "$inputcfg"

    # checking if jslist exists and is executable
    [[ -x "$jslist_exe" ]] || {
        dialog \
          --title "Fail!"
          --msgbox "\"$jslist_exe\" not found or isn't executable!" \
          5 40 
        stop_joy2key
        exit 1
    } # end of failed jslist_exe

    stop_joy2key
} # end of check_files



###############################################################################
# Show the input config file given and let the user decide if he/she
# wants to continue.
#
# Globals:
#   js_list_file: js_list_file must be already filled with 
#                 joysticks' index and names.
#
# Arguments:
#   $1 : NEEDED. The input-selection.cfg file. It's just a
#        retroarch.cfg like file with the input_playerN_joypad_index variables.
#   $2 : OPTIONAL. Its a string with a question to ask in the yesno dialog.
#        Keep in mind that the "No" answer always exit.
#
# Returns:
#   None
function show_input_config() {
    [[ -f "$1" ]] || {
        echo "Error: show_input_config: invalid argument!" >&2
        exit 1
    }

    local cfg_file
    cfg_file="$1"

    local question
    question=${2:-"Would you like to continue?"}

    local current_config_string

    for i in $(seq 1 4); do
        js_index_p[$i]=$(
          grep -m 1 "^input_player${i}_joypad_index" "$cfg_file" \
          | cut -d= -f2 \
          | sed 's/ *"\?\([0-9]\)*"\?.*/\1/' \
        )
        # the command sequence above takes the number after the = sign,
        # deleting the "double quotes" if they exist.

        if [[ -z "${js_index_p[$i]}" ]]; then
            js_name_p[$i]="** NO JOYSTICK! **"
        else 
            js_name_p[$i]=$(
              grep "^${js_index_p[$i]}" "$js_list_file" \
              | cut -d: -f2
            )

            [[ -z "${js_name_p[$i]}" ]] &&
                js_name_p[$i]="** NO JOYSTICK! **"
        fi

        current_config_string="$current_config_string
Player $i uses \"${js_name_p[$i]}\""

    done

    start_joy2key

    dialog \
      --title "Current config" \
      --yesno "
$current_config_string

$question" \
      0 0 || {
          stop_joy2key
          rm "$js_list_file"
          exit 0;
    }

    stop_joy2key

} # end of show_input_config


check_files

# the jslist returns a non-zero value if it doesn't find any joystick
$jslist_exe > $temp_file || {
    start_joy2key
    dialog --title "Fail!" --msgbox "No joystick found. :(" 5 40 
    rm -f "$temp_file"
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
rm -f "$temp_file"


show_input_config "$inputcfg" "Would you like to change it?"


temp_file="/tmp/jstmp-$$"
temp_inputcfg="/tmp/inputcfg-$$"

cat "$inputcfg" > "$temp_inputcfg"

start_joy2key

for i in $(seq 1 4); do
    # Obtaining the joystick list with the format
    # index "Joystick Name"
    # to use as dialog menu options
    dialogOptions=$(sed 's/:\(.*\)/ "\1"/' $js_list_file)

    echo "$dialogOptions" \
    | xargs dialog \
      --title "Input selection" \
      --menu "Which controller you want to use for Player $i?" \
      0 0 0 2> $temp_file

    js_index=$(sed 's/.*[^0-9].*//' $temp_file)

    # strings to be used with sed below
    old="^input_player${i}_joypad_index.*"
    new="input_player${i}_joypad_index = $js_index"

    sed "s/$old/$new/" $temp_inputcfg > $temp_file

    mv "$temp_file" "$temp_inputcfg"
done


show_input_config "$temp_inputcfg" "Do you accept this config?"

# If the script reaches the user accepted the config
mv "$temp_inputcfg" "$inputcfg"

stop_joy2key
rm -f "$js_list_file" "$temp_file" "$temp_inputcfg"
