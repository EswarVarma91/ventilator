import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splashscreen/splashscreen.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/calibration/CalibrationPage.dart';
import 'package:ventilator/database/ADatabaseHelper.dart';
import 'package:ventilator/database/DatabaseHelper.dart';

class SplashPage extends StatefulWidget {
  SplashPage({Key key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  
  DatabaseHelper dbHelper;
  ADatabaseHelper dbHelper1;
  static const shutdownChannel = const MethodChannel("shutdown");
  UsbPort port;
  // int counter=0;

  @override
  void initState() {
    turnOnScreen();
    super.initState();
    
    dbHelper = DatabaseHelper();
    dbHelper1 = ADatabaseHelper();
    // counter = counter+1;

    getData();
    // saveData();
  }

  Future<void> turnOnScreen() async {
    try {
      Screen.setBrightness(1.0);
      Screen.keepOn(true);
      var result = await shutdownChannel.invokeMethod('turnOnScreen');

      // print(result);
    } on PlatformException catch (e) {
      // print(e);
    }
  }

  getData() async {
    // preferences = await SharedPreferences.getInstance();
    // counter = (preferences.getInt("noTimes")).toInt();
    // await sleep(Duration(seconds: 7));
    saveData();
  }

  saveData() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    
    SharedPreferences preferences = await SharedPreferences.getInstance();
    
      preferences.setString("mode", "        ");
      
    preferences.setString("checkMode", "0");
    preferences.setInt("rr", 0);
    preferences.setInt("ie", 0);
    preferences.setString("i", "0.0");
    preferences.setString("e", "0.0");
    preferences.setInt("peep", 0);
    // preferences.setInt("ps", 40);
    preferences.setInt("fio2", 0);
    preferences.setInt("tih", 0);
    preferences.setInt("paw", 0);
    preferences.setInt("itrig", 0);
    preferences.setInt("atime", 0);
    preferences.setInt("ti", 0);
    preferences.setBool("play", true);
    // preferences.setInt("tidal", 14);
    // preferences.setInt("mv", 500);
    preferences.setInt("rrtotal", 0);
    preferences.setInt("ps", 0);
    preferences.setInt("pc", 0);
    preferences.setInt("vt", 0);
    preferences.setInt("te", 0);
    preferences.setInt("vte", 0);
    preferences.setString("pid", "");
    preferences.setString("pname", "");
    preferences.setString("pgender", "");
    preferences.setString("page", "");
    preferences.setString("pweight", "");
    preferences.setString("pheight", "");
    preferences.setInt('minrr', 1);
    preferences.setInt('maxrr', 70);
    preferences.setInt('minvte', 0);
    preferences.setInt('maxvte', 2400);
    preferences.setInt('minppeak', 0);
    preferences.setInt('maxppeak', 100);
    preferences.setInt('minpeep', 0);
    preferences.setInt('maxpeep', 40);
    var dateS = preferences.getString('lastRecordTime');
    var res = dbHelper.delete7Daysdata(dateS);
    var res1 = dbHelper1.delete1Daysdata(dateS);
   

    // if(counter==null){
    //   counter = counter +1;
    // }else{
    // counter = counter +1;
    // }

    
    // print(res.toString()+"  "+res1.toString());
    //  preferences.setInt('noTimes', counter);
    // await sleep(Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Container(
          color: Color(0xFF171e27),
          child: Center(
            child: SplashScreen(
            seconds: 2,
            title: Text("SWASIT",
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 72,
                          fontFamily: "appleFont"),
                    ),
            loadingText: Text("Please wait",style: TextStyle(color: Colors.white),),
            navigateAfterSeconds: Dashboard(),
            backgroundColor:Color(0xFF171e27),
            loaderColor: Colors.white,
          ),),
        ),
    );
  }
}
