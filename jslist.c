/* jslist.c
 * This little program just list the joysticks connected to the system.
 * The ouput format is "index:JoystickName".
 */

#include <stdio.h>
#include "SDL.h"

int main(void) {
	int num_joy, i;

	SDL_Init(SDL_INIT_JOYSTICK);

	num_joy = SDL_NumJoysticks();

	for(i = 0; i < num_joy; i++)
		printf("%d:%s\n", i, SDL_JoystickNameForIndex(i));

	SDL_Quit();
	return 0;
}
