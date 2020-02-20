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

  InventoryState() {
    // list of all foods in inventory
    inventoryList = new List<GroceryItem>();
    // map of food names to index in list
    quantityMap = new HashMap<String, int>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GroSho")
      ),
      body: _myListView(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addItem(),
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
                leading: Text(inventoryList[index].getQuantityString())
            )
        );
      },
    );
  }

  void addItem() {
    setState( () {
      if (quantityMap.containsKey("Milk")) {
        inventoryList[quantityMap["Milk"]].amount += 0.85;

      } else {
        GroceryItem gi = new GroceryItem(QuantityType.gallons, "Milk", 0.85);
        quantityMap["Milk"] = inventoryList.length;
        inventoryList.add(gi);
      }
    });
  }
}


