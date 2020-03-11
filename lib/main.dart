import 'package:flutter/material.dart';
import 'classes.dart';
import 'receipt_scan_page.dart';
import 'dart:collection';
import 'package:camera/camera.dart';
import 'storage.dart';
import 'budget_page.dart';
import 'package:edit_distance/edit_distance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  Databaser db = new Databaser();

  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: PageView(
      controller: PageController(
        initialPage: 1,
      ),
      children: <Widget>[
        BudgetPageFrame(),
        HomePage(db: db),
        ReceiptScanPage(mainCam: firstCamera),
      ]
    )
  ));
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.db}) : super(key: key);

  final Databaser db;

  @override
  InventoryState createState() => InventoryState(db);
}

class InventoryState extends State<HomePage> {

  Databaser db;

  List<GroceryItem> inventoryList;
  HashMap<String, int> quantityMap;
  QuantityType curQuan;
  String curQuanString;

  InventoryState(this.db) {
    // list of all foods in inventory
    inventoryList = new List<GroceryItem>();
    // map of food names to index in list
    quantityMap = new HashMap<String, int>();
    curQuanString = quantityToString(QuantityType.fl_oz);
  }

  // on load, read from database
  @override
  void initState() {
    super.initState();
    loadFromDB();
  }

  void loadFromDB() async {
    List<Map> maps = await db.getAll();
    for (Map m in maps) {
      addItem(GroceryItem.fromMap(m));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GroSho")
      ),
      body: _myListView(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => promptItem(context),
        child: Icon(Icons.add)
      ),
    );
  }


  // builds the Widget displaying all inventory items
  Widget _myListView(BuildContext context) {
    return ListView.builder(
      itemCount: inventoryList.length,
      itemBuilder: (context, index) {
        return Card(
            child: ListTile(
                onTap: () => promptItem(context, gi: inventoryList[index], giIndex: index),
                onLongPress: () => promptDelete(context, index),
                title: Text(inventoryList[index].name),
                leading: Text(inventoryList[index].getQuantityAsString())
            )
        );
      },
    );
  }

  void promptDelete(BuildContext context, int giIndex) {
    showDialog<Widget>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("Delete '${inventoryList[giIndex].name}'?"),
          contentPadding: EdgeInsets.all(15.0),
          children: <Widget>[
            RaisedButton(
              color: Color.fromARGB(255, 175, 80, 80),
              child: Text("Yes"),
              onPressed: () {
                deleteItem(giIndex);
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 10),
            RaisedButton(
              child: Text("No"),
              color: Color.fromARGB(255, 40, 40, 40),
              onPressed: () => Navigator.pop(context),
            )
          ]
        );
      }
    );
  }

  // handler for adding new or editing existing inventory items
  void promptItem(BuildContext context, {GroceryItem gi, int giIndex}) {
    showDialog<Widget>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: (gi==null) ? Text("Add to inventory:") : Text("Changing info:"),
          contentPadding: EdgeInsets.all(15.0),
          children: <Widget>[
            PromptDialog(addToList: addItem, updateList: updateItem, editItem: gi, giIndex: giIndex),
          ]
        );
      }
    );
  }

  void addItem(GroceryItem item) {
    setState( () {
      if (quantityMap.containsKey(item.id)) {
        inventoryList[quantityMap[item.id]].amount += item.amount;
      } else {
        quantityMap[item.id] = inventoryList.length;
        inventoryList.add(item);
      }

      db.insert(item);
    });
  }

  void updateItem(int index, QuantityType q, double amount) {
    inventoryList[index].q = q;
    inventoryList[index].amount = amount;
    setState(()=>{});
    db.update(inventoryList[index]);
  }

  void deleteItem(int index) {
    quantityMap.remove(inventoryList[index].getID());
    db.delete(inventoryList[index]);
    inventoryList.removeAt(index);
    setState(()=>{});
  }
}

// class to handle adding new inventory items via input prompt
// dialog must have its own state for dropdown to work
class PromptDialog extends StatefulWidget {
  PromptDialog({Key key, this.addToList, this.updateList, this.editItem, this.giIndex}) : super(key: key);

  // callback function to communicate with parent widget
  // adds a grocery item to the inventory
  final void Function(GroceryItem) addToList;
  final void Function(int, QuantityType, double) updateList;
  final GroceryItem editItem;
  final int giIndex;

  @override
  PromptDialogState createState() {
    if (editItem == null) {
      return new PromptDialogState();
    } else {
      return new PromptDialogState.edit(editItem, giIndex);
    }
  }
}

class PromptDialogState extends State<PromptDialog> {

  @override
  PromptDialogState() : super() {
    selectedString = quantityToString(QuantityType.unknown);
    selectedQ = QuantityType.unknown;
    isEditing = false;
    editItem = null;
  }

  PromptDialogState.edit(GroceryItem gi, int index) {
    selectedString = quantityToString(gi.q);
    selectedQ = gi.q;
    item = gi.name;
    amount = gi.amount;
    isEditing = true;
    editItem = gi;
    giIndex = index;
  }

  GroceryItem editItem;
  String selectedString;
  QuantityType selectedQ;
  String item;
  double amount;
  bool isEditing;
  int giIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        SizedBox(
          width: 280,
          // input for food name
          child: (!isEditing) ? TextField(
            // let user change name when adding item
              onChanged: (String input) {
                setState(() => item=input);
              },
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Item'
              )
            // prevent user from changing name when editing item
          ) : SizedBox(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 24,
              )
            ),
            height: 40,
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(
                width: 120,
                // input for amount (number)
                child: TextFormField(
                    onChanged: (String input) {
                      setState( () {
                        amount = double.parse(input);
                      });
                    },
                    initialValue: (amount==null) ? '' : amount.toStringAsFixed(2),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Quantity'
                    )
                ),
              ),
              DropdownButton<String>(
                items: QuantityType.values.map<DropdownMenuItem<String>>((QuantityType qt) {
                  return DropdownMenuItem<String>(
                    value: quantityToString(qt),
                    child: Text(quantityToString(qt)),
                  );
                }).toList(),
                onChanged: (String newValue) {
                  setState(() {
                    selectedString = newValue;
                    selectedQ = strToQuantity[newValue];
                  });
                },
                value: selectedString,
              ),
            ]
        ),
        SizedBox(height: 10),
        RaisedButton(
          onPressed: () {
            if (isEditing) {
              widget.updateList(giIndex, selectedQ, amount);
            } else {
              GroceryItem gi = new GroceryItem(selectedQ, item, item, amount);
              widget.addToList(gi);
            }
            Navigator.pop(context);
          },
          child: Text("Done"),
        )
      ]
    );

  }
}


