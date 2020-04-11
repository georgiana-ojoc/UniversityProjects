#include "draw.h"
#include "game.h"
#include "graphics.h"
#include <iostream>
#include "menu.h"
#include "winbgim.h"
#include <windows.h>

using namespace std;

void start(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
Meniu:
	menu(screen, data, player, boxesOnLine, boxesOnColumn);
	int x, y;
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
	}
	if (x >= screen.width / 2 - 450 && y >= 300 && x <= screen.width / 2 + 450 && y <= 450)
	{
		Beep(400, 100);
		clearviewport();
		selectGameMode(screen, data, player, boxesOnLine, boxesOnColumn);
		goto Meniu;
	}
	if (x >= screen.width / 2 - 450 && y >= 500 && x <= screen.width / 2 + 450 && y <= 650)
	{
		Beep(400, 100);
		clearviewport();
		reloadGame(screen, data);
		delay(250);
		goto Meniu;
	}
	if (x >= screen.width / 2 - 450 && y >= 700 && x <= screen.width / 2 + 450 && y <= 850)
	{
		Beep(400, 100);
		clearviewport();
		howToPlay(screen, data, player, boxesOnLine, boxesOnColumn);
		goto Meniu;
	}
	if (x >= screen.width / 2 - 450 && y >= 900 && x <= screen.width / 2 + 450 && y <= 1050)
	{
		Beep(400, 100);
		closegraph();
		exit(0);
	}
}

void menu(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 450, 300, screen.width / 2 + 450, 450);
	bar(screen.width / 2 - 450, 500, screen.width / 2 + 450, 650);
	bar(screen.width / 2 - 450, 700, screen.width / 2 + 450, 850);
	bar(screen.width / 2 - 450, 900, screen.width / 2 + 450, 1050);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 9);
	outtextxy(screen.width / 2, 100, "DOTS AND BOXES");
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	outtextxy(screen.width / 2, 400, "PLAY NEW GAME");
	outtextxy(screen.width / 2, 600, "RELOAD GAME");
	outtextxy(screen.width / 2, 800, "HOW TO PLAY");
	outtextxy(screen.width / 2, 1000, "QUIT");
}

void howToPlay(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	clearviewport();
	setbkcolor(BEIGE);
	cleardevice();
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 9);
	outtextxy(screen.width / 2, 100, "HOW TO PLAY");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 200, "1. Know the goal of the game to keep track of the rules.");
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 1);
	outtextxy(150, 250, "Dots and boxes is a simple game with a simple goal: whoever owns the most boxes at the end of the game wins. You and your");
	outtextxy(150, 300, "opponent take turns drawing horizontal or vertical lines to connect the boxes. When someone draws a line that completes a box,");
	outtextxy(150, 350, "you write your initial inside to win the box. Once all the dots have been connected, you can count up the boxes and find the winner.");
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 425, "2. Draw the forth wall of a box to win it for yourself.");
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 1);
	outtextxy(150, 475, "Each box is worth one point, so write your initial in the completed box to score it for yourself. If you have two different colored pens,");
	outtextxy(150, 525, "you can also scribble your color in to mark it as well.");
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 600, "3. Take an extra turn if you complete a box.");
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 1);
	outtextxy(150, 650, "Once you've finished a box, drawing the 4th line, you get to keep going. This allows you to create chains, where the 4th wall of your");
	outtextxy(150, 700, "first box makes the 3rd wall of another box. You can then use your extra turn to complete this box too, keeping the cycle alive until");
	outtextxy(150, 750, "the chain runs out. A chain is a line of boxes that one player can take in one turn, and is the central strategy element in boxes.");
	outtextxy(150, 800, "Whoever gets the longest and/or most chains usually wins. You must take your extra turn - you cannot skip it.");
	readimagefile("completedBox.jpg", screen.width / 2 - 100, 825, screen.width / 2 + 100, 1000);
	setlinestyle(SOLID_LINE, 0xFFFF, 1);
	rectangle(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	int x, y;
HowToPlay:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			return;
		}
		else
		{
			goto HowToPlay;
		}
	}
}

