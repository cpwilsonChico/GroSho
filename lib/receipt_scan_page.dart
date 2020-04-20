import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'classes.dart';
import 'storage.dart';
import 'receipt_builder.dart';
import 'receipt_parser.dart';
import 'receipt_finalizer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart';

/*class ReceiptScanPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "GroSho",
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: ImageView(),
    );
  }
}*/

class ReceiptScanPage extends StatefulWidget {
  final CameraDescription mainCam;

  ReceiptScanPage({Key key, @required this.mainCam}) : super(key: key);

  @override
  ImageState createState() => ImageState();
}

class ImageState extends State<ReceiptScanPage> {

  CameraController _camController;
  Future<void> _initCamController;
  List<String> imgPaths;

  @override
  void initState() {
    super.initState();
    imgPaths = new List<String>();
    _camController = CameraController(
      widget.mainCam,
      ResolutionPreset.high,
    );

    initController();
  }

  void initController() {
    _initCamController = _camController.initialize();
  }

  @override
  void dispose() {
    _camController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initCamController,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_camController);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        }
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () => takePhoto(context),

      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

    );
  }

  void takePhoto(BuildContext context) async {
    try {
      await _initCamController;
      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );
      await _camController.takePicture(path);
      imgPaths.add(path);
      popupConfirm(path, context);
      //doVision(path, context);
      /*
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: path)
        ),
      );*/

    } catch (e) {
      print(e);
    }
  }

  clickMore(BuildContext context) {
    Navigator.pop(context);
  }

  clickDone(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder:
    (context) => ReceiptFinalizer(imgPaths, clearData)));
  }

  clickCancel(BuildContext context) {
    imgPaths.clear();
    Navigator.pop(context);
  }

  clearData() {
    imgPaths.clear();
  }

  popupConfirm(String path, BuildContext context) {

    Navigator.push(context, MaterialPageRoute(builder:
        (context) => ReceiptBuilderFrame(imgPaths, clickMore, clickDone, clickCancel)
    ));
  }



    /*ReceiptParser rcp = new ReceiptParser(ocrData);
    PurchaseRecord pr = rcp.parse();

    if (pr != null) {
      Databaser.insertPurchase(pr);
    }
    imgPaths.clear();
  }*/
}

