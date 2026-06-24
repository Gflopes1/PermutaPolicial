// /lib/features/dashboard/widgets/minesweeper_game.dart

import 'package:flutter/material.dart';
import 'dart:math';

class MinesweeperGame extends StatefulWidget {
  const MinesweeperGame({super.key});

  @override
  State<MinesweeperGame> createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<MinesweeperGame> {
  static const int rows = 16;
  static const int cols = 16;
  static const int mines = 40;
  
  late List<List<Cell>> grid;
  bool gameStarted = false;
  bool gameOver = false;
  bool gameWon = false;
  int flagsPlaced = 0;
  int cellsRevealed = 0;
  DateTime? startTime;
  Duration elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    grid = List.generate(rows, (i) => List.generate(cols, (j) => Cell(row: i, col: j)));
    gameStarted = false;
    gameOver = false;
    gameWon = false;
    flagsPlaced = 0;
    cellsRevealed = 0;
    startTime = null;
    elapsedTime = Duration.zero;
  }

  void _startGame(int firstRow, int firstCol) {
    if (gameStarted) return;
    
    gameStarted = true;
    startTime = DateTime.now();
    
    // Gera minas evitando a primeira célula clicada
    final random = Random();
    int minesPlaced = 0;
    
    while (minesPlaced < mines) {
      final row = random.nextInt(rows);
      final col = random.nextInt(cols);
      
      // Não coloca mina na primeira célula clicada nem nas adjacentes
      if ((row == firstRow && col == firstCol) ||
          (row >= firstRow - 1 && row <= firstRow + 1 &&
           col >= firstCol - 1 && col <= firstCol + 1)) {
        continue;
      }
      
      if (!grid[row][col].isMine) {
        grid[row][col].isMine = true;
        minesPlaced++;
      }
    }
    
    // Calcula números adjacentes
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (!grid[i][j].isMine) {
          grid[i][j].adjacentMines = _countAdjacentMines(i, j);
        }
      }
    }
    
    setState(() {});
    _updateTimer();
  }

  int _countAdjacentMines(int row, int col) {
    int count = 0;
    for (int i = row - 1; i <= row + 1; i++) {
      for (int j = col - 1; j <= col + 1; j++) {
        if (i >= 0 && i < rows && j >= 0 && j < cols) {
          if (grid[i][j].isMine) count++;
        }
      }
    }
    return count;
  }

  void _revealCell(int row, int col) {
    if (gameOver || gameWon || grid[row][col].isRevealed || grid[row][col].isFlagged) {
      return;
    }

    if (!gameStarted) {
      _startGame(row, col);
    }

    if (grid[row][col].isMine) {
      // Game Over
      gameOver = true;
      _revealAllMines();
      setState(() {});
      return;
    }

    _revealCellRecursive(row, col);
    _checkWin();
    setState(() {});
  }

  void _revealCellRecursive(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return;
    if (grid[row][col].isRevealed || grid[row][col].isFlagged) return;
    if (grid[row][col].isMine) return;

    grid[row][col].isRevealed = true;
    cellsRevealed++;

    if (grid[row][col].adjacentMines == 0) {
      // Revela células adjacentes recursivamente
      for (int i = row - 1; i <= row + 1; i++) {
        for (int j = col - 1; j <= col + 1; j++) {
          if (i != row || j != col) {
            _revealCellRecursive(i, j);
          }
        }
      }
    }
  }

  void _toggleFlag(int row, int col) {
    if (gameOver || gameWon || grid[row][col].isRevealed) return;

    setState(() {
      if (grid[row][col].isFlagged) {
        grid[row][col].isFlagged = false;
        flagsPlaced--;
      } else {
        grid[row][col].isFlagged = true;
        flagsPlaced++;
      }
    });
  }

  void _revealAllMines() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (grid[i][j].isMine) {
          grid[i][j].isRevealed = true;
        }
      }
    }
  }

  void _checkWin() {
    if (cellsRevealed == (rows * cols - mines)) {
      gameWon = true;
      setState(() {});
    }
  }

  void _updateTimer() {
    if (gameStarted && !gameOver && !gameWon && startTime != null) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !gameOver && !gameWon) {
          setState(() {
            elapsedTime = DateTime.now().difference(startTime!);
          });
          _updateTimer();
        }
      });
    }
  }

  void _resetGame() {
    setState(() {
      _initializeGame();
    });
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cellSize = isMobile ? 20.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campo Minado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Novo Jogo',
            onPressed: _resetGame,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status do jogo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Minas',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '${mines - flagsPlaced}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        if (gameWon)
                          Column(
                            children: [
                              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                'Vitória!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        else if (gameOver)
                          Column(
                            children: [
                              Icon(Icons.sentiment_very_dissatisfied, color: Colors.red, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                'Game Over',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Icon(Icons.flag, color: theme.primaryColor, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                'Jogando',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        Column(
                          children: [
                            Text(
                              'Tempo',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              _formatTime(elapsedTime),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Grid do jogo
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: List.generate(rows, (i) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(cols, (j) {
                          return _buildCell(i, j, cellSize);
                        }),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Instruções
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Como Jogar',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInstruction('Toque', 'Revela a célula'),
                        _buildInstruction('Toque longo', 'Marca/desmarca bandeira'),
                        _buildInstruction('Objetivo', 'Revele todas as células sem minas'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String action, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$action: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(description),
        ],
      ),
    );
  }

  Widget _buildCell(int row, int col, double size) {
    final cell = grid[row][col];
    
    Color backgroundColor;
    Widget? content;
    
    if (cell.isRevealed) {
      if (cell.isMine) {
        backgroundColor = Colors.red.shade300;
        content = Icon(Icons.dangerous, size: size * 0.7, color: Colors.red.shade900);
      } else if (cell.adjacentMines > 0) {
        backgroundColor = Colors.grey.shade200;
        content = Text(
          cell.adjacentMines.toString(),
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            color: _getNumberColor(cell.adjacentMines),
          ),
        );
      } else {
        backgroundColor = Colors.grey.shade100;
      }
    } else {
      backgroundColor = Colors.grey.shade300;
      if (cell.isFlagged) {
        content = Icon(Icons.flag, size: size * 0.7, color: Colors.red);
      }
    }
    
    return GestureDetector(
      onTap: () => _revealCell(row, col),
      onLongPress: () => _toggleFlag(row, col),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: cell.isRevealed ? Colors.grey.shade400 : Colors.grey.shade500,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(child: content),
      ),
    );
  }

  Color _getNumberColor(int number) {
    switch (number) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.brown;
      case 6:
        return Colors.pink;
      case 7:
        return Colors.black;
      case 8:
        return Colors.grey.shade800;
      default:
        return Colors.black;
    }
  }
}

class Cell {
  final int row;
  final int col;
  bool isMine = false;
  bool isRevealed = false;
  bool isFlagged = false;
  int adjacentMines = 0;

  Cell({required this.row, required this.col});
}
