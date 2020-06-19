import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Dashboard.dart';
import 'DowngradeAppScreen.dart';

class About extends StatefulWidget {
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {
  static const shutdownChannel = const MethodChannel("shutdown");
  PermissionStatus _status;

  @override
  void initState() {
    super.initState();
    PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage)
        .then(_updateStatus);
  }

  void _updateStatus(PermissionStatus value) {
    setState(() {
      _status = value;
    });
  }

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
      resizeToAvoidBottomPadding: false,
      // appBar: AppBar(
      //   title: Text("About"),
      //   actions: <Widget>[
      //     PopupMenuButton<String>(
      //       onSelected: handleClick,
      //       itemBuilder: (BuildContext context) {
      //         return {'Revert to old Version', }.map((String choice) {
      //           return PopupMenuItem<String>(
      //             value: choice,
      //             child: Text(choice),
      //           );
      //         }).toList();
      //       },
      //     ),
      //   ],
      // ),

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
                                    builder: (context) => Dashboard()),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 28.0),
                          child: Text(
                            "About",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DowngradeAppScreen()),
                                );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 28.0),
                            child: Text(
                              "Revert",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12.0,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.wrap_text,
                                  size: 25, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DowngradeAppScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Center(
                    child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 80,
                    ),
                    Container(
                      child: Text(
                        "SWASIT",
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 122,
                            fontFamily: "appleFont"),
                      ),
                    ),
                    Container(
                      child: Text(
                        "Designed & Developed By Zyna Medtech",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 18,
                    ),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white),
                      child: FlatButton(
                        child: Text(
                          "Check for Update",
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        ),
                        onPressed: () {
                          // print("a");
                          checkforUpdates();
                        },
                      ),
                    ),
                    SizedBox(
                      height: 18,
                    ),
                  ],
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
