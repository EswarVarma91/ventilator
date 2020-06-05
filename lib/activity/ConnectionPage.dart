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
  List<SalesData> pressurePoints = [
    //  SalesData(0, 1500000),
    //  SalesData(1, 1735000),
    //  SalesData(2, 1678000),
    //  SalesData(3, 1890000),
    //  SalesData(4, 1907000),
    //  SalesData(5, 2300000),
    //  SalesData(6, 2360000),
    //  SalesData(7, 1980000),
    //  SalesData(8, 2654000),
    //  SalesData(9, 2789070),
    //  SalesData(10, 2654000),
    //  SalesData(11, 3245900),
    //  SalesData(12, 4098500),
    //  SalesData(13, 4500000),
    //  SalesData(14, 4456500),
    //  SalesData(15, 3900500),
    //  SalesData(16, 5123400),
    //  SalesData(17, 5589000),
    //  SalesData(18, 5940000),
    //  SalesData(19, 6367000),
    //  SalesData(20, 1500000),
    //  SalesData(21, 1735000),
    //  SalesData(22, 1678000),
    //  SalesData(23, 1890000),
    //  SalesData(24, 1907000),
    //  SalesData(25, 2300000),
    //  SalesData(26, 2360000),
    //  SalesData(27, 1980000),
    //  SalesData(28, 2654000),
    //  SalesData(29, 2789070),
    //  SalesData(30, 3020000),
    //  SalesData(31, 3245900),
    //  SalesData(32, 4098500),
    //  SalesData(33, 4500000),
    //  SalesData(34, 4456500),
    //  SalesData(35, 3900500),
    //  SalesData(36, 5123400),
    //  SalesData(37, 5589000),
    //  SalesData(38, 5940000),
    //  SalesData(39, 6367000),
    //  SalesData(40, 1500000),
    //  SalesData(41, 1735000),
    //  SalesData(42, 1678000),
    //  SalesData(43, 1890000),
    //  SalesData(44, 1907000),
    //  SalesData(45, 2300000),
    //  SalesData(46, 2360000),
    //  SalesData(47, 1980000),
    //  SalesData(48, 2654000),
    //  SalesData(49, 2789070),
    //  SalesData(50, 3020000),
    //  SalesData(51, 3245900),
    //  SalesData(52, 4098500),
    //  SalesData(53, 4500000),
    //  SalesData(54, 4456500),
    //  SalesData(55, 3900500),
    //  SalesData(56, 5123400),
    //  SalesData(57, 5589000),
    //  SalesData(58, 5940000),
    //  SalesData(59, 6367000),
    //  SalesData(60, 1500000),
    //  SalesData(61, 1735000),
    //  SalesData(62, 1678000),
    //  SalesData(63, 1890000),
    //  SalesData(64, 1907000),
    //  SalesData(65, 2300000),
    //  SalesData(66, 2360000),
    //  SalesData(67, 1980000),
    //  SalesData(68, 2654000),
    //  SalesData(69, 2789070),
    //  SalesData(70, 3020000),
    //  SalesData(71, 3245900),
    //  SalesData(72, 4098500),
    //  SalesData(73, 4500000),
    //  SalesData(74, 4456500),
    //  SalesData(75, 3900500),
    //  SalesData(76, 5123400),
    //  SalesData(77, 5589000),
    //  SalesData(78, 5940000),
    //  SalesData(79, 6367000),
    //  SalesData(80, 1500000),
    //  SalesData(81, 1735000),
    //  SalesData(82, 1678000),
    //  SalesData(83, 1890000),
    //  SalesData(84, 1907000),
    //  SalesData(85, 2300000),
    //  SalesData(86, 2360000),
    //  SalesData(87, 1980000),
    //  SalesData(88, 2654000),
    //  SalesData(89, 2789070),
    //  SalesData(90, 3020000),
    //  SalesData(91, 3245900),
    //  SalesData(92, 4098500),
    //  SalesData(93, 4500000),
    //  SalesData(94, 4456500),
    //  SalesData(95, 3900500),
    //  SalesData(96, 5123400),
    //  SalesData(97, 5589000),
    //  SalesData(98, 5940000),
    //  SalesData(99, 6367000),
    //  SalesData(100, 1500000),
    //  SalesData(101, 1735000),
    //  SalesData(102, 1678000),
    //  SalesData(103, 1890000),
    //  SalesData(104, 1907000),
    //  SalesData(105, 2300000),
    //  SalesData(106, 2360000),
    //  SalesData(107, 1980000),
    //  SalesData(108, 2654000),
    //  SalesData(109, 2789070),
    //  SalesData(110, 3020000),
    //  SalesData(111, 3245900),
    //  SalesData(112, 4098500),
    //  SalesData(113, 4500000),
    //  SalesData(114, 4456500),
    //  SalesData(115, 3900500),
    //  SalesData(116, 5123400),
    //  SalesData(117, 5589000),
    //  SalesData(118, 5940000),
    //  SalesData(119, 6367000),
    //  SalesData(120, 1500000),
    //  SalesData(121, 1735000),
    //  SalesData(122, 1678000),
    //  SalesData(123, 1890000),
    //  SalesData(124, 1907000),
    //  SalesData(125, 2300000),
    //  SalesData(126, 2360000),
    //  SalesData(127, 1980000),
    //  SalesData(128, 2654000),
    //  SalesData(129, 2789070),
    //  SalesData(130, 3020000),
    //  SalesData(131, 3245900),
    //  SalesData(132, 4098500),
    //  SalesData(133, 4500000),
    //  SalesData(134, 4456500),
    //  SalesData(135, 3900500),
    //  SalesData(136, 5123400),
    //  SalesData(137, 5589000),
    //  SalesData(138, 5940000),
    //  SalesData(139, 6367000),
    //  SalesData(140, 1500000),
    //  SalesData(141, 1735000),
    //  SalesData(142, 1678000),
    //  SalesData(143, 1890000),
    //  SalesData(144, 1907000),
    //  SalesData(145, 2300000),
    //  SalesData(146, 2360000),
    //  SalesData(147, 1980000),
    //  SalesData(148, 2654000),
    //  SalesData(149, 2789070),
    //  SalesData(150, 3020000),
    //  SalesData(151, 3245900),
    //  SalesData(152, 4098500),
    //  SalesData(153, 4500000),
    //  SalesData(154, 4456500),
    //  SalesData(155, 3900500),
    //  SalesData(156, 5123400),
    //  SalesData(157, 5589000),
    //  SalesData(158, 5940000),
    //  SalesData(159, 6367000),
    //  SalesData(160, 1500000),
    //  SalesData(161, 1735000),
    //  SalesData(162, 1678000),
    //  SalesData(163, 1890000),
    //  SalesData(164, 1907000),
    //  SalesData(165, 10300000),
    //  SalesData(166, 2360000),
    //  SalesData(167, 1980000),
    //  SalesData(168, 2654000),
    //  SalesData(169, 2789070),
    //  SalesData(170, 3020000),
    //  SalesData(171, 3245900),
    //  SalesData(172, 4098500),
    //  SalesData(173, 4500000),
    //  SalesData(174, 4456500),
    //  SalesData(175, 3900500),
    //  SalesData(176, 5123400),
    //  SalesData(177, 5589000),
    //  SalesData(178, 5940000),
    //  SalesData(179, 6367000),
    //  SalesData(180, 1500000),
    //  SalesData(181, 1735000),
    //  SalesData(182, 1678000),
    //  SalesData(183, 1890000),
    //  SalesData(184, 1907000),
    //  SalesData(185, 2300000),
    //  SalesData(186, 2360000),
    //  SalesData(187, 1980000),
    //  SalesData(188, 2654000),
    //  SalesData(189, 2789070),
    //  SalesData(190, 3020000),
    //  SalesData(191, 3245900),
    //  SalesData(192, 4098500),
    //  SalesData(193, 4500000),
    //  SalesData(194, 4456500),
    //  SalesData(195, 3900500),
    //  SalesData(196, 5123400),
    //  SalesData(197, 5589000),
    //  SalesData(198, 5940000),
    //  SalesData(199, 6367000),
    //  SalesData(200, 1500000),
  ];
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
    print(devices);
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
