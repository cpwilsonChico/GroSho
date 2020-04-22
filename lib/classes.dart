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

    _date = DateTime.parse(getDateAsString());
  }
  PurchaseRecord.withDateTime(this._dollars, this._cents, this._date) {
    if (_cents >= 100) {
      _dollars += _cents ~/ 100;
      _cents %= 100;
    }

    // manually convert int representation of time to string
    _year = _date.year.toString();
    _month = _date.month.toString();
    if (_date.month < 10) _month = "0" + _month;
    _day = _date.day.toString();
    if (_date.day < 10) _day = "0" + _day;
    int hr = _date.hour;
    if (hr < 10) {
      _clockTime = "0" + hr.toString();
    } else {
      _clockTime = hr.toString();
    }
    int minute = _date.minute;
    if (minute < 10) {
      _clockTime += ":0" + minute.toString();
    } else {
      _clockTime += ":" + minute.toString();
    }
    int second = _date.second;
    if (second < 10) {
      _clockTime += ":0" + second.toString();
    } else {
      _clockTime += ":" + second.toString();
    }
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
    try {
      _date = DateTime.parse(getDateAsString());
    } catch (e) {
      print(e.toString());
      _date = DateTime.now();
    }
  }

  String getDateAsString() {
    return _year + "-" + _month + "-" + _day + " " + _clockTime;
  }

  String getDollarAmount() {
    String centsString = _cents.toString();
    if (_cents < 10) centsString = "0" + centsString;
    return "\$ " + _dollars.toString() + "." + centsString;
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

  int getID() {
    return _id;
  }

}

class ReceiptType {
  PurchaseRecord pr;
  List<GroceryItem> list;
  List<String> unmatched;

  ReceiptType(this.pr, this.list, this.unmatched);
  ReceiptType.empty() {
    pr = null;
    list = null;
    unmatched = null;
  }
}