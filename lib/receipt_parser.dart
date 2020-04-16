import 'package:edit_distance/edit_distance.dart';
import 'dart:core';
import 'classes.dart';

class ReceiptParser {
  ReceiptParser(this._ocr) {
    namesFound = new List<String>();
  }

  List<List<String>> _ocr;
  List<String> namesFound;
  Levenshtein lev = new Levenshtein();

  //String tta = "";  // TOTAL TRANSACTION AMOUNT: $xx.xx
  //String cba = "";  // CASH BACK AMOUNT:         $xx.xx


  String dollarString = "";
  String dateString = "";
  int dollars = -1;
  int cents = -1;



  Future<ReceiptType> parse() async {
    print(_ocr.length);
    ReceiptType nullRec = ReceiptType.empty();
    for (int i = 0; i < _ocr.length; i++) {
      List<String> block = _ocr[i];
      for (int j = 0; j < block.length; j++) {
        String line = block[j];

        tryParseTransactionAmount(line, i);
        tryParseBalance(line, i);
        tryParseDate(line, i);
        tryParseItem(line);
        //tryParseDebit(line, i);
        //tryParseChange(line, i);
        //tryParseCBA(line, i);
      }
    }

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

    String centsString = cents.toString();
    if (cents < 10) centsString = "0" + centsString;
    print("I think the receipt totalled \$$dollars.$centsString");

    bool goodDate = convertDateFormat();
    print("I think the date of this receipt is $dateString");
    if (!goodDate) return null;

    DateTime receiptDate = DateTime.parse(dateString);

    List<GroceryItem> itemsFound = new List<GroceryItem>();
    for (String name in namesFound) {
      itemsFound.add(GroceryItem(QuantityType.gallons, name, name, 1));
    }

    PurchaseRecord recPr = PurchaseRecord.withDateTime(dollars, cents, receiptDate);
    ReceiptType rec = new ReceiptType(recPr, itemsFound);
    return rec;

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

  void tryParseItem(String line) {
    if (lev.distance("HOMOGZD MILK", line) <= 1) {
      namesFound.add("HOMOGZD MILK");
      print("MILK FOUND");
    }
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