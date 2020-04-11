#include <cstring>
#include <ctime>
#include "draw.h"
#include "game.h"
#include "graphics.h"
#include <iostream>
#include "minimax.h"
#include "minimaxDomain.h"

using namespace std;

LineNode* initializeLine(LineNode* lineList, Line line)
{
	lineList = new LineNode;
	lineList->line = line;
	return lineList;
}

Line getNodeLine(LineNode* lineList)
{
	return lineList->line;
}

bool isEmptyLine(LineNode* lineList)
{
	return lineList == NULL;
}

void insertLine(LineNode* lineList, Line line)
{
	LineNode* lineNode = new LineNode;
	lineNode->line = line;
	lineNode->next = lineList->next;
	lineList->next = lineNode;
}

LineNode* addToLineList(UnchangedGameData* data, LineNode* lineList, Line line)
{
	if (isEmptyLine(lineList))
		return initializeLine(lineList, line);
	else
		insertLine(lineList, line);
	return lineList;
}

LineNode* getLineList(UnchangedGameData* data, Node node)
{
	LineNode* lineList = NULL;
	unsigned numberOfBoxes = getNumberOfBoxes(data);
	for (unsigned boxIndex = 0; boxIndex < numberOfBoxes; boxIndex++)
	{
		if (!node.boxes[boxIndex].hasLeftLine)
		{
			Line line = getLineFromGlobals(data->boxesOnLine, data->boxesOnColumn, boxIndex, LEFT);
			lineList = addToLineList(data, lineList, line);
		}
		if (!node.boxes[boxIndex].hasTopLine)
		{
			Line line = getLineFromGlobals(data->boxesOnLine, data->boxesOnColumn, boxIndex, TOP);
			lineList = addToLineList(data, lineList, line);
		}
		if (!node.boxes[boxIndex].hasRightLine && (boxIndex%data->boxesOnLine == data->boxesOnLine - 1))
		{
			Line line = getLineFromGlobals(data->boxesOnLine, data->boxesOnColumn, boxIndex, RIGHT);
			lineList = addToLineList(data, lineList, line);
		}
		if (!node.boxes[boxIndex].hasBottomLine && (boxIndex >= (data->boxesOnColumn - 1)*data->boxesOnLine))
		{
			Line line = getLineFromGlobals(data->boxesOnLine, data->boxesOnColumn, boxIndex, BOTTOM);
			lineList = addToLineList(data, lineList, line);
		}
	}
	return lineList;
}

BoxNode* initializeChild(BoxNode* childList, Node* node)
{
	childList = new BoxNode;
	childList->node = *node;
	return childList;
}

bool isEmptyChild(BoxNode* childList)
{
	return childList == NULL;
}

void insertChild(BoxNode* childList, Node* node)
{
	BoxNode* childNode = new BoxNode;
	childNode->node = *node;
	childNode->next = childList->next;
	childList->next = childNode;
}

void markLine(Box* box, char* position)
{
	if (strcmp(position, TOP) == 0)
	{
		box->hasTopLine = true;
	}
	if (strcmp(position, BOTTOM) == 0)
	{
		box->hasBottomLine = true;
	}
	if (strcmp(position, LEFT) == 0)
	{
		box->hasLeftLine = true;
	}
	if (strcmp(position, RIGHT) == 0)
	{
		box->hasRightLine = true;
	}
}

unsigned getBoxIndex(unsigned boxesOnLine, unsigned boxLine, unsigned boxColumn)
{
	return boxLine * boxesOnLine + boxColumn;
}

Box* getNextBox(UnchangedGameData* data, Node* node, Line line)
{
	if (strcmp(line.position, TOP) == 0 && line.boxLine > 0)
	{
		return &node->boxes[getBoxIndex(data->boxesOnLine, line.boxLine - 1, line.boxColumn)];
	}
	if (strcmp(line.position, BOTTOM) == 0 && line.boxLine < (data->boxesOnColumn - 1))
	{
		return &node->boxes[getBoxIndex(data->boxesOnLine, line.boxLine + 1, line.boxColumn)];
	}
	if (strcmp(line.position, LEFT) == 0 && line.boxColumn > 0)
	{
		return &node->boxes[getBoxIndex(data->boxesOnLine, line.boxLine, line.boxColumn - 1)];
	}
	if (strcmp(line.position, RIGHT) == 0 && line.boxColumn < (data->boxesOnLine - 1))
	{
		return &node->boxes[getBoxIndex(data->boxesOnLine, line.boxLine, line.boxColumn + 1)];
	}
	return NULL;
}

