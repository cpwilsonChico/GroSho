import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'classes.dart';
import 'dart:io';
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

  @override
  void initState() {
    super.initState();
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: path)
        ),
      );
    } catch (e) {
      print(e);
    }
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.file(File(imagePath));
  }
}