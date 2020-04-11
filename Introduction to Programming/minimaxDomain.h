#pragma once

#include "draw.h"
#include "game.h"

struct Node
{
	Box boxes[64];
	unsigned currentPlayer = NO_PLAYER;
	Line lastLine;
};

struct UnchangedGameData
{
	Player* players;
	unsigned boxesOnLine;
	unsigned boxesOnColumn;
	int maximizingPlayer;
};

UnchangedGameData buildUnchangedGameData(Player players[3], unsigned boxesOnLine, unsigned boxesOnColumn);

unsigned getNumberOfBoxes(UnchangedGameData* data);