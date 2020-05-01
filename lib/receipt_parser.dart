import 'package:edit_distance/edit_distance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:core';
import 'classes.dart';

class ProtoItem {
  int qty;
  String id;
  ProtoItem(this.id, this.qty);
}

class ReceiptParser {
  static const MAX_ITEM_LEN = 30;
  static const MAX_EDIT_DIST = 3;
  ReceiptParser(this._ocr) {
    itemsFound = new List<GroceryItem>();
    queues = new List<List<ProtoItem>>();
    for (int i = 0; i < MAX_ITEM_LEN; i++) {
      queues.add(new List<ProtoItem>());
    }
  }

  ReceiptParser.blank();

  List<List<String>> _ocr;
  List<List<ProtoItem>> queues;
  List<GroceryItem> itemsFound;
  Levenshtein lev = new Levenshtein();

  //String tta = "";  // TOTAL TRANSACTION AMOUNT: $xx.xx
  //String cba = "";  // CASH BACK AMOUNT:         $xx.xx


  String dollarString = "";
  String dateString = "";
  int dollars = 0;
  int cents = 0;




  Future<ReceiptType> parse() async {
    print("ocr length: ${_ocr.length}");
    for (int i = 0; i < _ocr.length; i++) {
      print("i: $i");
      List<String> block = _ocr[i];
      for (int j = 0; j < block.length; j++) {
        String line = block[j];

        print(line);
        //print("PARSING TRANSACTION $i,$j");
        //tryParseTransactionAmount(line, i);
        print("PARSING BALANCE $i,$j");
        tryParseBalance(line, i);
        print("PARSING DATE $i,$j");
        tryParseDate(line, i);
        print("ADDING TO LIST $i,$j");
        addToList(line);
        print("POST ADD TO LIST $i,$j");
        //tryParseDebit(line, i);
        //tryParseChange(line, i);
        //tryParseCBA(line, i);
      }
    }

    print("AAA");

    if (dollarString == "") {
      print("Could not determine total cost from receipt image.");
      //return nullRec;
    } else {
      double dollarValue = double.tryParse(dollarString);
      if (dollarValue == null) {
        print("Could not determine total cost from receipt image");
        //return nullRec;
      } else {
        dollars = dollarValue.truncate();
        try {
          String centsSubStr = dollarString.substring(dollarString.length - 2);
          cents = int.parse(centsSubStr);
        } catch (e) {
          print("Failed to parse cents portion. Defaulting to 0...");
          cents = 0;
        }
      }
    }

    print("PRE PROCESS ITEMS");
    await processItems();
    print("POST PROCESS ITEMS");
    consolidateItems();

    String centsString = cents.toString();
    if (cents < 10) centsString = "0" + centsString;
    print("I think the receipt totalled \$$dollars.$centsString");

    bool goodDate = convertDateFormat();
    if (goodDate) {
      print("I think the date of this receipt is $dateString");
    }

    DateTime receiptDate;
    try {
      receiptDate = DateTime.parse(dateString);
    } catch (e) {
      print("error while parsing: ${e.toString()}");
    }

    print("end of PARSE 1");
    PurchaseRecord recPr;
    try {
      recPr = PurchaseRecord.withDateTime(
          dollars, cents, receiptDate);
    } catch (e) {
      recPr = null;
    }
    print("end of PARSE 2");
    ReceiptType rec = new ReceiptType(recPr, itemsFound);
    print("end of PARSE 3");
    return rec;
  }

  // combine duplicate grocery items
  void consolidateItems() {
    Map<String, int> indexMap = new Map<String, int>();
    List<int> removeThese = new List<int>();

    for (int i = 0; i < itemsFound.length; i++) {
      String id = itemsFound[i].getID();
      if (indexMap.containsKey(id)) {
        itemsFound[indexMap[id]].amount += itemsFound[i].amount;
        removeThese.add(i);
      } else {
        indexMap[id] = i;
      }
    }

    for (int i = 0; i < removeThese.length; i++) {
      // indices shift every time something is removed
      removeThese[i] -= i;
      itemsFound.removeAt(removeThese[i]);
    }
  }

