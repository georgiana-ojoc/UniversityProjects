#include <ctime>
#include <cstring>
#include "draw.h"
#include <fstream>
#include "game.h"
#include "graphics.h"
#include <iostream>
#include "menu.h"

using namespace std;

Screen getScreenDimensions()
{
	Screen screen;
	screen.width = GetSystemMetrics(SM_CXSCREEN);
	screen.height = GetSystemMetrics(SM_CYSCREEN);
	return screen;
}

void setColorPlayer(unsigned player)
{
	if (player == PLAYER_ONE)
		setcolor(PURPLE);
	else setcolor(ORANGE);
}

void setLineColorInBox(DotsAndBoxesData &data, Line line)
{
	unsigned color;
	if (data.currentPlayer == PLAYER_ONE)
		color = PURPLE;
	else color = ORANGE;
	if (strcmp(line.position, LEFT) == 0)
		data.boxes[line.boxIndex].colorLeftLine = color;
	else if (strcmp(line.position, RIGHT) == 0)
		data.boxes[line.boxIndex].colorRightLine = color;
	else if (strcmp(line.position, TOP) == 0)
		data.boxes[line.boxIndex].colorTopLine = color;
	else if (strcmp(line.position, BOTTOM) == 0)
		data.boxes[line.boxIndex].colorBottomLine = color;
}

void writePlayer(Screen screen, Player player[], unsigned currentPlayer)
{
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	setColorPlayer(currentPlayer);
	unsigned number;
	char c;
	char s[2];
	bool _continue = true;
	Dot dot;
	dot.x = screen.width / 2 - 250;
	dot.y = screen.height / 2 - 25;
	while (_continue)
		if (!kbhit())
		{
			c = getch();
			if (c == 13)
				_continue = false;
			else if (c == 8)
			{
				setcolor(BEIGE);
				if (dot.x >= screen.width / 2 - 175)
					dot.x -= 75;
				number = strlen(player[currentPlayer].name);
				player[currentPlayer].name[number - 1] = '\0';
				s[0] = 'W';
				s[1] = '\0';
				setcolor(BEIGE);
				outtextxy(dot.x, dot.y, s);
			}
			else if (dot.x <= screen.width / 2 + 500)
			{
				s[0] = c;
				s[1] = '\0';
				strcat(player[currentPlayer].name, s);
				setColorPlayer(currentPlayer);
				outtextxy(dot.x, dot.y, s);
				dot.x += 75;
			}
		}
}

unsigned writeNumber(Screen screen)
{
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	setcolor(CHOCOLATE);
	unsigned number= 0;
	char c;
	char s[2];
	bool _continue = true;
	Dot dot;
	dot.x = screen.width / 2 - 250;
	dot.y = screen.height / 2 - 25;
	while (_continue)
		if (!kbhit())
		{
			c = getch();
			if (c == 13)
				_continue = false;
			else if (c == 8 || c < 49 || c > 56)
			{
				setcolor(BEIGE);
				if (dot.x >= screen.width / 2 - 175)
					dot.x -= 75;
				number = 0;
				s[0] = '8';
				s[1] = '\0';
				setcolor(BEIGE);
				outtextxy(dot.x, dot.y, s);
			}
			else if (dot.x <= screen.width / 2 - 250)
			{
				s[0] = c;
				s[1] = '\0';
				number = (unsigned)c - 48;
				setcolor(CHOCOLATE);
				outtextxy(dot.x, dot.y, s);
				dot.x += 75;
			}
		}
	return number;
}

void drawBoard(DotsAndBoxesData &data)
{

	setfillstyle(SOLID_FILL, CHOCOLATE);
	bar(data.windowLeftSideLength - data.dotRadius * 3,
		data.windowTopSideLength - data.dotRadius * 3,
		data.windowLeftSideLength + data.boxesOnLine * data.boxLineLength + data.dotRadius * 3,
		data.windowTopSideLength + data.boxesOnColumn * data.boxLineLength + data.dotRadius * 3);
	setcolor(PINK);
	setfillstyle(SOLID_FILL, PINK);
	unsigned i, j;
	for (i = 0; i < data.dotsOnColumn; i++)
		for (j = 0; j < data.dotsOnLine; j++)
		{
			circle(data.dotsCoordinates[i][j].x, data.dotsCoordinates[i][j].y, data.dotRadius);
			fillellipse(data.dotsCoordinates[i][j].x, data.dotsCoordinates[i][j].y, data.dotRadius, data.dotRadius);
		}
}

