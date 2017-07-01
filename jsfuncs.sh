#!/usr/bin/env bash
# jsfuncs.sh
############
#
# These functions were originally part of joystick_selection.sh but as
# they became useful for runcommand-on{start,end}.sh, then I decided to
# put them in a separate file.
#
# Most of the functions have comments about what it does.
#

user="$SUDO_USER"
[[ -z "$user" ]] && user=$(id -un)

readonly rootdir="/opt/retropie"
readonly configdir="$rootdir/configs"
readonly global_jscfg="$configdir/all/joystick-selection.cfg"
readonly jslist_exe="$rootdir/supplementary/joystick-selection/jslist"
readonly jslist_file=$(mktemp /tmp/jslist.XXXX)
readonly temp_file=$(mktemp /tmp/deleteme.XXXX)

# getting some usefull functions from RetroPie
source "$rootdir/lib/inifuncs.sh"

# BYNAME is a flag to indicate the using of "joystick selection by name" method.
# The "ON" string means that the selection by name method is on, any string
# different from "ON" means "off"
BYNAME="OFF"
byname_msg=


# borrowed code from runcommand.sh
function start_joy2key() {
    local __joy2key_dev

    # get the first joystick device (if not already set)
    [[ -z "$__joy2key_dev" ]] && __joy2key_dev="$(ls -1 /dev/input/js* 2>/dev/null | head -n1)"

    # if joy2key.py is installed run it with cursor keys for axis, and enter + tab for buttons 0 and 1
    if [[ -f "$rootdir/supplementary/runcommand/joy2key.py" && -n "$__joy2key_dev" ]] && ! pgrep -f joy2key.py >/dev/null; then
        "$rootdir/supplementary/runcommand/joy2key.py" "$__joy2key_dev" 1b5b44 1b5b43 1b5b41 1b5b42 0a 09 &
        __joy2key_pid=$!
    fi
}


# borrowed code from runcommand.sh
function stop_joy2key() {
    if [[ -n "$__joy2key_pid" ]]; then
        kill -INT "$__joy2key_pid" 2> /dev/null
    fi
}


# use this instead of exit to stop_joy2key
function safe_exit() {
    stop_joy2key
    rm -f "$jslist_file" "$temp_file"
    exit $1
}


function fatalError() {
    echo "Error: $1" 1>&2
    safe_exit 1
}


# check if we are able to use the joystick selection by name method.
function check_byname_is_ok() {
    local okcount=0

    # checking if we have runcommand-onstart.sh feature...
    grep 'runcommand-onstart\.sh' "$rootdir/supplementary/runcommand/runcommand.sh" \
    | grep -qv '#.*runcommand-onstart\.sh'
    if [[ $? -ne 0 ]]; then
        dialog \
          --title "Joystick selection by name error!" \
          --yesno \
"It seems that your runcommand is outdated!

The joystick selection by name method depends on an updated version of RetroPie's runcommand.

You must update it via retropie_setup.sh to use joystick selection by name method.

Short way: execute retropie_setup.sh and choose \"Update RetroPie-Setup script\". And then go to
\"Manage Packages\" -> \"Manage core packages\" -> \"runcommand\" -> \"Update from binary\"

Detailed instructions can be found here:
https://github.com/RetroPie/RetroPie-Setup/wiki/Updating-RetroPie

Choose \"Yes\" to exit or \"No\" to continue using the joystick selection by index method." \
          0 0 >/dev/tty || return $?

        safe_exit 0
    fi
    okcount=$((okcount + 1)) # runcommand is updated - CHECKED!

    local jsonstart="$rootdir/supplementary/joystick-selection/js-onstart.sh"
    local rconstart="$configdir/all/runcommand-onstart.sh"

    # checking runcommand-onstart.sh
    if ! grep -q "^bash \"$jsonstart\" \"\$@\"" "$rconstart" 2> /dev/null; then
        sudo cat >> "$rconstart" << _EoF_
# the line below is needed to use the joystick selection by name method
bash "$jsonstart" "\$@"
_EoF_
        check_byname_is_ok
        return $?
    fi
    okcount=$((okcount + 1)) # runcommand-onstart calls js-onstart.sh - CHECKED!

    # checking if js-onstart.sh exists
    if ! [[ -f "$jsonstart" ]]; then
        cat > "/tmp/jsonstart.tmp" << _EoF_
#!/bin/bash
# this file is needed to use the joystick selection by name method.
# Do NOT edit it unless you are absolutely right of what you are doing.

[[ "\$4" != *retroarch* ]] && exit 0

source "$rootdir/supplementary/joystick-selection/jsfuncs.sh"

system="\$1"

get_configs
# if not using joystick selection by name method, there's nothing to do.
if [[ "\$BYNAME" != "ON" ]]; then
    exit 0
fi

echo "--- start of joystick-selection log" >&2
echo "joystick selection by name is ON!" >&2
js_to_retroarchcfg "\$system" && echo "joystick indexes for \"\$system\" was configured" >&2
js_to_retroarchcfg all && echo "joystick indexes for \"all\" was configured" >&2
echo "--- end of joystick-selection log" >&2
_EoF_
        sudo mv "/tmp/jsonstart.tmp" "$jsonstart"
        sudo chown "$user"."$user"   "$jsonstart"
        check_byname_is_ok
        return $?
    fi
    okcount=$((okcount + 1)) # js-onstart is OK - CHECKED!

    if [[ $okcount -lt 3 ]]; then
        return 1
    fi

    return 0
}


