/* jslist.c
 * This little program just list the joysticks connected to the system.
 * The ouput format is "index:JoystickName".
 * It returns a non-zero value if no joystick was found; otherwise, zero.
 *
 * To compile (libsdl2 is installed by default on RetroPie):
 * [prompt]$ gcc jslist.c -o jslist $(sdl2-config --cflags --libs)
 */

#include <stdio.h>
#include "SDL.h"

int main(int argc, char *argv[]) {
    int num_joy, i;

    if(argc > 1) {
        printf("%s%s%s%s",
            "\nThis program lists the joysticks connected to the system.\n",
            "It returns a non-zero value if no joystick was found.\n",
	    "The ouput format is:\nindex:JoystickName\n\n",
            "Usage: jslist\n\n");

        return 1;
    }

    SDL_Init(SDL_INIT_JOYSTICK);

    num_joy = SDL_NumJoysticks();

    if(num_joy < 1) {
        fputs("No joystick found!\n", stderr);
        SDL_Quit();
        return -1;
    }

    for(i = 0; i < num_joy; i++)
        printf("%d:%s\n", i, SDL_JoystickNameForIndex(i));

    SDL_Quit();
    return 0;
}
