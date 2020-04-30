import 'package:flutter/material.dart';
import 'classes.dart';
import 'storage.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';
import 'receipt_parser.dart';

// page for checking / editing receipt data
class ReceiptFinalizer extends StatefulWidget {
  final List<String> _imgPaths;
  final Function _clearData;
  ReceiptFinalizer(this._imgPaths, this._clearData);

  State<ReceiptFinalizer> createState() => ReceiptState(_imgPaths, _clearData);
}

class ReceiptState extends State<ReceiptFinalizer> {
  Future _visionFunction;
  Function _clearData;
  List<String> _imgPaths;
  ReceiptType receipt;

  Map<String, int> indexMap;

  ReceiptState(this._imgPaths, this._clearData);

  @override
  initState() {
    super.initState();
    indexMap = new Map<String, int>();
    _visionFunction = doVision();
  }

  Future<ReceiptType> doVision() async {
    List<List<String>> ocrData = new List<List<String>>();
    for (String path in _imgPaths) {
      File img = File(path);
      FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(img);
      TextRecognizer tr = FirebaseVision.instance.textRecognizer();
      VisionText vt = await tr.processImage(visionImage);

      int i = 0;
      for (TextBlock block in vt.blocks) {
        ocrData.add(new List<String>());
        int j = 0;
        for (TextLine line in block.lines) {
          //print("($i,$j) ${line.text}");
          j++;
          ocrData[i].add(line.text);
        }
        i++;
      }
    }

    print("PARSING FUTURE");
    ReceiptParser parser = new ReceiptParser(ocrData);
    receipt = await parser.parse();
    print("POST PARSE");
    setState((){});
    setupIndexMap();
    return receipt;
  }

  void setupIndexMap() {
    List<int> removeThese = new List<int>();
    for (int i = 0; i < receipt.list.length; i++) {
      GroceryItem gi = receipt.list[i];
      String id = gi.getID();
      if (indexMap.containsKey(id)) {
        receipt.list[indexMap[id]].amount += gi.amount;
        removeThese.add(i);
      } else {
        indexMap[gi.getID()] = i;
      }
    }

    for (int i = 0; i < removeThese.length; i++) {
      removeThese[i] -= i;
      receipt.list.removeAt(removeThese[i]);
    }
  }

  // adjusts indexMap after deleting an item
  // 0 1 2 3 4
  // 0 1   2 3
  void deleteCleanup(int index) {
    for (String key in indexMap.keys) {
      if (indexMap[key] < index) continue;
      if (indexMap[key] == index) {
        indexMap.remove(key);
      }
      if (indexMap[key] > index) {
        indexMap[key] -= 1;
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Confirm Your Receipt"),
      ),
      body: FutureBuilder(
        future: _visionFunction,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _clearData();
            // if parsing failed, display error message
            if ( (receipt == null) ? true : receipt.pr == null) {
              return Center(
                child: Text("Failed to parse receipt. Try again."),
              );
            } else {
              return ReceiptStager(receipt, deleteCleanup);
            }
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(height: 10),
                  Text("This may take a few seconds..."),
                ]
              )
            );
          }
        }
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: bottomNavHandler,
        currentIndex: 2,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.cancel), title: Text("Cancel"),),
          BottomNavigationBarItem(icon: Icon(Icons.add), title: Text("New")),
          BottomNavigationBarItem(icon: Icon(Icons.check), title: Text("Done")),
        ]
      )
    );
  }

  Future<bool> showBinaryDialog(String titleText, String contentText) async {
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("$titleText"),
            content: Text("$contentText"),
            actions: [
              FlatButton(
                child: Text("No"),
                onPressed: () => Navigator.pop(context, false),
              ),
              FlatButton(
                child: Text("Yes"),
                onPressed: () => Navigator.pop(context, true),
              )
            ],
            elevation: 24.0,
          );
        }
    );
  }

  Future<void> submitReceipt() async {
    await Databaser.insertPurchase(receipt.pr);
    for (GroceryItem gi in receipt.list) {
      await Databaser.insert(gi);
    }
    // pop to home page
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    //Navigator.pushNamed(context, "/");
  }

  Future<bool> showCancelDialog() async {
    bool cancel = await showBinaryDialog("Cancel this receipt?", "You will have to scan the receipt again.");
    if (cancel == null) return false;
    return cancel;
  }

  Future<bool> showDoneDialog() async {
    bool done = await showBinaryDialog("Confirm receipt?", "Make sure the date, price, and list of items match your receipt.");
    if (done == null) return false;
    return done;
  }

  // add new item, or increase amount of existing item
  void addItem(GroceryItem gi) {
    String id = gi.getID();
    if (indexMap.containsKey(id)) {
      receipt.list[indexMap[id]].amount += gi.amount;
    } else {
      receipt.list.add(gi);
      indexMap[id] = receipt.list.length-1;
    }
    setState((){});
  }

  void bottomNavHandler(int index) async {
    switch (index) {
      case 0:
        if (receipt == null) Navigator.pop(context);
        if (await showCancelDialog()) {
          Navigator.pop(context);
        }
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return NewItemMenu(addItem);
            }
        ));
        break;
      case 2:
        if (receipt.pr == null) return;
        if (await showDoneDialog()) {
          //Navigator.pop(context);
          await submitReceipt();
        }
    }
  }
}

