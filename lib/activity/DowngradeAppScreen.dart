import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'About.dart';

class DowngradeAppScreen extends StatefulWidget {
  @override
  _DowngradeAppScreenState createState() => _DowngradeAppScreenState();
}

class _DowngradeAppScreenState extends State<DowngradeAppScreen> {
  static const shutdownChannel = const MethodChannel("shutdown");

 Future<void> checkforUpdates() async {
    var params = <String, dynamic>{
      "urlFlutter": "https://eagleaspect.com:9000/static/apks/v1.7.5.apk"
    };
    try {
      var result =
          await shutdownChannel.invokeMethod('checkforUpdates', params);
      // // print(result);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<bool> _willPopCallback() async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: WillPopScope(
        onWillPop: _willPopCallback,
        child: Container(
          color: Color(0xFF171e27),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12.0,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back,
                                size: 25, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => About()),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 28.0),
                          child: Text(
                            "Downgrade to version",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ],
                    ),  
                  ],
                ), 
              ],
            ),
          ),
        ),
      ),
    );
  }
}
