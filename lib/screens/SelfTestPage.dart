import 'dart:async';
import 'dart:typed_data';
import 'package:grouped_checkbox/grouped_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:ventilator/screens/CallibrationPage.dart';

class SelfTestPage extends StatefulWidget {
  SelfTestPage({Key key}) : super(key: key);

  @override
  _SelfTestPageState createState() => _SelfTestPageState();
}

class _SelfTestPageState extends State<SelfTestPage> {
  List<Widget> _ports = [];
  UsbPort _port;
  String _status = "Idle";
  StreamSubscription<String> _subscription;
  Transaction<String> _transaction;
  SharedPreferences preferences;
  int _deviceId;
  Timer _timer;
  List<int> list = [];
  int counter = 0;
  var o2pressuresensor = 0,
      mtpressuresensor = 0,
      exhalationflowsensor = 0,
      inhalationflowsensor = 0,
      exhalationpressure = 0,
      inhalationpressure = 0,
      o2sensor = 0,
      inhalationvalve = 0,
      exhalationvalve = 0,
      ventvalue = 0,
      mainpower = 0,
      battery = 0,
      communication = 0,
      compressor = 0,
      blender = 0,checkOfffset=0;


 

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
          obj.add(1);
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
      if (event != null) {
        if (event[0] == 126 && event.length > 19) {
          list.addAll(event);
          list.removeAt(0);
        }
        setState(() {
          checkOfffset = list[3].toInt();
          o2pressuresensor = list[4].toInt();
          mtpressuresensor = list[5].toInt();
          exhalationflowsensor = list[6].toInt();

          inhalationflowsensor = list[7].toInt();
          exhalationpressure = list[8].toInt();
          inhalationpressure = list[9].toInt();

          o2sensor = list[10].toInt();
          inhalationvalve = list[11].toInt();
          exhalationvalve = list[12].toInt();

          ventvalue = list[13].toInt();
          mainpower = list[14].toInt();
          battery = list[15].toInt();

          communication = list[16].toInt();
          compressor = list[17].toInt();
          blender = list[18].toInt();
        });
      }
    });
    setState(() {
      _status = "Connected";
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      body: Container(
        color: Color(0xFF171e27),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 40,
              ),
              Container(
                child: Text(
                  "SWASIT",
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 82,
                      fontFamily: "appleFont"),
                ),
              ),
              SizedBox(
                height: 40,
              ),
              // CircularProgressIndicator()   o2pressuresensor.toString()=="1" ? "Passed" : o2pressuresensor.toString()=="0"? "Failed" : ""
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "O\u2082 Pressure Sensor  ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: o2pressuresensor == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "MT Pressure Sensor",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: mtpressuresensor == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Inhalation Valve        ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: inhalationvalve == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Exhalation Valve      ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: exhalationvalve == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Exhalation Flow Sensor        ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: exhalationflowsensor == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Inhalation Flow Sensor         ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: inhalationflowsensor == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Exhalation Pressure Sensor",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: exhalationpressure == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Inhalation Pressure Sensor",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: inhalationpressure == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "O \u2082 Sensor          ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: o2sensor == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Vent Sensor       ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: ventvalue == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Communication",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: communication == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Main Power       ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: mainpower == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Battery         ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: battery == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Compressor",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: compressor == 0 ? false : true,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          color: Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Blender        ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: blender == 0 ? false : true,
                                activeColor: Colors.red,
                                onChanged: (bool value) {},
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              SizedBox(height: 15,),
              checkOfffset==0 ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Self test in progress..",style: TextStyle(fontSize: 30,color: Colors.white),),
                  ),
                  SizedBox(width: 40,),
                  CircularProgressIndicator()
                ],
              ): Container(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text("Test Completed"),
                )),
              ),)
            ],
          ),
        ),
      ),
    );
  }

  sendSelfTestData() async {
    List<int> objSelfTestData = [0x7E, 0, 20, 0, 12, 0, 1, 0x7F];
    if (_status == "Connected") {
      await _port.write(Uint8List.fromList(objSelfTestData));
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => CallibrationPage()));
  }
}
