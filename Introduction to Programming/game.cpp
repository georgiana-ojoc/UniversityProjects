#include <ctime>
#include <cstring>
#include "draw.h"
#include <fstream>
#include "game.h"
#include "graphics.h"
#include <iostream>
#include "menu.h"
#include "minimaxDomain.h"
#include "minimax.h"

using namespace std;

Line getLineFromGlobals(unsigned boxesOnLine, unsigned boxesOnColumn, unsigned boxIndex, char* position)
{
	unsigned boxColumn = boxIndex % boxesOnLine;
	unsigned boxLine = (boxIndex - boxColumn) / boxesOnLine;
	return getLine(boxLine, boxColumn, boxIndex, position);
}

Line getLine(DotsAndBoxesData &data, unsigned boxIndex, char* position)
{
	return getLineFromGlobals(data.boxesOnLine, data.boxesOnColumn, boxIndex, position);
}

Line getLine(unsigned boxLine, unsigned boxColumn, unsigned boxIndex, char* position)
{
	Line line;
	line.boxLine = boxLine;
	line.boxColumn = boxColumn;
	line.boxIndex = boxIndex;
	line.position = position;
	return line;
}

void setDotsCoordinates(DotsAndBoxesData &data)
{
	unsigned i, j;
	for (i = 0; i < data.dotsOnColumn; i++)
		for (j = 0; j < data.dotsOnLine; j++)
		{
			data.dotsCoordinates[i][j].x = data.windowLeftSideLength + j * data.boxLineLength;
			data.dotsCoordinates[i][j].y = data.windowTopSideLength + i * data.boxLineLength;
		}
}

DotsAndBoxesData getData(Screen screen, unsigned boxesOnLine, unsigned boxesOnColumn)
{
	DotsAndBoxesData data;
	data.dotsOnLine = boxesOnLine + 1;
	data.dotsOnColumn = boxesOnColumn + 1;
	data.boxesOnLine = boxesOnLine;
	data.boxesOnColumn = boxesOnColumn;
	data.dotRadius = 10;
	data.boxLineLength = screen.height / data.boxesOnColumn * 0.7;
	data.windowLeftSideLength = (screen.width - data.boxesOnLine*data.boxLineLength) / 2;
	data.windowTopSideLength = (screen.height - data.boxesOnColumn*data.boxLineLength) / 2;
	setDotsCoordinates(data);
	return data;
}

void getPlayer(DotsAndBoxesData &data, Player player[])
{
	if (strcmp(data.gameMode, GAME_TWO) == 0)
		strcpy(player[2].name, "Computer");
	else if (strcmp(data.gameMode, GAME_THREE) == 0)
	{
		strcpy(player[1].name, "AComputer");
		strcpy(player[2].name, "BComputer");
	}
}

Dot getDotCoordinatesInSmallBox(DotsAndBoxesData &data, Dot dotInBigBox)
{
	Dot dotInSmallBox = dotInBigBox;
	dotInSmallBox.x = (dotInBigBox.x - data.windowLeftSideLength) % data.boxLineLength;
	dotInSmallBox.y = (dotInBigBox.y - data.windowTopSideLength) % data.boxLineLength;
	return dotInSmallBox;
}

bool isInBigBox(DotsAndBoxesData &data, Dot dot)
{
	if (dot.x < data.windowLeftSideLength
		|| dot.x > data.windowLeftSideLength + data.boxesOnLine * data.boxLineLength
		|| dot.y < data.windowTopSideLength
		|| dot.y > data.windowTopSideLength + data.boxesOnColumn * data.boxLineLength)
		return false;
	return true;
}

bool isInCornerOfSmallBox(DotsAndBoxesData &data, Dot dot)
{
	return (dot.x <= data.dotRadius || dot.x >= data.boxLineLength - data.dotRadius)
		&& (dot.y <= data.dotRadius || dot.y >= data.boxLineLength - data.dotRadius);
}

