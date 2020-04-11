#include "draw.h"
#include "game.h"
#include "graphics.h"
#include <iostream>
#include "menu.h"

using namespace std;

int main()
{
    double first = -5.12;
	Screen screen = getScreenDimensions();
	DotsAndBoxesData data;
	Player player[3];
	unsigned boxesOnLine = 0;
	unsigned boxesOnColumn = 0;
	initwindow(screen.width, screen.height, "", -3, -3, false, false);
	start(screen, data, player, boxesOnLine, boxesOnColumn);
	return 0;
}