// shows receipt info and items
class ReceiptStager extends StatefulWidget {
  final ReceiptType _receipt;
  final Function deleteCleanup;
  ReceiptStager(this._receipt, this.deleteCleanup);
  State<ReceiptStager> createState() => StagerState(_receipt, deleteCleanup);
}

class StagerState extends State<ReceiptStager> {
  ReceiptType _receipt;
  StagerState(this._receipt, this.deleteCleanup);
  Function deleteCleanup;

  void editQuantity(int index, int amount) {
    _receipt.list[index].changeAmount(amount);
    setState((){});
  }
  void deleteItem(BuildContext context, int index) async {
    bool shouldDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete ${_receipt.list[index].name}?"),
          content: Text("You can manually add this grocery item again."),
          actions: [
            FlatButton(
              child: Text("No"),
              onPressed: () => Navigator.pop(context, false),
            ),
            FlatButton(
              child: Text("Yes"),
              onPressed: () => Navigator.pop(context, true),
            )
          ],
          elevation: 24.0,
        );
      }
    );
    if (shouldDelete == null) return;
    if (!shouldDelete) return;
    _receipt.list.removeAt(index);
    deleteCleanup(index);
    setState((){});
  }

  void showTotalDialog() async {
    String input = "";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Change receipt total"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '\$12.34',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (String newVal) {
                    input = newVal;
                  }
              ),
            ]
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                try {
                  double inputNum = double.parse(input);
                  int index = input.indexOf(".");
                  // no decimal
                  if (index == -1) {
                    int dollars = int.parse(input);
                    _receipt.pr.setDollarsAndCents(dollars, 0);
                  // decimal
                  } else {
                    String dolString = input.substring(0, index);
                    int dollars = int.parse(dolString);
                    String cenString = input.substring(index+1);
                    if (cenString.length > 2) {
                      cenString = cenString.substring(0, 2);
                    }
                    int cents = int.parse(cenString);
                    if (cenString.length == 1) {
                      cents *= 10;
                    }
                    _receipt.pr.setDollarsAndCents(dollars, cents);
                  }
                  setState((){});
                  Navigator.pop(context);
                } catch (e) {

                }
              }
            )
          ]
        );
      }
    );
  }

  Widget build(BuildContext context) {
    Color moneyColor;
    if ( (_receipt.pr == null) ? true : _receipt.pr.getDollarValue() < 0.01) {
      print("dollar value: ${_receipt.pr.getDollarValue()}");
      moneyColor = Color.fromARGB(255, 196, 166, 166);
    } else {
      moneyColor = Color.fromARGB(255, 166, 196, 166);
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
            decoration: BoxDecoration(
              color: Color.fromARGB(0xFF, 0x80, 0x80, 0x80),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Date: ${_receipt.pr.getDateAsFriendlyString()}"),
                RaisedButton(
                  color: moneyColor,
                  child: Text(
                    "Total: ${_receipt.pr.getDollarAmount()}",
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: showTotalDialog
                ),
              ]
            )
          ),

          Expanded(
            child: Container(
                padding: EdgeInsets.all(6.0),
                child: (_receipt.list.length == 0)
                    ? Center(
                  child: Text("Failed to find any grocery items in your receipt."),
                )
                    : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _receipt.list.length,
                    itemBuilder: (context, index) {
                      return ItemStager(_receipt.list[index], index, editQuantity, deleteItem);
                    }
                )
            ),
          )
        ]
      )
    );
  }
}

// widget to display 1 grocery item
class ItemStager extends StatelessWidget {
  final GroceryItem _item;
  final int myIndex;
  final Function editQuantity;
  final Function deleteItem;
  ItemStager(this._item, this.myIndex, this.editQuantity, this.deleteItem);

  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        key: PageStorageKey<String>(_item.id),
        title: Text(_item.name),
        //subtitle: Text(_item.id, style: TextStyle(fontSize: 8)),
        leading: Text("${_item.amount}"),
        children: <Widget>[
          ItemEditWidget(_item.getID(), this.myIndex, this.editQuantity, this.deleteItem),
        ]
      ),
    );
  }
}

// widget shown when expanding a grocery item, allowing item editing
class ItemEditWidget extends StatefulWidget {
  final int myIndex;
  final Function editQuantity;
  final Function deleteItem;
  final String id;
  ItemEditWidget(this.id, this.myIndex, this.editQuantity, this.deleteItem);
  State<ItemEditWidget> createState() => ItemEditState(id, myIndex, editQuantity, deleteItem);
}

