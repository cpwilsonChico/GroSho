import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'classes.dart';


// singleton
// stores reference to the SQLite database
class Databaser {
  static const MAX_ITEM_LEN = 50;
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
    print("INSERTING ${gi.getID()}");
    if (await checkIfExists(gi.getID())) {
      double curAmount = (await get(gi.getID()))["_amount"];
      gi.amount += curAmount;
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

  static Future<Map> get(String id) async {
    List<Map> maps = await inv.query(INV_DB, where: '_id == ?', whereArgs: [id]);
    if (maps.length > 0) return maps[0];
    return null;
  }

  static Future updatePurchase(PurchaseRecord pr) async {

  }

  static Future insertPurchase(PurchaseRecord pr) async {
    if (pr == null) return;
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



  // return codes:
  // -2: no collection of that code length
  // -1: length exceeds max length
  // 1: code valid
  // TODO: use enum
  static Future<int> checkCodeExactly(String code) async {
    int len = code.length;
    if (len > MAX_ITEM_LEN) {
      return -1;
    }
    code = code.replaceAll(" ", "_");
    code = code.replaceAll("/", "-");
    code = code.toUpperCase();
    DocumentReference doc = Firestore.instance.collection("items$len").document(code);
    DocumentSnapshot snap = await doc.get();
    print("CHECK_CODE_EXACTLY: ${doc.toString()}");
    if (snap.data == null) {
      return -2;
    }
    return 1;
  }

  static Future<String> getNameByCode(String code) async {
    code = code.replaceAll(" ", "_");
    code = code.replaceAll("/", "-");
    code = code.toUpperCase();
    int len = code.length;
    DocumentReference doc = Firestore.instance.collection("items$len").document(code);
    if (doc == null) return null;
    DocumentSnapshot snap = await doc.get();
    if (snap == null || snap.data == null) return null;
    return snap.data["name"];
  }

  static Future<bool> insertCloudItem(GroceryItem gi) async {
    DocumentSnapshot doc = await Firestore.instance.collection("items${gi.getID().length}").document(gi.getID()).get();
    if (doc.data == null) {
      await Firestore.instance.collection("items${gi.getID().length}").add(gi.toMap());
      return true;
    } else {
      print("ERROR: inserting item ${gi.getID()} already exists.");
      return false;
    }
  }

} // Databaser
