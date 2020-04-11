#define UP "up"
#define DOWN "down"

#define NO_LINE "eroare"
#define LEFT "left"
#define RIGHT "right"
#define TOP "top"
#define BOTTOM "bottom"

#define NO_PLAYER 0
#define PLAYER_ONE 1
#define PLAYER_TWO 2

#define NO_GAME "eroare"
#define GAME_ONE "playerVersusPlayer"
#define GAME_TWO "playerVersusComputer"
#define GAME_THREE "computerVersusComputer"

#pragma once

#define NO_DIFFICULTY "noDifficulty"
#define EASY "easy"
#define MEDIUM "medium"
#define HARD "hard"

#define BEIGE COLOR(214, 176, 173)
#define CHOCOLATE COLOR(79, 67, 77)
#define ORANGE COLOR(214, 98, 98)
#define PINK COLOR(237, 175, 215)
#define PURPLE COLOR(168, 108, 193)
#define ROSE COLOR(196, 129, 182)

struct Screen
{
	unsigned width;
	unsigned height;
};

struct Dot
{
	unsigned x = 0;
	unsigned y = 0;
	char* event = UP;
};

struct Box
{
	bool hasLeftLine = false;
	unsigned long colorLeftLine;
	bool hasRightLine = false;
	unsigned long colorRightLine;
	bool hasTopLine = false;
	unsigned long colorTopLine;
	bool hasBottomLine = false;
	unsigned long colorBottomLine;
	unsigned owningPlayer = NO_PLAYER;
};

struct Line
{
	unsigned boxLine = 0;
	unsigned boxColumn = 0;
	unsigned boxIndex = 0;
	char* position = NO_LINE;
	
};

struct DotsAndBoxesData
{
	unsigned dotsOnLine = 0;
	unsigned dotsOnColumn = 0;
	unsigned boxesOnLine = 0;
	unsigned boxesOnColumn = 0;
	unsigned dotRadius = 0;
	unsigned boxLineLength = 0;
	unsigned windowLeftSideLength = 0;
	unsigned windowTopSideLength = 0;
	unsigned currentPlayer = NO_PLAYER;
	char* gameMode = NO_GAME;
	char* gameDifficulty = NO_DIFFICULTY;
	Dot dotsCoordinates[9][9];
	Box boxes[64];
};

struct Player
{
	char name[11] = "\0";
	int boxes = 0;
};

Screen getScreenDimensions();

void setColorPlayer(unsigned player);

void setLineColorInBox(DotsAndBoxesData &data, Line line);

void writePlayer(Screen screen, Player player[], unsigned currentPlayer);

unsigned writeNumber(Screen screen);

void drawBoard(DotsAndBoxesData &data);

void printCurrentPlayer(Screen screen, DotsAndBoxesData &data, Player player[]);

void printScore(Screen screen, DotsAndBoxesData &data, Player player[]);

void drawSaveButton(Screen screen, DotsAndBoxesData &data);

void drawBackButton(Screen screen, DotsAndBoxesData &data);

void getWindow(Screen screen, DotsAndBoxesData &data, Player player[]);

Dot getMouseCoordinates();

void drawLeftLine(DotsAndBoxesData &data, Line _line);

void drawRightLine(DotsAndBoxesData &data, Line _line);

void drawTopLine(DotsAndBoxesData &data, Line _line);

void drawBottomLine(DotsAndBoxesData &data, Line _line);

void drawLine(DotsAndBoxesData &data, Line line);

Dot getCenterBox(DotsAndBoxesData &data, Line line);

void printOwningPlayer(Screen screen, DotsAndBoxesData &data, Line line, Player player[]);

void printExistingOwningPlayer(Screen screen, DotsAndBoxesData &data, Line line, Player player[]);

void printWinner(Screen screen, DotsAndBoxesData &data, Player player[]);

void drawReloadedGame(Screen screen, DotsAndBoxesData &data, Player player[]);