void printCurrentPlayer(Screen screen, DotsAndBoxesData &data, Player player[])
{
	setbkcolor(BEIGE);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	setcolor(BEIGE);
	outtextxy(screen.width / 2, data.windowTopSideLength / 2, player[data.currentPlayer % 2 + 1].name);
	setColorPlayer(data.currentPlayer);
	outtextxy(screen.width / 2, data.windowTopSideLength / 2, player[data.currentPlayer].name);
}

void printScore(Screen screen, DotsAndBoxesData &data, Player player[])
{
	setbkcolor(BEIGE);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 9);
	char score[3] = "\0";
	itoa(player[1].boxes, score, 10);
	setColorPlayer(PLAYER_ONE);
	outtextxy(data.windowLeftSideLength / 2, screen.height / 2, score);
	itoa(player[2].boxes, score, 10);
	setColorPlayer(PLAYER_TWO);
	outtextxy(screen.width - data.windowLeftSideLength / 2, screen.height / 2, score);
}

void drawSaveButton(Screen screen, DotsAndBoxesData &data)
{
	setcolor(ROSE);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	outtextxy(screen.width - textwidth("Save"), data.windowTopSideLength / 2, "Save");
}

void drawBackButton(Screen screen, DotsAndBoxesData &data)
{
	setcolor(ROSE);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	outtextxy(textwidth("Back"), data.windowTopSideLength / 2, "Back");
}

void getWindow(Screen screen, DotsAndBoxesData &data, Player player[])
{
	setbkcolor(BEIGE);
	cleardevice();
	settextjustify(CENTER_TEXT, CENTER_TEXT);
	drawBoard(data);
	printCurrentPlayer(screen, data, player);
	printScore(screen, data, player);
	drawSaveButton(screen, data);
	drawBackButton(screen, data);
}

Dot getMouseCoordinates()
{
	Dot mouse;
	bool _continue = true;
	while (_continue)
		if (ismouseclick(WM_LBUTTONDOWN))
		{
			mouse.x = mousex();
			mouse.y = mousey();
			mouse.event = DOWN;
			clearmouseclick(WM_LBUTTONDOWN);
			_continue = false;
		}
		else
		{
			mouse.x = mousex();
			mouse.y = mousey();
			mouse.event = UP;
			clearmouseclick(WM_LBUTTONUP);
			_continue = false;
		}
	return mouse;
}

void drawLeftLine(DotsAndBoxesData &data, Line _line)
{
	line(data.dotsCoordinates[_line.boxLine][_line.boxColumn].x,
		data.dotsCoordinates[_line.boxLine][_line.boxColumn].y + data.dotRadius,
		data.dotsCoordinates[_line.boxLine + 1][_line.boxColumn].x,
		data.dotsCoordinates[_line.boxLine + 1][_line.boxColumn].y - data.dotRadius);
}

void drawRightLine(DotsAndBoxesData &data, Line _line)
{
	line(data.dotsCoordinates[_line.boxLine][_line.boxColumn + 1].x,
		data.dotsCoordinates[_line.boxLine][_line.boxColumn + 1].y + data.dotRadius,
		data.dotsCoordinates[_line.boxLine + 1][_line.boxColumn + 1].x,
		data.dotsCoordinates[_line.boxLine + 1][_line.boxColumn + 1].y - data.dotRadius);
}

void drawTopLine(DotsAndBoxesData &data, Line _line)
{
	line(data.dotsCoordinates[_line.boxLine][_line.boxColumn].x + data.dotRadius,
		data.dotsCoordinates[_line.boxLine][_line.boxColumn].y,
		data.dotsCoordinates[_line.boxLine][_line.boxColumn + 1].x - data.dotRadius,
		data.dotsCoordinates[_line.boxLine][_line.boxColumn + 1].y);
}

void drawBottomLine(DotsAndBoxesData &data, Line _line)
{
	line(data.dotsCoordinates[_line.boxLine + 1][_line.boxColumn].x + data.dotRadius,
		data.dotsCoordinates[_line.boxLine + 1][_line.boxColumn].y,
		data.dotsCoordinates[_line.boxLine + 1][_line.boxColumn + 1].x - data.dotRadius,
		data.dotsCoordinates[_line.boxLine + 1][_line.boxColumn + 1].y);
}

void drawLine(DotsAndBoxesData &data, Line line)
{
	data.dotRadius += 4;
	if (strcmp(line.position, LEFT) == 0)
		drawLeftLine(data, line);
	else if (strcmp(line.position, RIGHT) == 0)
		drawRightLine(data, line);
	else if (strcmp(line.position, TOP) == 0)
		drawTopLine(data, line);
	else if (strcmp(line.position, BOTTOM) == 0)
		drawBottomLine(data, line);
	data.dotRadius -= 4;
}

