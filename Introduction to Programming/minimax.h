#pragma once

#include "draw.h"
#include "game.h"
#include "minimaxDomain.h"

struct BoxNode
{
	Node node;
	BoxNode* next = NULL;
};

struct LineNode
{
	Line line;
	LineNode* next = NULL;
};

struct Move
{
	Line line = getLine(0, 0, 0, NO_LINE);
	int score = 0;
};

LineNode* initializeLine(LineNode* lineList, Line line);

Line getNodeLine(LineNode* lineList);

bool isEmptyLine(LineNode* lineList);

void insertLine(LineNode* lineList, Line line);

LineNode* addToLineList(UnchangedGameData* data, LineNode* lineList, Line line);

LineNode* getLineList(UnchangedGameData* data, Node node);

BoxNode* initializeChild(BoxNode* childList, Node* node);

bool isEmptyChild(BoxNode* childList);

void insertChild(BoxNode* childList, Node* node);

void markLine(Box* box, char* position);

unsigned getBoxIndex(unsigned boxesOnLine, unsigned boxLine, unsigned boxColumn);

Box* getNextBox(UnchangedGameData* data, Node* node, Line line);

char* reversePosition(char* position);

bool putPlayerIfNecessary(Box* box, unsigned player);

bool handleMove(UnchangedGameData* data, Node* node, Line line);

Node copyNode(UnchangedGameData* data, Node node);

int getScore(UnchangedGameData* data, Node node);

Move getMove(UnchangedGameData* data, Node node, Line* line);

Move minimaxMove(Move left, Move right, bool maximizingPlayer);

Move minimax(UnchangedGameData* data, Node node, unsigned depth, bool maximizingPlayer);

Line getMinimaxLine(DotsAndBoxesData data, Player players[]);