import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splashscreen/splashscreen.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/screens/SelfTestPage.dart';

class SplashPage extends StatefulWidget {
  SplashPage({Key key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  SharedPreferences preferences;
  DatabaseHelper dbHelper;
  static const shutdownChannel = const MethodChannel("shutdown");
  // int counter=0;

  @override
  void initState() {
    turnOnScreen();
    super.initState();
    dbHelper = DatabaseHelper();
    // counter = counter+1;
    var res = dbHelper.delete7Daysdata();
    // print(res);
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
    // preferences.setInt("tidal", 14);
    // preferences.setInt("mv", 500);
    preferences.setInt("rrtotal", 0);
    preferences.setInt("ps", 35);
    preferences.setInt("pc", 20);
    preferences.setInt("vt", 600);
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
