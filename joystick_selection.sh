#!/usr/bin/env bash
# joystick_selection.sh
#######################
# Show the available joysticks and let the user choose what controller to
# use for RetroArch Player 1-4.
#
# This program relies on the output of the jslist program to get the
# available joysticks and their respective indexes.
#
# Short description of what this script does:
# - puts at the beginning of $configdir/all/retroarch.cfg an "#include" 
#   pointing to the file $configdir/all/joystick-selection.cfg
# - let the user manage the joystick-selection.cfg through dialogs (this file
#   contains the configs for input_playerN_joypad_index for players 1-4).
#
# OBS.: the joystick selection doesn't work if the config_save_on_exit is set
#       to true, because the retroarch.cfg is overwritten frequently.
#
# TODO:
#      - implement the same functionality for non-libretro emulators.
#      - [robustness] alert the user if the Player 1 has no joystick.
#      - [robustness] verify if the "#include ...joystick-selection.cfg" line
#        is before any input_playerN_joypad_index in the retroarch.cfg.
#
# meleu, 2016/06

configdir="/opt/retropie/configs"

user="$SUDO_USER"
[[ -z "$user" ]] && user=$(id -un)
home="$(eval echo ~$user)"

jslist_exe="/opt/retropie/supplementary/jslist"

js_list_file="/tmp/jslist-$$"
retroarchcfg="$configdir/all/retroarch.cfg"
jscfg="$configdir/all/joystick-selection.cfg"


# borrowed code from runcommand.sh
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



function fatalError() {
    echo "Error: $1" 1>&2
    stop_joy2key
    exit 1
}


function safe_exit() {
    stop_joy2key
    exit $1
}



###############################################################################
# Puts the default joystick input configuration content in the given
# file ($1 argument).
# The default is:
# input_player1_joypad_index = "0"
# input_player2_joypad_index = "1"
# input_player3_joypad_index = "2"
# input_player4_joypad_index = "3"
#
# Globals:
#   None
#
# Arguments:
#   $1 : NEEDED. The file where the default config will be put.
#
# Returns:
#   1: if fails.
function default_input_config() {
    [[ "$1" ]] || fatalError "default_input_config: missing argument!"

    local temp_jscfg
    temp_jscfg="$1"

    cat << _EOF_ > "$temp_jscfg"
# This file is used to choose which controller to use for each player.
input_player1_joypad_index = "0"
input_player2_joypad_index = "1"
input_player3_joypad_index = "2"
input_player4_joypad_index = "3"
_EOF_
    if [ "$?" -ne 0 ]; then
        dialog --title "Error" \
          --msgbox "Unable to create a default configuration" \
          20 60 >/dev/tty
        return 1
    fi

    chown $user.$user "$temp_jscfg"
}



###############################################################################
# Fills the js_list_file with the available joysticks and their indexes.
#
# Globals:
#   jslist_exe
#   js_list_file
#
# Arguments:
#   None
#
# Returns:
#   1: if no joystick found.
function fill_js_list_file() {
    local temp_file
    temp_file=$(mktemp deleteme.XXXX)

    # the jslist returns a non-zero value if it doesn't find any joystick
    $jslist_exe > "$temp_file" || {
        dialog --title "Error" --msgbox "No joystick found. :(" 20 60 >/dev/tty
        rm -f "$temp_file"
        return 1
    }

    # This obscure command searches for duplicated joystick names and puts
    # a sequential number at the end of the repeated ones
    # credit goes to fedorqui (http://stackoverflow.com/users/1983854/fedorqui)
    awk -F: 'FNR==NR {count[$2]++; next}
             count[$2]>1 {$0=$0 OFS "#"++times[$2]}
             1' "$temp_file" "$temp_file" > "$js_list_file"

    # No need for this file anymore
    rm -f "$temp_file"
} # end of fill_js_list_file



