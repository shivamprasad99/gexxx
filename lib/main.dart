import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PickedFile pickedImage;

  bool isImageLoaded = false;
  Size _imageSize;

  Future pickImage() async {
    var tempStore = await ImagePicker().getImage(source: ImageSource.gallery);

    if (tempStore != null) {
      await _getImageSize(File(tempStore.path));
    }

    setState(() {
      pickedImage = tempStore;
      isImageLoaded = true;
      _elements.clear();
    });
  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    // Fetching image from path
    final Image image = Image.file(imageFile);

    // Retrieving its size
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  List<TextElement> _elements = [];

  void _initializeVision() async {
    FirebaseVisionImage ourImage =
        FirebaseVisionImage.fromFilePath(pickedImage.path);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);

    FlutterTts flutterTts = FlutterTts();

    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        // Retrieve the elements and store them in a list
        for (TextElement element in line.elements) {
          _elements.add(element);
          await flutterTts.speak(element.text);
        }
      }
    }
  }

  Future readText() async {
    FirebaseVisionImage ourImage =
        FirebaseVisionImage.fromFilePath(pickedImage.path);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);
    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          print(word.text);
        }
      }
    }
  }

  Future speakText() async {
    FirebaseVisionImage ourImage =
        FirebaseVisionImage.fromFilePath(pickedImage.path);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);
    FlutterTts flutterTts = FlutterTts();
    await flutterTts.speak(readText.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        SizedBox(height: 50.0),
        isImageLoaded
            ? Center(
                child: Container(
                color: Colors.black,
                child: CustomPaint(
                  foregroundPainter: TextDetectorPainter(_imageSize, _elements),
                  child: AspectRatio(
                    aspectRatio: _imageSize.aspectRatio,
                    child: Image.file(
                      File(pickedImage.path),
                    ),
                  ),
                ),
              ))
            : Container(),
        SizedBox(height: 10.0),
        Positioned(
            bottom: 0,
            child: Container(
              color: Colors.black54,
              width: MediaQuery.of(context).size.width,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RaisedButton(
                          color: Colors.lightGreen,
                          child: Row(children: [
                            Icon(
                              Icons.folder_open,
                              color: Colors.white,
                            ),
                            Text(
                              'Pick an image',
                              style: TextStyle(color: Colors.white),
                            )
                          ]),
                          onPressed: pickImage,
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    RaisedButton(
                      child: Text('Speak'),
                      onPressed: _initializeVision,
                    ),
                  ]),
            ))
      ],
    ));
  }
}

class TextDetectorPainter extends CustomPainter {
  TextDetectorPainter(this.absoluteImageSize, this.elements);

  final Size absoluteImageSize;
  final List<TextElement> elements;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    Rect scaleRect(TextContainer container) {
      return Rect.fromLTRB(
        container.boundingBox.left * scaleX,
        container.boundingBox.top * scaleY,
        container.boundingBox.right * scaleX,
        container.boundingBox.bottom * scaleY,
      );
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red
      ..strokeWidth = 2.0;

    for (TextElement element in elements) {
      canvas.drawRect(scaleRect(element), paint);
    }
  }

  @override
  bool shouldRepaint(TextDetectorPainter oldDelegate) {
    return true;
  }
}