bool existsLine(DotsAndBoxesData &data, unsigned boxIndex, char* position)
{
	Box box = data.boxes[boxIndex];
	if (strcmp(position, LEFT) == 0 && box.hasLeftLine)
		return true;
	if (strcmp(position, RIGHT) == 0 && box.hasRightLine)
		return true;
	if (strcmp(position, TOP) == 0 && box.hasTopLine)
		return true;
	if (strcmp(position, BOTTOM) == 0 && box.hasBottomLine)
		return true;
	return false;
}

void markLine(DotsAndBoxesData &data, Line line)
{
	if (strcmp(line.position, LEFT) == 0)
		data.boxes[line.boxIndex].hasLeftLine = true;
	else if (strcmp(line.position, RIGHT) == 0)
		data.boxes[line.boxIndex].hasRightLine = true;
	else if (strcmp(line.position, TOP) == 0)
		data.boxes[line.boxIndex].hasTopLine = true;
	else if (strcmp(line.position, BOTTOM) == 0)
		data.boxes[line.boxIndex].hasBottomLine = true;
}

bool hasNextBox(DotsAndBoxesData &data, unsigned boxIndex, char* position)
{
	if (strcmp(position, LEFT) == 0)
		return boxIndex % data.boxesOnLine > 0;
	if (strcmp(position, RIGHT) == 0)
		return boxIndex % data.boxesOnLine < data.boxesOnLine - 1;
	if (strcmp(position, TOP) == 0)
		return boxIndex >= data.boxesOnLine;
	if (strcmp(position, BOTTOM) == 0)
		return boxIndex < data.boxesOnLine * (data.boxesOnColumn - 1);
}

Line getNextBoxLine(DotsAndBoxesData &data, Line line)
{
	if (strcmp(line.position, LEFT) == 0)
		return getLine(line.boxLine, line.boxColumn - 1, line.boxIndex - 1, RIGHT);
	if (strcmp(line.position, RIGHT) == 0)
		return getLine(line.boxLine, line.boxColumn + 1, line.boxIndex + 1, LEFT);
	if (strcmp(line.position, TOP) == 0)
		return getLine(line.boxLine - 1, line.boxColumn, line.boxIndex - data.boxesOnLine, BOTTOM);
	if (strcmp(line.position, BOTTOM) == 0)
		return getLine(line.boxLine + 1, line.boxColumn, line.boxIndex + data.boxesOnLine, TOP);
}

unsigned getSides(Box box)
{
	unsigned sides = 0;
	if (box.hasLeftLine)
		sides++;
	if (box.hasRightLine)
		sides++;
	if (box.hasTopLine)
		sides++;
	if (box.hasBottomLine)
		sides++;
	return sides;
}

bool isBoxClosed(Box box)
{
	return getSides(box) == 4;
}

void markBox(DotsAndBoxesData &data, Line line)
{
	data.boxes[line.boxIndex].owningPlayer = data.currentPlayer;
}

unsigned changePlayer(DotsAndBoxesData &data, Line currentLine)
{
	Box currentBox = data.boxes[currentLine.boxIndex];
	bool closedBox = false;
	if (hasNextBox(data, currentLine.boxIndex, currentLine.position))
	{
		Line nextLine = getNextBoxLine(data, currentLine);
		Box nextBox = data.boxes[nextLine.boxIndex];
		if (isBoxClosed(currentBox) || isBoxClosed(nextBox))
			closedBox = true;
	}
	else if (isBoxClosed(currentBox))
		closedBox = true;
	if (!closedBox)
		return data.currentPlayer % 2 + 1;
	return data.currentPlayer;
}

void handleBox(Screen screen, DotsAndBoxesData &data, Line line, Player player[])
{
	markLine(data, line);
	setLineColorInBox(data, line);
	Box box = data.boxes[line.boxIndex];
	if (isBoxClosed(box))
	{
		markBox(data, line);
		printOwningPlayer(screen, data, line, player);
	}
}

