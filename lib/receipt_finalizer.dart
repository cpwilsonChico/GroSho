import 'package:flutter/material.dart';
import 'classes.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';
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
        title: Text("GroSho"),
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
              child: SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(),
              ),
            );
          }
        }
      )
    );
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
                Text("Date: ${_receipt.pr.getDateAsString()}"),
                Text("Total: ${_receipt.pr.getDollarAmount()}"),
              ]
            )
          ),

          Container(
            padding: EdgeInsets.all(6.0),
            child: (_receipt.list.length == 0)
            ? Center(
                  child: Text("Failed to find any grocery items in your receipt."),
                )
            : ListView.builder(
              shrinkWrap: true,
              itemCount: _receipt.list.length,
              itemBuilder: (context, index) {
                return ItemStager(_receipt.list[index]);
              }
            )
          ),
        ]
      )
    );
  }
}

class ItemStager extends StatelessWidget {
  final GroceryItem _item;
  ItemStager(this._item);

  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(_item.name),
        subtitle: Text(_item.id),
      ),
    );
  }
}