void selectGameMode(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 550, 300, screen.width / 2 + 550, 450);
	bar(screen.width / 2 - 550, 500, screen.width / 2 + 550, 650);
	bar(screen.width / 2 - 550, 700, screen.width / 2 + 550, 850);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	outtextxy(screen.width / 2, 100, "SELECT GAME MODE");
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(screen.width / 2, 400, "PLAYER VERSUS PLAYER");
	outtextxy(screen.width / 2, 600, "PLAYER VERSUS COMPUTER");
	outtextxy(screen.width / 2, 800, "COMPUTER VERSUS COMPUTER");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(150, 100, "BACK");
	int x, y;
SelectGameMode:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 550 && y >= 300 && x <= screen.width / 2 + 550 && y <= 450)
		{
			data.gameMode = GAME_ONE;
			Beep(400, 100);
			clearviewport();
			insertNameForPlayer1VersusPlayer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= screen.width / 2 - 550 && y >= 500 && x <= screen.width / 2 + 550 && y <= 650)
		{
			data.gameMode = GAME_TWO;
			Beep(400, 100);
			clearviewport();
			insertNameForPlayerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= screen.width / 2 - 550 && y >= 700 && x <= screen.width / 2 + 550 && y <= 850)
		{
			data.gameMode = GAME_THREE;
			Beep(400, 100);
			clearviewport();
			rowsForComputerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			start(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto SelectGameMode;
		}
	}
}

void insertNameForPlayer1VersusPlayer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 300, screen.height / 2 - 100, screen.width / 2 + 600, screen.height / 2);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	outtextxy(screen.width / 2, 100, "INSERT NAME");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	outtextxy(screen.width / 2 - 750, screen.height / 2 - 25, "Player 1: ");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	bar(screen.width / 2 - 100, screen.height - 300, screen.width / 2 + 100, screen.height - 225);
	outtextxy(screen.width / 2 - 85, screen.height - 250, "NEXT");
	writePlayer(screen, player, PLAYER_ONE);
	int x, y;
InserNameforPlayer1VersusPlayer:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 100 && y >= screen.height - 300 && x <= screen.width / 2 + 100 && y <= screen.height - 225)
		{
			Beep(400, 100);
			clearviewport();
			insertNameForPlayer2VersusPlayer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			selectGameMode(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto InserNameforPlayer1VersusPlayer;
		}
	}
}

void insertNameForPlayer2VersusPlayer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 300, screen.height / 2 - 100, screen.width / 2 + 600, screen.height / 2);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	outtextxy(screen.width / 2, 100, "INSERT NAME");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	outtextxy(screen.width / 2 - 750, screen.height / 2 - 25, "Player 2: ");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	bar(screen.width / 2 - 100, screen.height - 300, screen.width / 2 + 100, screen.height - 225);
	outtextxy(screen.width / 2 - 85, screen.height - 250, "NEXT");
	writePlayer(screen, player, PLAYER_TWO);
	int x, y;
InserNameforPlayer2VersusPlayer:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 100 && y >= screen.height - 300 && x <= screen.width / 2 + 100 && y <= screen.height - 225)
		{
			Beep(400, 100);
			clearviewport();
			rowsForPlayerVersusPlayer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			insertNameForPlayer1VersusPlayer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto InserNameforPlayer2VersusPlayer;
		}
	}
}

void rowsForPlayerVersusPlayer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 300, screen.height / 2 - 100, screen.width / 2 + 600, screen.height / 2);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(screen.width / 2, 100, "INSERT NUMBER OF ROWS (1 - 8)");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	outtextxy(screen.width / 2 - 750, screen.height / 2 - 25, "Rows: ");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	bar(screen.width / 2 - 100, screen.height - 300, screen.width / 2 + 100, screen.height - 225);
	outtextxy(screen.width / 2 - 85, screen.height - 250, "NEXT");
	boxesOnColumn = writeNumber(screen);
	int x, y;
RowsForPlayerVersusPlayer:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 100 && y >= screen.height - 300 && x <= screen.width / 2 + 100 && y <= screen.height - 225)
		{
			Beep(400, 100);
			clearviewport();
			columnsForPlayerVersusPlayer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			insertNameForPlayer2VersusPlayer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto RowsForPlayerVersusPlayer;
		}
	}
}

