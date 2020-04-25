import 'package:flutter/material.dart';
import 'classes.dart';
import 'storage.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';
import 'main.dart';
import 'receipt_parser.dart';


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

  ReceiptState(this._imgPaths, this._clearData);

  @override
  initState() {
    super.initState();
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
    return receipt;
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
            if (receipt.pr == null) {
              return Center(
                child: Text("Failed to parse receipt. Try again."),
              );
            } else {
              return ReceiptStager(receipt);
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

  void submitReceipt() {
    Databaser.insertPurchase(receipt.pr);
    for (GroceryItem gi in receipt.list) {
      Databaser.insert(gi);
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return HomePage();
    }));
  }

  Future<bool> showCancelDialog() async {
    if (receipt.pr == null) return true;
    bool cancel = await showBinaryDialog("Cancel this receipt?", "You will have to scan the receipt again.");
    if (cancel == null) return false;
    return cancel;
  }

  Future<bool> showDoneDialog() async {
    bool done = await showBinaryDialog("Confirm receipt?", "Make sure the date, price, and list of items match your receipt.");
    if (done == null) return false;
    return done;
  }

  void addItem(GroceryItem gi) {
    receipt.list.add(gi);
    setState((){});
  }

  void bottomNavHandler(int index) async {
    switch (index) {
      case 0:
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
        if (await showDoneDialog()) {
          submitReceipt();
          Navigator.pop(context);
        }
    }
  }
}

class ReceiptStager extends StatefulWidget {
  final ReceiptType _receipt;
  ReceiptStager(this._receipt);
  State<ReceiptStager> createState() => StagerState(_receipt);
}

class StagerState extends State<ReceiptStager> {
  ReceiptType _receipt;
  StagerState(this._receipt);

  void editQuantity(int index, int amount) {
    _receipt.list[index].amount += amount;
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
    setState((){});
  }

  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: Color.fromARGB(0xFF, 0x80, 0x80, 0x80),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Date: ${_receipt.pr.getDateAsFriendlyString()}"),
                Text("Total: ${_receipt.pr.getDollarAmount()}"),
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
          ItemEditWidget(this.myIndex, this.editQuantity, this.deleteItem),
        ]
      ),
    );
  }
}

class ItemEditWidget extends StatefulWidget {
  final int myIndex;
  final Function editQuantity;
  final Function deleteItem;
  ItemEditWidget(this.myIndex, this.editQuantity, this.deleteItem);
  State<ItemEditWidget> createState() => ItemEditState(myIndex, editQuantity, deleteItem);
}

class ItemEditState extends State<ItemEditWidget> {
  final int myIndex;
  final Function editQuantity;
  final Function deleteItem;
  ItemEditState(this.myIndex, this.editQuantity, this.deleteItem);

  Widget build(BuildContext context) {
    return ButtonBar(
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
    );
  }
}


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
        child: Stack(
          children: <Widget>[
            Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("Enter the code exactly as it appears on the receipt (e.g. HOMOGZD MILK): "),
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
                          Text("Short description (e.g. Milk, Eggs): "),
                          TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Description',
                              ),
                              onChanged: (newVal) {
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

          ]
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
    waiting = true;
    setState((){});

    if (insertingIntoDB) {
      bool success = await Databaser.insertCloudItem(new GroceryItem(QuantityType.gallons, inputID, inputName, 1));
      waiting = false;
      if (success) {
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
      GroceryItem gi = new GroceryItem(
        QuantityType.gallons,
        inputID,
        name,
        1,
      );
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
                content: Text("Could not find anything in the database that matched '$inputID'. Check your spelling, or add a new entry into the database."),
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