unsigned getBoxLineFromClick(DotsAndBoxesData &data, Dot dot)
{
	return (dot.y - data.windowTopSideLength) / data.boxLineLength;
}

unsigned getBoxColumnFromClick(DotsAndBoxesData &data, Dot dot)
{
	return (dot.x - data.windowLeftSideLength) / data.boxLineLength;
}

unsigned getBoxIndex(DotsAndBoxesData &data, unsigned boxLine, unsigned boxColumn)
{
	return boxLine * data.boxesOnLine + boxColumn;
}

char* getLinePosition(DotsAndBoxesData &data, Dot dot)
{
	if ((dot.y <= data.boxLineLength / 2 && dot.x < dot.y)
		|| (dot.y > data.boxLineLength / 2 && dot.x < data.boxLineLength - dot.y))
		return LEFT;
	if ((dot.y <= data.boxLineLength / 2 && dot.x > data.boxLineLength - dot.y)
		|| (dot.y > data.boxLineLength / 2 && dot.x > dot.y))
		return RIGHT;
	if (dot.y <= data.boxLineLength / 2
		&& dot.x > dot.y
		&& dot.x < data.boxLineLength - dot.y)
		return TOP;
	if (dot.y > data.boxLineLength / 2
		&& dot.x > data.boxLineLength - dot.y
		&& dot.x < dot.y)
		return BOTTOM;
	return NO_LINE;
}

void actionSaveButton(Screen screen, DotsAndBoxesData &data, Player player[], Dot mouse)
{
	if (strcmp(mouse.event, UP) == 0)
		if (mouse.x >= screen.width - 1.5 * textwidth("Save")
			&& mouse.x <= screen.width - 0.5 * textwidth("Save")
			&& mouse.y >= data.windowTopSideLength / 2 - textheight("Save")
			&& mouse.y <= data.windowTopSideLength / 2 + textheight("Save"))
		{
			setcolor(PURPLE);
			outtextxy(screen.width - textwidth("Save"), data.windowTopSideLength / 2, "Save");
		}
		else
		{
			setcolor(ROSE);
			outtextxy(screen.width - textwidth("Save"), data.windowTopSideLength / 2, "Save");
		}
	else if (strcmp(mouse.event, DOWN) == 0)
		if (mouse.x >= screen.width - 1.5 * textwidth("Save")
			&& mouse.x <= screen.width - 0.5 * textwidth("Save")
			&& mouse.y >= data.windowTopSideLength / 2 - textheight("Save")
			&& mouse.y <= data.windowTopSideLength / 2 + textheight("Save"))
		{
			Beep(400, 100);
			ofstream f("boxes.txt");
			f << data.boxesOnLine << ' ' << data.boxesOnColumn
				<< ' ' << data.currentPlayer << ' ' << data.gameMode << ' ' << data.gameDifficulty << '\n';
			for (unsigned i = 0; i < data.boxesOnLine * data.boxesOnColumn; i++)
				f << data.boxes[i].hasLeftLine << ' ' << data.boxes[i].colorLeftLine << ' '
				<< data.boxes[i].hasRightLine << ' ' << data.boxes[i].colorRightLine << ' '
				<< data.boxes[i].hasTopLine << ' ' << data.boxes[i].colorTopLine << ' '
				<< data.boxes[i].hasBottomLine << ' ' << data.boxes[i].colorBottomLine << ' '
				<< data.boxes[i].owningPlayer << '\n';
			f << player[1].name << ' ' << player[1].boxes << '\n';
			f << player[2].name << ' ' << player[2].boxes << '\n';
			f.close();
		}
}

