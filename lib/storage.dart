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

  static Future update(GroceryItem gi) async {
    if (!await(checkIfExists(gi.getID()))) {
      print("attempt to update non-existent grocery item in database");
      return;
    }
    await inv.update(INV_DB, gi.toMap(),
    where: '_id = ?', whereArgs: [gi.getID()]);
  }

  // either adds new row or updates existing
  static Future insert(GroceryItem gi) async {
    if (await checkIfExists(gi.getID())) {
      await inv.update(INV_DB, gi.toMap(),
        where: '_id = ?', whereArgs: [gi.getID()]);
    } else {
      await inv.insert(INV_DB, gi.toMap());
    }
  }

  static Future delete(GroceryItem gi) async {
    await inv.delete(INV_DB, where: '_id = ?', whereArgs: [gi.getID()]);
  }

  static Future<bool> checkIfExists(String id) async {
    List<Map> result = await inv.query(INV_DB, where: '_id == ?', whereArgs: [id]);
    return result.length == 1;
  }

  static Future<List<Map>> getAll() async {
    await initDB();
    List<Map> maps = await inv.query(INV_DB);
    return maps;
  }

  static Future updatePurchase(PurchaseRecord pr) async {

  }

  static Future insertPurchase(PurchaseRecord pr) async {
    print("INSERTING PR INTO DATABASE...");
    try {
      await inv.insert(COST_DB, pr.toMap());
    } catch (e) {
      print(e.toString());
    }
  }

  static Future deletePurchase(int id) async {
    await inv.delete(COST_DB, where: '_id = ?', whereArgs: [id]);
  }

  static Future<List<PurchaseRecord>> getAllPurchases() async {
    await Databaser.initDB();
    List<Map> maps = await inv.query(COST_DB);
    List<PurchaseRecord> records = maps.map((m) => PurchaseRecord.fromMap(m)).toList();
    return records;

  }

} // Databaser
