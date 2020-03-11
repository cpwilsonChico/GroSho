import 'package:sqflite/sqflite.dart';
import 'classes.dart';


// singleton
// stores reference to the SQLite database
class Databaser {
  static Database inv;
  static bool initialized = false;
  static bool oneExists = false;
  static const String INV_DB = "inventory";
  static const String COST_DB = "purchases";

  static final Databaser _databaser = Databaser._internal();
  factory Databaser() => _databaser;
  Databaser._internal() {
    initDB();
  }

  static Future initDB() async {
    if (initialized) return;
    inv = await openDatabase('inventory.db', version: 1, onCreate: (Database db, int version) async {
      await db.execute('''
    CREATE TABLE $INV_DB(
    _id text PRIMARY KEY,
    _name TEXT,
    _type INTEGER,
    _amount REAL)''');
      await db.execute('''
    CREATE TABLE $COST_DB(
    _id INTEGER PRIMARY KEY AUTOINCREMENT,
    _year TEXT,
    _month TEXT,
    _day TEXT,
    _clockTime TEXT,
    _dollars INTEGER,
    _cents INTEGER)
      ''');
    });
    initialized = true;
  }

  Future update(GroceryItem gi) async {
    if (!await(checkIfExists(gi.getID()))) {
      print("attempt to update non-existent grocery item in database");
      return;
    }
    await inv.update(INV_DB, gi.toMap(),
    where: '_id = ?', whereArgs: [gi.getID()]);
  }

  // either adds new row or updates existing
  Future insert(GroceryItem gi) async {
    if (await checkIfExists(gi.getID())) {
      await inv.update(INV_DB, gi.toMap(),
        where: '_id = ?', whereArgs: [gi.getID()]);
    } else {
      await inv.insert(INV_DB, gi.toMap());
    }
  }

  Future delete(GroceryItem gi) async {
    await inv.delete(INV_DB, where: '_id = ?', whereArgs: [gi.getID()]);
  }

  Future<bool> checkIfExists(String id) async {
    List<Map> result = await inv.query(INV_DB, where: '_id == ?', whereArgs: [id]);
    return result.length == 1;
  }

  Future<List<Map>> getAll() async {
    await initDB();
    List<Map> maps = await inv.query(INV_DB);
    return maps;
  }

  Future updatePurchase(int dollars, int cents, DateTime date) async {

  }

  Future insertPurchase(int dollars, int cents, DateTime date) async {

  }

  Future deletePurchase() async {

  }

  static Future getAllPurchases() async {
    await Databaser.initDB();
    List<Map> maps = await inv.query(COST_DB);
    return maps;
  }

} // Databaser