###############################################################################
# Checking the following:
#   - if retroarch.cfg has the "#include" line for joystick-selection.cfg, in
#     failure case let the user decide if we can add it to the file.
#   - if joystick-selection.cfg exists, create it if doesn't.
#   - if jslist exists and is executable
#
# Globals:
#   retroarchcfg
#   jscfg
#   jslist_exe
#
# Arguments:
#   None
#
# Returns:
#   1: if fails
function check_files() {
    # checking if the "#include ..." line is in the retroarch.cfg
    grep -q "^#include \"$jscfg\"$" "$retroarchcfg" || {
        dialog \
          --title "Error" \
          --yesno \
"Your retroarch.cfg isn't properly configured to work with this method of
joystick selection. You need to put the following line on your \"$retroarchcfg\"
(preferably at the beginning):
\n\n#include \"$jscfg\"\n\n
Do you want me to put it at the beginning of the retroarch.cfg now?
\n(if you choose \"No\", I will stop now)" \
          0 0 >/dev/tty || {
            return 1;
        }

        # Putting the "#include ..." at the beginning line of retroarch.cfg
        sed -i "1i\
# $(date +%Y-%m-%d): The following line was added to allow joystick selection\n\
#include \"$jscfg\"\n" \
          "$retroarchcfg" || return 1
    } # end of failed grep

    # if the joystick-selection.cfg doesn't exist or is empty, create it with
    # default values
    [[ -s "$jscfg" ]] || default_input_config "$jscfg"

    # checking if jslist exists and is executable
    [[ -x "$jslist_exe" ]] || {
        dialog --title "Error" \
          --msgbox "\"$jslist_exe\" not found or isn't executable!" \
          20 60 >/dev/tty
        return 1
    } # end of failed jslist_exe

} # end of check_files



###############################################################################
# Show the input config with the joystick names, and let the user decide if
# he/she wants to continue.
# The caller of this function must deal with the user decision. It returns
# 1 if the user choose "No", and 0 if the user choose "Yes".
#
# Globals:
#   js_list_file
#
# Arguments:
#   $1 : NEEDED. The joystick-selection.cfg file. It's just a
#        retroarch.cfg like file with the input_playerN_joypad_index variables.
#   $2 : OPTIONAL. Its a string with a question to ask in the yesno dialog.
#        Keep in mind that the "No" answer always exit.
#
# Returns:
#   -1: if it fails
#    1: if the user choose No in the --yesno dialog box.
#    0: if the user choose Yes in the --yesno dialog box.
function show_input_config() {
    [[ -f "$1" ]] || fatalError "show_input_config: invalid argument!"

    fill_js_list_file

    local cfg_file
    cfg_file="$1"

    local question
    question=${2:-"Would you like to continue?"}

    local current_config_string

    for i in $(seq 1 4); do
        # the command sequence below takes the number after the = sign,
        # deleting the "double quotes" if they exist.
        js_index_p[$i]=$(
          grep -m 1 "^input_player${i}_joypad_index" "$cfg_file" \
          | cut -d= -f2 \
          | sed 's/ *"\?\([0-9]\)*"\?.*/\1/' \
        )

        # getting the joystick names
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

        current_config_string="$current_config_string\n\
Player $i is set to \"${js_index_p[$i]}\" (${js_name_p[$i]})"

    done

    dialog \
      --title "Joystick selection" \
      --yesno "$current_config_string\n\n$question" \
      0 0 >/dev/tty || return 1

    return 0
} # end of show_input_config



###############################################################################
# Start a new joystick input selection configuration for players 1-4.
#
# Globals:
#   jscfg
#   js_list_file
#
# Arguments:
#   None
#
# Returns:
#   1: if fails.
#   0: if the user don't want to change the config
function new_input_config() {
    fill_js_list_file || return 1

    local temp_file
    local temp_jscfg
    local options
    local choice
    local old
    local new

    temp_file=$(mktemp temp.XXXX)
    temp_jscfg=$(mktemp jscfg.XXXX)

    cat "$jscfg" > "$temp_jscfg"
    for i in $(seq 1 4); do
        options="K \"Keep the current configuration for player $i\""
        # The sed below obtain the joystick list with the format
        # index "Joystick Name"
        # to use as dialog menu options
        options="$options $(sed 's/:\(.*\)/ "\1"/' $js_list_file)"
        choice=$(echo "$options" \
                   | xargs dialog \
                       --title "Player $i joystick selection" \
                       --menu "Which controller do you want to use for Player $i?" \
                       0 0 0 2>&1 >/dev/tty
        )

        # if the user choose K or Cancel, it'll keep the current config
        if [ -n "$choice" -a "$choice" != "K" ]; then
            old="^input_player${i}_joypad_index.*"
            new="input_player${i}_joypad_index = $choice"

            sed "s/$old/$new/" "$temp_jscfg" > "$temp_file"

            cat "$temp_file" > "$temp_jscfg"
        fi
    done

    show_input_config "$temp_jscfg" "Do you accept this config?" || return 1

    # If the script reaches this point, the user accepted the config
    cat "$temp_jscfg" > "$jscfg"

    rm -f "$temp_file" "$temp_jscfg"
} # end of new_input_config



###############################################################################
# The script starts here.

start_joy2key

check_files || safe_exit 1

while true; do
    cmd=(dialog \
         --menu "Joystick selection for RetroArch players 1-4." 18 80 12)
    options=(
        1 "Show current joystick selection for players 1-4."
        2 "Start a new joystick selection for players 1-4."
        3 "Restore the default settings."
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    if [[ -n "$choices" ]]; then
        case $choices in
            1) show_input_config "$jscfg" \
                 "Choose Yes or No to go to the previous menu." ;;

            2) new_input_config ;;

            3) temp_file=$(mktemp input-cfg.XXXX)
               default_input_config "$temp_file"
               show_input_config "$temp_file" \
                 "This is the default configuration. Do you accept it?" || continue

               cat "$temp_file" > "$jscfg"
               ;;

        esac
    else
        rm -f "$js_list_file" "$temp_file"
        break
    fi
done

safe_exit 0
