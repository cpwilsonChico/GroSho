import 'package:edit_distance/edit_distance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:core';
import 'classes.dart';

class ReceiptParser {
  static const MAX_ITEM_LEN = 50;
  ReceiptParser(this._ocr) {
    itemsFound = new List<GroceryItem>();
    queues = new List<List<String>>();
    for (int i = 0; i < MAX_ITEM_LEN; i++) {
      queues.add(new List<String>());
    }
  }

  ReceiptParser.blank();

  List<List<String>> _ocr;
  List<List<String>> queues;
  List<GroceryItem> itemsFound;
  Levenshtein lev = new Levenshtein();

  //String tta = "";  // TOTAL TRANSACTION AMOUNT: $xx.xx
  //String cba = "";  // CASH BACK AMOUNT:         $xx.xx


  String dollarString = "";
  String dateString = "";
  int dollars = -1;
  int cents = -1;




  Future<ReceiptType> parse() async {
    print("ocr length: ${_ocr.length}");
    ReceiptType nullRec = ReceiptType.empty();
    for (int i = 0; i < _ocr.length; i++) {
      print("i: $i");
      List<String> block = _ocr[i];
      for (int j = 0; j < block.length; j++) {
        String line = block[j];

        tryParseTransactionAmount(line, i);
        tryParseBalance(line, i);
        tryParseDate(line, i);
        addToList(line);
        //tryParseDebit(line, i);
        //tryParseChange(line, i);
        //tryParseCBA(line, i);
      }
    }

    print("AAA");

    if (dollarString == "") {
      print("Could not determine total cost from receipt image.");
      return nullRec;
    } else {
      double dollarValue = double.tryParse(dollarString);
      if (dollarValue == null) {
        print("Could not determine total cost from receipt image");
        return nullRec;
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

    String centsString = cents.toString();
    if (cents < 10) centsString = "0" + centsString;
    print("I think the receipt totalled \$$dollars.$centsString");

    bool goodDate = convertDateFormat();
    if (!goodDate) return nullRec;
    print("I think the date of this receipt is $dateString");

    DateTime receiptDate = DateTime.parse(dateString);

    PurchaseRecord recPr = PurchaseRecord.withDateTime(dollars, cents, receiptDate);
    ReceiptType rec = new ReceiptType(recPr, itemsFound, null);
    print("end of PARSE");
    return rec;

  }

  // processes each queued grocery code by checking against firebase
  Future processItems() async {
    print("BEGIN processItems()");
    // add all non-empty queues to the stream list
    for (int i = 0; i < queues.length; i++) {
      if (queues[i].isEmpty) continue;
      CollectionReference colref = Firestore.instance.collection("items$i");
      if (CollectionReference == null) continue;
      QuerySnapshot snap = await colref.getDocuments();
      print("POST SNAP");
      for (DocumentSnapshot doc in snap.documents) {
        String fromDB = doc.data["id"];
        for (int j = 0; j < queues[i].length; j++) {
          String candidate = queues[i][j];
          if (lev.distance(fromDB, candidate) < 2) {
            print("Found match: $candidate => $fromDB");
            itemsFound.add(new GroceryItem(fromDB, doc.data["name"], 1));
            queues[i].removeAt(j);
          }
        }
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
    line = line.replaceAll("/", "-");
    line = line.toUpperCase();
    if (line.contains("CRV")) return; // ignore CRV
    if (lev.distance(line, "REGULAR_PRICE") < 2) return;  // ignore discounts
    if (lev.distance(line, "CARD_SAVINGS") < 2) return;   // ignore discounts
    queues[line.length].add(line);
    print("length: ${line.length}");
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

  void parseItems(String line) {

  }

  void tryParseItem(String line) {
    line = line.trim();
    line = line.replaceAll(" ", "_");
    int strLen = line.length;
    String collecName = "items" + strLen.toString();

    Stream<QuerySnapshot> stream = Firestore.instance.collection(collecName).snapshots();
    stream.listen(
        (data) {
          print("data: $data");
          //if (lev.distance(line, data))
        },
        onDone: () {
          print("Data stream complete.");
        }
    );
  }

  void tryParseDate(String line, int index) {
    RegExp regDate = new RegExp(r"\d\d/\d\d/\d\d \d\d:\d\d");
    RegExpMatch match = regDate.firstMatch(line);
    if (match == null) return;
    String dateGuess = line.substring(match.start, match.end);
    print(dateGuess);

    if (dateString == "")
    {
        dateString = dateGuess;
    } else {
      // compare existing guess
      if (lev.distance(dateGuess, dateString) > 0) {
        print("Determined date $dateGuess does not match existing guess $dateString");
      } else {
        print("Matching date found");
      }
    }
  }

  void tryParseTransactionAmount(String line, int index) {
    RegExp tReg = new RegExp(r"T[A-Za-z\d ]{3,5} T[A-Za-z\d ]{9,11} [A-Za-z\d ]{4,6}T:?\s*\d+[., ]?\d\d");
    RegExpMatch match = tReg.firstMatch(line);
    if (match == null) return;
    print("Transaction regex match found: $line");
    if (lev.distance("TOTAL TRANSACTION AMOUNT", line.substring(0, 25)) > 3) return;
    print("Levenshtein check for TRANSACTION passed for $line");

    RegExp dReg = new RegExp(r"\d+[., ]?\d\d");
    RegExpMatch dolMatch = dReg.firstMatch(line);
    String dolString = line.substring(dolMatch.start, dolMatch.end);
    String balString = tryParseDollarFigure(dolString);
    if (balString == null) return;
    print ("Final TRANSACTION check passed");
    compareDollarFigure(balString);
  }

  void tryParseBalance(String line, int index) {

    // clear prefixed asterisks
    while (line[0] == '*' || line[0] == 'x' || line[0] == 'X') line = line.substring(1);
    line = line.trim();
    // handle OCR errors
    if (lev.distance('BALANCE', line) > 2) return;
    print("Levenshtein check for BALANCE passed for $line");
    tryParseBalanceProximity(index);
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