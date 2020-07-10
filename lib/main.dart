import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:splashscreen/splashscreen.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/activity/SplashPage.dart';
import 'package:ventilator/viewlog/ViewLogPatientList.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIOverlays([]);
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // UsbDevice device;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ventilator',
      theme: ThemeData(
        primaryColor: Color(0xFF171e27),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SafeArea(child: StartScreen()),
      //     initialRoute: '/spalash',
      // routes: {
      //   '/spalash': (context) => SafeArea(child: SplashPage()),
      //   // When navigating to the "/" route, build the FirstScreen widget.
      //   '/': (context) => Dashboard(),
      //   // When navigating to the "/second" route, build the SecondScreen widget.
      //   '/patientList': (context) => ViewLogPatientList(),
      // },
    );
  }
}

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  static const shutdownChannel = const MethodChannel("shutdown");
  Timer _timer;

  @override
  void initState() {
    turnOnScreen();
    super.initState();
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
          navigateAfterSeconds: SplashPage(),
          backgroundColor:Color(0xFF171e27),
          loaderColor: Colors.white,
        ),),
      ),
    );
  }
}
