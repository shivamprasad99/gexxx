import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
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

  File pickedImage;

  bool isImageLoaded = false;

  Future pickImage() async {
    var tempStore = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      pickedImage = tempStore;
      isImageLoaded = true;
    });
  }

  Future readText() async {
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage); 
    for (TextBlock block in readText.blocks){
      for (TextLine line in block.lines){
        for (TextElement word in line.elements){
          print(word.text);
        }
      }
    }
  }

  Future speakText() async {
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage); 
    FlutterTts flutterTts = FlutterTts();
    await flutterTts.speak(readText.text);
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(height: 100.0),
          isImageLoaded ? Center(
            child: Container(
              height: 200.0,
              width: 200.0,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(pickedImage), fit: BoxFit.cover
                )
              )
            )
          ) : Container(),
          SizedBox(height: 10.0),
          RaisedButton(
            child: Text('Pick an image'),
            onPressed: pickImage,
          ),
          SizedBox(height: 10.0),
          RaisedButton(
            child: Text('Read Text'),
            onPressed: readText,
          ),
          SizedBox(height: 10.0),
          RaisedButton(
            child: Text('Speak'),
            onPressed: speakText,
          ),
        ],
      )
    );
  }
}