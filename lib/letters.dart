import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:animated_text_kit/animated_text_kit.dart';

class ReadByLetter extends StatefulWidget {
  @override
  _ReadByLetterState createState() => _ReadByLetterState();
}

class _ReadByLetterState extends State<ReadByLetter> {
  PickedFile pickedImage;

  bool isImageLoaded = false;
  Size _imageSize;
  int i = 0;
  Widget image_widget;

  Future pickImage() async {
    i = 0;
    _allelements.clear();
    _elements.clear();
    setState(() {
      image_widget = Container();
    });
    var tempStore = await ImagePicker().getImage(source: ImageSource.gallery);

    if (tempStore != null) {
      await _getImageSize(File(tempStore.path));
    }

    setState(() {
      pickedImage = tempStore;
      isImageLoaded = true;
    });
  }

  FlutterTts flutterTts = FlutterTts();

  _next() {
    String curr_word = _allelements[i].text;

    setState(() {
      _elements.clear();
      _elements.add(_allelements[i]);
    });

    // var imgUrl = await _get_image_from_word(curr_word);

    showDialog(
        context: context,
        child: new AlertDialog(
          content: TypewriterAnimatedTextKit(
            onFinished: (){
              Navigator.pop(context);
            },
            totalRepeatCount: 1,
            speed: Duration(milliseconds: 1000),
            text: [curr_word],
            textStyle: TextStyle(fontSize: 30.0),
          ),
        ));

    int sp = 0;
    bool stop = false;
    flutterTts.speak(curr_word[sp]);
    flutterTts.setCompletionHandler(() {
      if (sp < curr_word.length - 1) {
        sp++;
        flutterTts.speak(curr_word[sp]);
      } else {
        if (!stop) flutterTts.speak(curr_word);
        stop = true;
      }
    });

    if (i < _allelements.length - 1)
      i++;
    else
      i = 0;
  }

  _get_image_from_word(word) async {
    var url = 'http://198.168.43.1/get-gif/';
    final response = await http.post(url, body: json.encode({'text': word}));

    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON.
      var jsonData = json.decode(response.body);
      return jsonData;
    } else {
      return "";
    }
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
  List<TextElement> _allelements = [];

  Future<void> _initializeVision() async {
    FirebaseVisionImage ourImage =
        FirebaseVisionImage.fromFilePath(pickedImage.path);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);
    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        // Retrieve the elements and store them in a list
        for (TextElement element in line.elements) {
          setState(() {
            _allelements.add(element);
          });
        }
      }
    }
  }

  @override
  void initState() {
    image_widget = Container();
    super.initState();
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
                    image_widget,
                    RaisedButton(onPressed: _next, child: Text('Next')),
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
                        SizedBox(
                          width: 20,
                        ),
                        RaisedButton(
                          color: Colors.lightGreen,
                          child: Row(children: [
                            Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            Text(
                              'Detect',
                              style: TextStyle(color: Colors.white),
                            )
                          ]),
                          onPressed: _initializeVision,
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),
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
