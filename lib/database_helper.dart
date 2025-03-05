import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'card_organizer.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            timestamp TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            suit TEXT,
            imageUrl TEXT,
            folderId INTEGER,
            FOREIGN KEY (folderId) REFERENCES folders(id)
          )
        ''');
        await _prepopulateDatabase(db);
      },
      version: 1,
    );
  }

  Future<void> _prepopulateDatabase(Database db) async {
    // Prepopulate folders
    await db.insert('folders', {'name': 'Hearts', 'timestamp': DateTime.now().toString()});
    await db.insert('folders', {'name': 'Spades', 'timestamp': DateTime.now().toString()});
    await db.insert('folders', {'name': 'Diamonds', 'timestamp': DateTime.now().toString()});
    await db.insert('folders', {'name': 'Clubs', 'timestamp': DateTime.now().toString()});

    // Base URL for Wikimedia Commons SVGs
    const baseUrl = 'https://upload.wikimedia.org/wikipedia/commons';

    // Full list of card image URLs (52 cards, SVG format)
    final cardImages = {
      'hearts': [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/01_of_hearts_A.svg/1280px-01_of_hearts_A.svg.png',   // Ace
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/02_of_hearts.svg/1280px-02_of_hearts.svg.png',     // 2
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/03_of_hearts.svg/1280px-03_of_hearts.svg.png',     // 3
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/04_of_hearts.svg/1280px-04_of_hearts.svg.png',     // 4
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/05_of_hearts.svg/1280px-05_of_hearts.svg.png',     // 5
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/06_of_hearts.svg/1280px-06_of_hearts.svg.png',     // 6
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/07_of_hearts.svg/1280px-07_of_hearts.svg.png',     // 7
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/08_of_hearts.svg/1280px-08_of_hearts.svg.png',     // 8
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/09_of_hearts.svg/1280px-09_of_hearts.svg.png',     // 9
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/10_of_hearts_-_David_Bellot.svg/1280px-10_of_hearts_-_David_Bellot.svg.png',     // 10
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Jack_of_hearts_fr.svg/1280px-Jack_of_hearts_fr.svg.png',   // Jack
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Queen_of_hearts_fr.svg/1280px-Queen_of_hearts_fr.svg.png',   // Queen
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/King_of_hearts_fr.svg/1280px-King_of_hearts_fr.svg.png',   // King
      ],
      'spades': [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/01_of_spades_A.svg/1280px-01_of_spades_A.svg.png',   // Ace
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/02_of_spades.svg/1280px-02_of_spades.svg.png',     // 2
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/03_of_spades.svg/1280px-03_of_spades.svg.png',     // 3
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/04_of_spades.svg/1280px-04_of_spades.svg.png',     // 4
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/05_of_spades.svg/1280px-05_of_spades.svg.png',     // 5
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/06_of_spades.svg/1280px-06_of_spades.svg.png',     // 6
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/07_of_spades.svg/1280px-07_of_spades.svg.png',     // 7
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/08_of_spades.svg/1280px-08_of_spades.svg.png',     // 8
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/09_of_spades.svg/1280px-09_of_spades.svg.png',     // 9
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/10_of_spades.svg/1280px-10_of_spades.svg.png',     // 10
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/11_of_spades_J.svg/1280px-11_of_spades_J.svg.png',   // Jack
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/12_of_spades_Q.svg/1280px-12_of_spades_Q.svg.png',   // Queen
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/13_of_spades_K.svg/1280px-13_of_spades_K.svg.png',   // King
      ],
      'diamonds': [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/01_of_diamonds_A.svg/1280px-01_of_diamonds_A.svg.png', // Ace
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/02_of_diamonds.svg/1280px-02_of_diamonds.svg.png',   // 2
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/03_of_diamonds.svg/1280px-03_of_diamonds.svg.png',   // 3
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/04_of_diamonds.svg/1280px-04_of_diamonds.svg.png',   // 4
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/05_of_diamonds.svg/1280px-05_of_diamonds.svg.png',   // 5
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/06_of_diamonds.svg/1280px-06_of_diamonds.svg.png',   // 6
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/07_of_diamonds.svg/1280px-07_of_diamonds.svg.png',   // 7
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/08_of_diamonds.svg/1280px-08_of_diamonds.svg.png',   // 8
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/09_of_diamonds.svg/1280px-09_of_diamonds.svg.png',   // 9
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/10_of_diamonds_-_David_Bellot.svg/1280px-10_of_diamonds_-_David_Bellot.svg.png',   // 10
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/Jack_of_diamonds_fr.svg/1280px-Jack_of_diamonds_fr.svg.png', // Jack
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Queen_of_diamonds_fr.svg/1280px-Queen_of_diamonds_fr.svg.png', // Queen
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/King_of_diamonds_fr.svg/1280px-King_of_diamonds_fr.svg.png', // King
      ],
      'clubs': [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/34/01_of_clubs_A.svg/1280px-01_of_clubs_A.svg.png',    // Ace
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/02_of_clubs.svg/1280px-02_of_clubs.svg.png',      // 2
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/03_of_clubs.svg/1280px-03_of_clubs.svg.png',      // 3
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/04_of_clubs.svg/1280px-04_of_clubs.svg.png',      // 4
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/05_of_clubs.svg/1280px-05_of_clubs.svg.png',      // 5
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/06_of_clubs.svg/1280px-06_of_clubs.svg.png',      // 6
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/07_of_clubs.svg/1280px-07_of_clubs.svg.png',      // 7
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/08_of_clubs.svg/1280px-08_of_clubs.svg.png',      // 8
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/09_of_clubs.svg/1280px-09_of_clubs.svg.png',      // 9
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/10_of_clubs.svg/1280px-10_of_clubs.svg.png',      // 10
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/11_of_clubs_J.svg/1280px-11_of_clubs_J.svg.png',    // Jack
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/12_of_clubs_Q.svg/1280px-12_of_clubs_Q.svg.png',    // Queen
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/13_of_clubs_K.svg/1280px-13_of_clubs_K.svg.png',    // King
      ],
    };


    // Populate cards table
    final suits = ['hearts', 'spades', 'diamonds', 'clubs'];
    for (var suit in suits) {
      for (int i = 1; i <= 13; i++) {
        await db.insert('cards', {
          'name': '$i of ${suit[0].toUpperCase()}${suit.substring(1)}',
          'suit': suit,
          'imageUrl': cardImages[suit]![i - 1], // Index 0-12 for 1-13
          'folderId': null,
        });
      }
    }
  }

  Future<void> initializeDatabase() async {
    await database;
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT f.id, f.name, c.imageUrl as previewImage, COUNT(c.id) as cardCount
      FROM folders f
      LEFT JOIN cards c ON f.id = c.folderId
      GROUP BY f.id, f.name
    ''');
  }

  Future<List<Map<String, dynamic>>> getCardsInFolder(int folderId) async {
    final db = await database;
    return await db.query('cards', where: 'folderId = ?', whereArgs: [folderId]);
  }

  Future<List<Map<String, dynamic>>> getAvailableCards() async {
    final db = await database;
    return await db.query('cards', where: 'folderId IS NULL');
  }

  Future<void> addCardToFolder(int cardId, int folderId) async {
    final db = await database;
    await db.update('cards', {'folderId': folderId}, where: 'id = ?', whereArgs: [cardId]);
  }

  Future<void> updateCard(int cardId, String newName) async {
    final db = await database;
    await db.update('cards', {'name': newName}, where: 'id = ?', whereArgs: [cardId]);
  }

  Future<void> deleteCardFromFolder(int cardId, int folderId) async {
    final db = await database;
    await db.update('cards', {'folderId': null}, where: 'id = ? AND folderId = ?', whereArgs: [cardId, folderId]);
  }

  Future<void> updateFolder(int folderId, String newName) async {
    final db = await database;
    await db.update('folders', {'name': newName}, where: 'id = ?', whereArgs: [folderId]);
  }

  Future<void> deleteFolder(int folderId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('cards', {'folderId': null}, where: 'folderId = ?', whereArgs: [folderId]);
      await txn.delete('folders', where: 'id = ?', whereArgs: [folderId]);
    });
  }

  Future<void> resetDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'card_organizer.db');
    // Delete the database file
    await deleteDatabase(dbPath);
    // Reinitialize (this will recreate and prepopulate the database)
    _database = null; // Clear the cached database instance
    await initializeDatabase();
  }
}