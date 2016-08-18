#!/usr/bin/env bash
# joystick_selection.sh
#######################
# Let the user define which controller to use for RetroArch players 1-4,
# global and system specific.
#
# The joystick selection has two methods of work: 1) selection by joystick
# index and 2) by joystick name.
# The advantage of the selection by name method is that there is no need
# to care about the joystick connection order. You can configure your
# "Generic USB SNES gamepad" to be the player1 no matter what USB port
# you use. Or, better yet, configure your "Fancy Bluetooth joypad" to be the
# player1 no matter what was the order it was paired or how many USB pads
# are connected.
#
# Dependencies:
#   jslist:     a small C program that list the available joysticks and
#               their respective indexes. (it comes from the same github
#               repository as this script, you probably already have it).
#   jsfuncs:    some functions to deal with joystick's indexes and names.
#               They were all here, but some of them are useful for
#               runcommand-on{start,end}.sh, then I decided to put them
#               in a different file (it comes from the same github
#               repo as this script, you probably already have it).
#   inifuncs:   a set of useful bash functions to manage config files
#               (it's used here to manipulate retroarch.cfg like files,
#               if you have RetroPie installed, the you have inifuncs
#               at /opt/retropie/lib/inifuncs.sh).
#   runcommand: actually the dependency is the runcommand-onstart feature.
#               Recently (Aug/2016) this feature was added to the
#               RetroPie's runcommand script. This is a dependency only to
#               use the joystick selection by name. If the installed
#               runcommand doesn't have this feature, the joystick_selection
#               tool doesn't allow the user turn on the joystick selection by
#               name method (you can use the "by index" method anyway).
#
# TODO:
#       - if joystick selection by name is on AND config_save_on_exit is on AND
#         the user changes the joypads for players1-4 via RGUI, the
#         joystick-selection will override these changes when launching again.
#         Needs a simple workaround using runcommand-onend.sh. Easy to solve.
#       - add a way to select the joystick to __joy2key_dev
#
# Possible issues:
#       - if the joystick name has ':' colon, we can face some problems
#         (cut field separator for jslist output).
#       - The RetroPie main developer said that he plans to change the way
#         iniGet works [https://retropie.org.uk/forum/topic/3099/feature-request-for-inifuncs-sh].
#         Maybe I'll need to keep a copy of the current inifuncs.sh in
#         the future...
#
# Note for developers: It's better to start reading the code from jsfuncs.sh.
#
# meleu, 2016/08

# get some usefull functions and global variables (the jsfuncs sources inifuncs)
source "/opt/retropie/supplementary/joystick-selection/jsfuncs.sh"


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
                else
                    js_name_p[$i]="$ini_value $(js_is_connected "$ini_value")"
                fi
            done
        else
            for i in 1 2 3 4; do
                iniGet "input_player${i}_joypad_index" "$retroarchcfg"
                if [[ -z "$ini_value" ]]; then
                    js_name_p[$i]="** UNSET **"
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



# STARTING POINT ##############################################################

# I've noticed a little delay to show the first main menu when running
# on a raspi1. This infobox is just to say that something is happenning.
dialog --title 'Joystick Selection' --infobox 'Please wait...' 0 0

# checking if jslist exists and is executable
[[ -x "$jslist_exe" ]] || {
    dialog --title "Error" \
      --msgbox "\"$jslist_exe\" not found or isn't executable!" \
      20 60 >/dev/tty
    safe_exit 1
}

get_configs

start_joy2key

main_menu

safe_exit 0
