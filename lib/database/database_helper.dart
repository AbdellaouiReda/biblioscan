import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/Livre.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Getter pour accéder à la base
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('biblio.db');
    return _database!;
  }

  /// 🏗️ Initialisation de la base
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// 🧱 Création des tables
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE livres (
        livre_id INTEGER PRIMARY KEY AUTOINCREMENT,
        biblio_id INTEGER,
        titre TEXT,
        auteur TEXT,
        annee_publication INTEGER,
        position_ligne INTEGER,
        position_colonne INTEGER,
        correction_manuelle INTEGER,
        image_path TEXT,
        video_path TEXT
      )
    ''');
  }

  // ----------------------------------------------------------
  // 🧩 CRUD : CREATE / READ / UPDATE / DELETE
  // ----------------------------------------------------------

  /// ➕ Ajouter un livre
  Future<int> insertLivre(Livre livre) async {
    final db = await instance.database;
    return await db.insert(
      'livres',
      livre.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 📖 Récupérer tous les livres d'une bibliothèque donnée
  Future<List<Livre>> getLivresByBibliotheque(int biblioId) async {
    final db = await instance.database;
    final maps = await db.query(
      'livres',
      where: 'biblio_id = ?',
      whereArgs: [biblioId],
    );

    return maps.map((json) => Livre.fromJson(json)).toList();
  }

  /// ✏️ Mettre à jour un livre existant
  Future<int> updateLivre(Livre livre) async {
    final db = await instance.database;
    return await db.update(
      'livres',
      livre.toJson(),
      where: 'livre_id = ?',
      whereArgs: [livre.livreId],
    );
  }

  /// 🗑️ Supprimer un livre
  Future<int> deleteLivre(int id) async {
    final db = await instance.database;
    return await db.delete(
      'livres',
      where: 'livre_id = ?',
      whereArgs: [id],
    );
  }

  /// 🚮 Vider complètement la table
  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete('livres');
  }

  // ----------------------------------------------------------
  // 🧹 Fermeture
  // ----------------------------------------------------------

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