void actionBackButton(Screen screen, DotsAndBoxesData &data, Player player[], Dot mouse)
{
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	if (strcmp(mouse.event, UP) == 0)
		if (mouse.x >= 0.5 * textwidth("Back")
			&& mouse.x <= 1.5 * textwidth("Back")
			&& mouse.y >= data.windowTopSideLength / 2 - textheight("Back")
			&& mouse.y <= data.windowTopSideLength / 2 + textheight("Back"))
		{
			setcolor(PURPLE);
			outtextxy(textwidth("Back"), data.windowTopSideLength / 2, "Back");
		}
		else
		{
			setcolor(ROSE);
			outtextxy(textwidth("Back"), data.windowTopSideLength / 2, "Back");
		}
	else if (strcmp(mouse.event, DOWN) == 0)
		if (mouse.x >= 0.5 * textwidth("Back")
			&& mouse.x <= 1.5 * textwidth("Back")
			&& mouse.y >= data.windowTopSideLength / 2 - textheight("Back")
			&& mouse.y <= data.windowTopSideLength / 2 + textheight("Back"))
		{
			Beep(400, 100);
			clearviewport();
			start(screen, data, player, data.boxesOnLine, data.boxesOnColumn);
		}
}

Line getClickLine(Screen screen, DotsAndBoxesData &data, Player player[])
{
	setlinestyle(DASHED_LINE, 0x0F0F, 1);
	Dot dot;
	unsigned boxLine = 0;
	unsigned boxColumn = 0;
	unsigned boxIndex = 0;
	char* position = NO_LINE;
	Line line = getLine(boxLine, boxColumn, boxIndex, position);
	while (true)
	{
		dot = getMouseCoordinates();
		actionSaveButton(screen, data, player, dot);
		actionBackButton(screen, data, player, dot);
		if (!isInBigBox(data, dot) && !existsLine(data, line.boxIndex, line.position))
		{
			setcolor(CHOCOLATE);
			drawLine(data, line);
			continue;
		}
		boxLine = getBoxLineFromClick(data, dot);
		boxColumn = getBoxColumnFromClick(data, dot);
		boxIndex = getBoxIndex(data, boxLine, boxColumn);
		dot = getDotCoordinatesInSmallBox(data, dot);
		if (isInCornerOfSmallBox(data, dot) && !existsLine(data, line.boxIndex, line.position))
		{
			setcolor(CHOCOLATE);
			drawLine(data, line);
			continue;
		}
		position = getLinePosition(data, dot);
		if (strcmp(position, NO_LINE) == 0 && !existsLine(data, line.boxIndex, line.position))
		{
			setcolor(CHOCOLATE);
			drawLine(data, line);
			continue;
		}
		if (!existsLine(data, boxIndex, position))
		{
			if (strcmp(dot.event, DOWN) == 0)
				return getLine(boxLine, boxColumn, boxIndex, position);
			if ((line.boxLine != boxLine || line.boxColumn != boxColumn
				|| line.boxIndex != boxIndex || line.position != position) && !existsLine(data, line.boxIndex, line.position))
				{
					setcolor(CHOCOLATE);
					drawLine(data, line);
				}
			line = getLine(boxLine, boxColumn, boxIndex, position);
			setcolor(ROSE);
			drawLine(data, line);
		}
	}
}

unsigned getNumberOfBoxes(DotsAndBoxesData &data)
{
	return data.boxesOnLine*data.boxesOnColumn;
}

Side getBoxTotal(DotsAndBoxesData &data)
{
	Side box;
	for (unsigned i = 0; i < getNumberOfBoxes(data); i++)
		if (getSides(data.boxes[i]) == 0)
		{
			box.zeroSides[box.totalZero] = i;
			box.totalZero++;
		}
		else if (getSides(data.boxes[i]) == 1)
		{
			box.oneSide[box.totalOne] = i;
			box.totalOne++;
		}
		else if (getSides(data.boxes[i]) == 2)
		{
			box.twoSides[box.totalTwo] = i;
			box.totalTwo++;
		}
		else if (getSides(data.boxes[i]) == 3)
		{
			box.threeSides[box.totalThree] = i;
			box.totalThree++;
		}
	return box;
}

