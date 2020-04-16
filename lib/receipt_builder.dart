import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:io';

class ReceiptBuilderFrame extends StatelessWidget {
  final List<String> _imgPaths;
  final Function _clickMore;
  final Function _clickDone;

  ReceiptBuilderFrame(this._imgPaths, this._clickMore, this._clickDone);

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      body: Column(
        children: <Widget>[
          ReceiptRecentImage(_imgPaths[_imgPaths.length-1]),
          ReceiptBuilderImageList(this._imgPaths),
          ReceiptBuilderButtons(this._clickMore, this._clickDone),
        ]
      ),
    );
  }
}

class ReceiptBuilderImageSmall extends StatelessWidget {
  final String _imgPath;
  final int _numImages;

  ReceiptBuilderImageSmall(this._imgPath, this._numImages);

  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: min(MediaQuery.of(context).size.width / _numImages, 90),
      child: AspectRatio(
        aspectRatio: 0.5625,
        child: Image.file(File(_imgPath)),
      )
    );
  }
}

class ReceiptBuilderImageList extends StatelessWidget {
  final List<String> _imgPaths;

  ReceiptBuilderImageList(this._imgPaths);

  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      padding: EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _imgPaths.map( (String path) {
            return ReceiptBuilderImageSmall(path, _imgPaths.length);
          }).toList(),
        )
      )
    );
  }
}

class ReceiptRecentImage extends StatelessWidget {
  final String _imgPath;

  ReceiptRecentImage(this._imgPath);

  Widget build(BuildContext context) {
    return Expanded(
      child: Image.file(File(_imgPath))
    );
  }
}

class ReceiptBuilderButtons extends StatelessWidget {
  final Function _clickMore;
  final Function _clickDone;

  ReceiptBuilderButtons(this._clickMore, this._clickDone);

  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white30,
      ),
      margin: EdgeInsets.all(32.0),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ReceiptBuilderButton("Add More", _clickMore),
            ReceiptBuilderButton("Done", _clickDone),
          ]
        )
      )
    );
  }
}

class ReceiptBuilderButton extends StatelessWidget {
  final String _displayText;
  final Function _callback;

  ReceiptBuilderButton(this._displayText, this._callback);

  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      child: FlatButton(
        padding: EdgeInsets.all(8),
        onPressed: () => _callback(context),
        child: Text(_displayText, style: TextStyle(color: Colors.white)),
        color: Colors.white30,
      )
    );

  }
}

/*
return Center(
      child: Container(
          child: Row(
              children: <Widget>[
                FlatButton(
                    child: Text("Add More"),
                    onPressed: () => clickMore(context)
                ),
                FlatButton(
                    child: Text("Done"),
                    onPressed: () => clickDone(context)
                )
              ]
          )
      )


class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.file(File(imagePath));
  }
}
 */