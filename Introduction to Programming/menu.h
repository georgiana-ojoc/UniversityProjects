#pragma once

void start(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void menu(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void howToPlay(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void selectGameMode(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void insertNameForPlayer1VersusPlayer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void insertNameForPlayer2VersusPlayer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void rowsForPlayerVersusPlayer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void columnsForPlayerVersusPlayer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void selectDifficultyForPlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void rowsForPlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void columnsForPlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void rowsForComputerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void columnsForComputerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);

void insertNameForPlayerVersusComputer(Screen screen, DotsAndBoxesData &data, Player player[], unsigned &boxesOnLine, unsigned &boxesOnColumn);