unsigned getEasyRandomBoxIndex(Side &box)
{
	unsigned availableBoxes[4];
	unsigned number = 0;
	unsigned i;
	unsigned boxIndex = 0;
	if (box.totalZero > 0)
	{
		availableBoxes[number] = 4;
		number++;
	}
	if (box.totalOne > 0)
	{
		availableBoxes[number] = 3;
		number++;
	}
	if (box.totalTwo > 0)
	{
		availableBoxes[number] = 2;
		number++;
	}
	if (box.totalThree > 0)
	{
		availableBoxes[number] = 1;
		number++;
	}
	number = rand() % number;
	if (availableBoxes[number] == 4)
	{
		i = rand() % box.totalZero;
		boxIndex = box.zeroSides[i];
		for (i++; i < box.totalZero; i++)
			box.zeroSides[i - 1] = box.zeroSides[i];
		box.totalZero--;
	}
	else if (availableBoxes[number] == 3)
	{
		i = rand() % box.totalOne;
		boxIndex = box.oneSide[i];
		for (i++; i < box.totalOne; i++)
			box.oneSide[i - 1] = box.oneSide[i];
		box.totalOne--;
	}
	else if (availableBoxes[number] == 2)
	{
		i = rand() % box.totalTwo;
		boxIndex = box.twoSides[i];
		for (i++; i < box.totalTwo; i++)
			box.twoSides[i - 1] = box.twoSides[i];
		box.totalTwo--;
	}
	else if (availableBoxes[number] == 1)
	{
		boxIndex = box.threeSides[0];
		for (i = 1; i < box.totalThree; i++)
			box.threeSides[i - 1] = box.threeSides[i];
		box.totalThree--;
	}
	return boxIndex;
}

unsigned getMediumRandomBoxIndex(Side &box)
{
	unsigned i;
	unsigned boxIndex = 0;
	if (box.totalThree > 0)
	{
		boxIndex = box.threeSides[0];
		for (i = 1; i < box.totalThree; i++)
			box.threeSides[i - 1] = box.threeSides[i];
		box.totalThree--;
	}
	else if (box.totalZero > 0)
	{
		i = rand() % box.totalZero;
		boxIndex = box.zeroSides[i];
		for (i++; i < box.totalZero; i++)
			box.zeroSides[i - 1] = box.zeroSides[i];
		box.totalZero--;
	}
	else if (box.totalOne > 0)
	{
		i = rand() % box.totalOne;
		boxIndex = box.oneSide[i];
		for (i++; i < box.totalOne; i++)
			box.oneSide[i - 1] = box.oneSide[i];
		box.totalOne--;
	}
	else if (box.totalTwo > 0)
	{
		i = rand() % box.totalTwo;
		boxIndex = box.twoSides[i];
		for (i++; i < box.totalTwo; i++)
			box.twoSides[i - 1] = box.twoSides[i];
		box.totalTwo--;
	}
	return boxIndex;
}

unsigned getSidesNextBox(DotsAndBoxesData &data, unsigned boxIndex, char* position)
{
	if (strcmp(position, LEFT) == 0)
		return getSides(data.boxes[boxIndex - 1]);
	if (strcmp(position, RIGHT) == 0)
		return getSides(data.boxes[boxIndex + 1]);
	if (strcmp(position, TOP) == 0)
		return getSides(data.boxes[boxIndex - data.boxesOnLine]);
	if (strcmp(position, BOTTOM) == 0)
		return getSides(data.boxes[boxIndex + data.boxesOnLine]);
}

