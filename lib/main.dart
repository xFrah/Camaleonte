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
  // Initialize with some empty controllers
  final List<TextEditingController> _playerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final List<FocusNode> _playerFocusNodes = [];

  final TextEditingController _footerController = TextEditingController();
  final FocusNode _footerFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes for initial controllers
    for (var i = 0; i < _playerControllers.length; i++) {
      _playerFocusNodes.add(FocusNode());
    }
    _footerFocusNode.addListener(_onFooterFocusChange);
  }

  @override
  void dispose() {
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    for (var node in _playerFocusNodes) {
      node.dispose();
    }
    _footerController.dispose();
    _footerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFooterFocusChange() {
    if (!_footerFocusNode.hasFocus && _footerController.text.trim().isNotEmpty) {
      _addNewPlayer(_footerController.text.trim());
    }
  }

  void _addNewPlayer(String name) {
    setState(() {
      _playerControllers.add(TextEditingController(text: name));
      _playerFocusNodes.add(FocusNode());
      _footerController.clear();
    });
    // Keep focus on the new footer input? Or let it go? 
    // Usually "enter" -> add -> focus new line.
    // "blur" -> add -> focus lost.
    // If we want to type multiple names fast:
    // User types "Name", hits enter -> Add, Focus footer again.
    // User types "Name", taps away -> Add, Focus lost.
    
    // We'll handle the focus request in the onSubmitted callback specifically if needed,
    // but the listener handles the logic. 
    // If triggered by onSubmitted, we might want to refocus the footer.
  }

  void _removePlayer(int index) {
    setState(() {
      _playerControllers[index].dispose();
      _playerControllers.removeAt(index);
      _playerFocusNodes[index].dispose();
      _playerFocusNodes.removeAt(index);
    });
  }

  void _startGame() {
    final playerNames = _playerControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    // Check footer too
    if (_footerController.text.trim().isNotEmpty) {
      playerNames.add(_footerController.text.trim());
    }

    if (playerNames.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servono almeno 3 giocatori!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Unfocus any active text field to prevent keyboard from popping up when returning
    for (var node in _playerFocusNodes) {
      node.unfocus();
    }
    _footerFocusNode.unfocus();
    FocusScope.of(context).unfocus(); // Double check global unfocus

    // Reset cursor position to avoid selection state on return
    // We use offset 0 instead of -1 to avoid potential RangeErrors
    for (var controller in _playerControllers) {
      controller.selection = const TextSelection.collapsed(offset: 0);
    }
    _footerController.selection = const TextSelection.collapsed(offset: 0);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(playerNames: playerNames),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                header: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Image.asset(
                          'assets/images/chameleon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 15.0),
                      child: Text(
                          'Inserisci i nomi dei giocatori:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                scrollController: _scrollController,
                buildDefaultDragHandles: false,
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                itemCount: _playerControllers.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = _playerControllers.removeAt(oldIndex);
                    _playerControllers.insert(newIndex, item);
                    
                    final node = _playerFocusNodes.removeAt(oldIndex);
                    _playerFocusNodes.insert(newIndex, node);
                  });
                },
                footer: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      // Invisible spacer to match the drag handle width + padding
                      const SizedBox(width: 56), 
                      Expanded(
                        child: TextField(
                          controller: _footerController,
                          focusNode: _footerFocusNode,
                          scrollPadding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 40),
                          decoration: const InputDecoration(
                            hintText: 'Aggiungi un altro giocatore...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.add),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              _addNewPlayer(value.trim());
                              _footerFocusNode.requestFocus();
                            }
                          },
                        ),
                      ),
                      // Invisible spacer to match the close button width + padding
                      const SizedBox(width: 56),
                    ],
                  ),
                ),
                itemBuilder: (context, index) {
                  return Padding(
                    key: ObjectKey(_playerControllers[index]),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            width: 56, // Fixed width for drag handle area
                            alignment: Alignment.center,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            focusNode: _playerFocusNodes[index],
                            controller: _playerControllers[index],
                            scrollPadding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 40),
                            decoration: InputDecoration(
                              hintText: 'Giocatore ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Container(
                          width: 56, // Fixed width for close button area
                          alignment: Alignment.center,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _removePlayer(index),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.transparent,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: ElevatedButton(
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
                  child: const Text('INIZIA'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final List<String> playerNames;

  const GameScreen({super.key, required this.playerNames});

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

    _impostorIndex = random.nextInt(widget.playerNames.length);
  }

  void _nextPlayer() {
    if (_currentPlayerIndex < widget.playerNames.length - 1) {
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

  void _previousPlayer() {
    if (_currentPlayerIndex > 0) {
      setState(() {
        _currentPlayerIndex--;
        _isRevealing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameStarted) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
                child: const Text(
                  'Tutti i giocatori hanno visto le loro coordinate.',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Inizia il round!',
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
                child: const Text('Torna al Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(
                widget.playerNames[_currentPlayerIndex],
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Passa il dispositivo a questo giocatore.',
                style: TextStyle(color: Colors.grey, fontSize: 18),
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
                            'TIENI PREMUTO\nPER RIVELARE',
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
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentPlayerIndex > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: ElevatedButton(
                        onPressed: _previousPlayer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        ),
                        child: const Text(
                          'Indietro',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
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
                      _currentPlayerIndex < widget.playerNames.length - 1
                          ? 'Prossimo'
                          : 'Fine',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    ),
  );
}
}
