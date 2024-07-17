import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(const IndecisiveCoApp());
}

class IndecisiveCoApp extends StatelessWidget {
  const IndecisiveCoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IndecisiveCo',
      theme: ThemeData.dark(),
      home: const IndecisiveCoHomePage(),
    );
  }
}

class IndecisiveCoHomePage extends StatefulWidget {
  const IndecisiveCoHomePage({super.key});

  @override
  IndecisiveCoHomePageState createState() => IndecisiveCoHomePageState();
}

class IndecisiveCoHomePageState extends State<IndecisiveCoHomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _items = [];
  final BehaviorSubject<int> _selectedIndexController = BehaviorSubject<int>();
  final Random _random = Random();
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    _selectedIndexController.close();
    super.dispose();
  }

  Future<void> _loadItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedItems = prefs.getStringList('items');
    if (savedItems != null) {
      setState(() {
        _items.addAll(savedItems);
      });
    }
  }

  Future<void> _saveItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('items', _items);
  }

  void _addItem() {
    if (_controller.text.isNotEmpty && !_isSpinning) {
      setState(() {
        _items.add(_controller.text);
        _controller.clear();
        _saveItems();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _saveItems();
    });
  }

  void _spinWheel() {
    if (_items.length >= 2 && !_isSpinning) {
      final int selectedIndex = _random.nextInt(_items.length);
      _selectedIndexController.add(selectedIndex);
      setState(() {
        _isSpinning = true;
      });
    }
  }

  void _showResultDialog(int selectedIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selected Item'),
          content: Text(_items[selectedIndex]),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                _removeItem(selectedIndex);
                Navigator.of(context).pop();
              },
              child: const Text('Remove Item'),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isSpinning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: 'Indecisive',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              WidgetSpan(
                child: Transform.translate(
                  offset: Offset(2, -8),
                  child: Text(
                    'Co',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _items.length < 2
                      ? Center(
                      child: Text('Add at least two items to spin the wheel',
                          style: TextStyle(fontSize: 18, color: Colors.white)))
                      : FortuneWheel(
                    selected: _selectedIndexController.stream,
                    onAnimationEnd: () {
                      _showResultDialog(_selectedIndexController.value);
                    },
                    items: [
                      for (var item in _items)
                        FortuneItem(
                          child: Text(item,
                              style: const TextStyle(fontSize: 24, color: Colors.white)),
                          style: FortuneItemStyle(
                            color: _getWheelColor(_items.indexOf(item)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              enabled: !_isSpinning,
              decoration: InputDecoration(
                labelText: 'Enter item',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _items.isEmpty
                ? const SizedBox.shrink()
                : Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: Key(_items[index]),
                    onDismissed: (direction) {
                      if (!_isSpinning) {
                        _removeItem(index);
                      }
                    },
                    confirmDismiss: (direction) async {
                      return !_isSpinning;
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      title: Text(_items[index]),
                      trailing: Icon(Icons.drag_handle), // Indication for swipe to delete
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _items.length < 2 || _isSpinning
          ? null
          : FloatingActionButton(
        onPressed: _spinWheel,
        child: const Icon(Icons.casino),
      ),
    );
  }

  Color _getWheelColor(int index) {
    // Basic color scheme
    List<Color> wheelColors = [
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
    ];
    return wheelColors[index % wheelColors.length];
  }
}
