import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camaleonte',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const GameSetupScreen(),
    );
  }
}

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _numberOfPlayers = 3;

  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(numberOfPlayers: _numberOfPlayers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Game'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Number of Players:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _numberOfPlayers > 3
                        ? () => setState(() => _numberOfPlayers--)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.green.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.remove, color: Colors.white, size: 30),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '$_numberOfPlayers',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _numberOfPlayers < 10 // Max players limit
                        ? () => setState(() => _numberOfPlayers++)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.green.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20, inherit: false),
                ),
                child: const Text('START'),
              ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final int numberOfPlayers;

  const GameScreen({super.key, required this.numberOfPlayers});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late String _commonCoordinate;
  late String _impostorCoordinate;
  late int _impostorIndex;
  int _currentPlayerIndex = 0;
  bool _isRevealing = false;
  bool _gameStarted = false;

  final List<String> _rows = ['A', 'B', 'C', 'D'];
  final List<String> _cols = ['1', '2', '3', '4'];

  @override
  void initState() {
    super.initState();
    _generateCoordinates();
  }

  void _generateCoordinates() {
    final random = Random();
    
    // Generate valid coordinates
    List<String> allCoordinates = [];
    for (var row in _rows) {
      for (var col in _cols) {
        allCoordinates.add('$row$col');
      }
    }

    _commonCoordinate = allCoordinates[random.nextInt(allCoordinates.length)];
    
    // Ensure impostor gets a different coordinate
    do {
      _impostorCoordinate = allCoordinates[random.nextInt(allCoordinates.length)];
    } while (_impostorCoordinate == _commonCoordinate);

    _impostorIndex = random.nextInt(widget.numberOfPlayers);
  }

  void _nextPlayer() {
    if (_currentPlayerIndex < widget.numberOfPlayers - 1) {
      setState(() {
        _currentPlayerIndex++;
        _isRevealing = false;
      });
    } else {
      setState(() {
        _gameStarted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameStarted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Game Started')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'All players have seen their coordinates.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Start the round!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20, inherit: false),
                ),
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pass and Play'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Player ${_currentPlayerIndex + 1}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pass the device to this player.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 50),
            
            // Reveal Button Logic
            GestureDetector(
              onTapDown: (_) => setState(() => _isRevealing = true),
              onTapUp: (_) => setState(() => _isRevealing = false),
              onTapCancel: () => setState(() => _isRevealing = false),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _isRevealing ? Colors.white : Colors.green,
                  border: Border.all(color: Colors.green, width: 4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _isRevealing
                      ? Text(
                          _currentPlayerIndex == _impostorIndex
                              ? _impostorCoordinate
                              : _commonCoordinate,
                          style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'HOLD TO\nREVEAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 50),
            
            ElevatedButton(
              onPressed: _nextPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: Text(
                _currentPlayerIndex < widget.numberOfPlayers - 1
                    ? 'Next Player'
                    : 'Finish Setup',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
