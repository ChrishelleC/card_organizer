import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'database_helper.dart';

void main() {
  runApp(CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FoldersScreen(),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _dbHelper.initializeDatabase();
  }

  Future<void> _resetDatabase() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    await _dbHelper.resetDatabase();
    Navigator.pop(context); // Close loading dialog
    setState(() {});
  }

  void _showUpdateFolderDialog(int folderId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Folder'),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: 'Folder Name')),
        actions: [
          TextButton(
            onPressed: () async {
              await _dbHelper.updateFolder(folderId, controller.text);
              setState(() {});
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(int folderId) async {
    await _dbHelper.deleteFolder(folderId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Organizer'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetDatabase,
            tooltip: 'Reset Database',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getFolders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final folders = snapshot.data!;
          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: SvgPicture.network(
                  folder['previewImage'] ?? 'https://upload.wikimedia.org/wikipedia/commons/7/7e/01_of_hearts_A.svg',
                  width: 50,
                  placeholderBuilder: (context) => CircularProgressIndicator(),
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                ),
                title: Text(folder['name']),
                subtitle: Text('${folder['cardCount']} cards'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showUpdateFolderDialog(folder['id'], folder['name']),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteFolder(folder['id']),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardsScreen(folderId: folder['id'], folderName: folder['name']),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  CardsScreen({required this.folderId, required this.folderName});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.folderName} Cards')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getCardsInFolder(widget.folderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final cards = snapshot.data!;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Card(
                child: Column(
                  children: [
                    SvgPicture.network(
                      card['imageUrl'],
                      height: 100,
                      fit: BoxFit.cover,
                      placeholderBuilder: (context) => CircularProgressIndicator(),
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                    ),
                    Text(card['name']),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showUpdateDialog(card),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteCard(card['id']),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddCardDialog() async {
    final availableCards = await _dbHelper.getAvailableCards();
    if (availableCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No cards available to add')));
      return;
    }

    final cardCount = (await _dbHelper.getCardsInFolder(widget.folderId)).length;
    if (cardCount >= 6) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('This folder can only hold 6 cards.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        int? selectedCardId; // Changed to int? instead of Map
        String selectedCardName = '';
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Add Card'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>( // Changed to int
                  value: selectedCardId,
                  hint: Text('Select a card'),
                  isExpanded: true,
                  items: availableCards.map((card) {
                    return DropdownMenuItem(
                      value: card['id'] as int, // Use only the ID as the value
                      child: Text(card['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCardId = value;
                      // Find the name for display
                      if (value != null) {
                        final selectedCard = availableCards.firstWhere(
                          (card) => card['id'] == value,
                          orElse: () => {'name': 'Unknown Card'},
                        );
                        selectedCardName = selectedCard['name'] as String;
                      }
                    });
                  },
                ),
                if (selectedCardId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Selected: $selectedCardName'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedCardId != null) {
                    await _dbHelper.addCardToFolder(selectedCardId!, widget.folderId);
                    setState(() {}); // Update dialog state
                    this.setState(() {}); // Update parent widget state
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a card')));
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdateDialog(Map<String, dynamic> card) {
    final controller = TextEditingController(text: card['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Card'),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: 'Card Name')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _dbHelper.updateCard(card['id'], controller.text);
              setState(() {});
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteCard(int cardId) async {
    final cardCount = (await _dbHelper.getCardsInFolder(widget.folderId)).length;
    
    if (cardCount <= 3) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Warning'),
          content: Text('You need at least 3 cards in this folder.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
      return; // Prevent deletion if card count is 3 or fewer
    }
    
    await _dbHelper.deleteCardFromFolder(cardId, widget.folderId);
    setState(() {});
  }
}