import 'package:flutter/material.dart';
import 'classes.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';
import 'receipt_parser.dart';


class ReceiptFinalizer extends StatefulWidget {
  final List<String> _imgPaths;
  ReceiptFinalizer(this._imgPaths);

  State<ReceiptFinalizer> createState() => ReceiptState(_imgPaths);
}

class ReceiptState extends State<ReceiptFinalizer> {
  Future _visionFunction;
  List<String> _imgPaths;
  ReceiptType receipt;

  ReceiptState(this._imgPaths);

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

      List<List<String>> ocrData = new List<List<String>>();
      int i = 0;
      for (TextBlock block in vt.blocks) {
        ocrData.add(new List<String>());
        int j = 0;
        for (TextLine line in block.lines) {
          print("($i,$j) ${line.text}");
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
      body: FutureBuilder(
        future: _visionFunction,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (receipt.pr == null) {
              return Text("Failed to parse receipt. Try again.");
            } else {
              return Text(receipt.pr.getDateAsString());
            }
          } else {
            return SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(),
            );
          }
        }
      )
    );
  }
}