bool isBoxIndexValid(DotsAndBoxesData &data, Side box, unsigned boxIndex)
{
	unsigned numberOfSidesCurrentBox = getSides(data.boxes[boxIndex]);
	if (!data.boxes[boxIndex].hasLeftLine)
		if (hasNextBox(data, boxIndex, LEFT))
		{
			if (numberOfSidesCurrentBox >= getSidesNextBox(data, boxIndex, LEFT))
				return true;
		}
		else return true;
	if (!data.boxes[boxIndex].hasRightLine)
		if (hasNextBox(data, boxIndex, RIGHT))
		{
			if (numberOfSidesCurrentBox >= getSidesNextBox(data, boxIndex, RIGHT))
				return true;
		}
		else return true;
	if (!data.boxes[boxIndex].hasTopLine)
		if (hasNextBox(data, boxIndex, TOP))
		{
			if (numberOfSidesCurrentBox >= getSidesNextBox(data, boxIndex, TOP))
				return true;
		}
		else return true;
	if (!data.boxes[boxIndex].hasBottomLine)
		if (hasNextBox(data, boxIndex, BOTTOM))
		{
			if (numberOfSidesCurrentBox >= getSidesNextBox(data, boxIndex, BOTTOM))
				return true;
		}
		else return true;
	return false;
}

void getAvailablePositions(DotsAndBoxesData &data, unsigned boxIndex, char* positions[], unsigned &number)
{
	if (!data.boxes[boxIndex].hasLeftLine)
	{
		positions[number] = LEFT;
		number++;
	}
	if (!data.boxes[boxIndex].hasRightLine)
	{
		positions[number] = RIGHT;
		number++;
	}
	if (!data.boxes[boxIndex].hasTopLine)
	{
		positions[number] = TOP;
		number++;
	}
	if (!data.boxes[boxIndex].hasBottomLine)
	{
		positions[number] = BOTTOM;
		number++;
	}
}

char* getRandomLinePosition(char* positions[], unsigned &number)
{
	unsigned index = rand() % number;
	char* position = positions[index];
	for (index++; index < number; index++)
		positions[index - 1] = positions[index];
	positions[number - 1] = NO_LINE;
	number--;
	return position;
}

bool isPositionValid(DotsAndBoxesData &data, unsigned boxIndex, char* position)
{
	return getSides(data.boxes[boxIndex]) >= getSidesNextBox(data, boxIndex, position);
}

Line getRandomLine(DotsAndBoxesData &data, Player player[])
{
	Side box = getBoxTotal(data);
	unsigned boxLine = 0;
	unsigned boxColumn = 0;
	unsigned boxIndex = 0;
	char* position = NO_LINE;
	if (strcmp(data.gameDifficulty, EASY) == 0)
		do
		{
			boxIndex = getEasyRandomBoxIndex(box);
		} while (!isBoxIndexValid(data, box, boxIndex));
	else if (strcmp(data.gameDifficulty, MEDIUM) == 0)
		do
		{
			boxIndex = getMediumRandomBoxIndex(box);
		} while (!isBoxIndexValid(data, box, boxIndex));
	boxColumn = boxIndex % data.boxesOnLine;
	boxLine = (boxIndex - boxColumn) / data.boxesOnLine;
	char* positions[4] = { NO_LINE, NO_LINE, NO_LINE, NO_LINE };
	unsigned number = 0;
	getAvailablePositions(data, boxIndex, positions, number);
		do
		{
			position = getRandomLinePosition(positions, number);
			if (!hasNextBox(data, boxIndex, position))
				break;
		} while (!isPositionValid(data, boxIndex, position));
	return getLine(boxLine, boxColumn, boxIndex, position);
}

Line getMovePlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[])
{
	if (data.currentPlayer == PLAYER_ONE)
		return getClickLine(screen, data, player);
	else if (data.currentPlayer == PLAYER_TWO)
		if (strcmp(data.gameDifficulty, EASY) == 0 || strcmp(data.gameDifficulty, MEDIUM) == 0)
			return getRandomLine(data, player);
		else if (strcmp(data.gameDifficulty, HARD) == 0)
			return getMinimaxLine(data, player);
}

bool isGameFinished(DotsAndBoxesData &data, Player player[])
{
	return player[1].boxes + player[2].boxes == getNumberOfBoxes(data);
}

