import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splashscreen/splashscreen.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/activity/ConnectionPage.dart';
import 'package:ventilator/screens/CallibrationPage.dart';
import 'package:ventilator/screens/SelfTestPage.dart';

class SplashPage extends StatefulWidget {
  SplashPage({Key key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  SharedPreferences preferences;
  // int counter=0;

  @override
  void initState() {
    super.initState();
    // counter = counter+1;
    getData();
    // saveData();
  }


  getData() async{
    preferences = await SharedPreferences.getInstance();
    // counter = (preferences.getInt("noTimes")).toInt();
    // await sleep(Duration(seconds: 7));
    saveData();
  }

  saveData() async {
    preferences = await SharedPreferences.getInstance();

    // if(counter==null){
    //   counter = counter +1;
    // }else{
      // counter = counter +1;
    // }
    
    preferences.setString("mode", "PC-CMV");
    preferences.setInt("rr", 20);
    preferences.setInt("ie", 3);
    preferences.setString("i", "1.0");
    preferences.setString("e", "3.0");
    preferences.setInt("peep", 10);
    // preferences.setInt("ps", 40);
    preferences.setInt("fio2", 21);
    preferences.setInt("tih", 50);
    preferences.setInt("paw", 0);
    // preferences.setInt("tidal", 14);
    // preferences.setInt("mv", 500);
    preferences.setInt("rrtotal", 0);
    preferences.setInt("ps", 35);
    preferences.setInt("vt", 600);
    preferences.setInt("te", 20);
    preferences.setInt("vte", 0 );
     preferences.setString("pid", "" );
     preferences.setString("pname", "" );
     preferences.setString("pgender", "" );
     preferences.setString("page", "" );
     preferences.setString("pweight", "" );
     preferences.setString("pheight", "" );
    //  preferences.setInt('noTimes', counter);
    // await sleep(Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Center(
        child: SplashScreen(
          seconds: 2,
          navigateAfterSeconds: SelfTestPage(),
          backgroundColor: Colors.white,
          loaderColor: Colors.black,
        ),
      ),
    );
  }
}
