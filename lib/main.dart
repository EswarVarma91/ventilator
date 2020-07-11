import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
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
      home: SafeArea(child: SplashPage()),
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
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              child: Text(
                "SWASIT",
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 142,
                    fontFamily: "appleFont"),
              ),
            ),
            SizedBox(height: 70),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SplashPage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.orange.withOpacity(0.8)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 18.0, bottom: 18.0, left: 40.0, right: 40.0),
                  child: Text("Start Ventilator",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24)),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
