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
#   jsfuncs:    the functions to deal with joystick's indexes and names.
#               They were all here, but some of them are useful for
#               runcommand-on{start,end}.sh, then I decided to put them
#               in a different file (it comes from the same github
#               repo as this script, you probably already have it).
#   inifuncs:   a set of useful bash functions to manage config files
#               (it's used here to manipulate retroarch.cfg like files,
#               if you have RetroPie installed, the you have inifuncs
#               at /opt/retropie/lib/inifuncs.sh).
#   runcommand: actually the dependency is the runcommand-onstart feature.
#               This feature was added to the RetroPie's runcommand script
#               in Aug/2016. This is a dependency only to
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
#
# Possible issues:
#       - if the joystick name has ':' colon, we can face some problems
#         (cut field separator for jslist output).
#       - The RetroPie main developer said that he plans to change the way
#         iniGet works [https://retropie.org.uk/forum/topic/3099/feature-request-for-inifuncs-sh].
#         Maybe I'll need to keep a copy of the current inifuncs.sh in
#         the future...
#
# meleu, June-2017

# I've noticed a little delay to show the first main menu when running
# on a raspi1. This infobox is just to say that something is happenning.
dialog --title 'Joystick Selection' --infobox 'Please wait...' 0 0

# get the functions and global variables (the jsfuncs sources inifuncs)
source "/opt/retropie/supplementary/joystick-selection/jsfuncs.sh"

# checking if jslist exists and is executable
if [[ ! -x "$jslist_exe" ]]; then
    dialog --title "Error" --msgbox "\"$jslist_exe\" not found or isn't executable!" 20 60 >/dev/tty
    safe_exit 1
fi

# checking for runcommand-menu feature
jsonmenu="/opt/retropie/configs/all/runcommand-menu/select joystick.sh"
if [[ ! -s "$jsonmenu" ]]; then
    mkdir -p "$(dirname "$jsonmenu")"
    cat > "$jsonmenu" << _EoF_
system="\$1"
game="\$(basename "\$3")"
ON_MENU=1

source "/opt/retropie/supplementary/joystick-selection/jsfuncs.sh"

system_js_select_menu "\$system" || exit 0
dialog --title " Launch the game? " --yesno "\nDo you want to launch \"\$game\" now?\n\n" 0 0 >/dev/tty \
    && exit 2 \
    || exit 0
_EoF_
fi

get_configs

start_joy2key

main_menu

safe_exit 0
