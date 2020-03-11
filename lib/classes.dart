import 'dart:collection';

enum QuantityType {
  cups,
  cans,
  gallons,
  ct,
  lbs,
  fl_oz,
  unknown,
}

Map<String, QuantityType> strToQuantity = {
  'unknown': QuantityType.unknown,
  'None': QuantityType.unknown,
  'cups': QuantityType.cups,
  'cans': QuantityType.cans,
  'gallons': QuantityType.gallons,
  'ct': QuantityType.ct,
  'lbs': QuantityType.lbs,
  'fl_oz': QuantityType.fl_oz,
};

String quantityToString(QuantityType q) {
  switch (q) {
    case QuantityType.cups:
      return 'cups';
    case QuantityType.cans:
      return 'cans';
    case QuantityType.gallons:
      return 'gallons';
    case QuantityType.ct:
      return 'ct';
    case QuantityType.lbs:
      return 'lbs';
    case QuantityType.fl_oz:
      return 'fl oz';
    case QuantityType.unknown:
      return 'None';
    default:
      return '';
  }

}

class GroceryItem {
  QuantityType q;
  String id;
  String name;
  double amount;
  // image

  // syntactic sugar for init list
  GroceryItem(this.q, this.id, this.name, this.amount);

  GroceryItem.fromMap(Map<String, dynamic> map) {
    id = map['_id'];
    name = map['_name'];
    amount = map['_amount'];
    q = QuantityType.values[map['_type']];

  }

  String getID() {
    return id;
  }

  String getQuantityAsString() {
    if (amount == null) return '';
    return amount.toStringAsFixed(2) + ' ' + ((q==QuantityType.unknown) ? '' : quantityToString(q));
  }

  Map<String, dynamic> toMap() {
    var tempMap = <String, dynamic>{
      "_id": id,
      "_name": name,
      "_type": q.index,
      "_amount": amount,
    };
    return tempMap;
  }
}


class PurchaseRecord {
  PurchaseRecord(this.dollars, this.cents, this.year, this.month, this.day, this.clockTime) {
    dollars += (cents % 100);
    cents %= 100;
  }
  int dollars;
  int cents;
  String year;
  String month;
  String day;
  String clockTime;
  int id;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = <String, dynamic> {
      "_dollars": dollars,
      "_cents": cents,
      "_year": year,
      "_month": month,
      "_day": day,
      "_clockTime": clockTime,
    };
    if (id != null) {
      map["_id"] = id;
    }

    return map;
  }

  PurchaseRecord.fromMap(Map<String, dynamic> map) {
    dollars = map["_dollars"];
    cents = map["_cents"];
    year = map["_year"];
    month = map["_month"];
    day = map["_day"];
    clockTime = map["_clockTime"];
    id = map["_id"];
  }

  String getDate() {
    return year + "-" + month + "-" + day + " " + clockTime;
  }

  String getDollarAmount() {
    return "\$ " + dollars.toString() + "." + cents.toString();
  }
}