#pragma once

struct Side
{
	unsigned zeroSides[64];
	unsigned totalZero = 0;
	unsigned oneSide[64];
	unsigned totalOne = 0;
	unsigned twoSides[64];
	unsigned totalTwo = 0;
	unsigned threeSides[64];
	unsigned totalThree = 0;
};

Line getLineFromGlobals(unsigned boxesOnLine, unsigned boxesOnColumn, unsigned boxIndex, char* position);

Line getLine(DotsAndBoxesData &data, unsigned boxIndex, char* position);

Line getLine(unsigned boxLine, unsigned boxColumn, unsigned boxIndex, char* position);

void setDotsCoordinates(DotsAndBoxesData &data);

DotsAndBoxesData getData(Screen screen, unsigned boxesOnLine, unsigned boxesOnColumn);

void getPlayer(DotsAndBoxesData &data, Player player[]);

Dot getDotCoordinatesInSmallBox(DotsAndBoxesData &data, Dot dotInBigBox);

bool isInBigBox(DotsAndBoxesData &data, Dot dot);

bool isInCornerOfSmallBox(DotsAndBoxesData &data, Dot dot);

bool existsLine(DotsAndBoxesData &data, unsigned boxIndex, char* position);

void markLine(DotsAndBoxesData &data, Line line);

bool hasNextBox(DotsAndBoxesData &data, unsigned boxIndex, char* position);

Line getNextBoxLine(DotsAndBoxesData &data, Line line);

unsigned getSides(Box box);

bool isBoxClosed(Box box);

void markBox(DotsAndBoxesData &data, Line line);

unsigned changePlayer(DotsAndBoxesData &data, Line currentLine);

void handleBox(Screen screen, DotsAndBoxesData &data, Line line, Player player[]);

unsigned getBoxLineFromClick(DotsAndBoxesData &data, Dot dot);

unsigned getBoxColumnFromClick(DotsAndBoxesData &data, Dot dot);

unsigned getBoxIndex(DotsAndBoxesData &data, unsigned boxLine, unsigned boxColumn);

char* getLinePosition(DotsAndBoxesData &data, Dot dot);

void actionSaveButton(Screen screen, DotsAndBoxesData &data, Player player[], Dot mouse);

void actionBackButton(Screen screen, DotsAndBoxesData &data, Player player[], Dot mouse);

Line getClickLine(Screen screen, DotsAndBoxesData &data, Player player[]);

unsigned getNumberOfBoxes(DotsAndBoxesData &data);

Side getBoxTotal(DotsAndBoxesData &data);

unsigned getEasyRandomBoxIndex(Side &box);

unsigned getMediumRandomBoxIndex(Side &box);

unsigned getSidesNextBox(DotsAndBoxesData &data, unsigned boxIndex, char* position);

bool isBoxIndexValid(DotsAndBoxesData &data, Side box, unsigned boxIndex);

void getAvailablePositions(DotsAndBoxesData &data, unsigned boxIndex, char* positions[], unsigned &number);

char* getRandomLinePosition(char* positions[], unsigned &number);

bool isPositionValid(DotsAndBoxesData &data, unsigned boxIndex, char* position);

Line getRandomLine(DotsAndBoxesData &data, Player player[]);

Line getMovePlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[]);

bool isGameFinished(DotsAndBoxesData &data, Player player[]);

void executeTurn(Screen screen, DotsAndBoxesData &data, Player player[]);

void playGame(Screen screen, DotsAndBoxesData &data, Player player[]);

void playNewGame(Screen screen, DotsAndBoxesData &data, Player player[], unsigned boxesOnLine, unsigned boxesOnColumn);

void reloadGame(Screen screen, DotsAndBoxesData data);