void executeTurn(Screen screen, DotsAndBoxesData &data, Player player[])
{
	Line currentLine;
	if (strcmp(data.gameMode, GAME_ONE) == 0)
		currentLine = getClickLine(screen, data, player);
	else if (strcmp(data.gameMode, GAME_TWO) == 0)
		currentLine = getMovePlayerVersusComputer(screen, data, player);
	else if (strcmp(data.gameMode, GAME_THREE) == 0)
		if (strcmp(data.gameDifficulty, EASY) == 0 || strcmp(data.gameDifficulty, MEDIUM) == 0)
			currentLine = getRandomLine(data, player);
		else if (strcmp(data.gameDifficulty, HARD) == 0)
			currentLine = getMinimaxLine(data, player);
	setlinestyle(SOLID_LINE, 0xFFFF, 7);
	setColorPlayer(data.currentPlayer);
	drawLine(data, currentLine);
	handleBox(screen, data, currentLine, player);
	if (hasNextBox(data, currentLine.boxIndex, currentLine.position))
	{
		Line nextLine = getNextBoxLine(data, currentLine);
		handleBox(screen, data, nextLine, player);
	}
	data.currentPlayer = changePlayer(data, currentLine);
	printCurrentPlayer(screen, data, player);
}

void playGame(Screen screen, DotsAndBoxesData &data, Player player[])
{
	setbkcolor(BEIGE);
	settextstyle(GOTHIC_FONT, HORIZ_DIR, 7);
	Dot mouse;
	while (!isGameFinished(data, player))
	{
		executeTurn(screen, data, player);
		delay(100);
		Dot mouse = getMouseCoordinates();
		actionSaveButton(screen, data, player, mouse);
		actionBackButton(screen, data, player, mouse);
	}
	if (isGameFinished(data, player))
		printWinner(screen, data, player);
}

void playNewGame(Screen screen, DotsAndBoxesData &data, Player player[], unsigned boxesOnLine, unsigned boxesOnColumn)
{
	readimagefile("sunset-swells.jpg", 0, 0, screen.width, screen.height);
	setbkcolor(BEIGE);
	setfillstyle(SOLID_FILL, BEIGE);
	data.dotsOnLine = boxesOnLine + 1;
	data.dotsOnColumn = boxesOnColumn + 1;
	data.boxesOnLine = boxesOnLine;
	data.boxesOnColumn = boxesOnColumn;
	data.dotRadius = 10;
	data.boxLineLength = screen.height / data.boxesOnColumn * 0.7;
	data.windowLeftSideLength = (screen.width - data.boxesOnLine*data.boxLineLength) / 2;
	data.windowTopSideLength = (screen.height - data.boxesOnColumn*data.boxLineLength) / 2;
	setDotsCoordinates(data);
	data.currentPlayer = PLAYER_ONE;
	getPlayer(data, player);
	getWindow(screen, data, player);
	playGame(screen, data, player);
}

void reloadGame(Screen screen, DotsAndBoxesData data)
{
	ifstream f("boxes.txt");
	f >> data.boxesOnLine >> data.boxesOnColumn;
	data = getData(screen, data.boxesOnLine, data.boxesOnColumn);
	f >> data.currentPlayer;
	char* gameMode = new char;
	char* gameDifficulty = new char;
	f >> gameMode >> gameDifficulty;
	data.gameMode = gameMode;
	data.gameDifficulty = gameDifficulty;
	for (unsigned i = 0; i < data.boxesOnLine * data.boxesOnColumn; i++)
		f >> data.boxes[i].hasLeftLine >> data.boxes[i].colorLeftLine
		>> data.boxes[i].hasRightLine >> data.boxes[i].colorRightLine
		>> data.boxes[i].hasTopLine >> data.boxes[i].colorTopLine
		>> data.boxes[i].hasBottomLine >> data.boxes[i].colorBottomLine
		>> data.boxes[i].owningPlayer;
	Player player[3];
	f >> player[1].name >> player[1].boxes;
	f >> player[2].name >> player[2].boxes;
	f.close();
	getWindow(screen, data, player);
	drawReloadedGame(screen, data, player);
	playGame(screen, data, player);
}
