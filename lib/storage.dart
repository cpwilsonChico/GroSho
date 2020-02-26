import 'package:sqflite/sqflite.dart';
import 'classes.dart';



// stores reference to the SQLite database

class Databaser {
  Database inv;
  bool initialized = false;
  static const String DB_NAME = "inventory";

  Databaser() {
    initDB();
  }

  Future initDB() async {
    if (initialized) return;
    inv = await openDatabase('inventory.db', version: 1, onCreate: (Database db, int version) async {
      await db.execute('''
    CREATE TABLE inventory(
    _id text PRIMARY KEY,
    _name text,
    _type INTEGER,
    _amount REAL)''');
    });
    initialized = true;
  }

  Future update(GroceryItem gi) async {
    if (!await(checkIfExists(gi.getID()))) {
      print("attempt to update non-existent grocery item in database");
      return;
    }
    await inv.update(DB_NAME, gi.toMap(),
    where: '_id = ?', whereArgs: [gi.getID()]);
  }

  // either adds new row or updates existing
  Future insert(GroceryItem gi) async {
    if (await checkIfExists(gi.getID())) {
      await inv.update(DB_NAME, gi.toMap(),
        where: '_id = ?', whereArgs: [gi.getID()]);
    } else {
      await inv.insert(DB_NAME, gi.toMap());
    }
  }

  Future delete(GroceryItem gi) async {
    await inv.delete(DB_NAME, where: '_id = ?', whereArgs: [gi.getID()]);
  }

  Future<bool> checkIfExists(String id) async {
    List<Map> result = await inv.query(DB_NAME, where: '_id == ?', whereArgs: [id]);
    return result.length == 1;
  }

  Future<List<Map>> getAll() async {
    await initDB();
    List<Map> maps = await inv.query(DB_NAME);
    return maps;
  }

} // Databaser