char* reversePosition(char* position)
{
	if (strcmp(position, TOP) == 0)
	{
		return BOTTOM;
	}
	if (strcmp(position, BOTTOM) == 0)
	{
		return TOP;
	}
	if (strcmp(position, LEFT) == 0)
	{
		return RIGHT;
	}
	if (strcmp(position, RIGHT) == 0)
	{
		return LEFT;
	}
	return NULL;
}

bool putPlayerIfNecessary(Box* box, unsigned player)
{
	if (box->hasBottomLine && box->hasTopLine && box->hasLeftLine && box->hasRightLine)
	{
		box->owningPlayer = player;
		return true;
	}
	return false;
}

bool handleMove(UnchangedGameData* data, Node* node, Line line)
{
	Box* currentBox = &node->boxes[line.boxIndex];
	markLine(currentBox, line.position);
	Box* nextBox = getNextBox(data, node, line);
	bool boxClosed = false;
	if (nextBox != NULL)
	{
		markLine(nextBox, reversePosition(line.position));
		boxClosed = boxClosed || putPlayerIfNecessary(nextBox, node->currentPlayer);
	}
	boxClosed = boxClosed || putPlayerIfNecessary(currentBox, node->currentPlayer);
	return boxClosed;
}

Node copyNode(UnchangedGameData* data, Node node)
{
	Node copy;
	int i;
	for (i = 0; i < getNumberOfBoxes(data); i++)
	{
		copy.boxes[i] = node.boxes[i];
	}
	copy.currentPlayer = node.currentPlayer;
	return copy;
}

int getScore(UnchangedGameData* data, Node node)
{
	int score = 0;
	int i;
	for (i = 0; i < getNumberOfBoxes(data); i++)
	{
		if (node.boxes[i].owningPlayer == data->maximizingPlayer)
		{
			score++;
		}
		else if (node.boxes[i].owningPlayer != NO_PLAYER)
		{
			score--;
		}
	}
	return score;
}

Move getMove(UnchangedGameData* data, Node node, Line* line)
{
	Move move;
	move.score = getScore(data, node);
	if (line != NULL)
		move.line = *line;
	return move;
}

Move minimaxMove(Move left, Move right, bool maximizingPlayer)
{
	if (maximizingPlayer)
	{
		if (left.score >= right.score)
		{
			return left;
		}
		else
		{
			return right;
		}
	}
	else
	{
		if (right.score >= left.score)
		{
			return left;
		}
		else
		{
			return right;
		}
	}
}

Move minimax(UnchangedGameData* data, Node node, unsigned depth, bool maximizingPlayer)
{
	int lineCount = 0;
	LineNode* lineList = getLineList(data, node);
	if (depth == 0 || isEmptyLine(lineList))
		return getMove(data, node, (Line*)NULL);
	Move move;
	if (maximizingPlayer)
		move.score = INT_MIN;
	else
		move.score = INT_MAX;
	while (lineList)
	{
		Line currentLine = lineList->line;
		Node child = copyNode(data, node);
		bool closedBox = handleMove(data, &child, currentLine);
		child.lastLine = currentLine;
		if (!closedBox)
			child.currentPlayer = node.currentPlayer % 2 + 1;
		bool childMaximizingPlayer = maximizingPlayer;
		if (child.currentPlayer != node.currentPlayer)
			childMaximizingPlayer = !maximizingPlayer;
		Move childMove = minimax(data, child, depth - 1, childMaximizingPlayer);
		childMove.line = child.lastLine;
		move = minimaxMove(move, childMove, maximizingPlayer);
		LineNode* old = lineList;
		lineList = lineList->next;
		delete old;
	}
	return move;
}

Line getMinimaxLine(DotsAndBoxesData data, Player player[])
{
	UnchangedGameData unchangedData;
	unchangedData.boxesOnColumn = data.boxesOnColumn;
	unchangedData.boxesOnLine = data.boxesOnLine;
	unchangedData.maximizingPlayer = data.currentPlayer;
	unchangedData.players = player;
	Node root;
	root.currentPlayer = data.currentPlayer;
	int i;
	for (i = 0; i < getNumberOfBoxes(data); i++)
		root.boxes[i] = data.boxes[i];
	unsigned depth = 3;
	bool maximizingPlayer = true;
	Move move = minimax(&unchangedData, root, depth, maximizingPlayer);
	return move.line;
}