  // processes each queued grocery code by checking against firebase
  Future processItems() async {
    print("BEGIN processItems()");
    // add all non-empty queues to the stream list
    for (int i = 0; i < queues.length; i++) {
      if (queues[i].isEmpty) continue;
      CollectionReference colref = Firestore.instance.collection("items$i");
      if (CollectionReference == null) continue;

      try {
        QuerySnapshot snap = await colref.getDocuments();
        print("POST SNAP");

        for (int j = 0; j < queues[i].length; j++) {
          String candidate = queues[i][j].id;
          for (DocumentSnapshot doc in snap.documents) {
            String fromDB = doc.documentID;
            if (lev.distance(fromDB, candidate) <= MAX_EDIT_DIST) {
              print("Found match: $candidate => $fromDB");
              itemsFound.add(new GroceryItem(fromDB, doc.data["name"], queues[i][j].qty));
              //queues[i].removeAt(j);
              break;
            }
          }
          print("No match found for $candidate in $i");
        }
      } catch (e) {
        print("error while parsing: ${e.toString()}");
      }
    }

    print("END OF processItems()");

  }

  void processItem(QuerySnapshot qs) {
    List<DocumentSnapshot> dsList = qs.documents;
    for (DocumentSnapshot ds in dsList) {
      Map<String, dynamic> dataFromDB = ds.data;
      print("Data from db: $dataFromDB");
    }
  }

  void addToList(String line) {
    line = line.trim();
    line = line.replaceAll(" ", "_");
    line = line.replaceAll("/", "#");
    line = line.toUpperCase();
    if (line.contains("CRV")) return; // ignore CRV
    if (lev.distance(line, "REGULAR_PRICE") < 2) return;  // ignore discounts
    if (lev.distance(line, "CARD_SAVINGS") < 2) return;   // ignore discounts


    // parse QTY from string
    RegExp reg = RegExp(r"\d+_QTY_");
    RegExpMatch match = reg.firstMatch(line);
    // whether the string contains "##_QTY":
    if (match == null) {
      // ignore lines that are too long
      if (line.length >= MAX_ITEM_LEN) return;
      ProtoItem pi = ProtoItem(line, 1);
      queues[line.length].add(pi);
    } else {
      RegExp qtyReg = RegExp(r"\d+");
      RegExpMatch qtyMatch = qtyReg.firstMatch(line);
      String qtyStr = line.substring(0, qtyMatch.end);
      line = line.substring(match.end);
      // ignore lines that are too long
      if (line.length > MAX_ITEM_LEN) return;
      try {
        ProtoItem pi = ProtoItem(line, int.parse(qtyStr));
        queues[line.length].add(pi);
      } catch (e) {
        ProtoItem pi = ProtoItem(line, 1);
        queues[line.length].add(pi);
      }
    }
  }

  bool convertDateFormat() {
    try {
      dateString += ":00";
      dateString =
          "20${dateString.substring(6, 8)}-${dateString.substring(0, 2)}" +
              "-${dateString.substring(3, 5)} ${dateString.substring(9)}";
    } catch (e) {
      print("Failed to format date.");
      return false;
    }

    return true;
  }

  void tryParseDate(String line, int index) {
    try {
      RegExp regDate = new RegExp(r"\d\d/\d\d/\d\d \d\d:\d\d");
      RegExpMatch match = regDate.firstMatch(line);
      if (match == null) return;
      String dateGuess = line.substring(match.start, match.end);
      print(dateGuess);

      if (dateString == "") {
        dateString = dateGuess;
      } else {
        // compare existing guess
        if (lev.distance(dateGuess, dateString) > 0) {
          print(
              "Determined date $dateGuess does not match existing guess $dateString");
        } else {
          print("Matching date found");
        }
      }
    } catch (e) {
      print("error while parsing date: ${e.toString()}");
    }
  }

