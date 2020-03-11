import 'package:flutter/material.dart';
import 'classes.dart';
import 'storage.dart';


class BudgetPageFrame extends StatelessWidget {

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Purchase History"),
      ),
      body: BudgetPage(),
    );
  }
}

class BudgetPage extends StatefulWidget {

  @override
  BudgetState createState() => BudgetState();
}

class BudgetState extends State<BudgetPage> {

  List<PurchaseRecord> purchases = new List<PurchaseRecord>();

  @override
  void initState() {
    super.initState();
    loadFromDB();
  }

  void loadFromDB() async {
    List<Map> maps = await Databaser.getAllPurchases();
    purchases.add(PurchaseRecord(
      23, 14, "2020", "03", "06", "14:06"
    ));
    setState((){});
  }

  Widget build(BuildContext context) {
    return PurchaseHistory(purchases);
  }
}


class PurchaseHistory extends StatelessWidget {

  final List<PurchaseRecord> _purchases;
  PurchaseHistory(this._purchases);

  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _purchases.length,
      itemBuilder: (context, index) {
        return PurchaseWidget(_purchases[index]);
      }
    );
  }
}


class PurchaseWidget extends StatelessWidget {

  PurchaseWidget(this._record);

  final PurchaseRecord _record;

  Widget build(BuildContext context) {
    return Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(_record.getDate()),
          Text(_record.getDollarAmount()),
        ]
      )
    );
  }
}