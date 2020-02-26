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