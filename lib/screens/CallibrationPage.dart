import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:ventilator/activity/Dashboard.dart';

class CallibrationPage extends StatefulWidget {
  CallibrationPage({Key key}) : super(key: key);

  @override
  _CallibrationPageState createState() => _CallibrationPageState();
}

class _CallibrationPageState extends State<CallibrationPage> {
  List<Widget> _ports = [];
  UsbPort _port;
  String _status = "Idle";
  StreamSubscription<String> _subscription;
  Transaction<String> _transaction;
  SharedPreferences preferences;
  int _deviceId;
  Timer _timer;
  int counter = 0;

  @override
  void initState() {
    super.initState();
    Screen.setBrightness(1.0);
    Screen.keepOn(true);
    UsbSerial.usbEventStream.listen((UsbEvent event) {
      _getPorts();
    });
    _getPorts();
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) async {
      counter = counter + 1;
      List<int> obj = [0x7E, 0, 20, 0, 11, 0];
      if (counter <= 250) {
        setState(() {
          obj.add(counter);
          obj.add(2);
          obj.add(0x7F);
        });
        // Fluttertoast.showToast(msg: obj.toString());
        if (_status == "Connected") {
          await _port.write(Uint8List.fromList(obj));
        } else {}
      } else {
        setState(() {
          counter = 0;
        });
      }
    });
  }

  _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      setState(() {
        _status = "Disconnected";
      });
      // Fluttertoast.showToast(msg: _status);
    }
    print(devices);
    _connectTo(devices[0]);
  }

  Future<bool> _connectTo(device) async {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port.close();
      _port = null;
    }

    if (device == null) {
      _deviceId = null;
      setState(() {
        _status = "Disconnected";
      });
    }

    _port = await device.create();
    if (!await _port.open()) {
      setState(() {
        _status = "Failed to open port";
      });
    }

    _deviceId = device.deviceId;
    await _port.setDTR(false);
    await _port.setRTS(false);
    await _port.setPortParameters(
        57600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    Transaction<Uint8List> transaction =
        Transaction.terminated(_port.inputStream, Uint8List.fromList([127]));

    transaction.stream.listen((event) async {
      if (event != null) {}
    });
    setState(() {
      _status = "Connected";
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Container(
      child: Center(
        child: Column(
          children: [
            Container(
              child: Image.asset(
                'assets/images/logo.png',
                width: 412,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: InkWell(
                    onTap: () {
                      sendFullTest();
                    },
                    child: Container(
                      width: 220,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            Text(
                              "Continue \n with".toUpperCase(),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              "Full Test".toUpperCase(),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: InkWell(
                    onTap: () {
                      sendCalibrationText();
                    },
                    child: Container(
                      width: 220,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            Text(
                              "Continue \n with".toUpperCase(),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              "Calibration".toUpperCase(),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Dashboard()),
                      );
                    },
                    child: Container(
                      width: 220,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            Text(
                              "Continue \n with".toUpperCase(),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              "Treatment".toUpperCase(),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  sendFullTest() async {
    List<int> objSelfTestData = [0x7E, 0, 20, 0, 13, 0, 1, 0x7F];
    if (_status == "Connected") {
      await _port.write(Uint8List.fromList(objSelfTestData));
    }
  }

  sendCalibrationText() async {
    List<int> objSelfTestData = [0x7E, 0, 20, 0, 14, 0, 1, 0x7F];
    if (_status == "Connected") {
      await _port.write(Uint8List.fromList(objSelfTestData));
    }
  }
}
