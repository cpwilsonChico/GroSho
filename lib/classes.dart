enum QuantityType {
  cups,
  cans,
  gallons,
  ct,
  lbs,
  fl_oz,
}

class GroceryItem {
  QuantityType q;
  String name;
  double amount;

  // syntactic sugar for init list
  GroceryItem(this.q, this.name, this.amount);

  String getQuantityString() {
    String ret = amount.toStringAsFixed(2) + ' ';
    switch (q) {
      case QuantityType.cups:
        return ret + 'cups';
      case QuantityType.cans:
        return ret + 'cans';
      case QuantityType.gallons:
        return ret + 'gallons';
      case QuantityType.ct:
        return ret + 'ct';
      case QuantityType.lbs:
        return ret + 'lbs';
      case QuantityType.fl_oz:
        return ret + 'fl oz';
      default:
        return ret;
    }
  }
  // image
}