  void tryParseTransactionAmount(String line, int index) {
    try {
      RegExp tReg = new RegExp(
          r"T[A-Za-z\d ]{3,5} T[A-Za-z\d ]{9,11} [A-Za-z\d ]{4,6}T:?\s*\d+[., ]?\d\d");
      RegExpMatch match = tReg.firstMatch(line);
      if (match == null) return;
      print("Transaction regex match found: $line");
      if (lev.distance("TOTAL TRANSACTION AMOUNT", line.substring(0, 25)) > 3)
        return;
      print("Levenshtein check for TRANSACTION passed for $line");

      RegExp dReg = new RegExp(r"\d+[., ]?\d\d");
      RegExpMatch dolMatch = dReg.firstMatch(line);
      String dolString = line.substring(dolMatch.start, dolMatch.end);
      String balString = tryParseDollarFigure(dolString);
      if (balString == null) return;
      print("Final TRANSACTION check passed");
      compareDollarFigure(balString);
    } catch (e) {
      print("error while parsing transaction amount: ${e.toString()}");
    }
  }

  void tryParseBalance(String line, int index) {

    // clear prefixed asterisks
    try {
      while (line[0] == '*' || line[0] == 'x' || line[0] == 'X')
        line = line.substring(1);
      line = line.trim();
      // handle OCR errors
      if (lev.distance('BALANCE', line) > 2) return;
      print("Levenshtein check for BALANCE passed for $line");
      tryParseBalanceProximity(index);
    } catch (e) {
      print("error while parsing balance: ${e.toString()}");
    }
  }

  void tryParseBalanceProximity(int index) {
    // try different text snippets that are near BALANCE
    // since one dollar amount found might be the tax, take the max
    String maxBalString = "";
    double max = -1;
    List<String> candidates = new List<String>();
    try {
      candidates.add(_ocr[index-1][0]);
    } catch (e) {}
    try {
      candidates.add(_ocr[index-1][1]);
    } catch (e) {}
    try {
      candidates.add(_ocr[index][1]);
    } catch (e) {}
    try {
      candidates.add(_ocr[index+1][0]);
    } catch (e) {}
    try {
      candidates.add(_ocr[index+1][1]);
    } catch (e) {}

    for (String balString in candidates) {
      print("Attempting BALANCE parse on $balString");
      balString = tryParseDollarFigure(balString);
      if (balString == null) continue;
      double parsedBal = double.parse(balString);
      if (parsedBal > max) {
        max = parsedBal;
        maxBalString = balString;
      }
    }

    compareDollarFigure(maxBalString);
  }

  String tryParseDollarFigure(String balString) {
    RegExp rDol = new RegExp(r"\d+\.\d\d");
    RegExpMatch match = rDol.firstMatch(balString);
    if (match == null) {
      // probably missing the decimal
      // find first non-digit character, and swap with a decimal
      RegExp rFirstDigits = new RegExp(r"\d+");
      RegExpMatch matchDigits = rFirstDigits.firstMatch(balString);
      if (matchDigits == null) {
        print("Could not parse dollar figure from $balString");
        return null;
      }
      if (matchDigits.end >= balString.length) {
        print("Could not parse dollar figure from $balString");
        return null;
      }

      balString =
          balString.replaceRange(matchDigits.end, matchDigits.end + 1, ".");
    }

    double bal;
    try {
      bal = double.parse(balString);
    } catch (e) {
      print("Could not parse dollar figure from $balString");
      return null;
    }
    return balString;
  }

  void compareDollarFigure(String balString) {
    if (dollarString == "") {
      dollarString = balString;
    } else {
      int dist = lev.distance(balString, dollarString);
      if (dist == 0) {
        print(
            "Determined figure was $balString, which EXACTLY matches existing figure $dollarString");
      } else if (dist == 1) {
        print(
            "Determined figure was $balString, which ALMOST matches existing figure $dollarString");
      } else {
        print(
            "Determined figure was $balString but DOES NOT match existing figure $dollarString");
      }
    }
  }
}