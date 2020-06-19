import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'About.dart';

class DowngradeAppScreen extends StatefulWidget {
  @override
  _DowngradeAppScreenState createState() => _DowngradeAppScreenState();
}

class _DowngradeAppScreenState extends State<DowngradeAppScreen> {
  static const shutdownChannel = const MethodChannel("shutdown");
  List<dynamic> data;

  @override
  void initState() {
    super.initState();
    getLatestUrl();
  }

  getLatestUrl() async {
    // make GET request
    String url =
        'https://www.eagleaspect.com:9000/ventilator-apk-manager/getAllAPKS';
    Response response = await get(url);
    setState(() {
      data = jsonDecode(response.body);
      // print(data.length);
      // Fluttertoast.showToast(msg: downloadUrl);
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
        appBar: AppBar(
          title: Text("Downgrade Version"),
        ),
        body: Container(
          color: Color(0xFF171e27),
          child: data != null
              ? ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    return ListTile(
                      leading: Icon(Icons.file_download,color: Colors.white,),
                      title: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Container(
                              child: Text(
                            _checkData(data[index]),
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.start,
                          )),
                        ),
                    );
                  })
              : Container(),
        ));
  }

  String _checkData(data) {
    if(data==null){
      return "";
    }else{
      return data.toString().split(".apk")[0].toString();
    }
  }
}