void columnsForPlayerVersusPlayer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 300, screen.height / 2 - 100, screen.width / 2 + 600, screen.height / 2);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(screen.width / 2, 100, "INSERT NUMBER OF COLUMNS (1 - 8)");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	outtextxy(screen.width / 2 - 750, screen.height / 2 - 25, "Columns: ");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	bar(screen.width / 2 - 100, screen.height - 300, screen.width / 2 + 100, screen.height - 225);
	outtextxy(screen.width / 2 - 85, screen.height - 250, "NEXT");
	boxesOnLine = writeNumber(screen);
	int x, y;
ColumnsForPlayerVersusPlayer:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 100 && y >= screen.height - 300 && x <= screen.width / 2 + 100 && y <= screen.height - 225)
		{
			Beep(400, 100);
			clearviewport();
			playNewGame(screen, data, player, boxesOnLine, boxesOnColumn);
			Dot mouse = getMouseCoordinates();
			actionBackButton(screen, data, player, mouse);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			start(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto ColumnsForPlayerVersusPlayer;
		}
	}
}

void insertNameForPlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 300, screen.height / 2 - 100, screen.width / 2 + 600, screen.height / 2);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	outtextxy(screen.width / 2, 100, "INSERT NAME");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	outtextxy(screen.width / 2 - 750, screen.height / 2 - 25, "Player: ");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	bar(screen.width / 2 - 100, screen.height - 300, screen.width / 2 + 100, screen.height - 225);
	outtextxy(screen.width / 2 - 85, screen.height - 250, "NEXT");
	writePlayer(screen, player, PLAYER_ONE);
	int x, y;
InserNameforPlayerVersusComputer:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 100 && y >= screen.height - 300 && x <= screen.width / 2 + 100 && y <= screen.height - 225)
		{
			Beep(400, 100);
			clearviewport();
			rowsForPlayerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			start(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto InserNameforPlayerVersusComputer;
		}
	}
}

void rowsForPlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 300, screen.height / 2 - 100, screen.width / 2 + 600, screen.height / 2);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(screen.width / 2, 100, "INSERT NUMBER OF ROWS (1 - 8)");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	outtextxy(screen.width / 2 - 750, screen.height / 2 - 25, "Rows: ");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	bar(screen.width / 2 - 100, screen.height - 300, screen.width / 2 + 100, screen.height - 225);
	outtextxy(screen.width / 2 - 85, screen.height - 250, "NEXT");
	boxesOnColumn = writeNumber(screen);
	int x, y;
RowsForPlayerVersusComputer:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 100 && y >= screen.height - 300 && x <= screen.width / 2 + 100 && y <= screen.height - 225)
		{
			Beep(400, 100);
			clearviewport();
			columnsForPlayerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			insertNameForPlayerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto RowsForPlayerVersusComputer;
		}
	}
}

void columnsForPlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 300, screen.height / 2 - 100, screen.width / 2 + 600, screen.height / 2);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(screen.width / 2, 100, "INSERT NUMBER OF COLUMNS (1 - 8)");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	outtextxy(screen.width / 2 - 750, screen.height / 2 - 25, "Columns: ");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	bar(screen.width / 2 - 100, screen.height - 300, screen.width / 2 + 100, screen.height - 225);
	outtextxy(screen.width / 2 - 85, screen.height - 250, "NEXT");
	boxesOnLine = writeNumber(screen);
	int x, y;
ColumnsForPlayerVersusComputer:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 100 && y >= screen.height - 300 && x <= screen.width / 2 + 100 && y <= screen.height - 225)
		{
			Beep(400, 100);
			clearviewport();
			selectDifficultyForPlayerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			rowsForPlayerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto ColumnsForPlayerVersusComputer;
		}
	}
}

void selectDifficultyForPlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 350, 300, screen.width / 2 + 350, 450);
	bar(screen.width / 2 - 350, 500, screen.width / 2 + 350, 650);
	bar(screen.width / 2 - 350, 700, screen.width / 2 + 350, 850);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 9);
	outtextxy(screen.width / 2, 100, "Select difficulty");
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	outtextxy(screen.width / 2, 400, "EASY");
	outtextxy(screen.width / 2, 600, "MEDIUM");
	outtextxy(screen.width / 2, 800, "HARD");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(150, 100, "BACK");
	int x, y;
