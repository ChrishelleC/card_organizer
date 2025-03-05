import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cards_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE Folders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    ''');
    await db.execute('''
    CREATE TABLE Cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      suit TEXT NOT NULL,
      image_url TEXT NOT NULL,
      folder_id INTEGER,
      FOREIGN KEY (folder_id) REFERENCES Folders(id)
    );
    ''');
  }

  // Insert a new folder
  Future<int> createFolder(Map<String, dynamic> folder) async {
    final db = await instance.database;
    return await db.insert('Folders', folder);
  }

  // Insert a new card
  Future<int> createCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    return await db.insert('Cards', card);
  }

  // Fetch all folders
  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await instance.database;
    return await db.query('Folders');
  }

  // Fetch all cards for a specific folder
  Future<List<Map<String, dynamic>>> getCards(int folderId) async {
    final db = await instance.database;
    return await db.query('Cards', where: 'folder_id = ?', whereArgs: [folderId]);
  }

  // Update a folder
  Future<int> updateFolder(Map<String, dynamic> folder, int id) async {
    final db = await instance.database;
    return await db.update('Folders', folder, where: 'id = ?', whereArgs: [id]);
  }

  // Update a card
  Future<int> updateCard(Map<String, dynamic> card, int id) async {
    final db = await instance.database;
    return await db.update('Cards', card, where: 'id = ?', whereArgs: [id]);
  }

  // Delete a folder (and all cards within it)
  Future<int> deleteFolder(int id) async {
    final db = await instance.database;
    await db.delete('Cards', where: 'folder_id = ?', whereArgs: [id]);
    return await db.delete('Folders', where: 'id = ?', whereArgs: [id]);
  }

  // Delete a card
  Future<int> deleteCard(int id) async {
    final db = await instance.database;
    return await db.delete('Cards', where: 'id = ?', whereArgs: [id]);
  }
}
