import 'package:flutter/material.dart';
import 'classes.dart';
import 'receipt_scan_page.dart';
import 'dart:collection';
import 'package:camera/camera.dart';
import 'storage.dart';
import 'nav_drawer.dart';
import 'budget_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  new Databaser();

  runApp(MaterialApp(
    theme: ThemeData.dark(),
    initialRoute: "/",
    routes: {
      "/": (context) => HomePage(),
      "/scanner": (context) => ReceiptScanPage(mainCam: firstCamera),
      "/budget": (context) => BudgetPageFrame(),
    },/*
    home: PageView(
      controller: PageController(
        initialPage: 1,
      ),
      children: <Widget>[
        BudgetPageFrame(),
        HomePage(),
        ReceiptScanPage(mainCam: firstCamera),
      ]
    )*/
  ));
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);


  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<HomePage> {

  List<GroceryItem> inventoryList;
  HashMap<String, int> quantityMap;

  InventoryState() {
    // list of all foods in inventory
    inventoryList = new List<GroceryItem>();
    // map of food names to index in list
    quantityMap = new HashMap<String, int>();
  }

  // on load, read from database
  @override
  void initState() {
    super.initState();
    loadFromDB();
  }

  void loadFromDB() async {
    List<Map> maps = await Databaser.getAll();
    for (Map m in maps) {
      addItem(GroceryItem.fromMap(m));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavDrawer(),
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
    });
  }

  void updateItem(int index, int amount) {
    inventoryList[index].amount = amount;
    setState(()=>{});
    Databaser.update(inventoryList[index]);
  }

  void deleteItem(int index) {
    quantityMap.remove(inventoryList[index].getID());
    Databaser.delete(inventoryList[index]);
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
  final void Function(int, int) updateList;
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
    isEditing = false;
    editItem = null;
  }

  PromptDialogState.edit(GroceryItem gi, int index) {
    item = gi.name;
    amount = gi.amount;
    isEditing = true;
    editItem = gi;
    giIndex = index;
  }

  GroceryItem editItem;
  String selectedString;
  String item;
  int amount;
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
                        amount = int.parse(input);
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
            ]
        ),
        SizedBox(height: 10),
        RaisedButton(
          onPressed: () {
            if (isEditing) {
              widget.updateList(giIndex, amount);
            } else {
              GroceryItem gi = new GroceryItem(item, item, amount);
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


