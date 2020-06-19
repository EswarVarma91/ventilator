import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:fluttertoast/fluttertoast.dart';
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
  Timer _timer, _timer1, _timer2;
  List<int> list = [];
  bool stateSetted = false;
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
      blender = 0,
      checkOfffset = 0;

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
        if (mounted) {
          setState(() {
            obj.add(counter);
            obj.add(1);
            obj.add(0x7F);
          });
        }
        // Fluttertoast.showToast(msg: obj.toString());
        if (_status == "Connected") {
          await _port.write(Uint8List.fromList(obj));
        } else {}
      } else {
        if (mounted) {
          setState(() {
            counter = 0;
          });
        }
      }
    });

    // _timer2 = Timer.periodic(Duration(seconds: 17), (timer) {
    //    Navigator.pushAndRemoveUntil(
    //           context,
    //           MaterialPageRoute(
    //               builder: (BuildContext context) => CallibrationPage()),
    //           ModalRoute.withName('/'));
    //  });

    // _timer1 = Timer.periodic(Duration(seconds: 15), (timer) async {
    //   if(mounted){
    //     setState(() {
    //     if(stateSetted==false){
    //       stateSetted = true;
    //        o2pressuresensor = 2;
    //         mtpressuresensor = 2;
    //         exhalationflowsensor = 2;
    //         inhalationflowsensor = 2;

    //         exhalationpressure = 2;
    //         inhalationpressure = 2;
    //         o2sensor = 2;
    //         inhalationvalve = 2;

    //         exhalationvalve = 2;
    //         ventvalue = 2;
    //         mainpower = 2;
    //         battery = 2;

    //         communication = 2;
    //         compressor = 2;
    //         blender = 2;
    //         checkOfffset = 1;
    //         }
    //   });
    //   }

    //   await sleep(Duration(seconds: 0));
    // });
  }

  _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      setState(() {
        _status = "Disconnected";
      });
    }
    // print(devices);
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
      // Fluttertoast.showToast(msg: event.toString());
      // print(event.length.toString());
      if (event != null) {
        if (event[0] == 126) {
          list.addAll(event);
          list.removeAt(0);
        }

        // if (list[112] == 2) {
        //   Navigator.pushAndRemoveUntil(
        //       context,
        //       MaterialPageRoute(
        //           builder: (BuildContext context) => CallibrationPage()),
        //       ModalRoute.withName('/'));
        // }

        setState(() {
          // list[26]=(0x55);
          // list[27]=(0x55);
          // list[28]=(0x55);
          // list[29]=(0x55);
          o2pressuresensor = ((list[26] & 0x3) >> 0);
          mtpressuresensor = ((list[26] & 0xC) >> 2);
          exhalationflowsensor = ((list[26] & 0x30) >> 4);
          inhalationflowsensor = ((list[26] & 0xC0) >> 6);

          exhalationpressure = ((list[27] & 0x3) >> 0);
          inhalationpressure = ((list[27] & 0xC) >> 2);
          o2sensor = ((list[27] & 0x30) >> 4);
          inhalationvalve = ((list[27] & 0xC0) >> 6);

          exhalationvalve = ((list[28] & 0x3) >> 0);
          ventvalue = ((list[28] & 0xC) >> 2);
          mainpower = ((list[28] & 0x30) >> 4);
          battery = ((list[28] & 0xC0) >> 6);

          communication = ((list[29] & 0x3) >> 0);
          compressor = ((list[29] & 0xC) >> 2);
          blender = ((list[29] & 0x30) >> 4);
          checkOfffset = ((list[29] & 0xC0) >> 6);

          if(checkOfffset==2){
            _port.close();
            _status="Disconnected";
          }

          // Fluttertoast.showToast(msg: o2pressuresensor.toString() +" "+mtpressuresensor.toString());
        });

        // Fluttertoast.showToast(msg: ((list[2] << 8) + list[3]).toString());
        // print("packet : "+((list[2] << 8) + list[3]).toString());

        // if(((list[2] << 8) + list[3]).toString()=="12"){
        // setState(() {
        //   checkOfffset = (list[2] << 8) + list[3].toInt();
        //   o2pressuresensor = list[4].toInt();
        //   mtpressuresensor = list[5].toInt();
        //   exhalationflowsensor = list[6].toInt();

        //   inhalationflowsensor = list[7].toInt();
        //   exhalationpressure = list[8].toInt();
        //   inhalationpressure = list[9].toInt();

        //   o2sensor = list[10].toInt();
        //   inhalationvalve = list[11].toInt();
        //   exhalationvalve = list[12].toInt();

        //   ventvalue = list[13].toInt();
        //   mainpower = list[14].toInt();
        //   battery = list[15].toInt();

        //   communication = list[16].toInt();
        //   compressor = list[17].toInt();
        //   blender = list[18].toInt();
        // });
        // }else{

        // }
        list.clear();
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
                                value: o2pressuresensor == 0
                                    ? false
                                    : o2pressuresensor == 1
                                        ? false
                                        : o2pressuresensor == 2 ? true : false,
                                activeColor: o2pressuresensor == 1
                                    ? Colors.red
                                    : o2pressuresensor == 2
                                        ? Colors.blue
                                        : Colors.green,
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
                                value: mtpressuresensor == 0
                                    ? false
                                    : mtpressuresensor == 1
                                        ? false
                                        : mtpressuresensor == 2 ? true : false,
                                activeColor: mtpressuresensor == 1
                                    ? Colors.red
                                    : mtpressuresensor == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: inhalationvalve == 0
                                    ? false
                                    : inhalationvalve == 1
                                        ? false
                                        : inhalationvalve == 2 ? true : false,
                                activeColor: inhalationvalve == 1
                                    ? Colors.red
                                    : inhalationvalve == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: exhalationvalve == 0
                                    ? false
                                    : exhalationvalve == 1
                                        ? false
                                        : exhalationvalve == 2 ? true : false,
                                activeColor: exhalationvalve == 1
                                    ? Colors.red
                                    : exhalationvalve == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: exhalationflowsensor == 0
                                    ? false
                                    : exhalationflowsensor == 1
                                        ? false
                                        : exhalationflowsensor == 2
                                            ? true
                                            : false,
                                activeColor: exhalationflowsensor == 1
                                    ? Colors.red
                                    : exhalationflowsensor == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: inhalationflowsensor == 0
                                    ? false
                                    : inhalationflowsensor == 1
                                        ? false
                                        : inhalationflowsensor == 2
                                            ? true
                                            : false,
                                activeColor: inhalationflowsensor == 1
                                    ? Colors.red
                                    : inhalationflowsensor == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: exhalationpressure == 0
                                    ? false
                                    : exhalationpressure == 1
                                        ? false
                                        : exhalationpressure == 2
                                            ? true
                                            : false,
                                activeColor: exhalationpressure == 1
                                    ? Colors.red
                                    : exhalationpressure == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: inhalationpressure == 0
                                    ? false
                                    : inhalationpressure == 1
                                        ? false
                                        : inhalationpressure == 2
                                            ? true
                                            : false,
                                activeColor: inhalationpressure == 1
                                    ? Colors.red
                                    : inhalationpressure == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: o2sensor == 0
                                    ? false
                                    : o2sensor == 1
                                        ? false
                                        : o2sensor == 2 ? true : false,
                                activeColor: o2sensor == 1
                                    ? Colors.red
                                    : o2sensor == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                  "Vent Value        ",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: ventvalue == 0
                                    ? false
                                    : ventvalue == 1
                                        ? false
                                        : ventvalue == 2 ? true : false,
                                activeColor: ventvalue == 1
                                    ? Colors.red
                                    : ventvalue == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: communication == 0
                                    ? false
                                    : communication == 1
                                        ? false
                                        : communication == 2 ? true : false,
                                activeColor: communication == 1
                                    ? Colors.red
                                    : communication == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: mainpower == 0
                                    ? false
                                    : mainpower == 1
                                        ? false
                                        : mainpower == 2 ? true : false,
                                activeColor: mainpower == 1
                                    ? Colors.red
                                    : mainpower == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                          color: battery == 1 ? Colors.red : Colors.grey,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "Battery         ",
                                  style: TextStyle(
                                      color: battery == 0
                                          ? Colors.black
                                          : battery == 1
                                              ? Colors.white
                                              : Colors.black),
                                ),
                              ),
                              Checkbox(
                                value: battery == 0
                                    ? false
                                    : battery == 1
                                        ? false
                                        : battery == 2 ? true : false,
                                activeColor: battery == 1
                                    ? Colors.red
                                    : battery == 2 ? Colors.blue : Colors.black,
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
                                value: compressor == 0
                                    ? false
                                    : compressor == 1
                                        ? false
                                        : compressor == 2 ? true : false,
                                activeColor: compressor == 1
                                    ? Colors.red
                                    : compressor == 2
                                        ? Colors.blue
                                        : Colors.black,
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
                                value: blender == 0
                                    ? false
                                    : blender == 1
                                        ? false
                                        : blender == 2 ? true : false,
                                activeColor: blender == 1
                                    ? Colors.red
                                    : blender == 2 ? Colors.blue : Colors.black,
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
              SizedBox(
                height: 15,
              ),
              checkOfffset == 2
                  ? 
                  InkWell(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    CallibrationPage()),
                            ModalRoute.withName('/'));
                      },
                      child: Container(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                              child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text("Test Completed"),
                          )),
                        ),
                      ),
                    ):
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Self test in progress..",
                            style: TextStyle(fontSize: 30, color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                        ),
                        CircularProgressIndicator()
                      ],
                    )  
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