Dot getCenterBox(DotsAndBoxesData &data, Line line)
{
	Dot centerBox;
	centerBox.x = data.dotsCoordinates[line.boxLine][line.boxColumn].x + data.boxLineLength / 2;
	centerBox.y = data.dotsCoordinates[line.boxLine][line.boxColumn].y + data.boxLineLength / 2;
	return centerBox;
}

void printOwningPlayer(Screen screen, DotsAndBoxesData &data, Line line, Player player[])
{
	setbkcolor(CHOCOLATE);
	char initial[2];
	initial[1] = '\0';
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	Dot centerBox = getCenterBox(data, line);
	if (data.currentPlayer == PLAYER_ONE)
	{
		player[1].boxes++;
		initial[0] = player[1].name[0];
		setcolor(PURPLE);
		outtextxy(centerBox.x, centerBox.y, initial);
	}
	else
	{
		player[2].boxes++;
		initial[0] = player[2].name[0];
		setcolor(ORANGE);
		outtextxy(centerBox.x, centerBox.y, initial);
	}
	printScore(screen, data, player);
}

void printExistingOwningPlayer(Screen screen, DotsAndBoxesData &data, Line line, Player player[])
{
	setbkcolor(CHOCOLATE);
	char initial[2];
	initial[1] = '\0';
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 5);
	Dot centerBox = getCenterBox(data, line);
	if (data.boxes[line.boxIndex].owningPlayer == PLAYER_ONE)
	{
		initial[0] = player[1].name[0];
		setcolor(PURPLE);
		outtextxy(centerBox.x, centerBox.y, initial);
	}
	else
	{
		initial[0] = player[2].name[0];
		setcolor(ORANGE);
		outtextxy(centerBox.x, centerBox.y, initial);
	}
}

void printWinner(Screen screen, DotsAndBoxesData &data, Player player[])
{
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 9);
	char winner[15];
	if (player[1].boxes > player[2].boxes)
	{
		strcpy(winner, player[1].name);
		strcat(winner, " won");
		setColorPlayer(PLAYER_ONE);
		outtextxy(screen.width / 2, data.windowTopSideLength / 2, winner);
	}
	else if (player[2].boxes > player[1].boxes)
	{
		strcpy(winner, player[2].name);
		strcat(winner, " won");
		setColorPlayer(PLAYER_TWO);
		outtextxy(screen.width / 2, data.windowTopSideLength / 2, winner);
	}
	else outtextxy(screen.width / 2, data.windowTopSideLength / 2, "Draw");
}

void drawReloadedGame(Screen screen, DotsAndBoxesData &data, Player player[])
{
	setlinestyle(SOLID_LINE, 0xFFFF, 7);
	data.dotRadius += 4;
	unsigned i;
	unsigned boxIndex;
	unsigned boxColumn;
	unsigned boxLine;
	Line line;
	for (i = 0; i < data.boxesOnLine * data.boxesOnColumn; i++)
	{
		if (data.boxes[i].hasLeftLine)
		{
			setcolor(data.boxes[i].colorLeftLine);
			boxIndex = i;
			boxColumn = boxIndex % data.boxesOnLine;
			boxLine = (boxIndex - boxColumn) / data.boxesOnLine;
			line = getLine(boxLine, boxColumn, boxIndex, LEFT);
			drawLeftLine(data, line);
		}
		if (data.boxes[i].hasRightLine)
		{
			setcolor(data.boxes[i].colorRightLine);
			boxIndex = i;
			boxColumn = boxIndex % data.boxesOnLine;
			boxLine = (boxIndex - boxColumn) / data.boxesOnLine;
			line = getLine(boxLine, boxColumn, boxIndex, RIGHT);
			drawRightLine(data, line);
		}
		if (data.boxes[i].hasTopLine)
		{
			setcolor(data.boxes[i].colorTopLine);
			boxIndex = i;
			boxColumn = boxIndex % data.boxesOnLine;
			boxLine = (boxIndex - boxColumn) / data.boxesOnLine;
			line = getLine(boxLine, boxColumn, boxIndex, TOP);
			drawTopLine(data, line);
		}
		if (data.boxes[i].hasBottomLine)
		{
			setcolor(data.boxes[i].colorBottomLine);
			boxIndex = i;
			boxColumn = boxIndex % data.boxesOnLine;
			boxLine = (boxIndex - boxColumn) / data.boxesOnLine;
			line = getLine(boxLine, boxColumn, boxIndex, BOTTOM);
			drawBottomLine(data, line);
		}
		if (isBoxClosed(data.boxes[i]))
			printExistingOwningPlayer(screen, data, line, player);
	}
	data.dotRadius -= 4;
}