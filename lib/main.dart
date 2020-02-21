import 'package:flutter/material.dart';
import 'classes.dart';
import 'dart:collection';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GroSho',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: HomePage()
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<HomePage> {

  List<GroceryItem> inventoryList;
  HashMap<String, int> quantityMap;
  QuantityType curQuan;
  String curQuanString;

  InventoryState() {
    // list of all foods in inventory
    inventoryList = new List<GroceryItem>();
    // map of food names to index in list
    quantityMap = new HashMap<String, int>();
    curQuanString = quantityToString(QuantityType.fl_oz);
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

  Widget _myListView(BuildContext context) {
    return ListView.builder(
      itemCount: inventoryList.length,
      itemBuilder: (context, index) {
        return Card(
            child: ListTile(
                title: Text(inventoryList[index].name),
                leading: Text(inventoryList[index].getAsString())
            )
        );
      },
    );
  }

  void promptItem(BuildContext context) {
    showDialog<Widget>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("Add to inventory:"),
          contentPadding: EdgeInsets.all(15.0),
          children: <Widget>[
            PromptDialog(addToList: addItem),
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
}

// dialog must have its own state for dropdown to work
class PromptDialog extends StatefulWidget {
  PromptDialog({Key key, this.addToList}) : super(key: key);

  // callback function to communicate with parent widget
  // adds a grocery item to the inventory
  final void Function(GroceryItem) addToList;

  @override
  PromptDialogState createState() => new PromptDialogState();
}

class PromptDialogState extends State<PromptDialog> {
  String selectedString = quantityToString(QuantityType.lbs);
  QuantityType selectedQ = QuantityType.lbs;
  String item;
  double amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(
                width: 120,
                child: TextField(
                    onChanged: (String input) {
                      setState( () {
                        amount = double.parse(input);
                      });
                    },
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
        SizedBox(
          width: 280,
          child: TextField(
              onChanged: (String input) {
                setState(() => item=input);
              },
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Item'
              )
          ),
        ),
        SizedBox(height: 10),
        RaisedButton(
          onPressed: () {
            GroceryItem gi = new GroceryItem(selectedQ, item, item, amount);
            widget.addToList(gi);
            Navigator.pop(context);
          },
          child: Text("Done"),
        )
      ]
    );

  }
}


