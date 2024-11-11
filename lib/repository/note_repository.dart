import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  // Get database instance (creates if not already created)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Incremented version number
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Create the database schema (for version 1)
  Future _createDB(Database db, int version) async {
    await db.execute(''' 
    CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      priority TEXT NOT NULL DEFAULT 'Medium',
      archived INTEGER NOT NULL DEFAULT 0  -- Add archived column (0 = not archived, 1 = archived)
    )
    ''');
  }

  // Handle schema upgrades (version 2+)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE notes ADD COLUMN priority TEXT NOT NULL DEFAULT "Medium"');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE notes ADD COLUMN archived INTEGER NOT NULL DEFAULT 0'); // Add archived column
    }
  }

  // Insert a new note into the database
  Future<void> insertNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    await db.insert('notes', note);
  }

  // Get all notes, optionally filtered by archived status
  Future<List<Map<String, dynamic>>> getNotes({bool? archived}) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (archived != null) {
      whereClause = 'archived = ?';
      whereArgs = [archived ? 1 : 0];
    }

    return await db.query(
      'notes',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
  }

  // Update an existing note in the database
  Future<void> updateNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    await db.update(
      'notes',
      note,
      where: 'id = ?',
      whereArgs: [note['id']],
    );
  }

  // Archive or unarchive a note
  Future<void> archiveOrUnarchiveNote(int id, bool archived) async {
    final db = await instance.database;
    await db.update(
      'notes',
      {'archived': archived ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a note from the database
  Future<void> deleteNote(int id) async {
    final db = await instance.database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
