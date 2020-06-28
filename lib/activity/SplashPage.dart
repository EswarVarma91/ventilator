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
  SharedPreferences preferences;
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


  getData() async{
    // preferences = await SharedPreferences.getInstance();
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
    preferences.setString("checkMode", "0");
    preferences.setInt("rr", 20);
    preferences.setInt("ie", 3);
    preferences.setString("i", "1.0");
    preferences.setString("e", "3.0");
    preferences.setInt("peep", 10);
    // preferences.setInt("ps", 40);
    preferences.setInt("fio2", 21);
    preferences.setInt("tih", 50);
    preferences.setInt("paw", 0);
    preferences.setInt("itrig", 3);
    preferences.setInt("atime", 10);
    preferences.setInt("ti", 1);
    // preferences.setInt("tidal", 14);
    // preferences.setInt("mv", 500);
    preferences.setInt("rrtotal", 0);
    preferences.setInt("ps", 25);
    preferences.setInt("pc", 25);
    preferences.setInt("vt", 400);
    preferences.setInt("te", 20);
    preferences.setInt("vte", 0 );
     preferences.setString("pid", "" );
     preferences.setString("pname", "" );
     preferences.setString("pgender", "" );
     preferences.setString("page", "" );
     preferences.setString("pweight", "" );
     preferences.setString("pheight", "" );
     preferences.setInt('minrr',1);
     preferences.setInt('maxrr',70);
     preferences.setInt('minvte',0);
     preferences.setInt('maxvte',2400);
     preferences.setInt('minppeak',0);
     preferences.setInt('maxppeak',100);
     preferences.setInt('minpeep',0);
     preferences.setInt('maxpeep',40);
    // var dateS = preferences.getString('lastRecordTime');
    //  var res = dbHelper.delete7Daysdata(dateS);
    // var res1 = dbHelper1.delete1Daysdata(dateS);
    // print(res.toString()+"  "+res1.toString());
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
          navigateAfterSeconds: Dashboard(),
          backgroundColor: Colors.white,
          loaderColor: Colors.black,
        ),
      ),
    );
  }
}
