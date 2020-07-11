import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:ventilator/activity/Constants.dart';

import 'Dashboard.dart';
import 'DowngradeAppScreen.dart';

class About extends StatefulWidget {
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {
  static const shutdownChannel = const MethodChannel("shutdown");
  String downloadUrl = "";

  @override
  void initState() {
    super.initState();
    // getLatestUrl();
  }

  getLatestUrl() async {
    // make GET request
    String url =
        'http://www.zynamedtech.com/ventilator-apk-manager/getLatestAPK';
    Response response = await get(url);
    setState(() {
      setState(() {
        downloadUrl = response.body.toString();
        checkforUpdates(downloadUrl);
      });
    });
  }

  Future<void> checkforUpdates(String downlrl) async {
    var params = <String, dynamic>{"urlFlutter": downlrl};
    try {
      var result =
          await shutdownChannel.invokeMethod('checkforUpdates', params);
      print(result);
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
                                      builder: (context) =>
                                          DowngradeAppScreen()),
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
                      child: downloadUrl!=null ?  FlatButton(
                        child: Text(
                          "Check for Update",
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        ),
                        onPressed: () {
                          // Fluttertoast.showToast(msg: Constants.versionNew.toString() +"   "+ versionCheck(downloadUrl)).toString();
                          if (Constants.versionNew == versionCheck(downloadUrl)) {
                            Fluttertoast.showToast(msg:"no updates found.!");
                          }else{
                            getLatestUrl();
                            
                          }
                        },
                      ):Container(),
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

   versionCheck(String downloadUrl) {
    //  Fluttertoast.showToast(msg: downloadUrl.split("/v")[1].toString().split(".apk")[0].toString());
    return downloadUrl.split("/v")[1].toString().split(".apk")[0].toString();
  }
}