SelectGameDifficulty:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 550 && y >= 300 && x <= screen.width / 2 + 550 && y <= 450)
		{
			data.gameDifficulty = EASY;
			Beep(400, 100);
			clearviewport();
			playNewGame(screen, data, player, boxesOnLine, boxesOnColumn);
			Dot mouse = getMouseCoordinates();
			actionBackButton(screen, data, player, mouse);
		}
		if (x >= screen.width / 2 - 550 && y >= 500 && x <= screen.width / 2 + 550 && y <= 650)
		{
			data.gameDifficulty = MEDIUM;
			Beep(400, 100);
			clearviewport();
			playNewGame(screen, data, player, boxesOnLine, boxesOnColumn);
			Dot mouse = getMouseCoordinates();
			actionBackButton(screen, data, player, mouse);
		}
		if (x >= screen.width / 2 - 550 && y >= 700 && x <= screen.width / 2 + 550 && y <= 850)
		{
			data.gameDifficulty = HARD;
			Beep(400, 100);
			clearviewport();
			playNewGame(screen, data, player, boxesOnLine, boxesOnColumn);
			Dot mouse = getMouseCoordinates();
			actionBackButton(screen, data, player, mouse);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			columnsForPlayerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto SelectGameDifficulty;
		}
	}
}

void rowsForComputerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 300, screen.height / 2 - 100, screen.width / 2 + 600, screen.height / 2);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(screen.width / 2, 100, "INSERT NUMBER OF ROWS (1 - 8)");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	outtextxy(screen.width / 2 - 750, screen.height / 2 - 25, "Rows: ");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	bar(screen.width / 2 - 100, screen.height - 300, screen.width / 2 + 100, screen.height - 225);
	outtextxy(screen.width / 2 - 85, screen.height - 250, "NEXT");
	int x, y;
	boxesOnColumn = writeNumber(screen);
RowsForComputerVersusComputer:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 100 && y >= screen.height - 300 && x <= screen.width / 2 + 100 && y <= screen.height - 225)
		{
			Beep(400, 100);
			clearviewport();
			columnsForComputerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			start(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto RowsForComputerVersusComputer;
		}
	}
}

void columnsForComputerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	bar(screen.width / 2 - 300, screen.height / 2 - 100, screen.width / 2 + 600, screen.height / 2);
	setcolor(CHOCOLATE);
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(screen.width / 2, 100, "INSERT NUMBER OF COLUMNS (1 - 8)");
	settextjustify(LEFT_TEXT, CENTER_TEXT);
	outtextxy(screen.width / 2 - 750, screen.height / 2 - 25, "Columns: ");
	bar(50, 50, 300, 125);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	outtextxy(100, 100, "BACK");
	bar(screen.width / 2 - 100, screen.height - 300, screen.width / 2 + 100, screen.height - 225);
	outtextxy(screen.width / 2 - 85, screen.height - 250, "NEXT");
	boxesOnLine = writeNumber(screen);
	int x, y;
ColumnsForComputerVersusComputer:
	while (!ismouseclick(WM_LBUTTONDOWN))
		;
	if (ismouseclick(WM_LBUTTONDOWN))
	{
		clearmouseclick(WM_LBUTTONDOWN);
		x = mousex();
		y = mousey();
		if (x >= screen.width / 2 - 100 && y >= screen.height - 300 && x <= screen.width / 2 + 100 && y <= screen.height - 225)
		{
			data.gameDifficulty = MEDIUM;
			Beep(400, 100);
			clearviewport();
			playNewGame(screen, data, player, boxesOnLine, boxesOnColumn);
			Dot mouse = getMouseCoordinates();
			actionBackButton(screen, data, player, mouse);
		}
		if (x >= 50 && y >= 50 && x <= 300 && y <= 125)
		{
			Beep(400, 100);
			clearviewport();
			rowsForComputerVersusComputer(screen, data, player, boxesOnLine, boxesOnColumn);
		}
		else
		{
			goto ColumnsForComputerVersusComputer;
		}
	}
}
