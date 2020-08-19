import 'package:flutter/material.dart';
import 'package:gexxx/letters.dart';
import 'package:gexxx/words.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: Container(
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              RaisedButton(
                child: Text('Read By Word'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReadByWord()),
                  );
                },
              ),
              RaisedButton(
                child: Text('Read By Letter'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReadByLetter()),
                  );
                },
              )
            ]),
          ),
        ));
  }
}