class ItemEditState extends State<ItemEditWidget> {
  final int myIndex;
  final Function editQuantity;
  final Function deleteItem;
  final String id;
  ItemEditState(this.id, this.myIndex, this.editQuantity, this.deleteItem);

  Widget build(BuildContext context) {
    String displayID = id.replaceAll("_", " ").replaceAll("#", "/");
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 73.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(displayID),
          ),
        ),
        ButtonBar(
          buttonPadding: EdgeInsets.fromLTRB(4, 0, 4, 0),
          children: <Widget>[
            FlatButton(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: Text("DELETE", style: TextStyle(color: Colors.red)),
              ),
              onPressed: () => deleteItem(context, myIndex),
            ),
            FlatButton(
              child: Icon(Icons.add, color: Colors.lightBlue),
              onPressed: () => editQuantity(myIndex, 1),
            ),
            FlatButton(
              child: Icon(Icons.remove, color: Colors.lightBlue),
              onPressed: () => editQuantity(myIndex, -1)
            )
          ]
        )
      ]
    );

  }
}

// page for adding new items to the receipt list
class NewItemMenu extends StatefulWidget {
  final Function addItem;
  NewItemMenu(this.addItem);
  State<NewItemMenu> createState() => NewItemMenuState(addItem);
}

class NewItemMenuState extends State<NewItemMenu> {
  String inputID;
  String inputName;
  Function addItem;
  bool waiting = false;
  bool insertingIntoDB = false;
  NewItemMenuState(this.addItem);

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Item"),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(4.0),
          child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("Enter the code exactly as it appears on the receipt (e.g. HOMOGZD MILK): "),
                  SizedBox(height:10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'ID',
                        ),
                        onChanged: (newVal) {
                          inputID = newVal;
                          setState((){});
                        }
                    ),
                  ),

                  Visibility(
                      visible: insertingIntoDB,
                      replacement: SizedBox(height: 0, width: 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(height:16),
                          Text("Short description, max ${ReceiptParser.MAX_ITEM_LEN} characters (e.g. Milk, Eggs): "),
                          SizedBox(height:10),
                          TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Description',
                              ),
                              onChanged: (String newVal) {
                                if (newVal.length > ReceiptParser.MAX_ITEM_LEN) {
                                  newVal = newVal.substring(0, ReceiptParser.MAX_ITEM_LEN);
                                }
                                inputName = newVal;
                                setState((){});
                              }
                          )
                        ]
                      ),
                  ),

                  Visibility(
                      visible: waiting,
                      replacement: SizedBox(height: 0, width: 0),
                      child: Center(
                          child: SizedBox(
                              height: 60, width: 60, child: CircularProgressIndicator()
                          )
                      )
                  )
                ]
              ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          onTap: bottomNavHandler,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.cancel), title: Text("Cancel")),
            BottomNavigationBarItem(icon: Icon(Icons.check), title: Text("Submit")),
          ]
      )
    );
  }

  Future<void> submitHandler() async {
    String originalInput = inputID;
    inputID = inputID.toUpperCase();
    inputID = inputID.replaceAll(" ", "_");
    inputID = inputID.replaceAll("/", "#");
    waiting = true;
    setState((){});

    if (insertingIntoDB) {
      GroceryItem gi = new GroceryItem(inputID, inputName, 1);
      bool success = await Databaser.insertCloudItem(gi);
      waiting = false;
      if (success) {
        addItem(gi);
        Navigator.pop(context);
      } else {
        setState((){});
        showDialog(
          context: context, builder: (context) {
            return AlertDialog(
              title: Text("Failed to Update Database"),
              content: Text("Could not add the new code to the database. Maybe the code already exists?"),
              actions: [
                FlatButton(
                  child: Text("OK"),
                  onPressed: () => Navigator.pop(context),
                )
              ]
            );
          }
        );
      }
      return;
    }


    int status = await Databaser.checkCodeExactly(inputID);
    if (status == 1) {

      String name = await Databaser.getNameByCode(inputID);
      GroceryItem gi = new GroceryItem(inputID, name, 1);
      addItem(gi);
      waiting = false;
      Navigator.pop(context);
    } else {
      waiting = false;
      setState((){});
      showDialog(
          context: context, builder: (context) {
            return AlertDialog(
                title: Text("Item Code Not Found"),
                content: Text("Could not find anything in the database that matched '$originalInput'. Check your spelling, or add a new entry into the database."),
                actions: [
                  FlatButton(
                      child: Text("GO BACK"),
                      onPressed: () => Navigator.pop(context),
                  ),
                  FlatButton(
                      child: Text("ADD ENTRY"),
                      onPressed: () {
                        insertingIntoDB = true;
                        setState((){});
                        Navigator.pop(context);
                      }
                  )
                ]
            );
          }
      );
    }
  }

  void bottomNavHandler(int index) async {
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        await submitHandler();
        break;
    }
  }
}