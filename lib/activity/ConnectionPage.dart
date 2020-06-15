import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

// import 'HomePage.dart';
// import 'MonitorScreen.dart';

class ConnectionPage extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionPage> {
  UsbPort _port;
  List<int> listCheckPressurePoints = [];
  List<SalesData> pressurePoints = [];
  String _status = "Idle";
  List<Widget> _ports = [];
  List<String> _serialData = [];
  StreamSubscription<String> _subscription;
  Transaction<String> _transaction;
  int _deviceId;
  Timer _timer;
  List<int> list = [];
  List<int> mainData = [];
  List<int> displayData = [];
  Random random = new Random();

  int lencheck = 0;
  UsbDevice device1;
  TextEditingController _textController = TextEditingController();
 
  String peep, ie, ps;

  Future<bool> _connectTo(device) async {
    _serialData.clear();
    list.clear();
    mainData.clear();

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
      return true;
    }

    _port = await device.create();
    if (!await _port.open()) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }

    _deviceId = device.deviceId;
    await _port.setDTR(true);
    await _port.setRTS(true);
    await _port.setPortParameters(
        19200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    Transaction<Uint8List> transaction =
        Transaction.terminated(_port.inputStream, Uint8List.fromList([127]));

    transaction.stream.listen((event) async {
      if (event != null) {
        if (event[0] == 126 && event.length > 110) {
          list.addAll(event);
          list.removeAt(0);
        }
        setState(() {
          setState(() {
            // pressure graph
            double temp = (((list[34] << 8) + list[35]))
                .toDouble(); // pressure points 35,36

            if (temp > 40000) {
              setState(() {
                temp = -((65535 - temp) / 100);
              });
            } else {
              setState(() {
                temp = temp / 100;
              });
            }

            listCheckPressurePoints.add(temp.toInt());

            if (listCheckPressurePoints.length <= 50) {
              setState(() {
                pressurePoints.add(
                    SalesData(listCheckPressurePoints.length, temp.toInt()));
              });
            } else {
              listCheckPressurePoints.clear();
            }

            // if (pressurePoints.length >= 100)
            //   pressurePoints.removeRange(0, 50);

            list.clear();

            //==============
          });
        });
      }
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    // print(devices);
    _connectTo(devices[0]);
  }

 

  @override
  void initState() {
    super.initState();
    // _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
    //   _generateTrace();
    // });
    UsbSerial.usbEventStream.listen((UsbEvent event) {
      _getPorts();
    });
    _getPorts();
  }

  // _generateTrace() {
    // int tempData = random.nextInt(50);
    // print(tempData);
    // listCheckPressurePoints.add(tempData);
    // if (listCheckPressurePoints.length <= 100) {
    //   int i = 2020+listCheckPressurePoints.length;
    //   int index=0;
    //   setState(() {
    //     pressurePoints.insert(index,SalesData(i-1, tempData));
    //     // Fluttertoast.showToast(msg: pressurePoints.toString());
    //     index++; 
    //     // pressurePoints.add(SalesData(listCheckPressurePoints.length + 1, null));
    //   });
    // } else {
    //   setState(() {
    //     listCheckPressurePoints=[];
    //     pressurePoints=[];
    //   });
    // }
  // }

 

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
         height: 550,
        child: Center(
            child: Column(children: <Widget>[
          Text(
            "pressure points",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 20,
          ),
          
        ])),
      ),
    );
  }
}

class SalesData {
  final int year;
  final int sales;

  SalesData(this.year, this.sales);
}
