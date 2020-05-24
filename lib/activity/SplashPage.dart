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
  int counter=0;

  @override
  void initState() {
    super.initState();
    saveData();
  }

  saveData() async {
    counter = counter+1;
    preferences = await SharedPreferences.getInstance();
    preferences.setString("mode", "PC-CMV");
    preferences.setInt("rr", 12);
    preferences.setInt("ie", 3);
    preferences.setInt("i", 1);
    preferences.setInt("e", 3);
    preferences.setInt("peep", 10);
    // preferences.setInt("ps", 40);
    preferences.setInt("fio2", 22);
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
     preferences.setString('noTimes', counter.toString());
    
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
