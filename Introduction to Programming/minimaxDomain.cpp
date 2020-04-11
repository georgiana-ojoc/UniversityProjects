#include "minimaxDomain.h"

UnchangedGameData buildUnchangedGameData(Player players[3], unsigned boxesOnLine, unsigned boxesOnColumn)
{
	UnchangedGameData data;
	data.players = players;
	data.boxesOnLine = boxesOnLine;
	data.boxesOnColumn = boxesOnColumn;
	return data;
}

unsigned getNumberOfBoxes(UnchangedGameData * data)
{
	return data->boxesOnColumn*data->boxesOnLine;
}