# get the initial configs
# [improvement]: maybe I'll add a way to define __joy2key_dev
function get_configs() {
    iniConfig ' = ' '"' '' 1

    iniGet joystick_selection_by_name "$global_jscfg"

    if [[ "$ini_value" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
        if check_byname_is_ok; then
            BYNAME="ON"
        else
            iniSet "joystick_selection_by_name" "false" "$global_jscfg"
            BYNAME="OFF"
        fi
    else
        BYNAME="OFF"
    fi

    byname_msg="Selection by name is: [$BYNAME]\n\n"
}



###############################################################################
# Fills the jslist_file with the available joysticks and their indexes.
#
# Globals:
#   jslist_exe
#   jslist_file
#
# Arguments:
#   None
#
# Returns:
#   1  if no joystick found.
#   0  otherwise
function fill_jslist_file() {
    # the jslist returns a non-zero value if it doesn't find any joystick
    "$jslist_exe" > "$temp_file" 2>/dev/null || return 1

    # This obscure command searches for duplicated joystick names and puts
    # a sequential number at the end of the repeated ones
    # credit goes to fedorqui (http://stackoverflow.com/users/1983854/fedorqui)
    awk -F: 'FNR==NR {count[$2]++; next}
             count[$2]>0 {$0=$0 OFS "#"++times[$2]}
             1' "$temp_file" "$temp_file" > "$jslist_file"
}



###############################################################################
# Get a joystick name and print its index. If the name is an integer, print
# this integer.
# OBS.: jslist_file MUST be filled.
#
# Globals:
#   jslist_file
#
# Arguments:
#   $1  Joystick name.
#
# Returns:
#   0       on success
# non-zero  otherwise
function js_name2index() {
    [[ "$1" ]] || return -1

    if [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "$1"
        return 0
    fi

    local js_name
    local js_index
    js_name="$1"
    js_index=$(grep "^[0-9]\+:$js_name" "$jslist_file" | cut -d: -f1)

    [[ -z "$js_index" ]] && return 1

    echo "$js_index" 
}




###############################################################################
# Get a joystick index and print its name. If there is no joystick with the 
# given index, print "(NOT CONNECTED)" and return a non-zero value.
#
# Globals:
#   jslist_file
#
# Arguments:
#   $1 : Joystick index (must be an integer).
#
# Returns:
#   0       on success
# non-zero  otherwise
function js_index2name() {
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "*** erro: js_index2name: argument must be an integer" >&2
        return -1
    fi

    local js_index="$1"
    local js_name
    local return_val=0

    js_name=$(grep "^$js_index:" "$jslist_file" | cut -d: -f2)

    if [[ -z "$js_name" ]]; then
        js_name="(NOT CONNECTED)"
        return_val=1
    fi

    echo "$js_name" 
    return $return_val
}



###############################################################################
# Get a joystick index or name and check if it is connected. If the argument
# is an integer, it is considered an index, otherwise it is considered a
# joystick name.
# If the joystick is connected, return 0.
# If the joystick isn't connected, print "(NOT CONNECTED)" and return non-zero.
#
# Globals:
#   jslist_file
#
# Arguments:
#   $1 : Joystick index or name
#
# Returns:
#   0       if the joystick is connected
# non-zero  otherwise
function js_is_connected() {
    [[ "$1" ]] || fatalError "js_is_connected: missing arguments!"

    # if it's an integer, than it's an index
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        if grep -q "^$1:" "$jslist_file"; then
            return 0
        else
            echo "(NOT CONNECTED)"
            return 1
        fi
    else
        if grep -q "^[0-9]\+:$1" "$jslist_file"; then
            return 0
        else
            echo "(NOT CONNECTED)"
            return 1
        fi
    fi
}


###############################################################################
# Make the retroarch.cfg configs match the joystick-selection.cfg. Only works
# if the BYNAME is on.
# Needs the system as an argument.
#
# Globals:
#   None
#
# Arguments:
#   $1  the system to configure
#
# Returns:
#   1   if BYNAME is off
#   0   otherwise
function js_to_retroarchcfg() {
    [[ "$BYNAME" != "ON" ]] && return 1
    [[ "$1" ]] && [[ -d "$configdir/$1" ]] || fatalError "js_to_retroarchcfg: the argument must be a valid system!"

    local jscfg="$configdir/$1/joystick-selection.cfg"
    local retroarchcfg="$configdir/$1/retroarch.cfg"

    [[ -f "$jscfg" ]] || return 1

    fill_jslist_file

    local js_index
    for i in 1 2 3 4; do
        iniGet "input_player${i}_joypad_index" "$jscfg"
        js_index=$(js_name2index "$ini_value")

        if [[ -z "$js_index" ]]; then
            iniUnset "input_player${i}_joypad_index" "$((i-1))" "$retroarchcfg"
        else
            iniSet "input_player${i}_joypad_index" "$js_index" "$retroarchcfg"
        fi
    done
}



###############################################################################
# Create a joystick-selection.cfg for the system given as argument. 
# The created file will be filled with the input_player[1-4]_joypad_index
# values from the respective retroarch.cfg.
#
# Globals:
#   None
#
# Arguments:
#   $1 : The joystick-selection.cfg file.
#
# Returns:
#   0
function retroarch_to_jscfg() {
    [[ "$1" ]] && [[ -d "$configdir/$1" ]] || fatalError "retroarch_to_jscfg: the argument must be a valid system!"

    local temp=$(mktemp /tmp/temp.XXX)
    local jscfg="$configdir/$1/joystick-selection.cfg"
    local retroarchcfg="$configdir/$1/retroarch.cfg"
    local jsname=

    [[ -f "$retroarchcfg" ]] || fatalError "retroarch_to_jscfg: \"$retroarchcfg\" not found!"

    fill_jslist_file

    cat > "$temp" << _EoF_ 
# This file was created by the joystick-selection tool.
# It's recommended to NOT edit it manually.
# The format is pretty simmilar to a retroarch.cfg file, but it contains only
# input_player[1-4]_joypad_index, and accepts "strings" as a value.
# Example:
# input_playerN_joypad_index = "joystick name"
# If "joystick name" is an integer, then the real joystick index is used.
_EoF_
    sudo mv "$temp" "$jscfg"
    sudo chown "$user"."$user" "$jscfg"

    if [[ "$jscfg" = "$global_jscfg" ]]; then
        if [[ "$BYNAME" = "ON" ]]; then
            iniSet "joystick_selection_by_name" "true" "$jscfg"
        else
            iniSet "joystick_selection_by_name" "false" "$jscfg"
        fi
    fi

    for i in 1 2 3 4; do
        iniGet "input_player${i}_joypad_index" "$retroarchcfg"
        if [[ -z "$ini_value" ]]; then
            iniUnset "input_player${i}_joypad_index" "$((i-1))" "$jscfg"
        else
            jsname=$(js_index2name "$ini_value")
            if [[ "$jsname" = "(NOT CONNECTED)" ]]; then
                iniUnset "input_player${i}_joypad_index" "$((i-1))" "$jscfg"
            else
                iniSet "input_player${i}_joypad_index" "$jsname" "$jscfg"
            fi
        fi
    done
} # end of retroarch_to_jscfg()



###############################################################################
# Toggle the joystick selection method (by name or by index).
#
# If toggle from "by name" to "by index", just set the
# "joystick_selection_by_name" to "false" in global joystick-selection.cfg.
#
# If toggle from "by index" to "by name", make all existent system's
# joystick-selection.cfg match the current config from the
# respective retroarch.cfg.
#
# Globals:
#   BYNAME
#   byname_msg
#
# Arguments:
#   None
#
# Returns:
#   0
function toggle_byname() {
    if [[ "$BYNAME" = "ON" ]]; then
        dialog \
          --title "Toggle \"selection by name\" capability" \
          --yesno "Are you sure you want to turn OFF the joystick selection by name method?" \
          0 0 >/dev/tty || return 1

        iniSet "joystick_selection_by_name" "false" "$global_jscfg"
        BYNAME="OFF"
    else
        check_byname_is_ok || return 1

        dialog \
          --title "Toggle \"selection by name\" capability" \
          --yesno "If you turn ON the joystick selection by name method, probably your current joystick selection will be lost (but you can easily reconfigure it using this tool).\n\nAre you sure you want to turn ON the joystick selection by name method?" \
          0 0 >/dev/tty || return 1

        dialog --title "Joystick Selection" --infobox "Please wait..." 0 0

        BYNAME="ON"
        local file
        local system
        # get all the systems *joypad_index configs and convert to an
        # equivalent joystick-selection.cfg
        for file in $(find "$configdir" -name retroarch.cfg 2>/dev/null); do
            if grep -q "^[[:space:]#]*input_player[1-4]_joypad_index[[:space:]]*=" "$file"; then
                system=${file%/*}
                system=${system//$configdir\//}
                retroarch_to_jscfg "$system"
            fi
        done
    fi
    byname_msg="Selection by name is: [$BYNAME]\n\n"
} # end of toggle_byname()



# Choose between global config, system specific config, toggle byname
function main_menu() {
    while true; do
        cmd=(dialog \
             --title " Joystick Selection Main Menu " \
             --menu "${byname_msg}This is a tool to let you choose which controller to use for RetroArch players 1-4" 19 80 12)
        options=(
            1 "Global joystick selection."
            2 "System specific joystick selection."
            3 "Toggle the joystick selection \"by-name\" method."
        )
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    
        if [[ -n "$choice" ]]; then
            case $choice in
                1)  system_js_select_menu "all"
                ;;

                2)  systems_menu
                ;;

                3)  toggle_byname
                ;;
            esac
        else
            break
        fi
    done
} # end of main_menu()



###############################################################################
# Show a menu to let the user configure the input for a given system.
# At the end of this function, if the BYNAME flag is ON, the retroarch.cfg
# system file will match the configs in joystick-selection.cfg system file.
#
# Globals:
#   js_list_file
#
# Arguments:
#   $1 : The system to be configured
#
# Returns:
#   0
function system_js_select_menu() {
    [[ "$1" ]] || fatalError "js_select: missing argument: \"system\""

    fill_jslist_file

    local system="$1"
    local js_name_p=()

    local retroarchcfg="$configdir/$system/retroarch.cfg"
    local jscfg="$configdir/$system/joystick-selection.cfg"

    while true; do
        # the 'if' outside the 'for' is for a performance reason
        if [[ "$BYNAME" = "ON" ]]; then
            for i in 1 2 3 4; do
                iniGet "input_player${i}_joypad_index" "$jscfg"
                if [[ -z "$ini_value" ]]; then
                    js_name_p[$i]="** UNSET **"
                elif [[ "$ini_value" == "16" ]]; then # 16 means disabled
                    js_name_p[$i]="** DISABLED **"
                else
                    js_name_p[$i]="$ini_value $(js_is_connected "$ini_value")"
                fi
            done
        else
            for i in 1 2 3 4; do
                iniGet "input_player${i}_joypad_index" "$retroarchcfg"
                if [[ -z "$ini_value" ]]; then
                    js_name_p[$i]="** UNSET **"
                elif [[ "$ini_value" == "16" ]]; then # 16 means disabled
                    js_name_p[$i]="** DISABLED **"
                else
                    js_name_p[$i]="$ini_value:$(js_index2name "$ini_value")"
                fi
            done
        fi

        cmd=(dialog \
             --title " Joystick Selection for \"$system\" " \
             --menu "${byname_msg}OBS: UNSET/NOT CONNECTED joysticks are set to RetroArch defaults when launching a game.\n\nChoose the player you want to configure:" \
             19 80 12
        )
        options=(
            1 "${js_name_p[1]}"
            2 "${js_name_p[2]}"
            3 "${js_name_p[3]}"
            4 "${js_name_p[4]}"
        )
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    
        if [[ -n "$choice" ]]; then
            player_js_select_menu "$choice" "$system"
        else
            break
        fi
    done

    # making retroarch.cfg match the configs in joystick-selection.cfg
    # to avoid user confusion when looking at the files.
    js_to_retroarchcfg "$system"

    # if this function was invoked by "runcommand-onmenu"...
    [[ "$ON_MENU" -eq 1 ]] && return 0

    # if the system is not "all", go back to the systems_menu
    [[ "$system" != "all" ]] && systems_menu
} # end of system_js_select_menu()



###############################################################################
# Show the available joysticks and let the user choose which one to use
# for the player given as a parameter.
#
# Globals:
#   None
#
# Arguments:
#   $1  an integer [1-4] that represents the player.
#   $2  the system to configure
#
# Returns:
#   0
function player_js_select_menu() {
    [[ "$1" =~ ^[1-4]$ ]] || fatalError "player_js_select_menu: invalid argument!"
    [[ "$2" ]] && [[ -d "$configdir/$2" ]] || fatalError "player_js_select_menu: arg2 must be a valid system!"

    local i="$1"
    local jscfg="$configdir/$2/joystick-selection.cfg"
    local retroarchcfg="$configdir/$2/retroarch.cfg"
    
    fill_jslist_file

    options="U \"Unset\""
    # The sed below obtain the joystick list with the format
    # index "Joystick Name"
    # to use as dialog menu options
    options+=" $(sed 's/:\(.*\)/ "\1"/' "$jslist_file")"

    # do not give the option to disable input for player1
    [[ "$i" -ne 1 ]] && options+=" D \"Disable input for player$i\""

    choice=$(
        echo "$options" \
        | xargs dialog \
            --title " Joystick Selection for \"$system\" " \
            --menu "${byname_msg}Choose the joystick for player$i" \
            19 80 12 2>&1 >/dev/tty
    )

    if [[ -n "$choice" ]]; then
        case $choice in
            U)
                iniUnset "input_player${i}_joypad_index" "$((i-1))" "$jscfg"
                iniUnset "input_player${i}_joypad_index" "$((i-1))" "$retroarchcfg"
            ;;

            D)
                # index 16 is an ugly workaround to disable joypad input
                if [[ "$BYNAME" = "ON" ]]; then
                    iniSet "input_player${i}_joypad_index" "16" "$jscfg"
                else
                    iniSet "input_player${i}_joypad_index" "16" "$retroarchcfg"
                fi
            ;;

            *)
                if [[ "$BYNAME" = "ON" ]]; then
                    iniSet "input_player${i}_joypad_index" "$(js_index2name "$choice")" "$jscfg"
                else
                    iniSet "input_player${i}_joypad_index" "$choice" "$retroarchcfg"
                fi
            ;;
        esac
    fi
} # end of player_js_select_menu()



###############################################################################
# Show the available systems to configure.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0
function systems_menu() {
    local file
    local system_list
    local system

    for file in $(find "$configdir" -name retroarch.cfg 2>/dev/null); do
        system=${file%/*}
        system=${system//$configdir\//}
        system_list+="$system\n"
    done
    system_list=$(echo -e "$system_list" | grep -v "^all$" | sort | nl )

    cmd=(dialog \
         --title "Joystick Selection" \
         --menu "What system do you want to configure?" 25 80 20)
    options=( $system_list )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty) || return 1

    system=$(echo -e "$system_list" | grep "^[[:blank:]]*$choice[[:blank:]]\+" | cut -f2)

    system_js_select_menu "$system"
}

