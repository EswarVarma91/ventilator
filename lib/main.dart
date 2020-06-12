import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/activity/SplashPage.dart';
import 'package:ventilator/viewlog/ViewLogPatientList.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIOverlays([]);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
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
        primaryColor:  Color(0xFF171e27),
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
