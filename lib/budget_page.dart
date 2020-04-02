import 'package:flutter/material.dart';
import 'classes.dart';
import 'package:charts_flutter/flutter.dart' as charts;
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
    purchases = await Databaser.getAllPurchases();
    /*purchases.add(PurchaseRecord(23, 14, "2020", "03", "06", "14:06:22"));
    purchases.add(PurchaseRecord(6, 78, "2020", "03", "08", "15:08:21"));
    purchases.add(PurchaseRecord(9, 78, "2020", "03", "18", "15:08:21"));
    purchases.add(PurchaseRecord(150, 78, "2020", "03", "01", "15:08:21"));
    purchases.add(PurchaseRecord(76, 78, "2020", "02", "26", "15:08:21"));*/
    purchases.sort(purchaseCompare);
    print(purchases[0].getID());
    setState((){});
  }

  int purchaseCompare(PurchaseRecord a, PurchaseRecord b) {
    return b.getDate().compareTo(a.getDate());
  }

  Widget build(BuildContext context) {

    var series = [
      new charts.Series(
        id: 'test',
        domainFn: (PurchaseRecord pr, _) => pr.getDate(),
        measureFn: (PurchaseRecord pr, _) => pr.getDollarValue(),
        colorFn: (PurchaseRecord pr, _) => new charts.Color(r: 255, g: 255, b: 255, a: 255),
        data: purchases,
      )
    ];

    var chart = new charts.TimeSeriesChart(
      series,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      domainAxis: new charts.DateTimeAxisSpec(
        renderSpec: new charts.SmallTickRendererSpec(
            labelStyle: new charts.TextStyleSpec(
              fontSize: 12,
              color: charts.MaterialPalette.white,
            )
        ),
      ),
      primaryMeasureAxis: new charts.NumericAxisSpec(
        renderSpec: new charts.SmallTickRendererSpec(
          labelStyle: new charts.TextStyleSpec(
            fontSize: 12,
            color: charts.MaterialPalette.white,
          )
        )
      )
    );

    var chartWidget = new Padding(
      padding: EdgeInsets.all(8.0),
      child: new SizedBox(
        height: 200,
        child: chart,
      )
    );

    return Column(
      children: <Widget>[
        chartWidget,
        PurchaseHistory(purchases),
      ]
    );
  }
}


class PurchaseHistory extends StatelessWidget {

  final List<PurchaseRecord> _purchases;
  PurchaseHistory(this._purchases);

  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: _purchases.length,
          itemBuilder: (context, index) {
            return PurchaseWidget(_purchases[index]);
          }
      )
    );
  }
}


class PurchaseWidget extends StatelessWidget {

  PurchaseWidget(this._record);

  final PurchaseRecord _record;

  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(_record.getDollarAmount(), style: TextStyle(
                  fontSize: 16,
                )),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(_record.getDateAsString(), style: TextStyle(
                  fontSize: 16,
                )),
              ),
            ]
        )
      )
    );
  }
}