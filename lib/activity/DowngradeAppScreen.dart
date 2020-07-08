import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

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
        'http://www.zynamedtech.com/ventilator-apk-manager/getAllAPKS';
    Response response = await get(url);
    setState(() {
      data = jsonDecode(response.body);
    });
  }

  Future<void> checkforUpdates(String dataUrl) async {
    var params = <String, dynamic>{
      "urlFlutter": dataUrl
    };
    try {
      var result =
          await shutdownChannel.invokeMethod('checkforUpdates', params);
      print(result);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  // ignore: unused_element
  // Future<bool> _willPopCallback() async {
  //   return true;
  // }

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
                      onTap: () {
                        checkforUpdates(data[index].toString());
                      },
                      leading: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.file_download,
                          color: Colors.white,
                        ),
                      ),
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
    if (data == null) {
      return "";
    } else {
      List arr= data.toString().split("/");
      return (arr[arr.length-1]).toString().split(".apk")[0];
    }
  }
}
