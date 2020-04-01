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
  PurchaseRecord(this._dollars, this._cents, this._year, this._month, this._day, this._clockTime) {
    if (_cents >= 100) {
      _dollars += _cents ~/ 100;
      _cents %= 100;
    }

    _date = DateTime.parse(_year + "-" + _month + "-" + _day + " " + _clockTime);
  }
  int _dollars;
  int _cents;
  String _year;
  String _month;
  String _day;
  String _clockTime;
  int _id;
  DateTime _date;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = <String, dynamic> {
      "_dollars": _dollars,
      "_cents": _cents,
      "_year": _year,
      "_month": _month,
      "_day": _day,
      "_clockTime": _clockTime,
    };
    if (_id != null) {
      map["_id"] = _id;
    }

    return map;
  }

  PurchaseRecord.fromMap(Map<String, dynamic> map) {
    _dollars = map["_dollars"];
    _cents = map["_cents"];
    _year = map["_year"];
    _month = map["_month"];
    _day = map["_day"];
    _clockTime = map["_clockTime"];
    _id = map["_id"];
  }

  String getDateAsString() {
    return _year + "-" + _month + "-" + _day + " " + _clockTime;
  }

  String getDollarAmount() {
    return "\$ " + _dollars.toString() + "." + _cents.toString();
  }

  double getDollarValue() {
    return _dollars + (_cents / 100);
  }

  int getDayAsInt() {
    return int.parse(_day);
  }

  DateTime getDate() {
    return _date;
  }

}