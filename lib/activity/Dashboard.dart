import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cupertino_range_slider/cupertino_range_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:ventilator/bottombar/CommonDialog.dart';
import 'package:ventilator/calibration/CalibrationPage.dart';
import 'package:ventilator/database/ADatabaseHelper.dart';
import 'package:ventilator/database/CounterDatabaseHelper.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';
import 'package:ventilator/graphs/Oscilloscope.dart';
import 'package:ventilator/screens/CallibrationPage.dart';
import 'package:ventilator/screens/SelfTestPage.dart';
import 'package:ventilator/viewlog/ViewLogDataDisplayPage.dart';
import 'package:ventilator/viewlog/ViewLogPatientList.dart';
import 'NewTreatmentScreen.dart';

class Dashboard extends StatefulWidget {
  UsbDevice device;

  @override
  _CheckPageState createState() => _CheckPageState();
}

class _CheckPageState extends State<Dashboard> {
  static const shutdownChannel = const MethodChannel("shutdown");
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Uint16List ulCrc16Table = Uint16List.fromList([
    0x0000,
    0xCC01,
    0xD801,
    0x1400,
    0xF001,
    0x3C00,
    0x2800,
    0xE401,
    0xA001,
    0x6C00,
    0x7800,
    0xB401,
    0x5000,
    0x9C01,
    0x8801,
    0x4400
  ]);
  List<double> traceSine1 = [
    5.0,
    5.0,
    5.0,
    5.0,
    5.0,
    10.0,
    15.0,
    20.0,
    60.0,
    60.0,
    60.0,
    60.0,
    60.0,
    60.0,
    18.0,
    15.0,
    12.0,
    10.0,
    -60.0,
    -60.0,
    -60.0,
    -60.0,
    -60.0,
    -60.0,
    -60.0,
    -60.0,
    -60.0,
    -60.0,
    -60.0,
    10.0,
    15.0,
    20.0,
    60.0,
    60.0,
    60.0,
    60.0,
    60.0,
    25.0,
    18.0,
    15.0,
    12.0,
    10.0,
    5.0,
    5.0,
    5.0,
    5.0,
    5.0,
    5.0,
    5.0,
    5.0,
    5.0,
  ];

  List<double> pressurePoints = [];
  List<double> flowPoints = [];
  List<double> volumePoints = [];
  Oscilloscope scopeOne, scopeOne1, scopeOne2;

  UsbPort _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  StreamSubscription<String> _subscription;
  Transaction<String> _transaction;
  SharedPreferences preferences;
  int _deviceId;
  double batteryPercentageValue = 0.0;
  double _progress = 50;
  Timer _timer, _timer1, _timer2, _timer3;
  List<int> list = [];

  double radians = 0, radians1 = 0;
  int paw, mvValue = 0, rrtotalValue = 0, lastmvValue = 0;
  int progressValuePressure = 6;
  int lencheck = 0;
  TextEditingController _textController = TextEditingController();
  int inspiratoryPressureR,
      expiratoryPressureR,
      fio2R,
      mixingTankPressureR,
      o2ipPressureR,
      turbineSpeedR,
      operatinModeR,
      alarmCodeR,
      alarmActivePriorityR,
      airipPressureR,
      inspirationflowR = 0,
      exhalationflowR,
      o2Valve,
      airiPValveStatusR,
      _2by2inhalationValueR,
      _2by2exhalationValueR,
      internalTemperatureR;
  int rrValue,
      peepValue,
      pcValue,
      psValue,
      vtValue,
      psValue1 = 0,
      peepDisplayValue = 0,
      fio2Value,
      ibytValue,
      vteValue,
      leakMeanValue,
      vtiMeanValue,
      vteMeanValue,
      pawMeanValue,
      rateMeanValue;
  int ieValue;
  double peepHeight = 280, psHeight = 280;
  String modeName, dateandTime;
  double tiValue = 0, teValue = 0;

  double mode1rrval = 12,
      mode1ieval = 2,
      mode1peepval = 10,
      mode1psval = 35,
      mode1fio2val = 21,
      mode1tival = 50;

  bool modeEnable = false,
      audioEnable = true,
      usbConnected = false,
      modesEnabled = false,
      alarmEnabled = false,
      newTreatEnabled = false,
      monitorEnabled = false,
      pccmvEnabled = true,
      vccmvEnabled = false,
      pacvEnabled = false,
      vacvEnabled = false,
      psimvEnabled = false,
      vsimvEnabled = false,
      psvEnabled = false,
      prvcEnabled = false,
      bipapEnabled = false,
      alarmsSetting1 = true,
      editbbEnabled = false,
      alarmsSetting2 = false;

  bool pacvItrig = true,
      pacvRr = false,
      pacvIe = false,
      pacvPeep = false,
      pacvPc = false,
      pacvVtMin = false,
      pacvVtMax = false,
      pacvFio2 = false,
      pacvFlowRamp = false;

  int pacvItrigValue = 3,
      pacvRrValue = 20,
      pacvIeValue = 51,
      pacvPeepValue = 10,
      pacvPcValue = 30,
      pacvVtMinValue = 100,
      pacvVtMaxValue = 1200,
      pacvFio2Value = 21,
      pacvFlowRampValue = 3;

  int pacvmaxValue = 10, pacvminValue = 1, pacvdefaultValue = 6;
  String pacvparameterName = "I Trig",
      pacvparameterUnits = "cmH\u2082O Below Peep";

  bool vacvItrig = true,
      vacvRr = false,
      vacvIe = false,
      vacvPeep = false,
      vacvVt = false,
      vacvPcMin = false,
      vacvPcMax = false,
      vacvFio2 = false,
      vacvFlowRamp = false;

  int vacvItrigValue = 3,
      vacvRrValue = 20,
      vacvIeValue = 51,
      vacvPeepValue = 10,
      vacvVtValue = 400,
      vacvPcMinValue = 20,
      vacvPcMaxValue = 60,
      vacvFio2Value = 21,
      vacvFlowRampValue = 4;

  int vacvmaxValue = 10, vacvminValue = 1, vacvdefaultValue = 6;
  String vacvparameterName = "I Trig",
      vacvparameterUnits = "cmH\u2082O Below Peep";

  bool psvItrig = true,
      psvPeep = false,
      psvIe = false,
      psvPs = false,
      psvTi = false,
      psvVtMin = false,
      psvVtMax = false,
      psvFio2 = false,
      psvAtime = false,
      psvEtrig = false,
      psvBackupRr = false,
      psvMinTe = false,
      psvFlowRamp = false;

  int psvItrigValue = 3,
      psvPeepValue = 10,
      psvIeValue = 51,
      psvPsValue = 30,
      psvTiValue = 5,
      psvVtMinValue = 100,
      psvVtMaxValue = 1200,
      psvFio2Value = 21,
      psvAtimeValue = 10,
      psvEtrigValue = 10,
      psvBackupRrValue = 20,
      psvMinTeValue = 1,
      psvFlowRampValue = 4;

  int psvmaxValue = 10, psvminValue = 1, psvdefaultValue = 6;
  String psvparameterName = "I Trig",
      psvparameterUnits = "cmH\u2082O  Below Peep";

  bool psimvItrig = true,
      psimvRr = false,
      psimvIe = false,
      psimvPeep = false,
      psimvPc = false,
      psimvPs = false,
      psimvVtMin = false,
      psimvVtMax = false,
      psimvFio2 = false,
      psimvFlowRamp = false;

  int psimvItrigValue = 3,
      psimvRrValue = 20,
      psimvPsValue = 30,
      psimvIeValue = 51,
      psimvPeepValue = 10,
      psimvPcValue = 30,
      psimvVtMinValue = 100,
      psimvVtMaxValue = 1200,
      psimvFio2Value = 21,
      psimvFlowRampValue = 3;

  int psimvmaxValue = 10, psimvminValue = 1, psimvdefaultValue = 6;
  String psimvparameterName = "I Trig",
      psimvparameterUnits = "cmH\u2082O  Below Peep";

  bool vsimvItrig = true,
      vsimvRr = false,
      vsimvIe = false,
      vsimvPeep = false,
      vsimvVt = false,
      vsimvPs = false,
      vsimvPcMin = false,
      vsimvPcMax = false,
      vsimvFio2 = false,
      vsimvFlowRamp = false;

  int vsimvItrigValue = 3,
      vsimvRrValue = 20,
      vsimvIeValue = 51,
      vsimvPeepValue = 10,
      vsimvVtValue = 400,
      vsimvPsValue = 22,
      vsimvPcMinValue = 20,
      vsimvPcMaxValue = 60,
      vsimvFio2Value = 21,
      vsimvFlowRampValue = 4;

  int vsimvmaxValue = 10, vsimvminValue = 1, vsimvdefaultValue = 6;
  String vsimvparameterName = "I Trig",
      vsimvparameterUnits = "cmH\u2082O Below Peep";

  bool prvcApnea = true;
  int prvcApneaValue = 30;
  int prvcmaxValue = 60, prvcminValue = 1, prvcdefaultValue = 30;
  String prvcparameterName = "Apnea", prvcparameterUnits = "s";

  bool pccmvRR = true, pccmvRRChanged = false;
  bool pccmvIe = false, pccmvIeChanged = false;
  bool pccmvPeep = false, pccmvPeepChanged = false;
  bool pccmvPc = false, pccmvPcChanged = false;
  bool pccmvFio2 = false, pccmvFio2Changed = false;
  bool pccmvVtmin = false, pccmvVtminChanged = false;
  bool pccmvVtmax = false, pccmvVtmaxChanged = false;
  bool pccmvFlowRamp = false, pccmvFlowRampChanged = false;
  bool pccmvTih = false, pccmvValueChanged = false;

  int pccmvRRValue = 20,
      pccmvIeValue = 51,
      pccmvPeepValue = 10,
      pccmvPcValue = 30,
      pccmvFio2Value = 21,
      pccmvVtminValue = 100,
      pccmvVtmaxValue = 1200,
      pccmvTihValue = 50,
      pccmvRRValueTemp = 20,
      pccmvIeValueTemp = 51,
      pccmvPeepValueTemp = 10,
      pccmvPcValueTemp = 30,
      pccmvFio2ValueTemp = 21,
      pccmvVtminValueTemp = 100,
      pccmvVtmaxValueTemp = 400,
      pccmvTihValueTemp = 50;
  int pccmvFlowRampValue = 4;

  int pccmvmaxValue = 60, pccmvminValue = 1, pccmvdefaultValue = 12;
  String pccmvparameterName = "RR", pccmvparameterUnits = "bpm";

  bool vccmvRR = true;
  bool vccmvIe = false;
  bool vccmvPeep = false;
  bool vccmvPcMin = false;
  bool vccmvPcMax = false;
  bool vccmvFio2 = false;
  bool vccmvVt = false;
  bool vccmvFlowRamp = false;
  bool vccmvTih = false;

  int vccmvRRValue = 20,
      vccmvIeValue = 51,
      vccmvPeepValue = 10,
      vccmvPcMinValue = 20,
      vccmvPcMaxValue = 60,
      vccmvFio2Value = 21,
      vccmvVtValue = 400,
      vccmvTihValue = 50;
  int vccmvFlowRampValue = 4;

  int vccmvmaxValue = 60, vccmvminValue = 1, vccmvdefaultValue = 12;
  String vccmvparameterName = "RR", vccmvparameterUnits = "";

  List<int> listCheckLength = new List();

  String alarmMessage = "";
  List<int> modeWriteList = [];
  List<int> writePlay = [];
  int lungImage = 0;
  double pressurePointsYAxisMax = 100.0;
  int fio2DisplayParameter = 0,
      mapDisplayValue = 0,
      ieDisplayValue = 0,
      cdisplayParameter = 0,
      rrDisplayValue = 0;
  String ioreDisplayParamter = "I/E";
  bool playOnEnabled = false, powerOnEnabled = false;
  var dbHelper = DatabaseHelper();
  var dbHelpera = ADatabaseHelper();
  var dbCounter = CounterDatabaseHelper();
  String lastRecordTime;
  String priorityNo, alarmActive;
  double pplateauDisplay = 0;
  int tempDisplay = 0,
      respiratoryFlag = 0,
      leakVolumeDisplay = 0,
      peakFlowDisplay = 0,
      spontaneousDisplay = 0;

  int minRrtotal = 1,
      maxRrtotal = 70,
      minvte = 0,
      maxvte = 2400,
      minmve = 0,
      maxmve = 100,
      minppeak = 0,
      maxppeak = 100,
      minpeep = 0,
      maxpeep = 40,
      minfio2 = 21,
      maxfio2 = 100;

  int alarmmaxValue = 100, alarmminValue = 1;
  String alarmparameterName = "RR Total";

  bool alarmRR = false,
      alarmVte = false,
      alarmPpeak = false,
      alarmpeep = false,
      alarmFio2 = false;
  bool alarmRRchanged = false,
      alarmVtechanged = false,
      alarmPpeakchanged = false,
      alarmpeepchanged = false,
      alarmFio2changed = false,
      alarmConfirmed = true;

  String patientId,
      patientName,
      patientGender,
      patientAge,
      patientHeight,
      patientWeight;

  bool newTreatmentEnabled = false, powerButtonEnabled = true;
  bool isplaying = false,
      _buttonPressed = false,
      respiratoryEnable = false,
      insExpButtonEnable = false;
  int previousCode = 101,
      presentCode,
      vteMinValue = 0,
      alarmPrevCounter = 101,
      alarmCounter;
  int cc = 0;
  String checkTempData;
  int powerIndication = 0, batteryPercentage, batteryStatus = 0;
  String sendBattery;
  List<int> listTemp = [];

  Future<bool> _connectTo(device) async {
    list.clear();
    pressurePoints.clear();
    volumePoints.clear();
    flowPoints.clear();

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
      // // print(event);
      // Fluttertoast.showToast(msg: event.length.toString() + " "+cc.toString() + );
      serializeEventData(event);
    });
    setState(() {
      _status = "Connected";
    });
  }

  _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      // getData();
      setState(() {
        _status = "Disconnected";
        usbConnected = false;
      });
      // Fluttertoast.showToast(msg: _status);
    }
    // print(devices);
    _connectTo(devices[0]);
  }

  int counter = 0, counterlength = 0;
  var presentTime;
  bool playing = false;
  String i = "1", e = "3";
  int _start = 30;
  bool _loopActive = false;
  int timerCounter = 00;
  int displayTemperature = 0;
  int globalCounter = 0, globalCounterNo = 1;

  // getNoTimes() async {
  //   await sleep(Duration(seconds: 6));
  //   preferences =await SharedPreferences.getInstance();
  //   noTimes = preferences.getInt("noTimes");
  // }

  // counterData() async {
  //   var data = await dbCounter.getCounterNo();
  //   // print(data);
  //   if (data.isEmpty) {
  //     globalCounter = globalCounter + 1;
  //     dbCounter.saveCounter(CounterValue(globalCounter.toString()));
  //     setState(() {
  //       globalCounterNo = globalCounter;
  //     });
  //   } else if (data.isNotEmpty) {
  //     globalCounter = int.tryParse(data[0].counterValue.toString());
  //     globalCounter = globalCounter + 1;
  //     dbCounter.updateCounterNo(globalCounter.toString());
  //     setState(() {
  //       globalCounterNo = globalCounter;
  //     });
  //   }
  // }

  @override
  initState() {
    super.initState();
    var now = new DateTime.now();
    lastRecordTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(now).toString();
    // counterData();
    getData();
    // getNoTimes();
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
          obj.add(3);
          obj.add(0x7F);
        });
        // Fluttertoast.showToast(msg: obj.toString());
        if (_status == "Connected") {
          await _port.write(Uint8List.fromList(obj));
        }
      } else {
        setState(() {
          counter = 0;
        });
      }
    });

    _timer2 = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_status == "Connected") {
        // String lastTime = await dbHelper.getLastRecordTime();
        // String lastRecordTime =
        //     lastTime.split("[{datetimeP: ")[1].split("}]")[0];

        var now = new DateTime.now();
        setState(() {
          presentTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
          DateTime date1 =
              DateFormat("yyyy-MM-dd HH:mm:ss").parse(lastRecordTime);
          DateTime date2 = DateFormat("yyyy-MM-dd HH:mm:ss").parse(presentTime);
          var differnceD = date2.difference(date1);
          if (differnceD.inSeconds > 5) {
            setState(() {
              respiratoryEnable = false;
              insExpButtonEnable = false;
              // powerButtonEnabled = true;
              // psValue1 = 0;
              // cc = 0;
              // mvValue = 0;
              // vteValue = 0;
              // peepDisplayValue = 0;
              // rrtotalValue = 0;
              // mapDisplayValue = 0;
              // peepDisplayValue = 0;
              // fio2DisplayParameter = 0;
              // pressurePoints.clear();
              // volumePoints.clear();
              // flowPoints.clear();
              // playOnEnabled = false;
            });
            // if (playOnEnabled) {
            //   if (mounted) {
            //     setState(() {
            //       psValue1 = 0;
            //       mvValue = 0;
            //       vteValue = 0;
            //       fio2DisplayParameter = 0;
            //       pressurePoints = [];
            //       volumePoints = [];
            //       flowPoints = [];
            //     });
            //   }
            // }
            // Fluttertoast.showToast(msg: "Timeout.");
            // psValue1 = 0;
            // mvValue = 0;
            // vteValue = 0;
            // fio2DisplayParameter = 0;
            // pressurePoints = [];
            // volumePoints = [];
            // flowPoints = [];
          } else {
            setState(() {
              // powerButtonEnabled = false;
            });
          }
        });
      }
    });
    _timer3 = Timer.periodic(Duration(milliseconds: 150), (timer) {
      if (_status == "Connected") {
        shutdownChannel.invokeMethod('getBatteryLevel').then((result) async {
          List<int> resList = [];
          setState(() {
            resList.add(0x7E);
            resList.add(0);
            resList.add(20);
            resList.add(0);
            resList.add(15);
            resList.add((result & 0x00FF));
            resList.add(0x7F);
          });
          await _port.write(Uint8List.fromList(resList));
        });
      }
    });
// _timer2 = Timer.periodic(Duration(minutes: 12), (timer) async {
//       if (_status == "Connected") {

//         var now = new DateTime.now();
//         setState(() {
//           presentTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
//           DateTime date1 =
//               DateFormat("yyyy-MM-dd HH:mm:ss").parse(lastRecordTime);
//           DateTime date2 = DateFormat("yyyy-MM-dd HH:mm:ss").parse(presentTime);
//           var differnceD = date2.difference(date1);
//           if (differnceD.inSeconds > 1200) {
//             setState(() {
//               powerButtonEnabled = true;
//             });
//           } else {
//             setState(() {
//               powerButtonEnabled = false;
//             });
//           }
//         });
//       }
//     });
  }

  saveData(VentilatorOMode data, String patientId) async {
    // // print("data saving id : " + patientId);
    dbHelper.save(data);
  }

  Future<void> _sendShutdown() async {
    try {
      var result = await shutdownChannel.invokeMethod('sendShutdowndevice');
      // // print(result);
    } on PlatformException catch (e) {
      // print(e);
    }
  }

  Future<void> _playMusicHigh() async {
    setState(() {
      isplaying = true;
    });
    try {
      var result = await shutdownChannel.invokeMethod('sendPlayAudioStartH');
      // // print(result);
    } on PlatformException catch (e) {
      // print(e);
    }
  }

  Future<void> _playMusicMedium() async {
    setState(() {
      isplaying = true;
    });
    try {
      var result = await shutdownChannel.invokeMethod('sendPlayAudioStartM');
      // // print(result);
    } on PlatformException catch (e) {
      // print(e);
    }
  }

  Future<void> _playMusicLower() async {
    setState(() {
      isplaying = true;
    });
    try {
      var result = await shutdownChannel.invokeMethod('sendPlayAudioStartL');
      // print(result);
    } on PlatformException catch (e) {
      // print(e);
    }
  }

  Future<void> _stopMusic() async {
    setState(() {
      isplaying = true;
    });
    try {
      var result = await shutdownChannel.invokeMethod('sendPlayAudioStop');
      // print(result);
    } on PlatformException catch (e) {
      // print(e);
    }
  }

  Future<void> sendSoundOn() async {
    try {
      var result = await shutdownChannel.invokeMethod('sendsoundon');
      // print(result);
    } on PlatformException catch (e) {
      // print(e);
    }
  }

  Future<void> sendSoundOff() async {
    try {
      var result = await shutdownChannel.invokeMethod('sendsoundoff');
      // print(result);
    } on PlatformException catch (e) {
      // print(e);
    }
  }

  Future<void> turnOffScreen() async {
    try {
      var result = await shutdownChannel.invokeMethod('turnOffScreen');
      // print(result);
    } on PlatformException catch (e) {
      // print(e);
    }
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

  getCrcData(List<int> obj) async {
    // obj.clear();
    int length = obj.length;
    // int n = 0, iCRC = 0xFFFF, i = 0;

    // while (n < length) {
    //   iCRC = iCRC ^ obj[n];
    //   i = 0;
    //   while (i < 8) {
    //     if ((iCRC & 0X0001) != 0) {
    //       iCRC = iCRC >> 1;
    //       iCRC = iCRC ^ 40961;
    //     } else
    //       iCRC = iCRC >> 1;
    //     i++;
    //   }
    //   n++;
    // }

    // obj.insert(length, iCRC & 0xFF);
    // obj.insert(length + 1, (iCRC & 0xFF00) >> 8);

    // obj.insert(length + 1, 0x7F);
    // print(obj.toString());

    if (_status == "Connected") {
      // Fluttertoast.showToast(msg: obj.toString());
      await _port.write(Uint8List.fromList(obj));
      setState(() {
        // modeWriteList.clear();
      });
    }
  }

  void _increaseCounterWhilePressed() async {
    // writeRespiratoryPauseData();
    // make sure that only one loop is active
    if (_loopActive) return;

    _loopActive = true;

    while (_buttonPressed) {
      // do your thing
      setState(() {
        if (timerCounter <= 29) {
          timerCounter++;
        }
        if (timerCounter == 30) {
          writeRespiratoryPauseData(0);
          setState(() {
            //  sleep(Duration(seconds: 2));
            _buttonPressed = false;
            // _loopActive = true;
          });
        }
      });
      // Fluttertoast.showToast(msg: timerCounter.toString());

      // wait a bit
      await Future.delayed(Duration(seconds: 1));
    }

    _loopActive = false;
  }

  writeRespiratoryPauseData(int data) async {
    List<int> resList = [];
    setState(() {
      resList.add(0x7E);
      resList.add(0);
      resList.add(20);
      resList.add(0);
      resList.add(13);
      resList.add((data & 0x00FF));
      resList.add(0x7F);
    });
    await _port.write(Uint8List.fromList(resList));
  }

  checkCrc(List<int> obj, length) async {
    int index = length - 2;
    int i = 0;
    int crcData = 0;
    int uiCrc = 0, r = 0;
    int temp = 0;
    // List<int> l = [];
    // l.insert(0,126);
    // l.addAll(obj);
    // // print(l);

    while (index-- > 0) {
      r = ulCrc16Table[uiCrc & 0xF];
      uiCrc = ((uiCrc >> 4) & 0x0FFF);

      temp = obj[i];

      uiCrc = (uiCrc ^ r ^ ulCrc16Table[temp & 0xF]);

      r = ulCrc16Table[uiCrc & 0xF];
      uiCrc = ((uiCrc >> 4) & 0x0FFF);
      uiCrc = (uiCrc ^ r ^ ulCrc16Table[(temp >> 4) & 0xF]);
      i++;
    }

    crcData = obj[length - 1] * 256 + obj[length - 2];

    if (crcData == uiCrc) {
      cc = cc + 1;
      if (cc > 20000) {
        setState(() {
          cc = 0;
        });
      }
      // Fluttertoast.showToast(
      //     msg: length.toString() +
      //         " counter " +
      //         cc.toString() +
      //         "  geting crc " +
      //         crcData.toString() +
      //         " cal crc " +
      //         uiCrc.toString());

      return true;
    } else {
      return false;
    }
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    if (mounted) {
      setState(() {
        dateandTime = formattedDateTime;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss').format(dateTime);
  }

  @override
  void dispose() async {
    _subscription.cancel();
    _transaction.dispose();
    _timer.cancel();
    _timer1.cancel();
    super.dispose();
  }

  getData() async {
    Screen.setBrightness(1.0);
    Screen.keepOn(true);
    preferences = await SharedPreferences.getInstance();
    setState(() {
      var checkData = preferences.getString('checkMode');
      modeName = preferences.getString("mode");
      rrValue = preferences.getInt("rr");
      ieValue = preferences.getInt("ie");
      i = preferences.getString("i");
      e = preferences.getString("e");
      peepValue = preferences.getInt("peep");
      psValue = preferences.getInt("ps");
      pcValue = preferences.getInt("pc");
      vtValue = preferences.getInt("vt");
      vteValue = preferences.getInt("vte");
      fio2Value = preferences.getInt("fio2");
      tiValue =
          (double.tryParse(i) / (double.tryParse(i) + double.tryParse(e))) *
              (60000 / rrValue);
      // print(tiValue.toString());
      teValue =
          (double.tryParse(e) / (double.tryParse(i) + double.tryParse(e))) *
              (60000 / rrValue);
      // print(teValue.toString());
      paw = preferences.getInt("paw");
      mvValue = 0;
      rrtotalValue = preferences.getInt("rrtotal");
      patientId = preferences.getString("pid");
      patientName = preferences.getString("pname");
      patientGender = preferences.getString("pgender");
      patientAge = preferences.getString("page");
      patientHeight = preferences.getString("pheight");
      patientWeight = preferences.getString("pweight");
      if (patientWeight == null || patientWeight == "") {
        patientWeight = "133";
      }
      if (i == null) {
        i = "1.0";
      }
      if (e == null) {
        e = "3.0";
      }
      if (vteValue == null) {
        vteValue = 0;
      }

      minRrtotal = preferences.getInt('minrr');
      maxRrtotal = preferences.getInt('maxrr');
      minvte = preferences.getInt('minvte');
      maxvte = preferences.getInt('maxvte');
      minppeak = preferences.getInt('minppeak');
      maxppeak = preferences.getInt('maxppeak');
      minpeep = preferences.getInt('minpeep');
      maxpeep = preferences.getInt('maxpeep');

      if (checkData == "0") {
      } else if (checkData == "pacv") {
        pacvItrigValue = preferences.getInt('pacvItrigValue');
        pacvRrValue = preferences.getInt('pacvRrValue');
        pacvIeValue = preferences.getInt('pacvIeValue');
        pacvPeepValue = preferences.getInt('pacvPeepValue');
        pacvPcValue = preferences.getInt('pacvPcValue');
        pacvVtMinValue = preferences.getInt('pacvVtMinValue');
        pacvVtMaxValue = preferences.getInt('pacvVtMaxValue');
        pacvFio2Value = preferences.getInt('pacvFio2Value');
        pacvFlowRampValue = preferences.getInt('pacvFlowRampValue');
        pacvmaxValue = 10;
        pacvminValue = 1;
        pacvdefaultValue = preferences.getInt('pacvdefaultValue');

        pacvparameterName = "I Trig";
        pacvparameterUnits = "cmH\u2082O Below Peep";
        pacvItrig = true;
        pacvRr = false;
        pacvIe = false;
        pacvPeep = false;
        pacvPc = false;
        pacvVtMin = false;
        pacvVtMax = false;
        pacvFio2 = false;
        pacvFlowRamp = false;
      } else if (checkData == "pccmv") {
        pccmvRRValue = preferences.getInt('pccmvRRValue');
        pccmvIeValue = preferences.getInt('pccmvIeValue');
        pccmvPeepValue = preferences.getInt('pccmvPeepValue');
        pccmvPcValue = preferences.getInt('pccmvPcValue');
        pccmvFio2Value = preferences.getInt('pccmvFio2Value');
        pccmvVtminValue = preferences.getInt('pccmvVtminValue');
        pccmvVtmaxValue = preferences.getInt('pccmvVtmaxValue');
        pccmvTihValue = preferences.getInt('pccmvTihValue');
        pccmvFlowRampValue = preferences.getInt('pccmvFlowRampValue');
        pccmvmaxValue = 60;
        pccmvminValue = 1;
        pccmvdefaultValue = preferences.getInt('pccmvdefaultValue');

        pccmvparameterName = "RR";
        pccmvparameterUnits = "";
        pccmvRR = true;
        pccmvIe = false;
        pccmvPeep = false;
        pccmvPc = false;
        pccmvFio2 = false;
        pccmvVtmin = false;
        pccmvVtmax = false;
        pccmvFlowRamp = false;
      } else if (checkData == "vccmv") {
        vccmvRRValue = preferences.getInt('vccmvRRValue');
        vccmvIeValue = preferences.getInt('vccmvIeValue');
        vccmvPeepValue = preferences.getInt('vccmvPeepValue');
        vccmvPcMinValue = preferences.getInt('vccmvPcMinValue');
        vccmvPcMaxValue = preferences.getInt('vccmvPcMaxValue');
        vccmvFio2Value = preferences.getInt('vccmvFio2Value');
        vccmvVtValue = preferences.getInt('vccmvVtValue');
        vccmvTihValue = preferences.getInt('vccmvTihValue');
        vccmvFlowRampValue = preferences.getInt('vccmvFlowRampValue');
        vccmvmaxValue = 60;
        vccmvminValue = 1;
        vccmvdefaultValue = preferences.getInt('vccmvdefaultValue');
        vccmvparameterName = "RR";
        vccmvparameterUnits = "";
        vccmvRR = true;
        vccmvIe = false;
        vccmvPeep = false;
        vccmvPcMin = false;
        vccmvPcMax = false;
        vccmvFio2 = false;
        vccmvVt = false;
        vccmvFlowRamp = false;
        vccmvTih = false;
      } else if (checkData == "vacv") {
        vacvItrigValue = preferences.getInt('vacvItrigValue');
        vacvRrValue = preferences.getInt('vacvRrValue');
        vacvIeValue = preferences.getInt('vacvIeValue');
        vacvPeepValue = preferences.getInt('vacvPeepValue');
        vacvVtValue = preferences.getInt('vacvVtValue');
        vacvPcMinValue = preferences.getInt('vacvPcMinValue');
        vacvPcMaxValue = preferences.getInt('vacvPcMaxValue');
        vacvFio2Value = preferences.getInt('vacvFio2Value');
        vacvFlowRampValue = preferences.getInt('vacvFlowRampValue');
        vacvmaxValue = 10;
        vacvminValue = 1;
        vacvdefaultValue = preferences.getInt('vacvdefaultValue');
        vacvparameterName = "I Trig";
        vacvparameterUnits = "cmH\u2082O Below Peep";
        vacvItrig = true;
        vacvRr = false;
        vacvIe = false;
        vacvPeep = false;
        vacvVt = false;
        vacvPcMin = false;
        vacvPcMax = false;
        vacvFio2 = false;
        vacvFlowRamp = false;
      } else if (checkData == "psimv") {
        psimvItrig = true;
        psimvRr = false;
        psimvIe = false;
        psimvPeep = false;
        psimvPc = false;
        psimvPs = false;
        psimvVtMin = false;
        psimvVtMax = false;
        psimvFio2 = false;
        psimvFlowRamp = false;

        psimvItrigValue = preferences.getInt('psimvItrigValue');
        psimvRrValue = preferences.getInt('psimvRrValue');
        psimvPsValue = preferences.getInt('psimvPsValue');
        psimvIeValue = preferences.getInt('psimvIeValue');
        psimvPeepValue = preferences.getInt('psimvPeepValue');
        psimvPcValue = preferences.getInt('psimvPcValue');
        psimvVtMinValue = preferences.getInt('psimvVtMinValue');
        psimvVtMaxValue = preferences.getInt('psimvVtMaxValue');
        psimvFio2Value = preferences.getInt('psimvFio2Value');
        psimvFlowRampValue = preferences.getInt('psimvFlowRampValue');
        psimvmaxValue = 10;
        psimvminValue = 1;
        psimvdefaultValue = preferences.getInt('psimvdefaultValue');
        psimvparameterName = "I Trig";
        psimvparameterUnits = "cmH\u2082O  Below Peep";
      } else if (checkData == "vsimv") {
        vsimvItrig = true;
        vsimvRr = false;
        vsimvIe = false;
        vsimvPeep = false;
        vsimvVt = false;
        vsimvPs = false;
        vsimvPcMin = false;
        vsimvPcMax = false;
        vsimvFio2 = false;
        vsimvFlowRamp = false;
        vsimvItrigValue = preferences.getInt('vsimvItrigValue');
        vsimvRrValue = preferences.getInt('vsimvRrValue');
        vsimvIeValue = preferences.getInt('vsimvIeValue');
        vsimvPeepValue = preferences.getInt('vsimvPeepValue');
        vsimvVtValue = preferences.getInt('vsimvVtValue');
        vsimvPsValue = preferences.getInt('vsimvPsValue');
        vsimvPcMinValue = preferences.getInt('vsimvPcMinValue');
        vsimvPcMaxValue = preferences.getInt('vsimvPcMaxValue');
        vsimvFio2Value = preferences.getInt('vsimvFio2Value');
        vsimvFlowRampValue = preferences.getInt('vsimvFlowRampValue');

        vsimvdefaultValue = preferences.getInt('vsimvdefaultValue');
        vsimvparameterName = "I Trig";
        vsimvparameterUnits = "cmH\u2082O Below Peep";
      } else if (checkData == "psv") {
        psvItrigValue = preferences.getInt('psvItrigValue');
        psvPeepValue = preferences.getInt('psvPeepValue');
        psvIeValue = preferences.getInt('psvIeValue');
        psvPsValue = preferences.getInt('psvPsValue');
        psvTiValue = preferences.getInt('psvTiValue');
        psvVtMinValue = preferences.getInt('psvVtMinValue');
        psvVtMaxValue = preferences.getInt('psvVtMaxValue');
        psvFio2Value = preferences.getInt('psvFio2Value');
        psvAtimeValue = preferences.getInt('psvAtimeValue');
        psvEtrigValue = preferences.getInt('psvEtrigValue');
        psvBackupRrValue = preferences.getInt('psvBackupRrValue');
        psvMinTeValue = preferences.getInt('psvMinTeValue');
        psvFlowRampValue = preferences.getInt('psvFlowRampValue');
        psvItrig = true;
        psvPeep = false;
        psvIe = false;
        psvPs = false;
        psvTi = false;
        psvVtMin = false;
        psvVtMax = false;
        psvFio2 = false;
        psvAtime = false;
        psvEtrig = false;
        psvBackupRr = false;
        psvMinTe = false;
        psvFlowRamp = false;
        psvmaxValue = 10;
        psvminValue = 1;
        psvdefaultValue = preferences.getInt('psvdefaultValue');
        psvparameterName = "I Trig";
        psvparameterUnits = "cmH\u2082O Below Peep";
      } else if (checkData == "prvc") {
        vacvItrigValue = preferences.getInt('vacvItrigValue');
        vacvRrValue = preferences.getInt('vacvRrValue');
        vacvIeValue = preferences.getInt('vacvIeValue');
        vacvPeepValue = preferences.getInt('vacvPeepValue');
        vacvVtValue = preferences.getInt('vacvVtValue');
        vacvPcMinValue = preferences.getInt('vacvPcMinValue');
        vacvPcMaxValue = preferences.getInt('vacvPcMaxValue');
        vacvFio2Value = preferences.getInt('vacvFio2Value');
        vacvFlowRampValue = preferences.getInt('vacvFlowRampValue');
        vacvmaxValue = 10;
        vacvminValue = 1;
        vacvdefaultValue = preferences.getInt('vacvdefaultValue');
        vacvparameterName = "I Trig";
        vacvparameterUnits = "cmH\u2082O Below Peep";
        vacvItrig = true;
        vacvRr = false;
        vacvIe = false;
        vacvPeep = false;
        vacvVt = false;
        vacvPcMin = false;
        vacvPcMax = false;
        vacvFio2 = false;
        vacvFlowRamp = false;
      }
    });
  }

  checkI(String i) {
    var data =
        i.split(".")[1].toString() == "0" ? i.split(".")[0].toString() : i;
    return data;
  }

  checkE(String e) {
    var data =
        e.split(".")[1].toString() == "0" ? e.split(".")[0].toString() : e;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    scopeOne = Oscilloscope(
        showYAxis: true,
        yAxisColor: Colors.grey,
        padding: 10.0,
        backgroundColor: Color(0xFF171e27),
        traceColor: Colors.yellow,
        yAxisMax: 100,
        yAxisMin: 0.0,
        dataSet: pressurePoints);

    scopeOne1 = Oscilloscope(
        showYAxis: true,
        yAxisColor: Colors.grey,
        padding: 10.0,
        backgroundColor: Color(0xFF171e27),
        traceColor: Colors.green,
        yAxisMax: 200.0,
        yAxisMin: -90.0,
        dataSet: flowPoints);

    scopeOne2 = Oscilloscope(
        showYAxis: true,
        yAxisColor: Colors.grey,
        padding: 10.0,
        backgroundColor: Color(0xFF171e27),
        traceColor: Colors.blue,
        yAxisMax: 1000.0,
        yAxisMin: 0.0,
        dataSet: volumePoints);

    return Scaffold(
        resizeToAvoidBottomPadding: false,
        key: _scaffoldKey, //_scaffoldKey.currentState.openDrawer(),
        drawer: Container(
          width: 190,
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
            ),
            child: Container(
              color: Colors.transparent,
              child: Drawer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 50),
                    Container(
                      color: Color(0xFF171e27),
                      width: 190,
                      height: 85,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 12, right: 12, top: 5),
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Text("",
                                    style: TextStyle(
                                        color: Colors.green, fontSize: 10)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Text(
                                  "",
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 10),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Text(
                                  cdisplayParameter.toString(),
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 38),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 0.0, bottom: 65),
                                child: Text(
                                  "Compliance",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  "ml/cmH\u2082O",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12),
                                    ),
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 18.0),
                                  child: Divider(
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ))
                          ],
                        )),
                      ),
                    ),
                    Container(
                      color: Color(0xFF171e27),
                      width: 190,
                      height: 85,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 12, right: 12, top: 10),
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Text("",
                                    style: TextStyle(
                                        color: Colors.yellow, fontSize: 10)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Text(
                                  "",
                                  style: TextStyle(
                                      color: Colors.yellow, fontSize: 10),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Text(
                                  leakVolumeDisplay == null
                                      ? "0"
                                      : (leakVolumeDisplay / 1000)
                                          .toStringAsFixed(3),
                                  // "0000",
                                  style: TextStyle(
                                      color: Colors.yellow, fontSize: 35),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 0.0, bottom: 60),
                                child: Text(
                                  "Leak Volume",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  "ml",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.yellow, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.yellow, fontSize: 12),
                                    ),
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 18.0),
                                  child: Divider(
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ))
                          ],
                        )),
                      ),
                    ),
                    Container(
                      color: Color(0xFF171e27),
                      width: 190,
                      height: 85,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12, top: 5, bottom: 5),
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Text("",
                                    style: TextStyle(
                                        color: Colors.pink, fontSize: 10)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Text(
                                  "",
                                  style: TextStyle(
                                      color: Colors.pink, fontSize: 10),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Text(
                                  peakFlowDisplay == null
                                      ? "0"
                                      : (((peakFlowDisplay * 60) / 1000)*1.2)
                                          .toStringAsFixed(3),
                                  // "00",
                                  style: TextStyle(
                                      color: Colors.pink, fontSize: 35),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 0.0, bottom: 60),
                                child: Text(
                                  "Peak Flow",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  "lpm",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.pink, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.pink, fontSize: 12),
                                    ),
                                    Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 18.0),
                                  child: Divider(
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                )),
                          ],
                        )),
                      ),
                    ),
                    operatinModeR == 4 ||
                            operatinModeR == 5 ||
                            operatinModeR == 3
                        ? Container(
                            color: Color(0xFF171e27),
                            width: 190,
                            height: 85,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, top: 5, bottom: 5),
                              child: Center(
                                  child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Text("",
                                          style: TextStyle(
                                              color: Colors.pink,
                                              fontSize: 10)),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Text(
                                        "",
                                        style: TextStyle(
                                            color: Colors.pink, fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Text(
                                        spontaneousDisplay == null
                                            ? "0"
                                            : (spontaneousDisplay / 1000)
                                                .toStringAsFixed(3),
                                        // "00",
                                        style: TextStyle(
                                            color: Colors.blue, fontSize: 35),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 0.0, bottom: 60),
                                      child: Text(
                                        "Spontaneous Volume",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Text(
                                        "ml",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0),
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                          Text(
                                            "",
                                            style: TextStyle(
                                                color: Colors.pink,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "",
                                            style: TextStyle(
                                                color: Colors.pink,
                                                fontSize: 12),
                                          ),
                                          Text(
                                            "",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 18.0),
                                        child: Divider(
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      )),
                                ],
                              )),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Container(
          color: Color(0xFF171e27),
          child: Stack(
            children: [
              Container(
                child: Row(
                  children: [
                    main(),
                    rightBar(),
                  ],
                ),
              ),
              // modesEnabled
              //     ? Padding(
              //         padding: const EdgeInsets.only(right: 96.0, bottom: 162),
              //         child: Align(
              //             alignment: Alignment.bottomRight,
              //             child: Container(
              //               height:0,
              //               width: 0,
              //               child: Card(
              //                 color: Colors.blue,
              //               ),
              //             )),
              //       )
              //     : Container(),
              // newTreatEnabled
              //     ? Padding(
              //         padding: const EdgeInsets.only(right: 96.0, bottom: 108),
              //         child: Align(
              //             alignment: Alignment.bottomRight,
              //             child: Container(
              //               height:0,
              //               width: 0,
              //               child: Card(
              //                 color: Colors.blue,
              //               ),
              //             )),
              //       )
              //     : Container(),
              // monitorEnabled
              //     ? Padding(
              //         padding: const EdgeInsets.only(right: 96.0, bottom: 54),
              //         child: Align(
              //             alignment: Alignment.bottomRight,
              //             child: Container(
              //               height: 0,
              //               width: 0,
              //               child: Card(
              //                 color: Colors.blue,
              //               ),
              //             )),
              //       )
              //
              //  : Container(),
              alarmEnabled
                  ? alarmClick()
                  : modesEnabled
                      ? modesClick()

                      //     ? Navigator.push(
                      //             context,
                      //             MaterialPageRoute(builder: (context) => NewTreatmentScreen()),)
                      : monitorEnabled ? monitorClick() : Container(),

              // _buttonPressed
              //     ? Center(
              //       child: Material(
              //           borderRadius: BorderRadius.circular(24.0),
              //           color: Colors.green,
              //           child: Padding(
              //             padding: const EdgeInsets.only(
              //                 left: 30.0, right: 30.0, top: 15, bottom: 15),
              //             child: Text(
              //               ioreDisplayParamter=="I" ?  "Inspiratory Pause : " +  (timerCounter.toString() + "s")
              //                 : ioreDisplayParamter=="E" ? "Expiratory Pause : "  + (timerCounter.toString() + "s")
              //                 : "Respiratory Pause : "+ (timerCounter.toString() + "s"),
              //                 style:
              //                     TextStyle(fontSize: 30, color: Colors.white)),
              //           ),
              //         ),
              //     )
              //     : Container()
            ],
          ),
        ));
  }

  modesClick() {
    return Container(
      color: Colors.transparent,
      child: Center(
          child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 0.0),
                child: Material(
                  color: Colors.grey,
                  elevation: 10.0,
                  shadowColor: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                        color: Color(0xFF171e27),
                        height: 590,
                        width: 1024,
                        child: Center(
                          child: Stack(
                            children: [
                              Container(
                                padding: EdgeInsets.only(left: 14),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 10,
                                      ),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  // setData();
                                                  pccmvEnabled = true;
                                                  vccmvEnabled = false;
                                                  pacvEnabled = false;
                                                  vacvEnabled = false;
                                                  psimvEnabled = false;
                                                  vsimvEnabled = false;
                                                  psvEnabled = false;
                                                  prvcEnabled = false;
                                                });
                                              },
                                              child: Card(
                                                color: pccmvEnabled
                                                    ? Colors.blue
                                                    : Colors.white,
                                                child: Container(
                                                  width: 115,
                                                  height: 70,
                                                  child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text("PC-CMV",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: pccmvEnabled
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  // setData();
                                                  pccmvEnabled = false;
                                                  vccmvEnabled = false;
                                                  pacvEnabled = true;
                                                  vacvEnabled = false;
                                                  psimvEnabled = false;
                                                  vsimvEnabled = false;
                                                  psvEnabled = false;
                                                  prvcEnabled = false;
                                                });
                                              },
                                              child: Card(
                                                color: pacvEnabled
                                                    ? Colors.blue
                                                    : Colors.white,
                                                child: Container(
                                                  width: 98,
                                                  height: 70,
                                                  child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text("PACV",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: pacvEnabled
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  // setData();
                                                  pccmvEnabled = false;
                                                  vccmvEnabled = true;
                                                  pacvEnabled = false;
                                                  vacvEnabled = false;
                                                  psimvEnabled = false;
                                                  vsimvEnabled = false;
                                                  psvEnabled = false;
                                                  prvcEnabled = false;
                                                });
                                              },
                                              child: Card(
                                                  color: vccmvEnabled
                                                      ? Colors.blue
                                                      : Colors.white,
                                                  child: Container(
                                                    width: 115,
                                                    height: 70,
                                                    child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Text("VC-CMV",
                                                              style: TextStyle(
                                                                  fontSize: 20,
                                                                  color: vccmvEnabled
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        )),
                                                  )),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  // setData();
                                                  pccmvEnabled = false;
                                                  vccmvEnabled = false;
                                                  pacvEnabled = false;
                                                  vacvEnabled = true;
                                                  psimvEnabled = false;
                                                  vsimvEnabled = false;
                                                  psvEnabled = false;
                                                  prvcEnabled = false;
                                                });
                                              },
                                              child: Card(
                                                color: vacvEnabled
                                                    ? Colors.blue
                                                    : Colors.white,
                                                child: Container(
                                                  width: 98,
                                                  height: 70,
                                                  child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text("VACV",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: vacvEnabled
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  // setData();
                                                  pccmvEnabled = false;
                                                  vccmvEnabled = false;
                                                  pacvEnabled = false;
                                                  vacvEnabled = false;
                                                  psimvEnabled = true;
                                                  vsimvEnabled = false;
                                                  psvEnabled = false;
                                                  prvcEnabled = false;
                                                });
                                              },
                                              child: Card(
                                                color: psimvEnabled
                                                    ? Colors.blue
                                                    : Colors.white,
                                                child: Container(
                                                  width: 98,
                                                  height: 70,
                                                  child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text("PSIMV",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: psimvEnabled
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  // setData();
                                                  pccmvEnabled = false;
                                                  vccmvEnabled = false;
                                                  pacvEnabled = false;
                                                  vacvEnabled = false;
                                                  psimvEnabled = false;
                                                  vsimvEnabled = true;
                                                  psvEnabled = false;
                                                  prvcEnabled = false;
                                                });
                                              },
                                              child: Card(
                                                color: vsimvEnabled
                                                    ? Colors.blue
                                                    : Colors.white,
                                                child: Container(
                                                  width: 98,
                                                  height: 70,
                                                  child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text("VSIMV",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: vsimvEnabled
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  // setData();
                                                  pccmvEnabled = false;
                                                  vccmvEnabled = false;
                                                  pacvEnabled = false;
                                                  vacvEnabled = false;
                                                  psimvEnabled = false;
                                                  vsimvEnabled = false;
                                                  psvEnabled = true;
                                                  prvcEnabled = false;
                                                });
                                              },
                                              child: Card(
                                                color: psvEnabled
                                                    ? Colors.blue
                                                    : Colors.white,
                                                child: Container(
                                                  width: 98,
                                                  height: 70,
                                                  child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text("PSV",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: psvEnabled
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  pccmvEnabled = false;
                                                  vccmvEnabled = false;
                                                  pacvEnabled = false;
                                                  vacvEnabled = false;
                                                  psimvEnabled = false;
                                                  vsimvEnabled = false;
                                                  psvEnabled = false;
                                                  prvcEnabled = true;
                                                });
                                              },
                                              child: Card(
                                                color: prvcEnabled
                                                    ? Colors.blue
                                                    : Colors.white,
                                                child: Container(
                                                  width: 98,
                                                  height: 70,
                                                  child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text("PRVC",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: prvcEnabled
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      modeDefaultSettings(),
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                alarmEnabled = true;
                                              });
                                            },
                                            child: Container(
                                              height: 80,
                                              width: 210,
                                              child: Card(
                                                child: Center(
                                                    child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text("Alarm Settings",
                                                      style: TextStyle(
                                                          fontSize: 22,
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                )),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      modesEnabled = false;
                                                      newTreatEnabled = false;

                                                      monitorEnabled = false;
                                                    });
                                                  },
                                                  child: Container(
                                                    height: 80,
                                                    width: 210,
                                                    child: Card(
                                                      child: Center(
                                                          child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text("Cancel",
                                                            style: TextStyle(
                                                                fontSize: 22,
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )),
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    // if(pccmvRR==true){
                                                    //   pccmvRRValue=pccmvTempValue;
                                                    // }
                                                    modeSetCheck();
                                                  },
                                                  child: Container(
                                                    height: 80,
                                                    width: 210,
                                                    child: Card(
                                                      child: Center(
                                                          child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text("Confirm",
                                                            style: TextStyle(
                                                                fontSize: 22,
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ),
                ),
              ))),
    );
  }

  alarmClick() {
    return Container(
      color: Colors.transparent,
      child: Center(
          child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 0.0),
                child: Material(
                  color: Colors.blue,
                  elevation: 10.0,
                  shadowColor: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                        color: Color(0xFF171e27),
                        height: 590,
                        width: 1024,
                        child: Center(
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Text("Alarm Settings",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 30)),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  alarmsComponents(),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        right: 10, top: 10, left: 20),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              alarmRRchanged = false;
                                              alarmVtechanged = false;
                                              alarmFio2changed = false;
                                              alarmpeepchanged = false;
                                              alarmPpeakchanged = false;
                                              newTreatEnabled = false;
                                              alarmEnabled = false;
                                              alarmRR = false;
                                              alarmVte = false;
                                              alarmPpeak = false;
                                              alarmpeep = false;
                                              alarmFio2 = false;
                                              newTreatEnabled = false;
                                              alarmConfirmed = true;
                                            });
                                          },
                                          child: Container(
                                            height: 80,
                                            width: 210,
                                            child: Card(
                                              child: Center(
                                                  child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text("Exit",
                                                    style: TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              )),
                                            ),
                                          ),
                                        ),
                                        alarmConfirmed == false
                                            ? Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        alarmConfirmed = true;
                                                      });
                                                    },
                                                    child: Container(
                                                      height: 80,
                                                      width: 210,
                                                      child: Card(
                                                        child: Center(
                                                            child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Text("Cancel",
                                                              style: TextStyle(
                                                                  fontSize: 22,
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        )),
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      // if(pccmvEnabled==true){
                                                      //     if(minRrtotal<pccmvRRValue){
                                                      //       Fluttertoast.showToast(msg: "RR Value is less");
                                                      //     }else if(maxRrtotal<pccmvRRValue){

                                                      //     }else if(minpeep<pccmvPeepValue){

                                                      //     }else if(pccmvPeepValue>maxpeep){

                                                      //     }else if(pccmvPcValue<minppeak){

                                                      //     }else if(pccmvPcValue>maxppeak){

                                                      //     }else{
                                                      //       writeAlarmsData();
                                                      //     }
                                                      // }else if(pacvEnabled==true){

                                                      // }
                                                      // else{
                                                      writeAlarmsData();
                                                      // }
                                                    },
                                                    child: Container(
                                                      height: 80,
                                                      width: 210,
                                                      child: Card(
                                                        child: Center(
                                                            child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Text("Confirm",
                                                              style: TextStyle(
                                                                  fontSize: 22,
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        )),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        )),
                  ),
                ),
              ))),
    );
  }

  systemClick() {
    return Container(
      color: Colors.transparent,
      child: Center(
          child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 110.0),
                child: Material(
                  color: Colors.blue,
                  elevation: 10.0,
                  shadowColor: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                        color: Color(0xFF171e27),
                        height: 590,
                        width: 904,
                        child: Center(
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 360,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                modesEnabled = false;
                                                newTreatEnabled = false;

                                                monitorEnabled = false;
                                              });
                                            },
                                            child: Container(
                                              height: 80,
                                              width: 210,
                                              child: Card(
                                                child: Center(
                                                    child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text("Cancel",
                                                      style: TextStyle(
                                                          fontSize: 22,
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                )),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 80,
                                            width: 210,
                                            child: Card(
                                              child: Center(
                                                  child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text("Confirm",
                                                    style: TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              )),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ),
                ),
              ))),
    );
  }

  monitorClick() {
    return Container(
      color: Colors.transparent,
      child: Center(
          child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 110.0),
                child: Material(
                  color: Colors.blue,
                  elevation: 10.0,
                  shadowColor: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                        color: Color(0xFF171e27),
                        height: 590,
                        width: 904,
                        child: Center(
                          child: Stack(
                            children: [
                              // Align(
                              //   alignment: Alignment(1.02, -1.03),
                              //   child: InkWell(
                              //     onTap: () {
                              //       setState(() {
                              //         modesEnabled = false;
                              //         newTreatEnabled = false;

                              //         monitorEnabled = false;
                              //       });
                              //     },
                              //     child: Container(
                              //       decoration: BoxDecoration(
                              //         color: Colors.red,
                              //         borderRadius: BorderRadius.circular(22),
                              //       ),
                              //       child: Padding(
                              //         padding: const EdgeInsets.all(12.0),
                              //         child: Icon(
                              //           Icons.close,
                              //           color: Colors.white,
                              //         ),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              Align(
                                alignment: Alignment.center,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 360,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                modesEnabled = false;
                                                newTreatEnabled = false;

                                                monitorEnabled = false;
                                              });
                                            },
                                            child: Container(
                                              height: 80,
                                              width: 210,
                                              child: Card(
                                                child: Center(
                                                    child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text("Cancel",
                                                      style: TextStyle(
                                                          fontSize: 22,
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                )),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 80,
                                            width: 210,
                                            child: Card(
                                              child: Center(
                                                  child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text("Confirm",
                                                    style: TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              )),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ),
                ),
              ))),
    );
  }

  rightBar() {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(left: 0, top: 0),
          child: Container(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: 4,
                ),
                Text(
                  "SWASIT",
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 22,
                      fontFamily: "appleFont"),
                ),
                Text(
                  "V1.7.4",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: "appleFont"),
                ),
                SizedBox(
                  height: 5,
                ),

                SizedBox(
                  height: 5,
                ),

                //   Center(
                //     child: Padding(
                //       padding: const EdgeInsets.all(4.0),
                //       child: Container(
                //       width: 60,
                //       child: LinearPercentIndicator(
                //         animation: true,
                //         lineHeight: 20.0,
                //         animationDuration: 2500,
                //         percent: batteryPercentageValue,
                //         center: Text(""),
                //         linearStrokeCap: LinearStrokeCap.roundAll,
                //         progressColor: Colors.green,
                //       ),
                // ),
                //     ),
                //   ),
                //  Center(
                //    child: Padding(
                //      padding: const EdgeInsets.only(bottom:5.0),
                //      child: Container(
                //       width: 60,
                //       child: Icon(Icons.close,color:Colors.red,size:26)
                // ),
                //    ),
                //  ),

                SizedBox(
                  height: 2,
                ),
                powerButtonEnabled
                    ? InkWell(
                        onTap: () {
                          turnOffScreen();
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.only(right: 40.0, bottom: 20),
                          child: IconButton(
                            icon: Icon(Icons.power_settings_new,
                                size: 70, color: Colors.red),
                            onPressed: () {
                              turnOffScreen();
                            },
                          ),
                        ),
                      )
                    : Container(),
                SizedBox(
                  height: 2,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    playOnEnabled
                        ? InkWell(
                            onTap: () {
                              setState(() {
                                playOnEnabled = false;
                              });
                              // counterData();
                              writeDataPlay();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 20.0, bottom: 20),
                              child: IconButton(
                                  icon: Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.green,
                                    size: 50,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      playOnEnabled = false;
                                    });
                                    // counterData();
                                    writeDataPlay();
                                  }),
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              setState(() {
                                playOnEnabled = true;
                              });
                              writeDataPause();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 20.0, bottom: 20),
                              child: IconButton(
                                  icon: Icon(
                                    Icons.pause_circle_filled,
                                    color: Colors.blue,
                                    size: 50,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      playOnEnabled = true;
                                    });
                                    writeDataPause();
                                  }),
                            ),
                          ),
                    //  powerIndication==1 ?  Image.asset("assets/images/switchon.png"):powerIndication==0 ?
                    //  Image.asset("assets/images/switchoff.png") : Icon(Icons.power_settings_new,color:Colors.red),
                    SizedBox(
                      height:
                          playOnEnabled ? 148 : powerButtonEnabled ? 181 : 300,
                    ),
                  ],
                ),
                playOnEnabled
                    ? Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              var data = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => NewTreatmentScreen()),
                              );
                              if (data == "1") {
                                getData();
                              }
                            },
                            child: Center(
                              child: Container(
                                width: 120,
                                child: Card(
                                  color: newTreatEnabled
                                      ? Colors.blue
                                      : Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 12.0,
                                        right: 12.0,
                                        top: 12,
                                        bottom: 12),
                                    child: Center(
                                        child: Text(
                                      "New Patient",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: newTreatEnabled
                                              ? Colors.white
                                              : Colors.black),
                                    )),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          //       InkWell(
                          //         onTap: () {
                          //           setState(() {
                          //             Navigator.push(
                          //               context,
                          //               new MaterialPageRoute(
                          //                   builder: (context) => SelfTestPage()),
                          //             );
                          //           });
                          //         },
                          //         child: Center(
                          //           child: Container(
                          //             width: 120,
                          //             child: Card(
                          //               color: monitorEnabled
                          //                   ? Colors.blue
                          //                   : Colors.white,
                          //               child: Padding(
                          //                 padding: const EdgeInsets.all(12.0),
                          //                 child: Center(
                          //                     child: Text(" Test \n Calibration",
                          //                         textAlign: TextAlign.center,
                          //                         style: TextStyle(
                          //                             fontWeight: FontWeight.bold,
                          //                             color: monitorEnabled
                          //                                 ? Colors.white
                          //                                 : Colors.black))),
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //       ),
                        ],
                      )
                    : Container(),
                InkWell(
                  onTap: () {
                    setState(() {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ViewLogPatientList()));
                    });
                  },
                  child: Center(
                    child: Container(
                      width: 120,
                      child: Card(
                        color: monitorEnabled ? Colors.blue : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                              child: Text("View Logs",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: monitorEnabled
                                          ? Colors.white
                                          : Colors.black))),
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      // if (patientId != "") {
                      modesEnabled = !modesEnabled;
                      // } else {
                      //   showAlertDialog(context);
                      // }
                    });
                  },
                  child: Center(
                    child: Container(
                      width: 120,
                      child: Card(
                        color: modesEnabled ? Colors.blue : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                              child: Text(
                            "Modes",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    modesEnabled ? Colors.white : Colors.black),
                          )),
                        ),
                      ),
                    ),
                  ),
                ),

                audioEnable
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            audioEnable = false;
                            sendSoundOff();
                          });
                        },
                        child: Center(
                          child: Image.asset(
                            "assets/images/bell_line.png",
                            color: Colors.white,
                            width: 98,
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: () {
                          setState(() {
                            audioEnable = true;
                            sendSoundOn();
                          });
                        },
                        child: Center(
                          child: Image.asset(
                            "assets/images/bell_silent_line.png",
                            color: Colors.grey,
                            width: 98,
                          ),
                        ),
                      ),
                // Container(
                //   height: 25,
                //   width: 25,
                //   margin: EdgeInsets.only(left: 80),
                //   decoration: new BoxDecoration(
                //     borderRadius: new BorderRadius.circular(25.0),
                //     border: new Border.all(
                //       width: 2.0,
                //       color: Colors.green,
                //     ),
                //   ),
                //   child: Center(
                //       child: Text(
                //     checkTempData == "1"
                //         ? "L"
                //         : checkTempData == "0"
                //             ? "U"
                //             : checkTempData == "2" ? "S" : "",
                //     style: TextStyle(color: Colors.white),
                //   )),
                // ),

                // Text(checkTempData=="1" ? "L" :checkTempData=="0" ? "U":"",style:TextStyle(color:Colors.red))
                // InkWell(
                //   onTap: () {
                //     setState(() {
                //       newTreatEnabled = !newTreatEnabled;
                //     });
                //   },
                //   child: Center(
                //     child: Container(
                //       width: 120,
                //       child: Card(
                //         color: newTreatEnabled ? Colors.blue : Colors.white,
                //         child: Padding(
                //           padding: const EdgeInsets.all(12.0),
                //           child: Center(
                //               child: Text(
                //             "Alarms",
                //             style: TextStyle(
                //                 fontWeight: FontWeight.bold,
                //                 color: newTreatEnabled
                //                     ? Colors.white
                //                     : Colors.black),
                //           )),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // InkWell(
                //   onTap: () {
                //     setState(() {
                //       // editbbEnabled = !editbbEnabled;
                //     });
                //   },
                //   child: Center(
                //     child: Container(
                //       width: 120,
                //       child: Card(
                //         color: editbbEnabled ? Colors.blue : Colors.white,
                //         child: Padding(
                //           padding: const EdgeInsets.all(12.0),
                //           child: Center(
                //               child: Text("Settings",
                //                   style: TextStyle(
                //                       fontWeight: FontWeight.bold,
                //                       color: editbbEnabled
                //                           ? Colors.white
                //                           : Colors.black))),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  main() {
    return Stack(
      children: [
        topbar(),
        leftbar(),
        Stack(
          children: [
            Container(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 25),
                          graphs(),
                          SizedBox(width: 9),
                          Container(
                            margin: EdgeInsets.only(top: 40),
                            width: 1,
                            height: 440,
                            color: Colors.white,
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 30,
                                ),
                                Column(
                                  children: [
                                    Center(
                                      child: Container(
                                        color: Color(0xFF171e27),
                                        width: 170,
                                        height: 81,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 2, left: 4),
                                          child: Center(
                                              child: Stack(
                                            children: [
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text("",
                                                      style: TextStyle(
                                                          color: Colors.green,
                                                          fontSize: 10)),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.bottomLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 5.0,
                                                          left: 4.0),
                                                  child: Text(
                                                    "cmH\u2082O",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.center,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Text(
                                                    mapDisplayValue.toString(),
                                                    // "000",
                                                    style: TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 35),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: 60, left: 4),
                                                  child: Text(
                                                    "MAP",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 18.0),
                                                    child: Divider(
                                                      color: Colors.white,
                                                      height: 1,
                                                    ),
                                                  ))
                                            ],
                                          )),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Container(
                                        color: Color(0xFF171e27),
                                        width: 170,
                                        height: 81,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 2, left: 4),
                                          child: Center(
                                              child: Stack(
                                            children: [
                                              Align(
                                                alignment: Alignment.bottomLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 5.0, left: 4),
                                                  child: Text(
                                                    "L/m",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.bottomLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text(
                                                    "",
                                                    style: TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 10),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.center,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Text(
                                                    (mvValue / 1000)
                                                        .toStringAsFixed(3),
                                                    // "0000",
                                                    style: TextStyle(
                                                        color: Colors.yellow,
                                                        fontSize: 35),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: 60, left: 4),
                                                  child: Text(
                                                    "MVe",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 18.0),
                                                    child: Divider(
                                                      color: Colors.white,
                                                      height: 1,
                                                    ),
                                                  ))
                                            ],
                                          )),
                                        ),
                                      ),
                                    ),
                                    // Container(
                                    //   height: 162,
                                    // )
                                    Center(
                                      child: Container(
                                        color: Color(0xFF171e27),
                                        width: 170,
                                        height: 81,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 2, left: 4),
                                          child: Center(
                                              child: Stack(
                                            children: [
                                              Align(
                                                alignment: Alignment.topRight,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text("",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10)),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.bottomLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text(
                                                    "cmH\u2082O",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.center,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Text(
                                                    pplateauDisplay
                                                        .toStringAsFixed(0),
                                                    // "0000",
                                                    style: TextStyle(
                                                        color: Colors.pink,
                                                        fontSize: 35),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: 60, left: 4),
                                                  child: Text(
                                                    "P Plateau",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 18.0),
                                                    child: Divider(
                                                      color: Colors.white,
                                                      height: 1,
                                                    ),
                                                  ))
                                            ],
                                          )),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: <Widget>[
                                        Center(
                                          child: Container(
                                            color: Color(0xFF171e27),
                                            width: 85,
                                            height: 81,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: Center(
                                                  child: Stack(
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2.0),
                                                      child: Text("",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.green,
                                                              fontSize: 10)),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.bottomLeft,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2.0),
                                                      child: Text(
                                                        "ms",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment: Alignment.center,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Text(
                                                        tiValue
                                                            .toStringAsFixed(0),
                                                        // "0000",
                                                        style: TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: 18),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                          bottom: 50, left: 4),
                                                      child: Text(
                                                        "Ti",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                top: 18.0),
                                                        child: Divider(
                                                          color: Colors.white,
                                                          height: 1,
                                                        ),
                                                      ))
                                                ],
                                              )),
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Container(
                                            color: Color(0xFF171e27),
                                            width: 85,
                                            height: 81,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: Center(
                                                  child: Stack(
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2.0),
                                                      child: Text("",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.green,
                                                              fontSize: 10)),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.bottomLeft,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2.0),
                                                      child: Text(
                                                        "ms",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment: Alignment.center,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Text(
                                                        teValue
                                                            .toStringAsFixed(0),
                                                        // "0000",
                                                        style: TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: 18),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                          bottom: 50, left: 4),
                                                      child: Text(
                                                        "Te",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                top: 18.0),
                                                        child: Divider(
                                                          color: Colors.white,
                                                          height: 1,
                                                        ),
                                                      ))
                                                ],
                                              )),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: 6,
                                ),
                                Stack(
                                  children: [
                                    insExpButtonEnable == false
                                        ? Align(
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Image.asset(
                                                    lungImage == 1
                                                        ? "assets/lungs/1.png"
                                                        : lungImage == 2
                                                            ? "assets/lungs/2.png"
                                                            : lungImage == 3
                                                                ? "assets/lungs/3.png"
                                                                : lungImage == 4
                                                                    ? "assets/lungs/4.png"
                                                                    : lungImage ==
                                                                            5
                                                                        ? "assets/lungs/5.png"
                                                                        : "assets/lungs/1.png",
                                                    width: 120),
                                                Container(
                                                  height: 25,
                                                  width: 25,
                                                  decoration: new BoxDecoration(
                                                    borderRadius:
                                                        new BorderRadius
                                                            .circular(25.0),
                                                    border: new Border.all(
                                                      width: 2.0,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  child: Center(
                                                      child: Text(
                                                          ioreDisplayParamter,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10))),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Column(
                                            children: <Widget>[
                                              Center(
                                                child: Listener(
                                                  onPointerDown: (details) {
                                                    writeRespiratoryPauseData(
                                                        1);
                                                    // _inpirationPressed = true;
                                                    _buttonPressed = true;
                                                    _increaseCounterWhilePressed();
                                                  },
                                                  onPointerUp: (details) {
                                                    writeRespiratoryPauseData(
                                                        0);
                                                    setState(() {
                                                      timerCounter = 0;
                                                      _buttonPressed = false;
                                                      // _inpirationPressed = false;
                                                    });
                                                  },
                                                  child: Material(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.0),
                                                    color: Colors.green,
                                                    child: Container(
                                                      width: 135,
                                                      height: 58.5,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child: Center(
                                                            child: Stack(
                                                          children: [
                                                            Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                "Inspiratory \n Pause",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .white),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                          ],
                                                        )),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Center(
                                                child: Listener(
                                                  onPointerDown: (details) {
                                                    writeRespiratoryPauseData(
                                                        2);
                                                    _buttonPressed = true;
                                                    _increaseCounterWhilePressed();
                                                  },
                                                  onPointerUp: (details) {
                                                    writeRespiratoryPauseData(
                                                        0);
                                                    setState(() {
                                                      timerCounter = 0;
                                                      _buttonPressed = false;
                                                      // _expiratoryPressed = false;
                                                    });
                                                  },
                                                  child: Material(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.0),
                                                    color: Colors.green,
                                                    child: Container(
                                                      width: 135,
                                                      height: 58.5,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child: Center(
                                                            child: Stack(
                                                          children: [
                                                            Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                "Expiratory \n Pause",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .white),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                          ],
                                                        )),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                            ],
                                          ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    bottombar(),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 40, left: 195),
              width: 1,
              height: 440,
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  leftbar() {
    return Stack(
      children: [
        Container(
            child: Container(
          padding: EdgeInsets.only(top: 50),
          child: Column(
            children: [
              Center(
                child: Container(
                  color: Color(0xFF171e27),
                  width: 200,
                  height: 85,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Center(
                        child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text("",
                                style: TextStyle(
                                    color: Colors.green, fontSize: 10)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              "",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 10),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: Text(
                              psValue1.toString(),
                              style:
                                  TextStyle(color: Colors.green, fontSize: 38),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 0.0, bottom: 65),
                            child: Text(
                              "PIP",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "cmH\u2082O",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  "MAX",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  maxppeak.toString(),
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  minppeak.toString(),
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 12),
                                ),
                                Text(
                                  "MIN",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: Divider(
                                color: Colors.white,
                                height: 1,
                              ),
                            ))
                      ],
                    )),
                  ),
                ),
              ),
              Center(
                child: Container(
                  color: Color(0xFF171e27),
                  width: 200,
                  height: 85,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Center(
                        child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text("",
                                style: TextStyle(
                                    color: Colors.yellow, fontSize: 10)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              "",
                              style:
                                  TextStyle(color: Colors.yellow, fontSize: 10),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: Text(
                              vteValue.toString(),
                              // "0000",
                              style:
                                  TextStyle(color: Colors.yellow, fontSize: 35),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 0.0, bottom: 60),
                            child: Text(
                              "VTe",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "mL",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  "MAX",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  maxvte.toString(),
                                  style: TextStyle(
                                      color: Colors.yellow, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  // modeName == "VC-CMV" ||
                                  //         modeName == "VACV" ||
                                  //         modeName == "VSIMV"
                                  //     ? vteMinValue.toString()
                                  //     :
                                  minvte.toString(),
                                  ////""
                                  style: TextStyle(
                                      color: Colors.yellow, fontSize: 12),
                                ),
                                Text(
                                  "MIN",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: Divider(
                                color: Colors.white,
                                height: 1,
                              ),
                            ))
                      ],
                    )),
                  ),
                ),
              ),
              Center(
                child: Container(
                  color: Color(0xFF171e27),
                  width: 200,
                  height: 85,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Center(
                        child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text("",
                                style: TextStyle(
                                    color: Colors.pink, fontSize: 10)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              "",
                              style:
                                  TextStyle(color: Colors.pink, fontSize: 10),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: Text(
                              peepDisplayValue.toString(),
                              // "00",
                              style:
                                  TextStyle(color: Colors.pink, fontSize: 35),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 0.0, bottom: 60),
                            child: Text(
                              "PEEP",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "cmH\u2082O",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  "MAX",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  maxpeep.toString(),
                                  style: TextStyle(
                                      color: Colors.pink, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  minpeep.toString(),
                                  style: TextStyle(
                                      color: Colors.pink, fontSize: 12),
                                ),
                                Text(
                                  "MIN",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: Divider(
                                color: Colors.white,
                                height: 1,
                              ),
                            )),
                      ],
                    )),
                  ),
                ),
              ),
              Center(
                child: Container(
                  color: Color(0xFF171e27),
                  width: 200,
                  height: 85,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Center(
                        child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text("",
                                style: TextStyle(
                                    color: Colors.blue, fontSize: 10)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              "",
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 10),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: Text(
                              rrDisplayValue.toString(),
                              // "00",
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 35),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 0.0, bottom: 60),
                            child: Text(
                              "RR",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "bpm",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  "MAX",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  maxRrtotal.toString(),
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  minRrtotal.toString(),
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 12),
                                ),
                                Text(
                                  "MIN",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: Divider(
                                color: Colors.white,
                                height: 1,
                              ),
                            ))
                      ],
                    )),
                  ),
                ),
              ),
              Center(
                child: Container(
                  color: Color(0xFF171e27),
                  width: 200,
                  height: 85,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Center(
                        child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text("",
                                style: TextStyle(
                                    color: Colors.blue, fontSize: 10)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              "",
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 10),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: Text(
                              fio2DisplayParameter.toString(),
                              // "000",
                              style:
                                  TextStyle(color: Colors.teal, fontSize: 35),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 0.0, bottom: 55, right: 0.0),
                            child: Text(
                              "FiO\u2082",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "%",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: Divider(
                                color: Colors.white,
                                height: 1,
                              ),
                            ))
                      ],
                    )),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  bottombar() {
    return Container(
      color: Color(0xFF171e27),
      width: 904,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                // CommonClick("RR");
              },
              child: Center(
                child: Container(
                  width: 120,
                  height: 110,
                  child: Card(
                    elevation: 40,
                    color: Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "RR",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 17.0),
                              child: Text(
                                rrValue.toString(),
                                style: TextStyle(
                                    fontSize: 30, color: Colors.white),
                              ),
                            ),
                          ),
                          // Align(
                          //   alignment: Alignment.centerRight,
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(top: 17.0),
                          //     child: Icon(
                          //         editbbEnabled ? Icons.lock_open : Icons.lock,
                          //         color: Colors.white,
                          //         size: 15),
                          //   ),
                          // ),
                          // Align(
                          //   alignment: Alignment.bottomCenter,
                          //   child: LinearProgressIndicator(
                          //     backgroundColor: Colors.grey,
                          //     valueColor: AlwaysStoppedAnimation<Color>(
                          //       Colors.white,
                          //     ),
                          //     value: rrValue != null ? rrValue / 60 : 0,
                          //   ),
                          // )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                // CommonClick("I:E");
              },
              child: Center(
                child: Container(
                  width: 120,
                  height: 110,
                  child: Card(
                    elevation: 40,
                    color: Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I:E".toUpperCase(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 17.0),
                              child: Text(
                                checkI(i) + ":" + checkE(e),
                                style: TextStyle(
                                    fontSize: 30, color: Colors.white),
                              ),
                            ),
                          ),
                          // Align(
                          //   alignment: Alignment.centerRight,
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(top: 17.0),
                          //     child: Icon(
                          //         editbbEnabled ? Icons.lock_open : Icons.lock,
                          //         color: Colors.white,
                          //         size: 15),
                          //   ),
                          // ),
                          // Align(
                          //   alignment: Alignment.bottomCenter,
                          //   child: LinearProgressIndicator(
                          //     backgroundColor: Colors.grey,
                          //     valueColor: AlwaysStoppedAnimation<Color>(
                          //       Colors.white,
                          //     ),
                          //     value: ieValue != null ? int.parse(ieValue)/ 4 : 0,
                          //   ),
                          // )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),

            InkWell(
              onTap: () {
                //  CommonClick("PEEP") ;
              },
              child: Center(
                child: Container(
                  width: 120,
                  height: 110,
                  child: Card(
                    elevation: 40,
                    color: Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "peep".toUpperCase(),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style:
                                  TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                          // Align(
                          //   alignment: Alignment.centerRight,
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(top: 17.0),
                          //     child: Icon(
                          //         editbbEnabled ? Icons.lock_open : Icons.lock,
                          //         color: Colors.white,
                          //         size: 15),
                          //   ),
                          // ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 17.0),
                              child: Text(
                                peepValue.toString(),
                                style: TextStyle(
                                    fontSize: 30, color: Colors.white),
                              ),
                            ),
                          ),
                          // Align(
                          //   alignment: Alignment.bottomCenter,
                          //   child: LinearProgressIndicator(
                          //     backgroundColor: Colors.grey,
                          //     valueColor: AlwaysStoppedAnimation<Color>(
                          //       Colors.white,
                          //     ),
                          //     value: peepValue != null ? peepValue / 30 : 0,
                          //   ),
                          // )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            modeName != "PSV"
                ? InkWell(
                    onTap: () {
                      //  CommonClick("PS") ;
                    },
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 110,
                        child: Card(
                          elevation: 40,
                          color: Color(0xFF213855),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                                child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    operatinModeR == 6 || operatinModeR == 2
                                        ? "PC"
                                        : operatinModeR == 7 ||
                                                operatinModeR == 1 ||
                                                operatinModeR == 5
                                            ? "Vt"
                                            : modeName == "PC-CMV" ||
                                                    modeName == "PACV"
                                                ? "PC"
                                                : modeName == "VC-CMV" ||
                                                        modeName == "VACV" ||
                                                        modeName == "VSIMV"
                                                    ? "Vt"
                                                    : "PC",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    "",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ),
                                // Align(
                                //   alignment: Alignment.centerRight,
                                //   child: Padding(
                                //     padding: const EdgeInsets.only(top: 17.0),
                                //     child: Icon(
                                //         editbbEnabled ? Icons.lock_open : Icons.lock,
                                //         color: Colors.white,
                                //         size: 15),
                                //   ),
                                // ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 17.0),
                                    child: Text(
                                      operatinModeR == 6 ||
                                              operatinModeR == 2 ||
                                              operatinModeR == 3
                                          ? psValue.toString()
                                          : operatinModeR == 7 ||
                                                  operatinModeR == 1 ||
                                                  operatinModeR == 5
                                              ? vtValue.toString()
                                              : modeName == "PC-CMV" ||
                                                      modeName == "PACV" ||
                                                      modeName == "PSV"
                                                  ? pcValue.toString()
                                                  : modeName == "VC-CMV" ||
                                                          modeName == "VACV" ||
                                                          modeName == "VSIMV"
                                                      ? vtValue.toString()
                                                      : pcValue.toString(),
                                      style: TextStyle(
                                          fontSize: 30, color: Colors.white),
                                    ),
                                  ),
                                ),
                                // Align(
                                //   alignment: Alignment.bottomCenter,
                                //   child: LinearProgressIndicator(
                                //     backgroundColor: Colors.grey,
                                //     valueColor: AlwaysStoppedAnimation<Color>(
                                //       Colors.white,
                                //     ),
                                //     value: psValue != null ? psValue / 60 : 0,
                                //   ),
                                // )
                              ],
                            )),
                          ),
                        ),
                      ),
                    ),
                  )
                : InkWell(
                    onTap: () {
                      //  CommonClick("PS") ;
                    },
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 110,
                        child: Card(
                          elevation: 40,
                          color: Color(0xFF213855),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                                child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    "PS",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    "",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 17.0),
                                    child: Text(
                                      psValue.toString(),
                                      style: TextStyle(
                                          fontSize: 30, color: Colors.white),
                                    ),
                                  ),
                                ),
                                // Align(
                                //   alignment: Alignment.bottomCenter,
                                //   child: LinearProgressIndicator(
                                //     backgroundColor: Colors.grey,
                                //     valueColor: AlwaysStoppedAnimation<Color>(
                                //       Colors.white,
                                //     ),
                                //     value: psValue != null ? psValue / 60 : 0,
                                //   ),
                                // )
                              ],
                            )),
                          ),
                        ),
                      ),
                    ),
                  ),
            operatinModeR == 4 || modeName == "PSIMV"
                ? InkWell(
                    onTap: () {
                      //  CommonClick("PS") ;
                    },
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 110,
                        child: Card(
                          elevation: 40,
                          color: Color(0xFF213855),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                                child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    "PS",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    "",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 17.0),
                                    child: Text(
                                      psValue.toString(),
                                      style: TextStyle(
                                          fontSize: 30, color: Colors.white),
                                    ),
                                  ),
                                ),
                                // Align(
                                //   alignment: Alignment.bottomCenter,
                                //   child: LinearProgressIndicator(
                                //     backgroundColor: Colors.grey,
                                //     valueColor: AlwaysStoppedAnimation<Color>(
                                //       Colors.white,
                                //     ),
                                //     value: psValue != null ? psValue / 60 : 0,
                                //   ),
                                // )
                              ],
                            )),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
            InkWell(
              onTap: () {
                // CommonClick("FiO\u2082");
              },
              child: Center(
                child: Container(
                  width: 120,
                  height: 110,
                  child: Card(
                    elevation: 40,
                    color: Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO\u2082",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "%",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                          // Align(
                          //   alignment: Alignment.centerRight,
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(top: 17.0),
                          //     child: Icon(
                          //         editbbEnabled ? Icons.lock_open : Icons.lock,
                          //         color: Colors.white,
                          //         size: 15),
                          //   ),
                          // ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 17.0),
                              child: Text(
                                fio2Value.toString(),
                                style: TextStyle(
                                    fontSize: 30, color: Colors.white),
                              ),
                            ),
                          ),
                          // Align(
                          //   alignment: Alignment.bottomCenter,
                          //   child: LinearProgressIndicator(
                          //     backgroundColor: Colors.grey,
                          //     valueColor: AlwaysStoppedAnimation<Color>(
                          //       Colors.white,
                          //     ),
                          //     value: fio2Value != null ? fio2Value / 100 : 0,
                          //   ),
                          // )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            // InkWell(
            //   onTap: () {
            //     editbbEnabled ? CommonClick("Tih") : Container();
            //   },
            //   child: Center(
            //     child: Container(
            //       width: 120,
            //       height: 110,
            //       child: Card(
            //         elevation: 40,
            //         color: Color(0xFF213855),
            //         child: Padding(
            //           padding: const EdgeInsets.all(12.0),
            //           child: Center(
            //               child: Stack(
            //             children: [
            //               Align(
            //                 alignment: Alignment.topLeft,
            //                 child: Text(
            //                   "Ti",
            //                   style: TextStyle(
            //                       fontSize: 18,
            //                       fontWeight: FontWeight.bold,
            //                       color: Colors.white),
            //                 ),
            //               ),
            //               // Align(
            //               //   alignment: Alignment.centerRight,
            //               //   child: Padding(
            //               //     padding: const EdgeInsets.only(top: 17.0),
            //               //     child: Icon(
            //               //         editbbEnabled ? Icons.lock_open : Icons.lock,
            //               //         color: Colors.white,
            //               //         size: 15),
            //               //   ),
            //               // ),
            //               Align(
            //                 alignment: Alignment.topRight,
            //                 child: Text(
            //                   "",
            //                   style:
            //                       TextStyle(fontSize: 12, color: Colors.white),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 17.0),
            //                   child: Text(
            //                     tiValue.toString(),
            //                     style: TextStyle(
            //                         fontSize: 25, color: Colors.white),
            //                   ),
            //                 ),
            //               ),
            //               // Align(
            //               //   alignment: Alignment.bottomCenter,
            //               //   child: LinearProgressIndicator(
            //               //     backgroundColor: Colors.grey,
            //               //     valueColor: AlwaysStoppedAnimation<Color>(
            //               //       Colors.white,
            //               //     ),
            //               //     value: tiValue != null ? tiValue / 75 : 0,
            //               //   ),
            //               // )
            //             ],
            //           )),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            // InkWell(
            //   onTap: () {
            //     editbbEnabled ? CommonClick("Te") : Container();
            //   },
            //   child: Center(
            //     child: Container(
            //       width: 120,
            //       height: 110,
            //       child: Card(
            //         elevation: 40,
            //         color: Color(0xFF213855),
            //         child: Padding(
            //           padding: const EdgeInsets.all(12.0),
            //           child: Center(
            //               child: Stack(
            //             children: [
            //               Align(
            //                 alignment: Alignment.topLeft,
            //                 child: Text(
            //                   "TE",
            //                   style: TextStyle(
            //                       fontSize: 18,
            //                       fontWeight: FontWeight.bold,
            //                       color: Colors.white),
            //                 ),
            //               ),
            //               // Align(
            //               //   alignment: Alignment.centerRight,
            //               //   child: Padding(
            //               //     padding: const EdgeInsets.only(top: 17.0),
            //               //     child: Icon(
            //               //         editbbEnabled ? Icons.lock_open : Icons.lock,
            //               //         color: Colors.white,
            //               //         size: 15),
            //               //   ),
            //               // ),
            //               Align(
            //                 alignment: Alignment.topRight,
            //                 child: Text(
            //                   "",
            //                   style:
            //                       TextStyle(fontSize: 12, color: Colors.white),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 17.0),
            //                   child: Text(
            //                     teValue.toString(),
            //                     style: TextStyle(
            //                         fontSize: 25, color: Colors.white),
            //                   ),
            //                 ),
            //               ),
            //               // Align(
            //               //   alignment: Alignment.bottomCenter,
            //               //   child: LinearProgressIndicator(
            //               //     backgroundColor: Colors.grey,
            //               //     valueColor: AlwaysStoppedAnimation<Color>(
            //               //       Colors.white,
            //               //     ),
            //               //     value: 60,
            //               //   ),
            //               // )
            //             ],
            //           )),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(
              width: operatinModeR == 4 || modeName == "PSIMV" ? 10 : 130,
            ),
            respiratoryEnable == true
                ? InkWell(
                    onTap: () {
                      insExpButtonEnable = !insExpButtonEnable;
                    },
                    child: Center(
                      child: Material(
                        borderRadius: BorderRadius.circular(24.0),
                        color: insExpButtonEnable ? Colors.white : Colors.green,
                        child: Container(
                          width: 160,
                          height: 110,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                                child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Respiratory \n Pause",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: insExpButtonEnable
                                            ? Colors.black
                                            : Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            )),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  topbar() {
    return Container(
      width: 904,
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: [
              Container(
                  child: Padding(
                padding: const EdgeInsets.only(
                    left: 25, right: 0, top: 4, bottom: 4),
                child: Text(
                  modeName.toString(),
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              )),
              Container(
                  child: Padding(
                padding: const EdgeInsets.only(
                    left: 10, right: 0, top: 4, bottom: 10),
                child: Text(
                  patientName.toString(),
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              )),
              SizedBox(width: 10),
              Material(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                      height: 40,
                      width: 80,
                      child: batteryStatus == 0
                          ? batteryPercentage != null
                              ? Center(
                                  child: Text(
                                      batteryPercentage.toString() + " %",
                                      style: TextStyle(fontSize: 20)))
                              : Image.asset("assets/images/nobattery.png",
                                  width: 28, color: Colors.black)
                          : batteryStatus == 1
                              ? Image.asset("assets/images/chargingbattery.png",
                                  width: 28, color: Colors.black)
                              : Image.asset("assets/images/nobattery.png",
                                  width: 28, color: Colors.black))),
              SizedBox(width: 10),
              Material(
                  borderRadius: BorderRadius.circular(5),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => SelfTestPage()),
                      );
                    },
                    child: Container(
                        height: 40,
                        width: 80,
                        child: Image.asset(
                          "assets/images/calibrate.png",
                          width: 60,
                        )),
                  )),
              SizedBox(width: 10),
              timerCounter != 0
                  ? Material(
                      borderRadius: BorderRadius.circular(14.0),
                      color: Colors.white,
                      child: Container(
                        width: 80,
                        height: 40,
                        child: Center(
                            child: timerCounter <= 9
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                        "00:0" + timerCounter.toString(),
                                        style: TextStyle(
                                            color: Colors.green, fontSize: 20)),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text("00:" + timerCounter.toString(),
                                        style: TextStyle(
                                            color: Colors.green, fontSize: 20)),
                                  )),
                      ))
                  : Material(
                      borderRadius: BorderRadius.circular(5.0),
                      color: Colors.white,
                      child: Container(
                        width: 80,
                        height: 40,
                        child: Center(
                            child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("00:00",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 20)),
                        )),
                      )),
              SizedBox(width: 10),
              Material(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                      width: 80,
                      height: 40,
                      child: Center(
                          child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(displayTemperature.toString() + "\u2103",
                            style: TextStyle(fontSize: 20)),
                      )))),
              SizedBox(width: 10),
              Material(
                  borderRadius: BorderRadius.circular(5),
                  color: powerIndication == 1
                      ? Colors.green
                      : powerIndication == 0 ? Colors.red : Colors.red,
                  child: Container(
                      width: 80,
                      height: 40,
                      child: Center(
                          child: Text("AC Power",
                              style: TextStyle(color: Colors.white))))),
            ],
          ),

          // Stack(
          //   children: [
          //     Padding(
          //       padding: const EdgeInsets.only(bottom: 6),
          //       child: Container(
          //         child: Text(
          //           dateandTime ?? "",
          //           style: TextStyle(color: Colors.white, fontSize: 15),
          //         ),
          //       ),
          //     ),
          //   ],
          // )
        ],
      ),
    );
  }

  modeDefaultSettings() {
    return Row(
      children: [
        pacvEnabled ? pacvData() : Container(),
        vacvEnabled ? vacvData() : Container(),
        pccmvEnabled ? pccmvData() : Container(),
        vccmvEnabled ? vccmvData() : Container(),
        psimvEnabled ? psimvData() : Container(),
        vsimvEnabled ? vsimvData() : Container(),
        psvEnabled ? psvData() : Container(),
        prvcEnabled ? prvcData() : Container(),
      ],
    );
  }

  psvData() {
    return Row(
      children: [
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  psvmaxValue = 60;
                  psvminValue = 1;
                  psvparameterName = "Backup RR";
                  psvparameterUnits = "bpm";
                  psvItrig = false;
                  psvPeep = false;
                  psvIe = false;
                  psvPs = false;
                  psvTi = false;
                  psvVtMin = false;
                  psvVtMax = false;
                  psvFio2 = false;
                  psvAtime = false;
                  psvEtrig = false;
                  psvFlowRamp = false;
                  psvBackupRr = true;
                  psvMinTe = false;
                });
              },
              child: Center(
                child: Container(
                  width: 130,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psvBackupRr ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Backup RR",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: psvBackupRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: psvBackupRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "60",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvBackupRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvBackupRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psvBackupRrValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psvBackupRr
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psvBackupRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psvBackupRrValue != null
                                    ? psvBackupRrValue / 60
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  psvmaxValue = 61;
                  psvminValue = 1;
                  psvparameterName = "Backup I:E";
                  psvparameterUnits = "";
                  psvItrig = false;
                  psvPeep = false;
                  psvIe = false;
                  psvPs = false;
                  psvTi = false;
                  psvVtMin = false;
                  psvVtMax = false;
                  psvFio2 = false;
                  psvAtime = false;
                  psvIe = true;
                  psvFlowRamp = false;
                  psvBackupRr = false;
                  psvMinTe = false;
                });
              },
              child: Center(
                child: Container(
                  width: 130,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psvIe ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Backup I:E",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1:4.0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "4.0:1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                // psvIeValue,
                                getIeData(psvIeValue, 1),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psvIe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psvIe ? Color(0xFF213855) : Color(0xFFE0E0E0),
                                ),
                                value: psvIeValue != null ? psvIeValue / 61 : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  psvmaxValue = 30;
                  psvminValue = 1;
                  psvparameterName = "PEEP";
                  psvparameterUnits = "";
                  psvItrig = false;
                  psvPeep = true;
                  psvIe = false;
                  psvPs = false;
                  psvTi = false;
                  psvVtMin = false;
                  psvVtMax = false;
                  psvFio2 = false;
                  psvAtime = false;
                  psvEtrig = false;
                  psvFlowRamp = false;
                  psvBackupRr = false;
                  psvMinTe = false;
                });
              },
              child: Center(
                child: Container(
                  width: 130,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psvPeep ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PEEP",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "30",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psvPeepValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psvPeep
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psvPeepValue != null
                                    ? psvPeepValue / 30
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  psvmaxValue = 30;
                  psvminValue = 5;
                  psvparameterName = "A Time";
                  psvparameterUnits = "s";
                  psvItrig = false;
                  psvPeep = false;
                  psvIe = false;
                  psvPs = false;
                  psvTi = false;
                  psvVtMin = false;
                  psvVtMax = false;
                  psvFio2 = false;
                  psvAtime = true;
                  psvEtrig = false;
                  psvFlowRamp = false;
                  psvBackupRr = false;
                  psvMinTe = false;
                });
              },
              child: Center(
                child: Container(
                  width: 130,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psvAtime ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Apena Time",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psvAtime
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "s",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvAtime
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "30",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvAtime
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "5",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvAtime
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psvAtimeValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psvAtime
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psvAtime
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psvAtimeValue != null
                                    ? psvAtimeValue / 30
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  psvmaxValue = 100;
                  psvminValue = 21;
                  psvparameterName = "FiO\u2082";
                  psvparameterUnits = "%";
                  psvItrig = false;
                  psvPeep = false;
                  psvIe = false;
                  psvPs = false;
                  psvTi = false;
                  psvVtMin = false;
                  psvVtMax = false;
                  psvFio2 = true;
                  psvAtime = false;
                  psvEtrig = false;
                  psvFlowRamp = false;
                  psvBackupRr = false;
                  psvMinTe = false;
                });
              },
              child: Center(
                child: Container(
                  width: 130,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psvFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO\u2082",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "%",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "21",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psvFio2Value.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psvFio2
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psvFio2Value != null
                                    ? psvFio2Value / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  psvmaxValue = 10;
                  psvminValue = 1;
                  psvparameterName = "I Trig";
                  psvparameterUnits = "cmH\u2082O Below PEEP";
                  psvItrig = true;
                  psvPeep = false;
                  psvIe = false;
                  psvPs = false;
                  psvTi = false;
                  psvVtMin = false;
                  psvVtMax = false;
                  psvFio2 = false;
                  psvAtime = false;
                  psvEtrig = false;
                  psvFlowRamp = false;
                  psvBackupRr = false;
                  psvMinTe = false;
                });
              },
              child: Center(
                child: Container(
                  width: 130,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psvItrig ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I Trig",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "-" + psvItrigValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psvItrig
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psvItrigValue != null
                                    ? psvItrigValue / 10
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    psvmaxValue = 1200;
                    psvminValue = 100;
                    psvparameterName = "Vt Min";
                    psvparameterUnits = "mL";
                    psvItrig = false;
                    psvPeep = false;
                    psvIe = false;
                    psvPs = false;
                    psvTi = false;
                    psvVtMin = true;
                    psvVtMax = false;
                    psvFio2 = false;
                    psvAtime = false;
                    psvEtrig = false;
                    psvBackupRr = false;
                    psvFlowRamp = false;
                    psvMinTe = false;
                  });
                },
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    child: Card(
                      elevation: 40,
                      color: psvVtMin ? Color(0xFFE0E0E0) : Color(0xFF213855),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Vt Min",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: psvVtMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                "mL",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvVtMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                "1200",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvVtMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                "100",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvVtMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0),
                                child: Text(
                                  psvVtMinValue.toString(),
                                  style: TextStyle(
                                      fontSize: 35,
                                      color: psvVtMin
                                          ? Color(0xFF213855)
                                          : Color(0xFFE0E0E0)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20.0, left: 10, right: 10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    psvVtMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0),
                                  ),
                                  value: psvVtMinValue != null
                                      ? psvVtMinValue / 1200
                                      : 0,
                                ),
                              ),
                            )
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    psvmaxValue = 1200;
                    psvminValue = 100;
                    psvparameterName = "Vt Max";
                    psvparameterUnits = "mL";
                    psvItrig = false;
                    psvPeep = false;
                    psvIe = false;
                    psvPs = false;
                    psvTi = false;
                    psvVtMin = false;
                    psvVtMax = true;
                    psvBackupRr = false;
                    psvFio2 = false;
                    psvAtime = false;
                    psvEtrig = false;
                    psvFlowRamp = false;
                    psvMinTe = false;
                  });
                },
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    child: Card(
                      elevation: 40,
                      color: psvVtMax ? Color(0xFFE0E0E0) : Color(0xFF213855),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Vt Max",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: psvVtMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                "mL",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvVtMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                "1200",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvVtMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                "100",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvVtMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0),
                                child: Text(
                                  psvVtMaxValue.toString(),
                                  style: TextStyle(
                                      fontSize: 35,
                                      color: psvVtMax
                                          ? Color(0xFF213855)
                                          : Color(0xFFE0E0E0)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20.0, left: 10, right: 10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    psvVtMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0),
                                  ),
                                  value: psvVtMaxValue != null
                                      ? psvVtMaxValue / 1200
                                      : 0,
                                ),
                              ),
                            )
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    psvmaxValue = 80;
                    psvminValue = 1;
                    psvparameterName = "PS";
                    psvparameterUnits = "cmH\u2082O";
                    psvItrig = false;
                    psvPeep = false;
                    psvIe = false;
                    psvPs = true;
                    psvTi = false;
                    psvVtMin = false;
                    psvVtMax = false;
                    psvFio2 = false;
                    psvAtime = false;
                    psvEtrig = false;
                    psvFlowRamp = false;
                    psvBackupRr = false;
                    psvMinTe = false;
                  });
                },
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    child: Card(
                      elevation: 40,
                      color: psvPs ? Color(0xFFE0E0E0) : Color(0xFF213855),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "PS",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: psvPs
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                "cmH\u2082O",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvPs
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                "80",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvPs
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                "1",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvPs
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0),
                                child: Text(
                                  psvPsValue.toString(),
                                  style: TextStyle(
                                      fontSize: 35,
                                      color: psvPs
                                          ? Color(0xFF213855)
                                          : Color(0xFFE0E0E0)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20.0, left: 10, right: 10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    psvPs
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0),
                                  ),
                                  value:
                                      psvPsValue != null ? psvPsValue / 80 : 0,
                                ),
                              ),
                            )
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
        Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    psvmaxValue = 30;
                    psvminValue = 0;
                    psvparameterName = "Ti";
                    psvparameterUnits = "s";
                    psvItrig = false;
                    psvPeep = false;
                    psvIe = false;
                    psvPs = false;
                    psvTi = true;
                    psvVtMin = false;
                    psvVtMax = false;
                    psvFio2 = false;
                    psvAtime = false;
                    psvEtrig = false;
                    psvFlowRamp = false;
                    psvBackupRr = false;
                    psvMinTe = false;
                  });
                },
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    child: Card(
                      elevation: 40,
                      color: psvTi ? Color(0xFFE0E0E0) : Color(0xFF213855),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Ti",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: psvTi
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                "s",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvTi
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                "30",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvTi
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                "0",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvTi
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0),
                                child: Text(
                                  psvTiValue.toString(),
                                  style: TextStyle(
                                      fontSize: 35,
                                      color: psvTi
                                          ? Color(0xFF213855)
                                          : Color(0xFFE0E0E0)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20.0, left: 10, right: 10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    psvTi
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0),
                                  ),
                                  value:
                                      psvTiValue != null ? psvTiValue / 60 : 0,
                                ),
                              ),
                            )
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    psvmaxValue = 5;
                    psvminValue = 1;
                    psvparameterName = "Min Te";
                    psvparameterUnits = "s";
                    psvItrig = false;
                    psvPeep = false;
                    psvIe = false;
                    psvPs = false;
                    psvTi = false;
                    psvVtMin = false;
                    psvVtMax = false;
                    psvFio2 = false;
                    psvAtime = false;
                    psvBackupRr = false;
                    psvEtrig = false;
                    psvFlowRamp = false;
                    psvMinTe = true;
                  });
                },
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    child: Card(
                      elevation: 40,
                      color: psvMinTe ? Color(0xFFE0E0E0) : Color(0xFF213855),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Min Te",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: psvMinTe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                "s",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvMinTe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                "5",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvMinTe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                "1",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: psvMinTe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0),
                                child: Text(
                                  psvMinTeValue.toString(),
                                  style: TextStyle(
                                      fontSize: 35,
                                      color: psvMinTe
                                          ? Color(0xFF213855)
                                          : Color(0xFFE0E0E0)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20.0, left: 10, right: 10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    psvMinTe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0),
                                  ),
                                  value: psvMinTeValue != null
                                      ? psvMinTeValue / 5
                                      : 0,
                                ),
                              ),
                            )
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 126,
              )
            ]),
        SizedBox(width: 118),
        Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                height: 145,
                width: 340,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Alarm Limit",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("RR"),
                                  Text("$minRrtotal-$maxRrtotal"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("Vte"),
                                    Text("$minvte-$maxvte"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("Ppeak"),
                                  Text("$minppeak-$maxppeak"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("PEEP"),
                                    Text("$minpeep-$maxpeep"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 5,
            ),
            patientId != ""
                ? Container(
                    height: 40,
                    width: 340,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFE0E0E0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("IBW : " + patientWeight.toString()),
                          Text("Ideal Vt : " +
                              (int.tryParse(patientWeight) * 6).toString() +
                              " - " +
                              (int.tryParse(patientWeight) * 8).toString())
                        ],
                      ),
                    ))
                : Container(),
            SizedBox(
              height: 5,
            ),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                width: 340,
                height: 195,
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.remove,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (psvItrig == true &&
                                    psvItrigValue != psvminValue) {
                                  setState(() {
                                    psvItrigValue = psvItrigValue - 1;
                                  });
                                } else if (psvPeep == true &&
                                    psvPeepValue != psvminValue) {
                                  setState(() {
                                    psvPeepValue = psvPeepValue - 1;
                                    if (psvItrigValue > 1 &&
                                        psvItrigValue > psvPeepValue) {
                                      psvItrigValue = psvPeepValue;
                                    }
                                  });
                                } else if (psvPs == true &&
                                    psvPsValue != psvminValue) {
                                  setState(() {
                                    psvPsValue = psvPsValue - 1;
                                  });
                                } else if (psvIe == true &&
                                    psvIeValue != psvminValue) {
                                  setState(() {
                                    psvIeValue = psvIeValue - 1;
                                  });
                                } else if (psvTi == true &&
                                    psvTiValue != psvminValue) {
                                  setState(() {
                                    psvTiValue = psvTiValue - 1;
                                  });
                                } else if (psvVtMin == true &&
                                    psvVtMinValue != psvminValue) {
                                  setState(() {
                                    psvVtMinValue = psvVtMinValue - 1;
                                    //  if (psvVtMinValue >= psvVtMaxValue) {
                                    //    psvVtMaxValue = psvVtMaxValue - 1;
                                    //  }
                                  });
                                } else if (psvVtMax == true &&
                                    psvVtMaxValue != psvVtMinValue + 1) {
                                  psvVtMaxValue = psvVtMaxValue - 1;
                                } else if (psvFio2 == true &&
                                    psvFio2Value != psvminValue) {
                                  setState(() {
                                    psvFio2Value = psvFio2Value - 1;
                                  });
                                } else if (psvFlowRamp == true &&
                                    psvFlowRampValue != psvminValue) {
                                  setState(() {
                                    psvFlowRampValue = psvFlowRampValue - 1;
                                  });
                                } else if (psvAtime == true &&
                                    psvAtimeValue != psvminValue) {
                                  setState(() {
                                    psvAtimeValue = psvAtimeValue - 1;
                                  });
                                } else if (psvEtrig == true &&
                                    psvEtrigValue != psvminValue) {
                                  setState(() {
                                    psvEtrigValue = psvEtrigValue - 1;
                                  });
                                } else if (psvBackupRr == true &&
                                    psvBackupRrValue != psvminValue) {
                                  setState(() {
                                    psvBackupRrValue = psvBackupRrValue - 1;
                                  });
                                } else if (psvMinTe == true &&
                                    psvMinTeValue != psvminValue) {
                                  setState(() {
                                    psvMinTeValue = psvMinTeValue - 1;
                                  });
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 40,
                          ),
                          Text(
                            psvparameterName,
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.normal),
                          ),
                          SizedBox(
                            width: 40,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (psvItrig == true &&
                                    psvItrigValue != psvmaxValue) {
                                  setState(() {
                                    psvItrigValue = psvItrigValue + 1;
                                    if (psvPeepValue <= psvItrigValue) {
                                      if (psvPeepValue == 0) {
                                        psvItrigValue = 1;
                                      } else {
                                        psvItrigValue = psvPeepValue;
                                      }
                                    }
                                  });
                                } else if (psvPeep == true &&
                                    psvPeepValue != psvmaxValue) {
                                  setState(() {
                                    psvPeepValue = psvPeepValue + 1;
                                  });
                                } else if (psvPs == true &&
                                    psvPsValue != psvmaxValue) {
                                  setState(() {
                                    psvPsValue = psvPsValue + 1;
                                  });
                                } else if (psvIe == true &&
                                    psvIeValue != psvmaxValue) {
                                  setState(() {
                                    psvIeValue = psvIeValue + 1;
                                  });
                                } else if (psvTi == true &&
                                    psvTiValue != psvmaxValue) {
                                  setState(() {
                                    psvTiValue = psvTiValue + 1;
                                  });
                                } else if (psvVtMin == true &&
                                    psvVtMinValue != pacvmaxValue) {
                                  setState(() {
                                    if (psvVtMaxValue < 1190) {
                                      psvVtMinValue = psvVtMinValue + 1;
                                      psvVtMaxValue = psvVtMinValue + 1;
                                    }
                                  });
                                } else if (psvVtMax == true &&
                                    psvVtMaxValue != pacvmaxValue) {
                                  setState(() {
                                    psvVtMaxValue = psvVtMaxValue + 1;
                                  });
                                } else if (psvFio2 == true &&
                                    psvFio2Value != psvmaxValue) {
                                  setState(() {
                                    psvFio2Value = psvFio2Value + 1;
                                  });
                                } else if (psvFlowRamp == true &&
                                    psvFlowRampValue != psvmaxValue) {
                                  setState(() {
                                    psvFlowRampValue = psvFlowRampValue + 1;
                                  });
                                } else if (psvAtime == true &&
                                    psvAtimeValue != psvmaxValue) {
                                  setState(() {
                                    psvAtimeValue = psvAtimeValue + 1;
                                  });
                                } else if (psvEtrig == true &&
                                    psvEtrigValue != psvmaxValue) {
                                  setState(() {
                                    psvEtrigValue = psvEtrigValue + 1;
                                  });
                                } else if (psvBackupRr == true &&
                                    psvBackupRrValue != psvmaxValue) {
                                  setState(() {
                                    psvBackupRrValue = psvBackupRrValue + 1;
                                  });
                                } else if (psvMinTe == true &&
                                    psvMinTeValue != psvmaxValue) {
                                  setState(() {
                                    psvMinTeValue = psvMinTeValue + 1;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              psvItrig
                                  ? "-" + psvItrigValue.toInt().toString()
                                  : psvPeep
                                      ? psvPeepValue.toInt().toString()
                                      : psvPs
                                          ? psvPsValue.toInt().toString()
                                          : psvIe
                                              // ? psvIeValue.toInt().toString()
                                              ? getIeData(psvIeValue, 1)
                                              : psvTi
                                                  ? psvTiValue
                                                      .toInt()
                                                      .toString()
                                                  : psvVtMin
                                                      ? psvVtMinValue
                                                          .toInt()
                                                          .toString()
                                                      : psvVtMax
                                                          ? psvVtMaxValue
                                                              .toInt()
                                                              .toString()
                                                          : psvFio2
                                                              ? psvFio2Value
                                                                  .toInt()
                                                                  .toString()
                                                              : psvFlowRamp
                                                                  ? psvFlowRampValue
                                                                      .toInt()
                                                                      .toString()
                                                                  : psvAtime
                                                                      ? psvAtimeValue
                                                                          .toInt()
                                                                          .toString()
                                                                      : psvEtrig
                                                                          ? psvEtrigValue
                                                                              .toInt()
                                                                              .toString()
                                                                          : psvBackupRr
                                                                              ? psvBackupRrValue.toInt().toString()
                                                                              : psvMinTe ? psvMinTeValue.toInt().toString() : "",
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Container(
                          width: 350,
                          child: Slider(
                            min: psvminValue.toDouble(),
                            max: psvmaxValue.toDouble(),
                            onChanged: (double value) {
                              if (psvItrig == true && psvItrigValue != 10) {
                                setState(() {
                                  psvItrigValue = psvItrigValue + 1;
                                  if (psvPeepValue <= psvItrigValue) {
                                    if (psvPeepValue == 0) {
                                      psvItrigValue = 1;
                                    } else {
                                      psvItrigValue = psvPeepValue;
                                    }
                                  }
                                });
                              } else if (psvPeep == true) {
                                setState(() {
                                  psvPeepValue = value.toInt();
                                  if (psvItrigValue > 1 &&
                                      psvItrigValue > psvPeepValue) {
                                    psvItrigValue = psvPeepValue;
                                  }
                                });
                              } else if (psvPs == true) {
                                setState(() {
                                  psvPsValue = value.toInt();
                                });
                              } else if (psvIe == true) {
                                setState(() {
                                  psvIeValue = value.toInt();
                                });
                              } else if (psvTi == true) {
                                setState(() {
                                  psvTiValue = value.toInt();
                                });
                              } else if (psvVtMin == true) {
                                if (value.toInt() < 1190) {
                                  psvVtMinValue = value.toInt();
                                  psvVtMaxValue = psvVtMinValue + 1;
                                }
                              } else if (psvVtMax == true) {
                                setState(() {
                                  if (value.toInt() <= psvVtMinValue + 1) {
                                    psvVtMaxValue = psvVtMinValue + 1;
                                  } else {
                                    psvVtMaxValue = value.toInt();
                                  }
                                });
                              } else if (psvFio2 == true) {
                                setState(() {
                                  psvFio2Value = value.toInt();
                                });
                              } else if (psvFlowRamp == true) {
                                setState(() {
                                  psvFlowRampValue = value.toInt();
                                });
                              } else if (psvEtrig == true) {
                                setState(() {
                                  psvEtrigValue = value.toInt();
                                });
                              } else if (psvAtime == true) {
                                setState(() {
                                  psvAtimeValue = value.toInt();
                                });
                              } else if (psvBackupRr == true) {
                                setState(() {
                                  psvBackupRrValue = value.toInt();
                                });
                              } else if (psvMinTe == true) {
                                setState(() {
                                  psvMinTeValue = value.toInt();
                                });
                              }
                            },
                            value: psvItrig
                                ? psvItrigValue.toDouble()
                                : psvPeep
                                    ? psvPeepValue.toDouble()
                                    : psvPs
                                        ? psvPsValue.toDouble()
                                        : psvIe
                                            ? psvIeValue.toDouble()
                                            : psvTi
                                                ? psvTiValue.toDouble()
                                                : psvVtMin
                                                    ? psvVtMinValue.toDouble()
                                                    : psvVtMax
                                                        ? psvVtMaxValue
                                                            .toDouble()
                                                        : psvFio2
                                                            ? psvFio2Value
                                                                .toDouble()
                                                            : psvFlowRamp
                                                                ? psvFlowRampValue
                                                                    .toDouble()
                                                                : psvEtrig
                                                                    ? psvEtrigValue
                                                                        .toDouble()
                                                                    : psvAtime
                                                                        ? psvAtimeValue
                                                                            .toDouble()
                                                                        : psvBackupRr
                                                                            ? psvBackupRrValue
                                                                                .toDouble()
                                                                            : psvMinTe
                                                                                ? psvMinTeValue.toDouble()
                                                                                : "",
                          )),
                      SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45.0, right: 45.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(psvIe
                                ? getIeData(psvminValue, 1)
                                : psvItrig
                                    ? "-" + psvminValue.toString()
                                    : psvminValue.toString()),
                            Text(
                              psvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(psvIe
                                ? getIeData(psvmaxValue, 1)
                                : psvItrig
                                    ? "-" + psvmaxValue.toString()
                                    : psvmaxValue.toString())
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  pacvData() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  pacvmaxValue = 60;
                  pacvminValue = 1;
                  pacvparameterName = "RR";
                  pacvparameterUnits = "bpm";
                  pacvItrig = false;
                  pacvRr = true;
                  pacvIe = false;
                  pacvPeep = false;
                  pacvPc = false;
                  pacvVtMin = false;
                  pacvVtMax = false;
                  pacvFio2 = false;
                  pacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pacvRr ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "RR",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "60",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pacvRrValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pacvRr
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value:
                                    pacvRrValue != null ? pacvRrValue / 60 : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  pacvmaxValue = 61;
                  pacvminValue = 1;
                  pacvparameterName = "I:E";
                  pacvparameterUnits = "";
                  pacvItrig = false;
                  pacvRr = false;
                  pacvIe = true;
                  pacvPeep = false;
                  pacvPc = false;
                  pacvVtMin = false;
                  pacvVtMax = false;
                  pacvFio2 = false;
                  pacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pacvIe ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I:E",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1:4.0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "4.0:1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                getIeData(pacvIeValue, 1),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pacvIe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value:
                                    pacvIeValue != null ? pacvIeValue / 61 : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  pacvmaxValue = 30;
                  pacvminValue = 0;
                  pacvparameterName = "PEEP";
                  pacvparameterUnits = "cmH\u2082O";
                  pacvItrig = false;
                  pacvRr = false;
                  pacvIe = false;
                  pacvPeep = true;
                  pacvPc = false;
                  pacvVtMin = false;
                  pacvVtMax = false;
                  pacvFio2 = false;
                  pacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pacvPeep ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PEEP",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "30",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pacvPeepValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pacvPeep
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pacvPeepValue != null
                                    ? pacvPeepValue / 30
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  pacvmaxValue = 10;
                  pacvminValue = 1;
                  pacvparameterName = "I Trig";
                  pacvparameterUnits = "cmH\u2082O Below PEEP";
                  pacvItrig = true;
                  pacvRr = false;
                  pacvIe = false;
                  pacvPeep = false;
                  pacvPc = false;
                  pacvVtMin = false;
                  pacvVtMax = false;
                  pacvFio2 = false;
                  pacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pacvItrig ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I Trig",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "-10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "-1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "-" + pacvItrigValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pacvItrig
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pacvItrigValue != null
                                    ? pacvItrigValue / 10
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  pacvmaxValue = 80;
                  pacvminValue = 1;
                  pacvparameterName = "PC";
                  pacvparameterUnits = "cmH\u2082O";
                  pacvItrig = false;
                  pacvRr = false;
                  pacvIe = false;
                  pacvPeep = false;
                  pacvPc = true;
                  pacvVtMin = false;
                  pacvVtMax = false;
                  pacvFio2 = false;
                  pacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pacvPc ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pacvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "80",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pacvPcValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pacvPc
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pacvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value:
                                    pacvPcValue != null ? pacvPcValue / 80 : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  pacvmaxValue = 100;
                  pacvminValue = 21;
                  pacvparameterName = "FiO\u2082";
                  pacvparameterUnits = "%";
                  pacvItrig = false;
                  pacvRr = false;
                  pacvIe = false;
                  pacvPeep = false;
                  pacvPc = false;
                  pacvVtMin = false;
                  pacvVtMax = false;
                  pacvFio2 = true;
                  pacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pacvFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO\u2082",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "%",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "21",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pacvFio2Value.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pacvFio2
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pacvFio2Value != null
                                    ? pacvFio2Value / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  pacvmaxValue = 1200;
                  pacvminValue = 100;
                  pacvparameterName = "Vt Min";
                  pacvparameterUnits = "mL";
                  pacvItrig = false;
                  pacvRr = false;
                  pacvIe = false;
                  pacvPeep = false;
                  pacvPc = false;
                  pacvVtMin = true;
                  pacvVtMax = false;
                  pacvFio2 = false;
                  pacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pacvVtMin ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Vt Min",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pacvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pacvVtMinValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pacvVtMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pacvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pacvVtMinValue != null
                                    ? pacvVtMinValue / 1200
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  pacvmaxValue = 1200;
                  pacvminValue = 100;
                  pacvparameterName = "Vt Max";
                  pacvparameterUnits = "mL";
                  pacvItrig = false;
                  pacvRr = false;
                  pacvIe = false;
                  pacvPeep = false;
                  pacvPc = false;
                  pacvVtMin = false;
                  pacvVtMax = true;
                  pacvFio2 = false;
                  pacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pacvVtMax ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Vt Max",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pacvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pacvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pacvVtMaxValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pacvVtMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pacvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pacvVtMaxValue != null
                                    ? pacvVtMaxValue / 1200
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),

            // InkWell(
            //   onTap: () {
            //     setState(() {
            //       pacvmaxValue = 4;
            //       pacvminValue = 0;
            //       pacvparameterName = "Flow Ramp";
            //       pacvparameterUnits = "";
            //       pacvItrig = false;
            //       pacvRr = false;
            //       pacvIe = false;
            //       pacvPeep = false;
            //       pacvPc = false;
            //       pacvVtMin = false;
            //       pacvVtMax = false;
            //       pacvFio2 = false;
            //       pacvFlowRamp = true;
            //     });
            //   },
            //   child: Center(
            //     child: Container(
            //       width: 146,
            //       height: 130,
            //       child: Card(
            //         elevation: 40,
            //         color: pacvFlowRamp ? Color(0xFFE0E0E0) : Color(0xFF213855),
            //         child: Padding(
            //           padding: const EdgeInsets.all(6.0),
            //           child: Center(
            //               child: Stack(
            //             children: [
            //               Align(
            //                 alignment: Alignment.topLeft,
            //                 child: Text(
            //                   "Flow Ramp",
            //                   style: TextStyle(
            //                       fontSize: 15,
            //                       fontWeight: FontWeight.bold,
            //                       color: pacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.topRight,
            //                 child: Text(
            //                   "",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: pacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomRight,
            //                 child: Text(
            //                   "4",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: pacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomLeft,
            //                 child: Text(
            //                   "0",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: pacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 1.0),
            //                   child: Text(
            //                     pacvFlowRampValue.toString() == "0"
            //                         ? "AF"
            //                         : pacvFlowRampValue.toString() == "1"
            //                             ? "AS"
            //                             : pacvFlowRampValue.toString() == "2"
            //                                 ? "DF"
            //                                 : pacvFlowRampValue.toString() ==
            //                                         "3"
            //                                     ? "DS"
            //                                     : pacvFlowRampValue
            //                                                 .toString() ==
            //                                             "4"
            //                                         ? "S"
            //                                         : "S",
            //                     style: TextStyle(
            //                         fontSize: 35,
            //                         color: pacvFlowRamp
            //                             ? Color(0xFF213855)
            //                             : Color(0xFFE0E0E0)),
            //                   ),
            //                 ),
            //               ),
            //               Padding(
            //                 padding: const EdgeInsets.only(
            //                     bottom: 20.0, left: 10, right: 10),
            //                 child: Align(
            //                   alignment: Alignment.bottomCenter,
            //                   child: LinearProgressIndicator(
            //                     backgroundColor: Colors.grey,
            //                     valueColor: AlwaysStoppedAnimation<Color>(
            //                       pacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0),
            //                     ),
            //                     value: pacvFlowRampValue != null
            //                         ? pacvFlowRampValue / 4
            //                         : 0,
            //                   ),
            //                 ),
            //               )
            //             ],
            //           )),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
        SizedBox(width: 140),
        Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                height: 145,
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Alarm Limit",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("RR"),
                                  Text("$minRrtotal-$maxRrtotal"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("Vte"),
                                    Text("$minvte-$maxvte"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("Ppeak"),
                                  Text("$minppeak-$maxppeak"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("PEEP"),
                                    Text("$minpeep-$maxpeep"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 5,
            ),
            patientId != ""
                ? Container(
                    height: 40,
                    width: 400,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFE0E0E0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("IBW : " + patientWeight.toString()),
                          Text("Ideal Vt : " +
                              (int.tryParse(patientWeight) * 6).toString() +
                              " - " +
                              (int.tryParse(patientWeight) * 8).toString())
                        ],
                      ),
                    ))
                : Container(),
            SizedBox(
              height: 5,
            ),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                width: 400,
                height: 195,
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.remove,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (pacvItrig == true &&
                                    pacvItrigValue != pacvminValue) {
                                  setState(() {
                                    pacvItrigValue = pacvItrigValue - 1;
                                  });
                                } else if (pacvPeep == true &&
                                    pacvPeepValue != pacvminValue) {
                                  setState(() {
                                    pacvPeepValue = pacvPeepValue - 1;
                                    if (pacvItrigValue > 1 &&
                                        pacvItrigValue > pacvPeepValue) {
                                      pacvItrigValue = pacvPeepValue;
                                    }
                                  });
                                } else if (pacvRr == true &&
                                    pacvRrValue != pacvminValue) {
                                  setState(() {
                                    pacvRrValue = pacvRrValue - 1;
                                  });
                                } else if (pacvIe == true &&
                                    pacvIeValue != pacvminValue) {
                                  setState(() {
                                    pacvIeValue = pacvIeValue - 1;
                                  });
                                } else if (pacvPc == true &&
                                    pacvPcValue != pacvminValue) {
                                  setState(() {
                                    pacvPcValue = pacvPcValue - 1;
                                  });
                                } else if (pacvVtMin == true &&
                                    pacvVtMinValue != pacvminValue) {
                                  setState(() {
                                    pacvVtMinValue = pacvVtMinValue - 1;
                                  });
                                } else if (pacvVtMax == true &&
                                    pacvVtMaxValue != pacvVtMinValue + 1) {
                                  pacvVtMaxValue = pacvVtMaxValue - 1;
                                } else if (pacvFio2 == true &&
                                    pacvFio2Value != pacvminValue) {
                                  setState(() {
                                    pacvFio2Value = pacvFio2Value - 1;
                                  });
                                } else if (pacvFlowRamp == true &&
                                    pacvFlowRampValue != pacvminValue) {
                                  setState(() {
                                    pacvFlowRampValue = pacvFlowRampValue - 1;
                                  });
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          Text(
                            pacvparameterName,
                            style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.normal),
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (pacvItrig == true &&
                                    pacvItrigValue != pacvmaxValue) {
                                  setState(() {
                                    pacvItrigValue = pacvItrigValue + 1;
                                    if (pacvPeepValue <= pacvItrigValue) {
                                      if (pacvPeepValue == 0) {
                                        pacvItrigValue = 1;
                                      } else {
                                        pacvItrigValue = pacvPeepValue;
                                      }
                                    }
                                  });
                                } else if (pacvPeep == true &&
                                    pacvPeepValue != pacvmaxValue) {
                                  setState(() {
                                    pacvPeepValue = pacvPeepValue + 1;
                                    // if (pacvPcValue <= pacvPeepValue) {
                                    //   pacvPcValue = pacvPeepValue + 1;
                                    // }
                                  });
                                } else if (pacvRr == true &&
                                    pacvRrValue != pacvmaxValue) {
                                  setState(() {
                                    pacvRrValue = pacvRrValue + 1;
                                  });
                                } else if (pacvIe == true &&
                                    pacvIeValue != pacvmaxValue) {
                                  setState(() {
                                    pacvIeValue = pacvIeValue + 1;
                                  });
                                } else if (pacvPc == true &&
                                    pacvPcValue != pacvmaxValue) {
                                  setState(() {
                                    pacvPcValue = pacvPcValue + 1;
                                  });
                                } else if (pacvVtMin == true &&
                                    pacvVtMinValue != pacvmaxValue) {
                                  setState(() {
                                    if (pacvVtMaxValue < 1190) {
                                      pacvVtMinValue = pacvVtMinValue + 1;
                                      pacvVtMaxValue = pacvVtMinValue + 1;
                                    }
                                  });
                                } else if (pacvVtMax == true &&
                                    pacvVtMaxValue != pacvmaxValue) {
                                  setState(() {
                                    pacvVtMaxValue = pacvVtMaxValue + 1;
                                  });
                                } else if (pacvFio2 == true &&
                                    pacvFio2Value != pacvmaxValue) {
                                  setState(() {
                                    pacvFio2Value = pacvFio2Value + 1;
                                  });
                                } else if (pacvFlowRamp == true &&
                                    pacvFlowRampValue != pacvmaxValue) {
                                  setState(() {
                                    pacvFlowRampValue = pacvFlowRampValue + 1;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              pacvItrig
                                  ? "-" + pacvItrigValue.toInt().toString()
                                  : pacvPeep
                                      ? pacvPeepValue.toInt().toString()
                                      : pacvRr
                                          ? pacvRrValue.toInt().toString()
                                          : pacvIe
                                              ? getIeData(pacvIeValue, 1)
                                              : pacvPc
                                                  ? pacvPcValue
                                                      .toInt()
                                                      .toString()
                                                  : pacvVtMin
                                                      ? pacvVtMinValue
                                                          .toInt()
                                                          .toString()
                                                      : pacvVtMax
                                                          ? pacvVtMaxValue
                                                              .toInt()
                                                              .toString()
                                                          : pacvFio2
                                                              ? pacvFio2Value
                                                                  .toInt()
                                                                  .toString()
                                                              : pacvFlowRamp
                                                                  ? pacvFlowRampValue
                                                                      .toInt()
                                                                      .toString()
                                                                  : "",
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      // pacvFio2
                      //     ? Container()
                      //     :
                      Container(
                          width: 350,
                          child: Slider(
                            min: pacvminValue.toDouble() ?? 0,
                            max: pacvmaxValue.toDouble() ?? 0,
                            onChanged: (double value) {
                              if (pacvItrig == true &&
                                  pacvItrigValue != pacvPeepValue) {
                                setState(() {
                                  pacvItrigValue = value.toInt();
                                  if (pacvPeepValue <= pacvItrigValue) {
                                    if (pacvPeepValue == 0) {
                                      pacvItrigValue = 1;
                                    } else {
                                      pacvItrigValue = pacvPeepValue;
                                    }
                                  }
                                });
                              } else if (pacvPeep == true) {
                                pacvPeepValue = value.toInt();
                                if (pacvItrigValue > 1 &&
                                    pacvItrigValue > pacvPeepValue) {
                                  pacvItrigValue = pacvPeepValue;
                                }
                              } else if (pacvRr == true) {
                                setState(() {
                                  pacvRrValue = value.toInt();
                                });
                              } else if (pacvIe == true) {
                                setState(() {
                                  pacvIeValue = value.toInt();
                                });
                              } else if (pacvPc == true) {
                                setState(() {
                                  pacvPcValue = value.toInt();
                                });
                              } else if (pacvVtMin == true) {
                                if (value.toInt() < 1190) {
                                  pacvVtMinValue = value.toInt();
                                  pacvVtMaxValue = pacvVtMinValue + 1;
                                }
                              } else if (pacvVtMax == true) {
                                setState(() {
                                  if (value.toInt() <= pacvVtMinValue + 1) {
                                    pacvVtMaxValue = pacvVtMinValue + 1;
                                  } else {
                                    pacvVtMaxValue = value.toInt();
                                  }
                                });
                              } else if (pacvFio2 == true) {
                                setState(() {
                                  pacvFio2Value = value.toInt();
                                });
                              } else if (pacvFlowRamp == true) {
                                setState(() {
                                  pacvFlowRampValue = value.toInt();
                                });
                              }
                            },
                            value: pacvItrig
                                ? pacvItrigValue.toDouble()
                                : pacvPeep
                                    ? pacvPeepValue.toDouble()
                                    : pacvRr
                                        ? pacvRrValue.toDouble()
                                        : pacvIe
                                            ? pacvIeValue.toDouble()
                                            : pacvPc
                                                ? pacvPcValue.toDouble()
                                                : pacvVtMin
                                                    ? pacvVtMinValue.toDouble()
                                                    : pacvVtMax
                                                        ? pacvVtMaxValue
                                                            .toDouble()
                                                        : pacvFio2
                                                            ? pacvFio2Value
                                                                .toDouble()
                                                            : pacvFlowRamp
                                                                ? pacvFlowRampValue
                                                                    .toDouble()
                                                                : "",
                          )),
                      SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45.0, right: 45.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(pacvIe
                                ? getIeData(pacvminValue, 1)
                                : pacvItrig
                                    ? "-" + pacvminValue.toString()
                                    : pacvminValue.toString()),
                            Text(
                              pacvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(pacvIe
                                ? getIeData(pacvmaxValue, 1)
                                : pacvItrig
                                    ? "-" + pacvmaxValue.toString()
                                    : pacvmaxValue.toString()),
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  prvcData() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 60;
                  vacvminValue = 1;
                  vacvparameterName = "RR";
                  vacvparameterUnits = "bpm";
                  vacvItrig = false;
                  vacvRr = true;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvRr ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "RR",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "60",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvRrValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvRr
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value:
                                    vacvRrValue != null ? vacvRrValue / 60 : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 61;
                  vacvminValue = 1;
                  vacvparameterName = "I:E";
                  vacvparameterUnits = "";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = true;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvIe ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I:E",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1:4.0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "4.0:1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                // vacvIeValue,
                                getIeData(vacvIeValue, 1),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvIe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value:
                                    vacvIeValue != null ? vacvIeValue / 4 : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 30;
                  vacvminValue = 0;
                  vacvparameterName = "PEEP";
                  vacvparameterUnits = "cmH\u2082O";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = true;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvPeep ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PEEP",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "30",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvPeepValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvPeep
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvPeepValue != null
                                    ? vacvPeepValue / 30
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 1200;
                  vacvminValue = 200;
                  vacvparameterName = "Vt";
                  vacvparameterUnits = "mL";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = true;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvVt ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Vt",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvVtValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvVt
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvVtValue != null
                                    ? vacvVtValue / 1200
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 100;
                  vacvminValue = 21;
                  vacvparameterName = "FiO\u2082";
                  vacvparameterUnits = "%";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = true;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO\u2082",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "%",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "21",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvFio2Value.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvFio2
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvFio2Value != null
                                    ? vacvFio2Value / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 10;
                  vacvminValue = 1;
                  vacvparameterName = "I Trig";
                  vacvparameterUnits = "cmH\u2082O Below PEEP";
                  vacvItrig = true;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvItrig ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I Trig",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "-10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "-1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "-" + vacvItrigValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvItrig
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvItrigValue != null
                                    ? vacvItrigValue / 10
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 100;
                  vacvminValue = 10;
                  vacvparameterName = "PC Min";
                  vacvparameterUnits = "cmH\u2082O";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = true;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvPcMin ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC Min",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvPcMinValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvPcMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvPcMinValue != null
                                    ? vacvPcMinValue / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 100;
                  vacvminValue = 10;
                  vacvparameterName = "PC Max";
                  vacvparameterUnits = "cmH\u2082O";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = true;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvPcMax ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC Max",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvPcMaxValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvPcMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvPcMaxValue != null
                                    ? vacvPcMaxValue / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),

            // InkWell(
            //   onTap: () {
            //     setState(() {
            //       vacvmaxValue = 4;
            //       vacvminValue = 0;
            //       vacvparameterName = "Flow Ramp";
            //       vacvparameterUnits = "";
            //       vacvItrig = false;
            //       vacvRr = false;
            //       vacvIe = false;
            //       vacvPeep = false;
            //       vacvVt = false;
            //       vacvPcMin = false;
            //       vacvPcMax = false;
            //       vacvFio2 = false;
            //       vacvFlowRamp = true;
            //     });
            //   },
            //   child: Center(
            //     child: Container(
            //       width: 146,
            //       height: 130,
            //       child: Card(
            //         elevation: 40,
            //         color: vacvFlowRamp ? Color(0xFFE0E0E0) : Color(0xFF213855),
            //         child: Padding(
            //           padding: const EdgeInsets.all(6.0),
            //           child: Center(
            //               child: Stack(
            //             children: [
            //               Align(
            //                 alignment: Alignment.topLeft,
            //                 child: Text(
            //                   "Flow Ramp",
            //                   style: TextStyle(
            //                       fontSize: 15,
            //                       fontWeight: FontWeight.bold,
            //                       color: vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.topRight,
            //                 child: Text(
            //                   "",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomRight,
            //                 child: Text(
            //                   "4",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomLeft,
            //                 child: Text(
            //                   "0",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 1.0),
            //                   child: Text(
            //                     vacvFlowRampValue.toString() == "0"
            //                         ? "AF"
            //                         : vacvFlowRampValue.toString() == "1"
            //                             ? "AS"
            //                             : vacvFlowRampValue.toString() == "2"
            //                                 ? "DF"
            //                                 : vacvFlowRampValue.toString() ==
            //                                         "3"
            //                                     ? "DS"
            //                                     : vacvFlowRampValue
            //                                                 .toString() ==
            //                                             "4"
            //                                         ? "S"
            //                                         : "S",
            //                     style: TextStyle(
            //                         fontSize: 35,
            //                         color: vacvFlowRamp
            //                             ? Color(0xFF213855)
            //                             : Color(0xFFE0E0E0)),
            //                   ),
            //                 ),
            //               ),
            //               Padding(
            //                 padding: const EdgeInsets.only(
            //                     bottom: 20.0, left: 10, right: 10),
            //                 child: Align(
            //                   alignment: Alignment.bottomCenter,
            //                   child: LinearProgressIndicator(
            //                     backgroundColor: Colors.grey,
            //                     valueColor: AlwaysStoppedAnimation<Color>(
            //                       vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0),
            //                     ),
            //                     value: vacvFlowRampValue != null
            //                         ? vacvFlowRampValue / 4
            //                         : 0,
            //                   ),
            //                 ),
            //               )
            //             ],
            //           )),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            // Container(
            //   width: 146,
            // )
          ],
        ),
        SizedBox(width: 140),
        Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                height: 145,
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Alarm Limit",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("RR"),
                                  Text("$minRrtotal-$maxRrtotal"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("Vte"),
                                    Text("$minvte-$maxvte"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("Ppeak"),
                                  Text("$minppeak-$maxppeak"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("PEEP"),
                                    Text("$minpeep-$maxpeep"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 5,
            ),
            patientId != ""
                ? Container(
                    height: 40,
                    width: 400,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFE0E0E0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("IBW : " + patientWeight.toString()),
                          Text("Ideal Vt : " +
                              (int.tryParse(patientWeight) * 6).toString() +
                              " - " +
                              (int.tryParse(patientWeight) * 8).toString())
                        ],
                      ),
                    ))
                : Container(),
            SizedBox(
              height: 5,
            ),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                width: 400,
                height: 195,
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.remove,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (vacvItrig == true &&
                                    vacvItrigValue != vacvminValue) {
                                  setState(() {
                                    vacvItrigValue = vacvItrigValue - 1;
                                  });
                                } else if (vacvPeep == true &&
                                    vacvPeepValue != vacvminValue) {
                                  setState(() {
                                    vacvPeepValue = vacvPeepValue - 1;
                                    if (vacvItrigValue > 1 &&
                                        vacvItrigValue > vacvPeepValue) {
                                      vacvItrigValue = vacvPeepValue;
                                    }
                                  });
                                } else if (vacvRr == true &&
                                    vacvRrValue != vacvminValue) {
                                  setState(() {
                                    vacvRrValue = vacvRrValue - 1;
                                  });
                                } else if (vacvIe == true &&
                                    vacvIeValue != vacvminValue) {
                                  setState(() {
                                    vacvIeValue = vacvIeValue - 1;
                                  });
                                } else if (vacvVt == true &&
                                    vacvVtValue != vacvminValue) {
                                  setState(() {
                                    vacvVtValue = vacvVtValue - 1;
                                  });
                                } else if (vacvPcMin == true &&
                                    vacvPcMinValue != vacvminValue) {
                                  setState(() {
                                    vacvPcMinValue = vacvPcMinValue - 1;
                                    // if (vacvPcMinValue >= vacvPcMaxValue) {
                                    //   vacvPcMaxValue = vacvPcMaxValue - 1;
                                    // }
                                  });
                                } else if (vacvPcMax == true &&
                                    vacvPcMaxValue != vacvPcMinValue + 1) {
                                  vacvPcMaxValue = vacvPcMaxValue - 1;
                                } else if (vacvFio2 == true &&
                                    vacvFio2Value != vacvminValue) {
                                  setState(() {
                                    vacvFio2Value = vacvFio2Value - 1;
                                  });
                                } else if (vacvFlowRamp == true &&
                                    vacvFlowRampValue != vacvminValue) {
                                  setState(() {
                                    vacvFlowRampValue = vacvFlowRampValue - 1;
                                  });
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          Text(
                            vacvparameterName,
                            style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.normal),
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (vacvItrig == true &&
                                    vacvItrigValue != vacvmaxValue) {
                                  setState(() {
                                    vacvItrigValue = vacvItrigValue + 1;
                                    if (vacvPeepValue <= vacvItrigValue) {
                                      if (vacvPeepValue == 0) {
                                        vacvItrigValue = 1;
                                      } else {
                                        vacvItrigValue = vacvPeepValue;
                                      }
                                    }
                                  });
                                } else if (vacvPeep == true &&
                                    vacvPeepValue != vacvmaxValue) {
                                  setState(() {
                                    vacvPeepValue = vacvPeepValue + 1;
                                    // if (vacvPcMinValue <= vacvPeepValue) {
                                    //   vacvPcMinValue = vacvPeepValue + 1;
                                    //   if (vacvPcMaxValue <= vacvPcMinValue) {
                                    //     vacvPcMaxValue = vacvPcMinValue + 1;
                                    //   }
                                    // }
                                  });
                                } else if (vacvRr == true &&
                                    vacvRrValue != vacvmaxValue) {
                                  setState(() {
                                    vacvRrValue = vacvRrValue + 1;
                                  });
                                } else if (vacvIe == true &&
                                    vacvIeValue != vacvmaxValue) {
                                  setState(() {
                                    vacvIeValue = vacvIeValue + 1;
                                  });
                                } else if (vacvVt == true &&
                                    vacvVtValue != vacvmaxValue) {
                                  setState(() {
                                    vacvVtValue = vacvVtValue + 1;
                                  });
                                } else if (vacvPcMin == true &&
                                    vacvPcMinValue != vacvmaxValue) {
                                  setState(() {
                                    if (vacvPcMaxValue < 90) {
                                      vacvPcMinValue = vacvPcMinValue + 1;
                                      vacvPcMaxValue = vacvPcMinValue + 1;
                                    }
                                  });
                                } else if (vacvPcMax == true &&
                                    vacvPcMaxValue != vacvmaxValue) {
                                  setState(() {
                                    vacvPcMaxValue = vacvPcMaxValue + 1;
                                  });
                                } else if (vacvFio2 == true &&
                                    vacvFio2Value != vacvmaxValue) {
                                  setState(() {
                                    vacvFio2Value = vacvFio2Value + 1;
                                  });
                                } else if (vacvFlowRamp == true &&
                                    vacvFlowRampValue != vacvmaxValue) {
                                  setState(() {
                                    vacvFlowRampValue = vacvFlowRampValue + 1;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              vacvItrig
                                  ? "-" + vacvItrigValue.toInt().toString()
                                  : vacvPeep
                                      ? vacvPeepValue.toInt().toString()
                                      : vacvRr
                                          ? vacvRrValue.toInt().toString()
                                          : vacvIe
                                              ? getIeData(vacvIeValue, 1)
                                              : vacvVt
                                                  ? vacvVtValue
                                                      .toInt()
                                                      .toString()
                                                  : vacvPcMin
                                                      ? vacvPcMinValue
                                                          .toInt()
                                                          .toString()
                                                      : vacvPcMax
                                                          ? vacvPcMaxValue
                                                              .toInt()
                                                              .toString()
                                                          : vacvFio2
                                                              ? vacvFio2Value
                                                                  .toInt()
                                                                  .toString()
                                                              : vacvFlowRamp
                                                                  ? vacvFlowRampValue
                                                                      .toInt()
                                                                      .toString()
                                                                  : "",
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      // vacvFio2
                      //     ? Container()
                      //     :
                      Container(
                          width: 350,
                          child: Slider(
                            min: vacvminValue.toDouble(),
                            max: vacvmaxValue.toDouble(),
                            onChanged: (double value) {
                              if (vacvItrig == true && vacvItrigValue != 10) {
                                setState(() {
                                  vacvItrigValue = vacvItrigValue + 1;
                                  if (vacvPeepValue <= vacvItrigValue) {
                                    if (vacvPeepValue == 0) {
                                      vacvItrigValue = 1;
                                    } else {
                                      vacvItrigValue = vacvPeepValue;
                                    }
                                  }
                                });
                              } else if (vacvPeep == true) {
                                setState(() {
                                  vacvPeepValue = value.toInt();
                                  if (vacvItrigValue > 1 &&
                                      vacvItrigValue > vacvPeepValue) {
                                    vacvItrigValue = vacvPeepValue;
                                  }
                                });
                              } else if (vacvRr == true) {
                                setState(() {
                                  vacvRrValue = value.toInt();
                                });
                              } else if (vacvIe == true) {
                                setState(() {
                                  vacvIeValue = value.toInt();
                                });
                              } else if (vacvVt == true) {
                                setState(() {
                                  vacvVtValue = value.toInt();
                                });
                              } else if (vacvPcMin == true) {
                                if (value.toInt() < 90) {
                                  vacvPcMinValue = value.toInt();
                                  vacvPcMaxValue = vacvPcMinValue + 1;
                                }
                              } else if (vacvPcMax == true) {
                                setState(() {
                                  if (value.toInt() <= vacvPcMinValue + 1) {
                                    vacvPcMaxValue = vacvPcMinValue + 1;
                                  } else {
                                    vacvPcMaxValue = value.toInt();
                                  }
                                });
                              } else if (vacvFio2 == true) {
                                setState(() {
                                  vacvFio2Value = value.toInt();
                                });
                              } else if (vacvFlowRamp == true) {
                                setState(() {
                                  vacvFlowRampValue = value.toInt();
                                });
                              }
                            },
                            value: vacvItrig
                                ? vacvItrigValue.toDouble()
                                : vacvPeep
                                    ? vacvPeepValue.toDouble()
                                    : vacvRr
                                        ? vacvRrValue.toDouble()
                                        : vacvIe
                                            ? vacvIeValue.toDouble()
                                            : vacvVt
                                                ? vacvVtValue.toDouble()
                                                : vacvPcMin
                                                    ? vacvPcMinValue.toDouble()
                                                    : vacvPcMax
                                                        ? vacvPcMaxValue
                                                            .toDouble()
                                                        : vacvFio2
                                                            ? vacvFio2Value
                                                                .toDouble()
                                                            : vacvFlowRamp
                                                                ? vacvFlowRampValue
                                                                    .toDouble()
                                                                : "",
                          )),
                      SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45.0, right: 45.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(vacvIe
                                ? getIeData(vacvminValue, 1)
                                : vacvItrig
                                    ? "-" + vacvminValue.toString()
                                    : vacvminValue.toString()),
                            Text(
                              vacvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(vacvIe
                                ? getIeData(vacvminValue, 1)
                                : vacvItrig
                                    ? "-" + vacvmaxValue.toString()
                                    : vacvmaxValue.toString())
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  psimvData() {
    return Row(
      children: [
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 60;
                  psimvminValue = 1;
                  psimvparameterName = "RR";
                  psimvparameterUnits = "bpm";
                  psimvItrig = false;
                  psimvRr = true;
                  psimvIe = false;
                  psimvPeep = false;
                  psimvPc = false;
                  psimvVtMin = false;
                  psimvVtMax = false;
                  psimvFio2 = false;
                  psimvFlowRamp = false;
                  psimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psimvRr ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "RR",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "60",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psimvRrValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psimvRr
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psimvRrValue != null
                                    ? psimvRrValue / 60
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 61;
                  psimvminValue = 1;
                  psimvparameterName = "I:E";
                  psimvparameterUnits = "";
                  psimvItrig = false;
                  psimvRr = false;
                  psimvIe = true;
                  psimvPeep = false;
                  psimvPc = false;
                  psimvVtMin = false;
                  psimvVtMax = false;
                  psimvFio2 = false;
                  psimvFlowRamp = false;
                  psimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psimvIe ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I:E",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1:4.0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "4.0:1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                // psimvIeValue.toString(),
                                getIeData(psimvIeValue, 1),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psimvIe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psimvIeValue != null
                                    ? psimvIeValue / 61
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 30;
                  psimvminValue = 0;
                  psimvparameterName = "PEEP";
                  psimvparameterUnits = "cmH\u2082O";
                  psimvItrig = false;
                  psimvRr = false;
                  psimvIe = false;
                  psimvPeep = true;
                  psimvPc = false;
                  psimvVtMin = false;
                  psimvVtMax = false;
                  psimvFio2 = false;
                  psimvFlowRamp = false;
                  psimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psimvPeep ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PEEP",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "30",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psimvPeepValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psimvPeep
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psimvPeepValue != null
                                    ? psimvPeepValue / 30
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 80;
                  psimvminValue = 1;
                  psimvparameterName = "PC";
                  psimvparameterUnits = "cmH\u2082O";
                  psimvItrig = false;
                  psimvRr = false;
                  psimvIe = false;
                  psimvPeep = false;
                  psimvPc = true;
                  psimvVtMin = false;
                  psimvVtMax = false;
                  psimvFio2 = false;
                  psimvFlowRamp = false;
                  psimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psimvPc ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psimvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "80",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psimvPcValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psimvPc
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psimvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psimvPcValue != null
                                    ? psimvPcValue / 80
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 100;
                  psimvminValue = 21;
                  psimvparameterName = "FiO\u2082";
                  psimvparameterUnits = "%";
                  psimvItrig = false;
                  psimvRr = false;
                  psimvIe = false;
                  psimvPeep = false;
                  psimvPc = false;
                  psimvVtMin = false;
                  psimvVtMax = false;
                  psimvFio2 = true;
                  psimvFlowRamp = false;
                  psimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psimvFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO\u2082",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "%",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "21",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psimvFio2Value.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psimvFio2
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psimvFio2Value != null
                                    ? psimvFio2Value / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 10;
                  psimvminValue = 1;
                  psimvparameterName = "I Trig";
                  psimvparameterUnits = "cmH\u2082O Below PEEP";
                  psimvItrig = true;
                  psimvRr = false;
                  psimvIe = false;
                  psimvPeep = false;
                  psimvPc = false;
                  psimvPs = false;
                  psimvVtMin = false;
                  psimvVtMax = false;
                  psimvFio2 = false;
                  psimvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psimvItrig ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I Trig",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "-10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "-1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "-" + psimvItrigValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psimvItrig
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psimvItrigValue != null
                                    ? psimvItrigValue / 10
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 1200;
                  psimvminValue = 100;
                  psimvparameterName = "Vt Min";
                  psimvparameterUnits = "mL";
                  psimvItrig = false;
                  psimvRr = false;
                  psimvIe = false;
                  psimvPeep = false;
                  psimvPc = false;
                  psimvVtMin = true;
                  psimvVtMax = false;
                  psimvFio2 = false;
                  psimvFlowRamp = false;
                  psimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psimvVtMin ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Vt Min",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psimvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psimvVtMinValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psimvVtMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psimvVtMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psimvVtMinValue != null
                                    ? psimvVtMinValue / 1200
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),

            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 1200;
                  psimvminValue = 100;
                  psimvparameterName = "Vt Max";
                  psimvparameterUnits = "mL";
                  psimvItrig = false;
                  psimvRr = false;
                  psimvIe = false;
                  psimvPeep = false;
                  psimvPc = false;
                  psimvVtMin = false;
                  psimvVtMax = true;
                  psimvFio2 = false;
                  psimvFlowRamp = false;
                  psimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psimvVtMax ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Vt Max",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psimvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psimvVtMaxValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psimvVtMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psimvVtMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psimvVtMaxValue != null
                                    ? psimvVtMaxValue / 1200
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),

            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 70;
                  psimvminValue = 1;
                  psimvparameterName = "PS";
                  psimvparameterUnits = "cmH\u2082O";
                  psimvItrig = false;
                  psimvRr = false;
                  psimvIe = false;
                  psimvPeep = false;
                  psimvPc = false;
                  psimvVtMin = false;
                  psimvVtMax = false;
                  psimvFio2 = false;
                  psimvFlowRamp = false;
                  psimvPs = true;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: psimvPs ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PS",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: psimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "70",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: psimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                psimvPsValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: psimvPs
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  psimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: psimvPsValue != null
                                    ? psimvPsValue / 70
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            // Container(height: 260,)s

            // InkWell(
            //   onTap: () {
            //     setState(() {
            //       psimvmaxValue = 4;
            //       psimvminValue = 0;
            //       psimvparameterName = "Flow Ramp";
            //       psimvparameterUnits = "";
            //       psimvItrig = false;
            //       psimvRr = false;
            //       psimvIe = false;
            //       psimvPeep = false;
            //       psimvPc = false;
            //       psimvVtMin = false;
            //       psimvVtMax = false;
            //       psimvFio2 = false;
            //       psimvFlowRamp = true;
            //     });
            //   },
            //   child: Center(
            //     child: Container(
            //       width: 146,
            //       height: 130,
            //       child: Card(
            //         elevation: 40,
            //         color:
            //             psimvFlowRamp ? Color(0xFFE0E0E0) : Color(0xFF213855),
            //         child: Padding(
            //           padding: const EdgeInsets.all(6.0),
            //           child: Center(
            //               child: Stack(
            //             children: [
            //               Align(
            //                 alignment: Alignment.topLeft,
            //                 child: Text(
            //                   "Flow Ramp",
            //                   style: TextStyle(
            //                       fontSize: 15,
            //                       fontWeight: FontWeight.bold,
            //                       color: psimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.topRight,
            //                 child: Text(
            //                   "",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: psimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomRight,
            //                 child: Text(
            //                   "4",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: psimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomLeft,
            //                 child: Text(
            //                   "0",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: psimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 1.0),
            //                   child: Text(
            //                     psimvFlowRampValue.toString() == "0"
            //                         ? "AF"
            //                         : psimvFlowRampValue.toString() == "1"
            //                             ? "AS"
            //                             : psimvFlowRampValue.toString() == "2"
            //                                 ? "DF"
            //                                 : psimvFlowRampValue.toString() ==
            //                                         "3"
            //                                     ? "DS"
            //                                     : psimvFlowRampValue
            //                                                 .toString() ==
            //                                             "4"
            //                                         ? "S"
            //                                         : "S",
            //                     style: TextStyle(
            //                         fontSize: 35,
            //                         color: psimvFlowRamp
            //                             ? Color(0xFF213855)
            //                             : Color(0xFFE0E0E0)),
            //                   ),
            //                 ),
            //               ),
            //               Padding(
            //                 padding: const EdgeInsets.only(
            //                     bottom: 20.0, left: 10, right: 10),
            //                 child: Align(
            //                   alignment: Alignment.bottomCenter,
            //                   child: LinearProgressIndicator(
            //                     backgroundColor: Colors.grey,
            //                     valueColor: AlwaysStoppedAnimation<Color>(
            //                       psimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0),
            //                     ),
            //                     value: psimvFlowRampValue != null
            //                         ? psimvFlowRampValue / 4
            //                         : 0,
            //                   ),
            //                 ),
            //               )
            //             ],
            //           )),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
        SizedBox(width: 140),
        Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                height: 145,
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Alarm Limit",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("RR"),
                                  Text("$minRrtotal-$maxRrtotal"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("Vte"),
                                    Text("$minvte-$maxvte"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("Ppeak"),
                                  Text("$minppeak-$maxppeak"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("PEEP"),
                                    Text("$minpeep-$maxpeep"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 5,
            ),
            patientId != ""
                ? Container(
                    height: 40,
                    width: 400,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFE0E0E0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("IBW : " + patientWeight.toString()),
                          Text("Ideal Vt : " +
                              (int.tryParse(patientWeight) * 6).toString() +
                              " - " +
                              (int.tryParse(patientWeight) * 8).toString())
                        ],
                      ),
                    ))
                : Container(),
            SizedBox(
              height: 5,
            ),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                width: 400,
                height: 195,
                child: Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.remove,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (psimvItrig == true &&
                                    psimvItrigValue != psimvminValue) {
                                  setState(() {
                                    psimvItrigValue = psimvItrigValue - 1;
                                  });
                                } else if (psimvPeep == true &&
                                    psimvPeepValue != psimvminValue) {
                                  setState(() {
                                    psimvPeepValue = psimvPeepValue - 1;
                                    if (psimvItrigValue > 1 &&
                                        psimvItrigValue > psimvPeepValue) {
                                      psimvItrigValue = psimvPeepValue;
                                    }
                                  });
                                } else if (psimvRr == true &&
                                    psimvRrValue != psimvminValue) {
                                  setState(() {
                                    psimvRrValue = psimvRrValue - 1;
                                  });
                                } else if (psimvIe == true &&
                                    psimvIeValue != psimvminValue) {
                                  setState(() {
                                    psimvIeValue = psimvIeValue - 1;
                                  });
                                } else if (psimvPc == true &&
                                    psimvPcValue != psimvminValue) {
                                  setState(() {
                                    psimvPcValue = psimvPcValue - 1;
                                  });
                                } else if (psimvVtMin == true &&
                                    psimvVtMinValue != psimvminValue) {
                                  setState(() {
                                    psimvVtMinValue = psimvVtMinValue - 1;
                                    //  if (psimvVtMinValue >= psimvVtMaxValue) {
                                    //    psimvVtMaxValue = psimvVtMaxValue - 1;
                                    //  }
                                  });
                                } else if (psimvVtMax == true &&
                                    psimvVtMaxValue != psimvVtMinValue + 1) {
                                  psimvVtMaxValue = psimvVtMaxValue - 1;
                                } else if (psimvFio2 == true &&
                                    psimvFio2Value != psimvminValue) {
                                  setState(() {
                                    psimvFio2Value = psimvFio2Value - 1;
                                  });
                                } else if (psimvFlowRamp == true &&
                                    psimvFlowRampValue != psimvminValue) {
                                  setState(() {
                                    psimvFlowRampValue = psimvFlowRampValue - 1;
                                  });
                                } else if (psimvPs == true &&
                                    psimvPsValue != psimvminValue) {
                                  setState(() {
                                    psimvPsValue = psimvPsValue - 1;
                                  });
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          Text(
                            psimvparameterName,
                            style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.normal),
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (psimvItrig == true &&
                                    psimvItrigValue != psimvmaxValue) {
                                  setState(() {
                                    psimvItrigValue = psimvItrigValue + 1;
                                    if (psimvPeepValue <= psimvItrigValue) {
                                      if (psimvPeepValue == 0) {
                                        psimvItrigValue = 1;
                                      } else {
                                        psimvItrigValue = psimvPeepValue;
                                      }
                                    }
                                  });
                                } else if (psimvPeep == true &&
                                    psimvPeepValue != psimvmaxValue) {
                                  setState(() {
                                    psimvPeepValue = psimvPeepValue + 1;
                                  });
                                } else if (psimvRr == true &&
                                    psimvRrValue != psimvmaxValue) {
                                  setState(() {
                                    psimvRrValue = psimvRrValue + 1;
                                  });
                                } else if (psimvIe == true &&
                                    psimvIeValue != psimvmaxValue) {
                                  setState(() {
                                    psimvIeValue = psimvIeValue + 1;
                                  });
                                } else if (psimvPc == true &&
                                    psimvPcValue != psimvmaxValue) {
                                  setState(() {
                                    psimvPcValue = psimvPcValue + 1;
                                  });
                                } else if (psimvVtMin == true &&
                                    psimvVtMinValue != pacvmaxValue) {
                                  setState(() {
                                    if (psimvVtMaxValue < 1190) {
                                      psimvVtMinValue = psimvVtMinValue + 1;
                                      psimvVtMaxValue = psimvVtMinValue + 1;
                                    }
                                  });
                                } else if (psimvVtMax == true &&
                                    psimvVtMaxValue != pacvmaxValue) {
                                  setState(() {
                                    psimvVtMaxValue = psimvVtMaxValue + 1;
                                  });
                                } else if (psimvFlowRamp == true &&
                                    psimvFlowRampValue != psimvmaxValue) {
                                  setState(() {
                                    psimvFlowRampValue = psimvFlowRampValue + 1;
                                  });
                                } else if (psimvPs == true &&
                                    psimvPsValue != psimvmaxValue) {
                                  setState(() {
                                    psimvPsValue = psimvPsValue + 1;
                                  });
                                } else if (psimvFio2 == true &&
                                    psimvFio2Value != psimvmaxValue) {
                                  setState(() {
                                    psimvFio2Value = psimvFio2Value + 1;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              psimvItrig
                                  ? "-" + psimvItrigValue.toInt().toString()
                                  : psimvPeep
                                      ? psimvPeepValue.toInt().toString()
                                      : psimvRr
                                          ? psimvRrValue.toInt().toString()
                                          : psimvIe
                                              ? getIeData(psimvIeValue, 1)
                                              : psimvPc
                                                  ? psimvPcValue
                                                      .toInt()
                                                      .toString()
                                                  : psimvVtMin
                                                      ? psimvVtMinValue
                                                          .toInt()
                                                          .toString()
                                                      : psimvVtMax
                                                          ? psimvVtMaxValue
                                                              .toInt()
                                                              .toString()
                                                          : psimvFio2
                                                              ? psimvFio2Value
                                                                  .toInt()
                                                                  .toString()
                                                              : psimvFlowRamp
                                                                  ? psimvFlowRampValue
                                                                      .toInt()
                                                                      .toString()
                                                                  : psimvPs
                                                                      ? psimvPsValue
                                                                          .toInt()
                                                                          .toString()
                                                                      : "",
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                          width: 350,
                          child: Slider(
                            min: psimvminValue.toDouble() ?? 0,
                            max: psimvmaxValue.toDouble(),
                            onChanged: (double value) {
                              if (psimvItrig == true && psimvItrigValue != 10) {
                                setState(() {
                                  psimvItrigValue = psimvItrigValue + 1;
                                  if (psimvPeepValue <= psimvItrigValue) {
                                    if (psimvPeepValue == 0) {
                                      psimvItrigValue = 1;
                                    } else {
                                      psimvItrigValue = psimvPeepValue;
                                    }
                                  }
                                });
                              } else if (psimvPeep == true) {
                                setState(() {
                                  psimvPeepValue = value.toInt();
                                  if (psimvItrigValue > 1 &&
                                      psimvItrigValue > psimvPeepValue) {
                                    psimvItrigValue = psimvPeepValue;
                                  }
                                });
                              } else if (psimvRr == true) {
                                setState(() {
                                  psimvRrValue = value.toInt();
                                });
                              } else if (psimvIe == true) {
                                setState(() {
                                  psimvIeValue = value.toInt();
                                });
                              } else if (psimvPc == true) {
                                setState(() {
                                  psimvPcValue = value.toInt();
                                });
                              } else if (psimvVtMin == true) {
                                if (value.toInt() < 1190) {
                                  psimvVtMinValue = value.toInt();
                                  psimvVtMaxValue = psimvVtMinValue + 1;
                                }
                              } else if (psimvVtMax == true) {
                                setState(() {
                                  if (value.toInt() <= psimvVtMinValue + 1) {
                                    psimvVtMaxValue = psimvVtMinValue + 1;
                                  } else {
                                    psimvVtMaxValue = value.toInt();
                                  }
                                });
                              } else if (psimvFio2 == true) {
                                setState(() {
                                  psimvFio2Value = value.toInt();
                                });
                              } else if (psimvFlowRamp == true) {
                                setState(() {
                                  psimvFlowRampValue = value.toInt();
                                });
                              } else if (psimvPs == true) {
                                setState(() {
                                  // if (value.toInt() <= psimvPcValue &&
                                  //     value.toInt() >= psimvPeepValue) {
                                  psimvPsValue = value.toInt();
                                  // }
                                  //
                                });
                              }
                            },
                            value: psimvItrig
                                ? psimvItrigValue.toDouble()
                                : psimvPeep
                                    ? psimvPeepValue.toDouble()
                                    : psimvRr
                                        ? psimvRrValue.toDouble()
                                        : psimvIe
                                            ? psimvIeValue.toDouble()
                                            : psimvPc
                                                ? psimvPcValue.toDouble()
                                                : psimvVtMin
                                                    ? psimvVtMinValue.toDouble()
                                                    : psimvVtMax
                                                        ? psimvVtMaxValue
                                                            .toDouble()
                                                        : psimvFio2
                                                            ? psimvFio2Value
                                                                .toDouble()
                                                            : psimvFlowRamp
                                                                ? psimvFlowRampValue
                                                                    .toDouble()
                                                                : psimvPs
                                                                    ? psimvPsValue
                                                                        .toDouble()
                                                                    : "",
                          )),
                      SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45.0, right: 45.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(psimvIe
                                ? getIeData(psimvminValue, 1)
                                : psimvItrig
                                    ? "-" + psimvminValue.toString()
                                    : psimvminValue.toString()),
                            Text(
                              psimvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(psimvIe
                                ? getIeData(psimvmaxValue, 1)
                                : psimvItrig
                                    ? "-" + psimvmaxValue.toString()
                                    : psimvmaxValue.toString())
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  pccmvData() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  pccmvmaxValue = 60;
                  pccmvminValue = 1;
                  pccmvparameterName = "RR";
                  pccmvparameterUnits = "bpm";
                  // pccmvTempValue = pccmvRRValue;
                  pccmvRRChanged = true;
                  pccmvRR = true;
                  pccmvIe = false;
                  pccmvPeep = false;
                  pccmvPc = false;
                  pccmvFio2 = false;
                  pccmvVtmin = false;
                  pccmvVtmax = false;
                  pccmvFlowRamp = false;
                  pccmvTih = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pccmvRR ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "RR",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: pccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "60",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pccmvRRValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pccmvRR
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pccmvRRValue != null
                                    ? pccmvRRValue / 60
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  pccmvmaxValue = 61;
                  pccmvminValue = 1;
                  pccmvparameterName = "I:E";
                  pccmvparameterUnits = "";
                  pccmvRR = false;
                  pccmvIe = true;
                  pccmvPeep = false;
                  pccmvPc = false;
                  pccmvFio2 = false;
                  pccmvVtmin = false;
                  pccmvVtmax = false;
                  pccmvFlowRamp = false;
                  pccmvTih = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pccmvIe ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I:E",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: pccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1:4.0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "4.0:1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                getIeData(pccmvIeValue, 1),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pccmvIe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pccmvIeValue != null
                                    ? pccmvIeValue / 61
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  pccmvmaxValue = 30;
                  pccmvminValue = 0;
                  pccmvparameterName = "PEEP";
                  pccmvparameterUnits = "cmH\u2082O";
                  pccmvRR = false;
                  pccmvIe = false;
                  pccmvPeep = true;
                  pccmvPc = false;
                  pccmvFio2 = false;
                  pccmvVtmin = false;
                  pccmvVtmax = false;
                  pccmvFlowRamp = false;
                  pccmvTih = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pccmvPeep ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PEEP",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: pccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "30",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pccmvPeepValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pccmvPeep
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pccmvPeepValue != null
                                    ? pccmvPeepValue / 30
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  pccmvmaxValue = 80;
                  pccmvminValue = 1;
                  pccmvparameterName = "PC";
                  pccmvparameterUnits = "cmH\u2082O";
                  pccmvRR = false;
                  pccmvIe = false;
                  pccmvPeep = false;
                  pccmvPc = true;
                  pccmvFio2 = false;
                  pccmvVtmin = false;
                  pccmvVtmax = false;
                  pccmvFlowRamp = false;
                  pccmvTih = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pccmvPc ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pccmvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: pccmvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "80",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pccmvPcValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pccmvPc
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pccmvPc
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pccmvPcValue != null
                                    ? pccmvPcValue / 80
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  pccmvmaxValue = 100;
                  pccmvminValue = 21;
                  pccmvparameterName = "FiO\u2082";
                  pccmvparameterUnits = "%";
                  pccmvRR = false;
                  pccmvIe = false;
                  pccmvPeep = false;
                  pccmvPc = false;
                  pccmvFio2 = true;
                  pccmvVtmin = false;
                  pccmvVtmax = false;
                  pccmvFlowRamp = false;
                  pccmvTih = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pccmvFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO" + '\u2082',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "%",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: pccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "21",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pccmvFio2Value.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pccmvFio2
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pccmvFio2Value != null
                                    ? pccmvFio2Value / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  pccmvmaxValue = 1200;
                  pccmvminValue = 100;
                  pccmvparameterName = "VTmin";
                  pccmvparameterUnits = "mL";
                  pccmvRR = false;
                  pccmvIe = false;
                  pccmvPeep = false;
                  pccmvPc = false;
                  pccmvFio2 = false;
                  pccmvVtmin = true;
                  pccmvVtmax = false;
                  pccmvFlowRamp = false;
                  pccmvTih = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pccmvVtmin ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "VTmin",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pccmvVtmin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: pccmvVtmin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvVtmin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvVtmin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pccmvVtminValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pccmvVtmin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pccmvVtmin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pccmvVtminValue != null
                                    ? pccmvVtminValue / 1200
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  pccmvmaxValue = 1200;
                  pccmvminValue = 200;
                  pccmvparameterName = "VTmax";
                  pccmvparameterUnits = "mL";
                  pccmvRR = false;
                  pccmvIe = false;
                  pccmvPeep = false;
                  pccmvPc = false;
                  pccmvFio2 = false;
                  pccmvVtmin = false;
                  pccmvVtmax = true;
                  pccmvFlowRamp = false;
                  pccmvTih = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: pccmvVtmax ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "VTmax",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: pccmvVtmax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: pccmvVtmax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvVtmax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: pccmvVtmax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                pccmvVtmaxValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: pccmvVtmax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pccmvVtmax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: pccmvVtmaxValue != null
                                    ? pccmvVtmaxValue / 1200
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            // InkWell(
            //   onTap: () {
            //     setState(() {
            //       pccmvmaxValue = 4;
            //       pccmvminValue = 0;
            //       pccmvparameterName = "Flow Ramp";
            //       pccmvparameterUnits = "";
            //       pccmvRR = false;
            //       pccmvIe = false;
            //       pccmvPeep = false;
            //       pccmvPc = false;
            //       pccmvFio2 = false;
            //       pccmvVtmin = false;
            //       pccmvVtmax = false;
            //       pccmvFlowRamp = true;
            //       pccmvTih = false;
            //     });
            //   },
            //   child: Center(
            //     child: Container(
            //       width: 146,
            //       height: 130,
            //       child: Card(
            //         elevation: 40,
            //         color:
            //             pccmvFlowRamp ? Color(0xFFE0E0E0) : Color(0xFF213855),
            //         child: Padding(
            //           padding: const EdgeInsets.all(6.0),
            //           child: Center(
            //               child: Stack(
            //             children: [
            //               Align(
            //                 alignment: Alignment.topLeft,
            //                 child: Text(
            //                   "Flow Ramp",
            //                   style: TextStyle(
            //                       fontSize: 15,
            //                       fontWeight: FontWeight.bold,
            //                       color: pccmvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.topRight,
            //                 child: Text(
            //                   "",
            //                   style: TextStyle(
            //                       fontSize: 9,
            //                       color: pccmvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomRight,
            //                 child: Text(
            //                   "4",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: pccmvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomLeft,
            //                 child: Text(
            //                   "0",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: pccmvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 1.0),
            //                   child: Text(
            //                     pccmvFlowRampValue.toString() == "0"
            //                         ? "AF"
            //                         : pccmvFlowRampValue.toString() == "1"
            //                             ? "AS"
            //                             : pccmvFlowRampValue.toString() == "2"
            //                                 ? "DF"
            //                                 : pccmvFlowRampValue.toString() ==
            //                                         "3"
            //                                     ? "DS"
            //                                     : pccmvFlowRampValue
            //                                                 .toString() ==
            //                                             "4"
            //                                         ? "S"
            //                                         : "S",
            //                     style: TextStyle(
            //                         fontSize: 35,
            //                         color: pccmvFlowRamp
            //                             ? Color(0xFF213855)
            //                             : Color(0xFFE0E0E0)),
            //                   ),
            //                 ),
            //               ),
            //               Padding(
            //                 padding: const EdgeInsets.only(
            //                     bottom: 20.0, left: 10, right: 10),
            //                 child: Align(
            //                   alignment: Alignment.bottomCenter,
            //                   child: LinearProgressIndicator(
            //                     backgroundColor: Colors.grey,
            //                     valueColor: AlwaysStoppedAnimation<Color>(
            //                       pccmvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0),
            //                     ),
            //                     value: pccmvFlowRampValue != null
            //                         ? pccmvFlowRampValue / 4
            //                         : 0,
            //                   ),
            //                 ),
            //               )
            //             ],
            //           )),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            Container(
              width: 136,
            )
          ],
        ),
        SizedBox(width: 140),
        Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                height: 145,
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Alarm Limit",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("RR"),
                                  Text("$minRrtotal-$maxRrtotal"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("Vte"),
                                    Text("$minvte-$maxvte"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("Ppeak"),
                                  Text("$minppeak-$maxppeak"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("PEEP"),
                                    Text("$minpeep-$maxpeep"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 5,
            ),
            patientId != ""
                ? Container(
                    height: 40,
                    width: 400,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFE0E0E0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("IBW : " + patientWeight ?? 0.toString()),
                          Text("Ideal Vt : " +
                              (int.tryParse(patientWeight ?? 0) * 6)
                                  .toString() +
                              " - " +
                              (int.tryParse(patientWeight ?? 0) * 8).toString())
                        ],
                      ),
                    ))
                : Container(),
            SizedBox(
              height: 5,
            ),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                width: 400,
                height: 195,
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.remove,
                              color: Colors.black,
                              size: 55,
                            ),
                            onPressed: () {
                              setState(() {
                                if (pccmvRR == true &&
                                    pccmvRRValue != pccmvminValue) {
                                  setState(() {
                                    pccmvRRValue = pccmvRRValue - 1;
                                  });
                                  sendRRData(pccmvRRValue);
                                } else if (pccmvIe == true &&
                                    pccmvIeValue != pccmvminValue) {
                                  setState(() {
                                    pccmvIeValue = pccmvIeValue - 1;
                                  });
                                } else if (pccmvPeep == true &&
                                    pccmvPeepValue != pccmvminValue) {
                                  setState(() {
                                    pccmvPeepValue = pccmvPeepValue - 1;
                                  });
                                } else if (pccmvPc == true &&
                                    pccmvPcValue != pccmvminValue) {
                                  setState(() {
                                    pccmvPcValue = pccmvPcValue - 1;
                                  });
                                } else if (pccmvFio2 == true &&
                                    pccmvFio2Value != pccmvminValue) {
                                  setState(() {
                                    pccmvFio2Value = pccmvFio2Value - 1;
                                  });
                                } else if (pccmvVtmin == true &&
                                    pccmvVtminValue != pccmvminValue) {
                                  setState(() {
                                    pccmvVtminValue = pccmvVtminValue - 1;
                                    // if (pccmvVtminValue >= pccmvVtmaxValue) {
                                    //   pccmvVtmaxValue = pccmvVtmaxValue - 1;
                                    // }
                                  });
                                } else if (pccmvVtmax == true &&
                                    pccmvVtmaxValue != pccmvVtminValue + 1) {
                                  pccmvVtmaxValue = pccmvVtmaxValue - 1;
                                  // if (pccmvVtmaxValue <=
                                  //     pccmvVtminValue + 100) {
                                  //   pccmvVtminValue = pccmvVtmaxValue - 100;
                                  // }
                                } else if (pccmvFlowRamp == true &&
                                    pccmvFlowRampValue != pccmvminValue) {
                                  setState(() {
                                    pccmvFlowRampValue = pccmvFlowRampValue - 1;
                                  });
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          Text(
                            pccmvparameterName,
                            style: TextStyle(fontSize: 36),
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 55,
                            ),
                            onPressed: () {
                              setState(() {
                                if (pccmvRR == true &&
                                    pccmvRRValue != pccmvmaxValue) {
                                  setState(() {
                                    pccmvRRValue = pccmvRRValue + 1;
                                  });
                                  sendRRData(pccmvRRValue);
                                } else if (pccmvIe == true &&
                                    pccmvIeValue != pccmvmaxValue) {
                                  setState(() {
                                    pccmvIeValue = pccmvIeValue + 1;
                                  });
                                } else if (pccmvPeep == true &&
                                    pccmvPeepValue != pccmvmaxValue) {
                                  setState(() {
                                    pccmvPeepValue = pccmvPeepValue + 1;
                                    if (pccmvPcValue <= pccmvPeepValue) {
                                      pccmvPcValue = pccmvPeepValue + 1;
                                    }
                                  });
                                } else if (pccmvPc == true &&
                                    pccmvPcValue != pccmvmaxValue) {
                                  setState(() {
                                    pccmvPcValue = pccmvPcValue + 1;
                                  });
                                } else if (pccmvFio2 == true &&
                                    pccmvFio2Value != pccmvmaxValue) {
                                  setState(() {
                                    pccmvFio2Value = pccmvFio2Value + 1;
                                  });
                                } else if (pccmvVtmin == true &&
                                    pccmvVtminValue != pccmvmaxValue) {
                                  setState(() {
                                    if (pccmvVtmaxValue < 1390) {
                                      pccmvVtminValue = pccmvVtminValue + 1;
                                      pccmvVtmaxValue = pccmvVtminValue + 1;
                                    }
                                  });
                                } else if (pccmvVtmax == true &&
                                    pccmvVtmaxValue != pccmvmaxValue) {
                                  setState(() {
                                    pccmvVtmaxValue = pccmvVtmaxValue + 1;
                                  });
                                } else if (pccmvFlowRamp == true &&
                                    pccmvFlowRampValue != pccmvmaxValue) {
                                  setState(() {
                                    pccmvFlowRampValue = pccmvFlowRampValue + 1;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              pccmvRR
                                  ? pccmvRRValue.toInt().toString()
                                  // : pccmvIe
                                  //     ? "1:" + pccmvIeValue.toInt().toString()

                                  : pccmvIe
                                      ? getIeData(pccmvIeValue, 1)
                                      : pccmvPeep
                                          ? pccmvPeepValue.toInt().toString()
                                          : pccmvPc
                                              ? pccmvPcValue.toInt().toString()
                                              : pccmvFio2
                                                  ? pccmvFio2Value
                                                      .toInt()
                                                      .toString()
                                                  : pccmvVtmin
                                                      ? pccmvVtminValue
                                                          .toInt()
                                                          .toString()
                                                      : pccmvVtmax
                                                          ? pccmvVtmaxValue
                                                              .toInt()
                                                              .toString()
                                                          : pccmvFlowRamp
                                                              ? pccmvFlowRampValue
                                                                          .toString() ==
                                                                      "0"
                                                                  ? "AF"
                                                                  : pccmvFlowRampValue
                                                                              .toString() ==
                                                                          "1"
                                                                      ? "AS"
                                                                      : pccmvFlowRampValue.toString() ==
                                                                              "2"
                                                                          ? "DF"
                                                                          : pccmvFlowRampValue.toString() == "3"
                                                                              ? "DS"
                                                                              : pccmvFlowRampValue.toString() == "4" ? "S" : "S"
                                                              : "",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      // pccmvFio2
                      //     ? Container()
                      //     :
                      Container(
                        width: 350,
                        child: Slider(
                          activeColor: Colors.black,
                          inactiveColor: Colors.black,
                          min: pccmvminValue.toDouble() ?? 0,
                          max: pccmvmaxValue.toDouble() ?? 0,
                          value: pccmvRR
                              ? pccmvRRValue.toDouble()
                              : pccmvIe
                                  ? pccmvIeValue.toDouble()
                                  : pccmvPeep
                                      ? pccmvPeepValue.toDouble()
                                      : pccmvPc
                                          ? pccmvPcValue.toDouble()
                                          : pccmvFio2
                                              ? pccmvFio2Value.toDouble()
                                              : pccmvVtmin
                                                  ? pccmvVtminValue.toDouble()
                                                  : pccmvVtmax
                                                      ? pccmvVtmaxValue
                                                          .toDouble()
                                                      : pccmvFlowRamp
                                                          ? pccmvFlowRampValue
                                                              .toDouble()
                                                          : "",
                          onChanged: (double value) {
                            setState(() {
                              if (pccmvRR == true) {
                                setState(() {
                                  pccmvRRValue = value.toInt();
                                });
                                sendRRData(pccmvRRValue);
                              } else if (pccmvIe == true) {
                                setState(() {
                                  pccmvIeValue = value.toInt();
                                });
                              } else if (pccmvPeep == true) {
                                // if (pccmvPcValue <= pccmvPeepValue) {
                                setState(() {
                                  // pccmvPcValue = value.toInt() + 1;
                                  pccmvPeepValue = value.toInt();
                                });
                                // } else {
                                //   pccmvPeepValue = value.toInt();
                                // }
                              } else if (pccmvPc == true) {
                                setState(() {
                                  pccmvPcValue = value.toInt();
                                });
                              } else if (pccmvFio2 == true) {
                                setState(() {
                                  pccmvFio2Value = value.toInt();
                                });
                              } else if (pccmvVtmin == true) {
                                if (value.toInt() < 1190) {
                                  pccmvVtminValue = value.toInt();
                                  if (pccmvVtmaxValue <= pccmvVtminValue) {
                                    pccmvVtmaxValue = pccmvVtminValue + 1;
                                  }
                                }
                                // if (pccmvVtminValue >=
                                //     (pccmvVtmaxValue) - 100) {
                                //   pccmvVtmaxValue = pccmvVtminValue + 100;
                                // }
                              } else if (pccmvVtmax == true) {
                                setState(() {
                                  if (value.toInt() <= pccmvVtminValue + 1) {
                                    pccmvVtmaxValue = pccmvVtminValue + 1;
                                  } else {
                                    pccmvVtmaxValue = value.toInt();
                                  }
                                });
                              } else if (pccmvFlowRamp == true) {
                                setState(() {
                                  pccmvFlowRampValue = value.toInt();
                                });
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45.0, right: 45.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(pccmvIe
                                ? getIeData(pccmvminValue, 1)
                                : pccmvminValue.toString()),
                            Text(
                              pccmvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(pccmvIe
                                ? getIeData(pccmvmaxValue, 1)
                                : pccmvmaxValue.toString())
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  vccmvData() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vccmvmaxValue = 60;
                  vccmvminValue = 1;
                  vccmvparameterName = "RR";
                  vccmvparameterUnits = "bpm";
                  vccmvRR = true;
                  vccmvIe = false;
                  vccmvPeep = false;
                  vccmvPcMax = false;
                  vccmvPcMin = false;
                  vccmvFio2 = false;
                  vccmvVt = false;
                  vccmvFlowRamp = false;
                  vccmvTih = false;
                });
                sleep(const Duration(milliseconds: 200));
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vccmvRR ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "RR",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: vccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "60",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vccmvRRValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vccmvRR
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vccmvRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vccmvRRValue != null
                                    ? vccmvRRValue / 60
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vccmvmaxValue = 61;
                  vccmvminValue = 1;
                  vccmvparameterName = "I:E";
                  vccmvparameterUnits = "";
                  vccmvRR = false;
                  vccmvIe = true;
                  vccmvPeep = false;
                  vccmvPcMax = false;
                  vccmvPcMin = false;
                  vccmvFio2 = false;
                  vccmvVt = false;
                  vccmvFlowRamp = false;
                  vccmvTih = false;
                });
                sleep(const Duration(milliseconds: 200));
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vccmvIe ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I:E",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: vccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1:4.0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "4.0:1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                getIeData(vccmvIeValue, 1),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vccmvIe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vccmvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vccmvIeValue != null
                                    ? vccmvIeValue / 61
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vccmvmaxValue = 30;
                  vccmvminValue = 0;
                  vccmvparameterName = "PEEP";
                  vccmvparameterUnits = "cmH\u2082O";
                  vccmvRR = false;
                  vccmvIe = false;
                  vccmvPeep = true;
                  vccmvPcMax = false;

                  vccmvPcMin = false;
                  vccmvFio2 = false;
                  vccmvVt = false;
                  vccmvFlowRamp = false;
                  vccmvTih = false;
                });
                sleep(const Duration(milliseconds: 200));
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vccmvPeep ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PEEP",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: vccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "30",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vccmvPeepValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vccmvPeep
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vccmvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vccmvPeepValue != null
                                    ? vccmvPeepValue / 30
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vccmvmaxValue = 1200;
                  vccmvminValue = 200;
                  vccmvparameterName = "VT";
                  vccmvparameterUnits = "mL";
                  vccmvRR = false;
                  vccmvIe = false;
                  vccmvPeep = false;
                  vccmvVt = true;
                  vccmvPcMax = false;
                  vccmvPcMin = false;
                  vccmvFio2 = false;
                  vccmvFlowRamp = false;
                  vccmvTih = false;
                });
                sleep(const Duration(milliseconds: 200));
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vccmvVt ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "VT",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vccmvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: vccmvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vccmvVtValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vccmvVt
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vccmvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vccmvVtValue != null
                                    ? vccmvVtValue / 1200
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vccmvmaxValue = 100;
                  vccmvminValue = 21;
                  vccmvparameterName = "FiO\u2082";
                  vccmvparameterUnits = "%";
                  vccmvRR = false;
                  vccmvIe = false;
                  vccmvPeep = false;
                  vccmvVt = false;
                  vccmvPcMax = false;
                  vccmvPcMin = false;
                  vccmvFio2 = true;
                  vccmvFlowRamp = false;
                  vccmvTih = false;
                });
                sleep(const Duration(milliseconds: 200));
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vccmvFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO\u2082",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "%",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: vccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "21",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vccmvFio2Value.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vccmvFio2
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vccmvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vccmvFio2Value != null
                                    ? vccmvFio2Value / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () async {
                setState(() {
                  vccmvmaxValue = 100;
                  vccmvminValue = 10;
                  vccmvparameterName = "PC Min";
                  vccmvparameterUnits = "cmH\u2082O";
                  vccmvRR = false;
                  vccmvIe = false;
                  vccmvPeep = false;
                  vccmvVt = false;
                  vccmvPcMax = false;
                  vccmvPcMin = true;
                  vccmvFio2 = false;
                  vccmvFlowRamp = false;
                  vccmvTih = false;
                });
                sleep(const Duration(milliseconds: 200));
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vccmvPcMin ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC Min",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vccmvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: vccmvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vccmvPcMinValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vccmvPcMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vccmvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vccmvPcMinValue != null
                                    ? vccmvPcMinValue / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vccmvmaxValue = 100;
                  vccmvminValue = 10;
                  vccmvparameterName = "PC Max";
                  vccmvparameterUnits = "cmH\u2082O";
                  vccmvRR = false;
                  vccmvIe = false;
                  vccmvPeep = false;
                  vccmvVt = false;
                  vccmvPcMax = true;
                  vccmvPcMin = false;
                  vccmvFio2 = false;
                  vccmvFlowRamp = false;
                  vccmvTih = false;
                });
                sleep(const Duration(milliseconds: 200));
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vccmvPcMax ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC Max",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vccmvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: vccmvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vccmvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vccmvPcMaxValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vccmvPcMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vccmvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vccmvPcMaxValue != null
                                    ? vccmvPcMaxValue / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            Container(width: 146),
          ],
        ),
        SizedBox(width: 140),
        Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                height: 145,
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Alarm Limit",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("RR"),
                                  Text("$minRrtotal-$maxRrtotal"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("Vte"),
                                    Text("$minvte-$maxvte"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("Ppeak"),
                                  Text("$minppeak-$maxppeak"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("PEEP"),
                                    Text("$minpeep-$maxpeep"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 5,
            ),
            patientId != ""
                ? Container(
                    height: 40,
                    width: 400,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFE0E0E0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("IBW : " + patientWeight.toString()),
                          Text("Ideal Vt : " +
                              (int.tryParse(patientWeight) * 6).toString() +
                              " - " +
                              (int.tryParse(patientWeight) * 8).toString())
                        ],
                      ),
                    ))
                : Container(),
            SizedBox(
              height: 5,
            ),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                width: 400,
                height: 195,
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.remove,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (vccmvRR == true &&
                                    vccmvRRValue != vccmvminValue) {
                                  setState(() {
                                    vccmvRRValue = vccmvRRValue - 1;
                                  });
                                } else if (vccmvIe == true &&
                                    vccmvIeValue != vccmvminValue) {
                                  setState(() {
                                    vccmvIeValue = vccmvIeValue - 1;
                                  });
                                } else if (vccmvPeep == true &&
                                    vccmvPeepValue != vccmvminValue) {
                                  setState(() {
                                    vccmvPeepValue = vccmvPeepValue - 1;
                                    // if (vccmvPcMinValue <= vccmvPeepValue) {
                                    //   vccmvPcMinValue = vccmvPeepValue + 1;
                                    //   if (vccmvPcMaxValue <=
                                    //       vccmvPcMinValue) {
                                    //     vccmvPcMaxValue = vccmvPcMinValue + 1;
                                    //   }
                                    // }
                                  });
                                } else if (vccmvPcMax == true &&
                                    vccmvPcMaxValue != vccmvPcMinValue + 1) {
                                  vccmvPcMaxValue = vccmvPcMaxValue - 1;
                                } else if (vccmvFio2 == true &&
                                    vccmvFio2Value != vccmvminValue) {
                                  setState(() {
                                    vccmvFio2Value = vccmvFio2Value - 1;
                                  });
                                } else if (vccmvPcMin == true &&
                                    vccmvPcMinValue != vccmvminValue) {
                                  setState(() {
                                    vccmvPcMinValue = vccmvPcMinValue - 1;
                                    // if (vccmvPcMinValue >= vccmvPcMaxValue) {
                                    //   vccmvPcMaxValue = vccmvPcMaxValue - 1;
                                    // }
                                  });
                                } else if (vccmvVt == true &&
                                    vccmvVtValue != vccmvminValue) {
                                  setState(() {
                                    vccmvVtValue = vccmvVtValue - 1;
                                  });
                                } else if (vccmvFlowRamp == true &&
                                    vccmvFlowRampValue != vccmvminValue) {
                                  setState(() {
                                    vccmvFlowRampValue = vccmvFlowRampValue - 1;
                                  });
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          Text(
                            vccmvparameterName,
                            style: TextStyle(fontSize: 36),
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (vccmvRR == true &&
                                    vccmvRRValue != vccmvmaxValue) {
                                  setState(() {
                                    vccmvRRValue = vccmvRRValue + 1;
                                  });
                                } else if (vccmvIe == true &&
                                    vccmvIeValue != vccmvmaxValue) {
                                  setState(() {
                                    vccmvIeValue = vccmvIeValue + 1;
                                  });
                                } else if (vccmvPeep == true &&
                                    vccmvPeepValue != vccmvmaxValue) {
                                  setState(() {
                                    vccmvPeepValue = vccmvPeepValue + 1;
                                    // if (vccmvPcMinValue <= vccmvPeepValue) {
                                    //   vccmvPcMinValue = vccmvPeepValue + 1;
                                    //   if (vccmvPcMaxValue <=
                                    //       vccmvPcMinValue) {
                                    //     vccmvPcMaxValue = vccmvPcMinValue + 1;
                                    //   }
                                    // }
                                  });
                                } else if (vccmvFio2 == true &&
                                    vccmvFio2Value != vccmvmaxValue) {
                                  setState(() {
                                    vccmvFio2Value = vccmvFio2Value + 1;
                                  });
                                } else if (vccmvVt == true &&
                                    vccmvVtValue != vccmvmaxValue) {
                                  setState(() {
                                    vccmvVtValue = vccmvVtValue + 1;
                                  });
                                } else if (vccmvPcMin == true &&
                                    vccmvPcMinValue != vccmvmaxValue) {
                                  setState(() {
                                    if (vccmvPcMaxValue < 90) {
                                      vccmvPcMinValue = vccmvPcMinValue + 1;
                                      vccmvPcMaxValue = vccmvPcMinValue + 1;
                                    }
                                  });
                                } else if (vccmvPcMax == true &&
                                    vccmvPcMaxValue != vccmvmaxValue) {
                                  setState(() {
                                    vccmvPcMaxValue = vccmvPcMaxValue + 1;
                                  });
                                } else if (vccmvFlowRamp == true &&
                                    vccmvFlowRampValue != vccmvmaxValue) {
                                  setState(() {
                                    vccmvFlowRampValue = vccmvFlowRampValue + 1;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              vccmvRR
                                  ? vccmvRRValue.toInt().toString()
                                  : vccmvIe
                                      ? getIeData(vccmvIeValue, 1)
                                      : vccmvPeep
                                          ? vccmvPeepValue.toInt().toString()
                                          : vccmvPcMin
                                              ? vccmvPcMinValue
                                                  .toInt()
                                                  .toString()
                                              : vccmvFio2
                                                  ? vccmvFio2Value
                                                      .toInt()
                                                      .toString()
                                                  : vccmvPcMax
                                                      ? vccmvPcMaxValue
                                                          .toInt()
                                                          .toString()
                                                      : vccmvVt
                                                          ? vccmvVtValue
                                                              .toInt()
                                                              .toString()
                                                          : vccmvFlowRamp
                                                              ? vccmvFlowRampValue
                                                                          .toString() ==
                                                                      "0"
                                                                  ? "AF"
                                                                  : vccmvFlowRampValue
                                                                              .toString() ==
                                                                          "1"
                                                                      ? "AS"
                                                                      : vccmvFlowRampValue.toString() ==
                                                                              "2"
                                                                          ? "DF"
                                                                          : vccmvFlowRampValue.toString() == "3"
                                                                              ? "DS"
                                                                              : vccmvFlowRampValue.toString() == "4" ? "S" : "S"
                                                              : "",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      // vccmvFio2
                      //     ? Container()
                      //     :
                      Container(
                        width: 350,
                        child: Slider(
                          min: vccmvminValue.toDouble() ?? 0,
                          max: vccmvmaxValue.toDouble() ?? 0,
                          value: vccmvRR
                              ? vccmvRRValue.toDouble()
                              : vccmvIe
                                  ? vccmvIeValue.toDouble()
                                  : vccmvPeep
                                      ? vccmvPeepValue.toDouble()
                                      : vccmvPcMax
                                          ? vccmvPcMaxValue.toDouble()
                                          : vccmvFio2
                                              ? vccmvFio2Value.toDouble()
                                              : vccmvVt
                                                  ? vccmvVtValue.toDouble()
                                                  : vccmvPcMin
                                                      ? vccmvPcMinValue
                                                          .toDouble()
                                                      : vccmvFlowRamp
                                                          ? vccmvFlowRampValue
                                                              .toDouble()
                                                          : "",
                          onChanged: (double value) {
                            setState(() {
                              if (vccmvRR == true) {
                                setState(() {
                                  vccmvRRValue = value.toInt();
                                });
                              } else if (vccmvIe == true) {
                                setState(() {
                                  vccmvIeValue = value.toInt();
                                });
                              } else if (vccmvPeep == true) {
                                setState(() {
                                  vccmvPeepValue = value.toInt();
                                  // if (vccmvPcMinValue <= vccmvPeepValue) {
                                  //   vccmvPcMinValue = value.toInt() + 1;
                                  // if (vccmvPcMaxValue <= vccmvPcMinValue) {
                                  //   vccmvPcMaxValue = value.toInt() + 1;
                                  // }
                                  // }
                                });
                              } else if (vccmvFio2 == true) {
                                setState(() {
                                  vccmvFio2Value = value.toInt();
                                });
                              } else if (vccmvVt == true) {
                                setState(() {
                                  vccmvVtValue = value.toInt();
                                });
                              } else if (vccmvPcMin == true) {
                                if (value.toInt() < 90) {
                                  vccmvPcMinValue = value.toInt();
                                  vccmvPcMaxValue = vccmvPcMinValue + 1;
                                }
                              } else if (vccmvPcMax == true) {
                                setState(() {
                                  if (value.toInt() <= vccmvPcMinValue + 1) {
                                    vccmvPcMaxValue = vccmvPcMinValue + 1;
                                  } else {
                                    vccmvPcMaxValue = value.toInt();
                                  }
                                });
                              } else if (vccmvFlowRamp == true) {
                                setState(() {
                                  vccmvFlowRampValue = value.toInt();
                                });
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45.0, right: 45.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(vccmvIe
                                ? getIeData(vccmvIeValue, 1)
                                : vccmvminValue.toString()),
                            Text(
                              vccmvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(vccmvIe
                                ? getIeData(vccmvmaxValue, 1)
                                : vccmvmaxValue.toString())
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  vsimvData() {
    return Row(
      children: [
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 60;
                  vsimvminValue = 1;
                  vsimvparameterName = "RR";
                  vsimvparameterUnits = "bpm";
                  vsimvItrig = false;
                  vsimvRr = true;
                  vsimvIe = false;
                  vsimvPeep = false;
                  vsimvVt = false;
                  vsimvPcMin = false;
                  vsimvPcMax = false;
                  vsimvFio2 = false;
                  vsimvFlowRamp = false;
                  vsimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vsimvRr ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "RR",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vsimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "60",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vsimvRrValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vsimvRr
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vsimvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vsimvRrValue != null
                                    ? vsimvRrValue / 60
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 61;
                  vsimvminValue = 1;
                  vsimvparameterName = "I:E";
                  vsimvparameterUnits = "";
                  vsimvItrig = false;
                  vsimvRr = false;
                  vsimvIe = true;
                  vsimvPeep = false;
                  vsimvVt = false;
                  vsimvPcMin = false;
                  vsimvPcMax = false;
                  vsimvFio2 = false;
                  vsimvFlowRamp = false;
                  vsimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vsimvIe ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I:E",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vsimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1:4.0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "4.0:1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                getIeData(vsimvIeValue, 1),
                                // ,
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vsimvIe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vsimvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vsimvIeValue != null
                                    ? vsimvIeValue / 61
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 30;
                  vsimvminValue = 0;
                  vsimvparameterName = "PEEP";
                  vsimvparameterUnits = "cmH\u2082O";
                  vsimvItrig = false;
                  vsimvRr = false;
                  vsimvIe = false;
                  vsimvPeep = true;
                  vsimvVt = false;
                  vsimvPcMin = false;
                  vsimvPcMax = false;
                  vsimvFio2 = false;
                  vsimvFlowRamp = false;
                  vsimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vsimvPeep ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PEEP",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vsimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "30",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vsimvPeepValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vsimvPeep
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vsimvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vsimvPeepValue != null
                                    ? vsimvPeepValue / 30
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 1200;
                  vsimvminValue = 200;
                  vsimvparameterName = "Vt";
                  vsimvparameterUnits = "mL";
                  vsimvItrig = false;
                  vsimvRr = false;
                  vsimvIe = false;
                  vsimvPeep = false;
                  vsimvVt = true;
                  vsimvPcMin = false;
                  vsimvPcMax = false;
                  vsimvFio2 = false;
                  vsimvFlowRamp = false;
                  vsimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vsimvVt ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Vt",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vsimvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vsimvVtValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vsimvVt
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vsimvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vsimvVtValue != null
                                    ? vsimvVtValue / 2000
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 100;
                  vsimvminValue = 21;
                  vsimvparameterName = "FiO\u2082";
                  vsimvparameterUnits = "%";
                  vsimvItrig = false;
                  vsimvRr = false;
                  vsimvIe = false;
                  vsimvPeep = false;
                  vsimvVt = false;
                  vsimvPcMin = false;
                  vsimvPcMax = false;
                  vsimvFio2 = true;
                  vsimvFlowRamp = false;
                  vsimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vsimvFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO\u2082",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vsimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "%",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "21",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vsimvFio2Value.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vsimvFio2
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vsimvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vsimvFio2Value != null
                                    ? vsimvFio2Value / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 10;
                  vsimvminValue = 1;
                  vsimvparameterName = "I Trig";
                  vsimvparameterUnits = "cmH\u2082O Below PEEP";
                  vsimvItrig = true;
                  vsimvRr = false;
                  vsimvIe = false;
                  vsimvPeep = false;
                  vsimvVt = false;
                  vsimvPcMin = false;
                  vsimvPcMax = false;
                  vsimvFio2 = false;
                  vsimvFlowRamp = false;
                  vsimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vsimvItrig ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I Trig",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vsimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "-" + vsimvItrigValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vsimvItrig
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vsimvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vsimvItrigValue != null
                                    ? vsimvItrigValue / 10
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 100;
                  vsimvminValue = 10;
                  vsimvparameterName = "PC Min";
                  vsimvparameterUnits = "cmH\u2082O";
                  vsimvItrig = false;
                  vsimvRr = false;
                  vsimvIe = false;
                  vsimvPeep = false;
                  vsimvVt = false;
                  vsimvPcMin = true;
                  vsimvPcMax = false;
                  vsimvFio2 = false;
                  vsimvFlowRamp = false;
                  vsimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vsimvPcMin ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC Min",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vsimvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vsimvPcMinValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vsimvPcMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vsimvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vsimvPcMinValue != null
                                    ? vsimvPcMinValue / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 100;
                  vsimvminValue = 10;
                  vsimvparameterName = "PC Max";
                  vsimvparameterUnits = "cmH\u2082O";
                  vsimvItrig = false;
                  vsimvRr = false;
                  vsimvIe = false;
                  vsimvPeep = false;
                  vsimvVt = false;
                  vsimvPcMin = false;
                  vsimvPcMax = true;
                  vsimvFio2 = false;
                  vsimvFlowRamp = false;
                  vsimvPs = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vsimvPcMax ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC Max",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vsimvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vsimvPcMaxValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vsimvPcMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vsimvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vsimvPcMaxValue != null
                                    ? vsimvPcMaxValue / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),

            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 70;
                  vsimvminValue = 1;
                  vsimvparameterName = "PS";
                  vsimvparameterUnits = "cmH\u2082O";
                  vsimvItrig = false;
                  vsimvRr = false;
                  vsimvIe = false;
                  vsimvPeep = false;
                  vsimvVt = false;
                  vsimvPs = true;
                  vsimvPcMin = false;
                  vsimvPcMax = false;
                  vsimvFio2 = false;
                  vsimvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vsimvPs ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PS",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vsimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "70",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vsimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vsimvPsValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vsimvPs
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vsimvPs
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vsimvPsValue != null
                                    ? vsimvPsValue / 70
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),

            // InkWell(
            //   onTap: () {
            //     setState(() {
            //       vsimvmaxValue = 4;
            //       vsimvminValue = 0;
            //       vsimvparameterName = "Flow Ramp";
            //       vsimvparameterUnits = "";
            //       vsimvItrig = false;
            //       vsimvRr = false;
            //       vsimvIe = false;
            //       vsimvPeep = false;
            //       vsimvVt = false;
            //       vsimvPcMin = false;
            //       vsimvPcMax = false;
            //       vsimvFio2 = false;
            //       vsimvFlowRamp = true;
            //     });
            //   },
            //   child: Center(
            //     child: Container(
            //       width: 146,
            //       height: 130,
            //       child: Card(
            //         elevation: 40,
            //         color:
            //             vsimvFlowRamp ? Color(0xFFE0E0E0) : Color(0xFF213855),
            //         child: Padding(
            //           padding: const EdgeInsets.all(6.0),
            //           child: Center(
            //               child: Stack(
            //             children: [
            //               Align(
            //                 alignment: Alignment.topLeft,
            //                 child: Text(
            //                   "Flow Ramp",
            //                   style: TextStyle(
            //                       fontSize: 15,
            //                       fontWeight: FontWeight.bold,
            //                       color: vsimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.topRight,
            //                 child: Text(
            //                   "",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: vsimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomRight,
            //                 child: Text(
            //                   "4",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: vsimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomLeft,
            //                 child: Text(
            //                   "0",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: vsimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 1.0),
            //                   child: Text(
            //                     vsimvFlowRampValue.toString() == "0"
            //                         ? "AF"
            //                         : vsimvFlowRampValue.toString() == "1"
            //                             ? "AS"
            //                             : vsimvFlowRampValue.toString() == "2"
            //                                 ? "DF"
            //                                 : vsimvFlowRampValue.toString() ==
            //                                         "3"
            //                                     ? "DS"
            //                                     : vsimvFlowRampValue
            //                                                 .toString() ==
            //                                             "4"
            //                                         ? "S"
            //                                         : "S",
            //                     style: TextStyle(
            //                         fontSize: 35,
            //                         color: vsimvFlowRamp
            //                             ? Color(0xFF213855)
            //                             : Color(0xFFE0E0E0)),
            //                   ),
            //                 ),
            //               ),
            //               Padding(
            //                 padding: const EdgeInsets.only(
            //                     bottom: 20.0, left: 10, right: 10),
            //                 child: Align(
            //                   alignment: Alignment.bottomCenter,
            //                   child: LinearProgressIndicator(
            //                     backgroundColor: Colors.grey,
            //                     valueColor: AlwaysStoppedAnimation<Color>(
            //                       vsimvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0),
            //                     ),
            //                     value: vsimvFlowRampValue != null
            //                         ? vsimvFlowRampValue / 4
            //                         : 0,
            //                   ),
            //                 ),
            //               )
            //             ],
            //           )),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            // Container(height: 260),
          ],
        ),
        SizedBox(width: 140),
        Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                height: 145,
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Alarm Limit",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("RR"),
                                  Text("$minRrtotal-$maxRrtotal"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("Vte"),
                                    Text("$minvte-$maxvte"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("Ppeak"),
                                  Text("$minppeak-$maxppeak"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("PEEP"),
                                    Text("$minpeep-$maxpeep"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 5,
            ),
            patientId != ""
                ? Container(
                    height: 40,
                    width: 400,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFE0E0E0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("IBW : " + patientWeight.toString()),
                          Text("Ideal Vt : " +
                              (int.tryParse(patientWeight) * 6).toString() +
                              " - " +
                              (int.tryParse(patientWeight) * 8).toString())
                        ],
                      ),
                    ))
                : Container(),
            SizedBox(
              height: 5,
            ),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                width: 400,
                height: 195,
                child: Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.remove,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (vsimvItrig == true &&
                                    vsimvItrigValue != vsimvminValue) {
                                  setState(() {
                                    vsimvItrigValue = vsimvItrigValue - 1;
                                  });
                                } else if (vsimvPeep == true &&
                                    vsimvPeepValue != vsimvminValue) {
                                  setState(() {
                                    vsimvPeepValue = vsimvPeepValue - 1;
                                    if (vsimvItrigValue > 1 &&
                                        vsimvItrigValue > vsimvPeepValue) {
                                      vsimvItrigValue = vsimvPeepValue;
                                    }
                                  });
                                } else if (vsimvRr == true &&
                                    vsimvRrValue != vsimvminValue) {
                                  setState(() {
                                    vsimvRrValue = vsimvRrValue - 1;
                                  });
                                } else if (vsimvIe == true &&
                                    vsimvIeValue != vsimvminValue) {
                                  setState(() {
                                    vsimvIeValue = vsimvIeValue - 1;
                                  });
                                } else if (vsimvVt == true &&
                                    vsimvVtValue != vsimvminValue) {
                                  setState(() {
                                    vsimvVtValue = vsimvVtValue - 1;
                                  });
                                } else if (vsimvPcMin == true &&
                                    vsimvPcMinValue != vsimvminValue) {
                                  setState(() {
                                    vsimvPcMinValue = vsimvPcMinValue - 1;
                                    // if (vsimvPcMinValue >= vsimvPcMaxValue) {
                                    //   vsimvPcMaxValue = vsimvPcMaxValue - 1;
                                    // }
                                  });
                                } else if (vsimvPcMax == true &&
                                    vsimvPcMaxValue != vsimvPcMinValue + 1) {
                                  vsimvPcMaxValue = vsimvPcMaxValue - 1;
                                } else if (vsimvFio2 == true &&
                                    vsimvFio2Value != vsimvminValue) {
                                  setState(() {
                                    vsimvFio2Value = vsimvFio2Value - 1;
                                  });
                                } else if (vsimvFlowRamp == true &&
                                    vsimvFlowRampValue != vsimvminValue) {
                                  setState(() {
                                    vsimvFlowRampValue = vsimvFlowRampValue - 1;
                                  });
                                } else if (vsimvPs == true &&
                                    vsimvPsValue != vsimvminValue) {
                                  setState(() {
                                    vsimvPsValue = vsimvPsValue - 1;
                                  });
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          Text(
                            vsimvparameterName,
                            style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.normal),
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (vsimvItrig == true &&
                                    vsimvItrigValue != vsimvmaxValue) {
                                  setState(() {
                                    vsimvItrigValue = vsimvItrigValue + 1;
                                    if (vsimvPeepValue <= vsimvItrigValue) {
                                      if (vsimvPeepValue == 0) {
                                        vsimvItrigValue = 1;
                                      } else {
                                        vsimvItrigValue = vsimvPeepValue;
                                      }
                                    }
                                  });
                                } else if (vsimvPeep == true &&
                                    vsimvPeepValue != vsimvmaxValue) {
                                  setState(() {
                                    vsimvPeepValue = vsimvPeepValue + 1;
                                  });
                                } else if (vsimvRr == true &&
                                    vsimvRrValue != vsimvmaxValue) {
                                  setState(() {
                                    vsimvRrValue = vsimvRrValue + 1;
                                  });
                                } else if (vsimvIe == true &&
                                    vsimvIeValue != vsimvmaxValue) {
                                  setState(() {
                                    vsimvIeValue = vsimvIeValue + 1;
                                  });
                                } else if (vsimvVt == true &&
                                    vsimvVtValue != vsimvmaxValue) {
                                  setState(() {
                                    vsimvVtValue = vsimvVtValue + 1;
                                  });
                                } else if (vsimvPcMin == true &&
                                    vsimvPcMinValue != pacvmaxValue) {
                                  setState(() {
                                    if (vsimvPcMaxValue < 90) {
                                      vsimvPcMinValue = vsimvPcMinValue + 1;
                                      vsimvPcMaxValue = vsimvPcMinValue + 1;
                                    }
                                  });
                                } else if (vsimvPcMax == true &&
                                    vsimvPcMaxValue != pacvmaxValue) {
                                  setState(() {
                                    vsimvPcMaxValue = vsimvPcMaxValue + 1;
                                  });
                                } else if (vsimvFio2 == true &&
                                    vsimvFio2Value != vsimvmaxValue) {
                                  setState(() {
                                    vsimvFio2Value = vsimvFio2Value + 1;
                                  });
                                } else if (vsimvFlowRamp == true &&
                                    vsimvFlowRampValue != vsimvmaxValue) {
                                  setState(() {
                                    vsimvFlowRampValue = vsimvFlowRampValue + 1;
                                  });
                                } else if (vsimvPs == true &&
                                    vsimvPsValue != vsimvmaxValue) {
                                  setState(() {
                                    vsimvPsValue = vsimvPsValue + 1;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              vsimvItrig
                                  ? "-" + vsimvItrigValue.toInt().toString()
                                  : vsimvPeep
                                      ? vsimvPeepValue.toInt().toString()
                                      : vsimvRr
                                          ? vsimvRrValue.toInt().toString()
                                          : vsimvIe
                                              ? getIeData(vsimvIeValue, 1)
                                                  .toString()
                                              : vsimvVt
                                                  ? vsimvVtValue
                                                      .toInt()
                                                      .toString()
                                                  : vsimvPcMin
                                                      ? vsimvPcMinValue
                                                          .toInt()
                                                          .toString()
                                                      : vsimvPcMax
                                                          ? vsimvPcMaxValue
                                                              .toInt()
                                                              .toString()
                                                          : vsimvFio2
                                                              ? vsimvFio2Value
                                                                  .toInt()
                                                                  .toString()
                                                              : vsimvFlowRamp
                                                                  ? vsimvFlowRampValue
                                                                      .toInt()
                                                                      .toString()
                                                                  : vsimvPs
                                                                      ? vsimvPsValue
                                                                          .toInt()
                                                                          .toString()
                                                                      : "",
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                          width: 350,
                          child: Slider(
                            min: vsimvminValue.toDouble() ?? 0,
                            max: vsimvmaxValue.toDouble(),
                            onChanged: (double value) {
                              if (vsimvItrig == true && vsimvItrigValue != 10) {
                                setState(() {
                                  vsimvItrigValue = vsimvItrigValue + 1;
                                  if (vsimvPeepValue <= vsimvItrigValue) {
                                    if (vsimvPeepValue == 0) {
                                      vsimvItrigValue = 1;
                                    } else {
                                      vsimvItrigValue = vsimvPeepValue;
                                    }
                                  }
                                });
                              } else if (vsimvPeep == true) {
                                setState(() {
                                  vsimvPeepValue = value.toInt();
                                  if (vsimvItrigValue > 1 &&
                                      vsimvItrigValue > vsimvPeepValue) {
                                    vsimvItrigValue = vsimvPeepValue;
                                  }
                                });
                              } else if (vsimvRr == true) {
                                setState(() {
                                  vsimvRrValue = value.toInt();
                                });
                              } else if (vsimvIe == true) {
                                setState(() {
                                  vsimvIeValue = value.toInt();
                                });
                              } else if (vsimvVt == true) {
                                setState(() {
                                  vsimvVtValue = value.toInt();
                                });
                              } else if (vsimvPcMin == true) {
                                if (value.toInt() < 90) {
                                  vsimvPcMinValue = value.toInt();
                                  vsimvPcMaxValue = vsimvPcMinValue + 1;
                                }
                              } else if (vsimvPcMax == true) {
                                setState(() {
                                  if (value.toInt() <= vsimvPcMinValue + 1) {
                                    vsimvPcMaxValue = vsimvPcMinValue + 1;
                                  } else {
                                    vsimvPcMaxValue = value.toInt();
                                  }
                                });
                              } else if (vsimvFio2 == true) {
                                setState(() {
                                  vsimvFio2Value = value.toInt();
                                });
                              } else if (vsimvFlowRamp == true) {
                                setState(() {
                                  vsimvFlowRampValue = value.toInt();
                                });
                              } else if (vsimvPs == true) {
                                setState(() {
                                  vsimvPsValue = value.toInt();
                                });
                              }
                            },
                            value: vsimvItrig
                                ? vsimvItrigValue.toDouble()
                                : vsimvPeep
                                    ? vsimvPeepValue.toDouble()
                                    : vsimvRr
                                        ? vsimvRrValue.toDouble()
                                        : vsimvIe
                                            ? vsimvIeValue.toDouble()
                                            : vsimvVt
                                                ? vsimvVtValue.toDouble()
                                                : vsimvPcMin
                                                    ? vsimvPcMinValue.toDouble()
                                                    : vsimvPcMax
                                                        ? vsimvPcMaxValue
                                                            .toDouble()
                                                        : vsimvFio2
                                                            ? vsimvFio2Value
                                                                .toDouble()
                                                            : vsimvFlowRamp
                                                                ? vsimvFlowRampValue
                                                                    .toDouble()
                                                                : vsimvPs
                                                                    ? vsimvPsValue
                                                                        .toDouble()
                                                                    : "",
                          )),
                      SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45.0, right: 45.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(vsimvItrig
                                ? "-" + vsimvminValue.toString()
                                : vsimvminValue.toString()),
                            Text(
                              vsimvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(vsimvItrig
                                ? "-" + vsimvmaxValue.toString()
                                : vsimvmaxValue.toString())
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  vacvData() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 60;
                  vacvminValue = 1;
                  vacvparameterName = "RR";
                  vacvparameterUnits = "bpm";
                  vacvItrig = false;
                  vacvRr = true;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvRr ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "RR",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "60",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvRrValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvRr
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvRr
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value:
                                    vacvRrValue != null ? vacvRrValue / 60 : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 61;
                  vacvminValue = 1;
                  vacvparameterName = "I:E";
                  vacvparameterUnits = "";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = true;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvIe ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I:E",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1:4.0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "4.0:1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                // vacvIeValue,
                                getIeData(vacvIeValue, 1),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvIe
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvIe
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value:
                                    vacvIeValue != null ? vacvIeValue / 4 : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 30;
                  vacvminValue = 0;
                  vacvparameterName = "PEEP";
                  vacvparameterUnits = "cmH\u2082O";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = true;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvPeep ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PEEP",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "30",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvPeepValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvPeep
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvPeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvPeepValue != null
                                    ? vacvPeepValue / 30
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 1200;
                  vacvminValue = 200;
                  vacvparameterName = "Vt";
                  vacvparameterUnits = "mL";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = true;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvVt ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Vt",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "1200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "200",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvVtValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvVt
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvVt
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvVtValue != null
                                    ? vacvVtValue / 1200
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 100;
                  vacvminValue = 21;
                  vacvparameterName = "FiO\u2082";
                  vacvparameterUnits = "%";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = true;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO\u2082",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "%",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "21",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvFio2Value.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvFio2
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvFio2Value != null
                                    ? vacvFio2Value / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 10;
                  vacvminValue = 1;
                  vacvparameterName = "I Trig";
                  vacvparameterUnits = "cmH\u2082O Below PEEP";
                  vacvItrig = true;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvItrig ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "I Trig",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "-10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "-1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "-" + vacvItrigValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvItrig
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvItrig
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvItrigValue != null
                                    ? vacvItrigValue / 10
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 100;
                  vacvminValue = 10;
                  vacvparameterName = "PC Min";
                  vacvparameterUnits = "mL";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = true;
                  vacvPcMax = false;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvPcMin ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC Min",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvPcMinValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvPcMin
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvPcMin
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvPcMinValue != null
                                    ? vacvPcMinValue / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 100;
                  vacvminValue = 10;
                  vacvparameterName = "PC Max";
                  vacvparameterUnits = "mL";
                  vacvItrig = false;
                  vacvRr = false;
                  vacvIe = false;
                  vacvPeep = false;
                  vacvVt = false;
                  vacvPcMin = false;
                  vacvPcMax = true;
                  vacvFio2 = false;
                  vacvFlowRamp = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: vacvPcMax ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PC Max",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "10",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                vacvPcMaxValue.toString(),
                                style: TextStyle(
                                    fontSize: 35,
                                    color: vacvPcMax
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20.0, left: 10, right: 10),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vacvPcMax
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0),
                                ),
                                value: vacvPcMaxValue != null
                                    ? vacvPcMaxValue / 100
                                    : 0,
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),

            // InkWell(
            //   onTap: () {
            //     setState(() {
            //       vacvmaxValue = 4;
            //       vacvminValue = 0;
            //       vacvparameterName = "Flow Ramp";
            //       vacvparameterUnits = "";
            //       vacvItrig = false;
            //       vacvRr = false;
            //       vacvIe = false;
            //       vacvPeep = false;
            //       vacvVt = false;
            //       vacvPcMin = false;
            //       vacvPcMax = false;
            //       vacvFio2 = false;
            //       vacvFlowRamp = true;
            //     });
            //   },
            //   child: Center(
            //     child: Container(
            //       width: 146,
            //       height: 130,
            //       child: Card(
            //         elevation: 40,
            //         color: vacvFlowRamp ? Color(0xFFE0E0E0) : Color(0xFF213855),
            //         child: Padding(
            //           padding: const EdgeInsets.all(6.0),
            //           child: Center(
            //               child: Stack(
            //             children: [
            //               Align(
            //                 alignment: Alignment.topLeft,
            //                 child: Text(
            //                   "Flow Ramp",
            //                   style: TextStyle(
            //                       fontSize: 15,
            //                       fontWeight: FontWeight.bold,
            //                       color: vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.topRight,
            //                 child: Text(
            //                   "",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomRight,
            //                 child: Text(
            //                   "4",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomLeft,
            //                 child: Text(
            //                   "0",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 1.0),
            //                   child: Text(
            //                     vacvFlowRampValue.toString() == "0"
            //                         ? "AF"
            //                         : vacvFlowRampValue.toString() == "1"
            //                             ? "AS"
            //                             : vacvFlowRampValue.toString() == "2"
            //                                 ? "DF"
            //                                 : vacvFlowRampValue.toString() ==
            //                                         "3"
            //                                     ? "DS"
            //                                     : vacvFlowRampValue
            //                                                 .toString() ==
            //                                             "4"
            //                                         ? "S"
            //                                         : "S",
            //                     style: TextStyle(
            //                         fontSize: 35,
            //                         color: vacvFlowRamp
            //                             ? Color(0xFF213855)
            //                             : Color(0xFFE0E0E0)),
            //                   ),
            //                 ),
            //               ),
            //               Padding(
            //                 padding: const EdgeInsets.only(
            //                     bottom: 20.0, left: 10, right: 10),
            //                 child: Align(
            //                   alignment: Alignment.bottomCenter,
            //                   child: LinearProgressIndicator(
            //                     backgroundColor: Colors.grey,
            //                     valueColor: AlwaysStoppedAnimation<Color>(
            //                       vacvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0),
            //                     ),
            //                     value: vacvFlowRampValue != null
            //                         ? vacvFlowRampValue / 4
            //                         : 0,
            //                   ),
            //                 ),
            //               )
            //             ],
            //           )),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
        SizedBox(width: 140),
        Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                height: 145,
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Alarm Limit",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("RR"),
                                  Text("$minRrtotal-$maxRrtotal"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("Vte"),
                                    Text("$minvte-$maxvte"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("Ppeak"),
                                  Text("$minppeak-$maxppeak"),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                  children: [
                                    Text("PEEP"),
                                    Text("$minpeep-$maxpeep"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 5,
            ),
            patientId != ""
                ? Container(
                    height: 40,
                    width: 400,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFE0E0E0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("IBW : " + patientWeight.toString()),
                          Text("Ideal Vt : " +
                              (int.tryParse(patientWeight) * 6).toString() +
                              " - " +
                              (int.tryParse(patientWeight) * 8).toString())
                        ],
                      ),
                    ))
                : Container(),
            SizedBox(
              height: 5,
            ),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                width: 400,
                height: 195,
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.remove,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (vacvItrig == true &&
                                    vacvItrigValue != vacvminValue) {
                                  setState(() {
                                    vacvItrigValue = vacvItrigValue - 1;
                                  });
                                } else if (vacvPeep == true &&
                                    vacvPeepValue != vacvminValue) {
                                  setState(() {
                                    vacvPeepValue = vacvPeepValue - 1;
                                    if (vacvItrigValue > 1 &&
                                        vacvItrigValue > vacvPeepValue) {
                                      vacvItrigValue = vacvPeepValue;
                                    }
                                  }); //peep negative
                                } else if (vacvRr == true &&
                                    vacvRrValue != vacvminValue) {
                                  setState(() {
                                    vacvRrValue = vacvRrValue - 1;
                                  });
                                } else if (vacvIe == true &&
                                    vacvIeValue != vacvminValue) {
                                  setState(() {
                                    vacvIeValue = vacvIeValue - 1;
                                  });
                                } else if (vacvVt == true &&
                                    vacvVtValue != vacvminValue) {
                                  setState(() {
                                    vacvVtValue = vacvVtValue - 1;
                                  });
                                } else if (vacvPcMin == true &&
                                    vacvPcMinValue != vacvminValue) {
                                  setState(() {
                                    vacvPcMinValue = vacvPcMinValue - 1;
                                    // if (vacvPcMinValue >= vacvPcMaxValue) {
                                    //   vacvPcMaxValue = vacvPcMaxValue - 1;
                                    // }
                                  });
                                } else if (vacvPcMax == true &&
                                    vacvPcMaxValue != vacvPcMinValue + 1) {
                                  vacvPcMaxValue = vacvPcMaxValue - 1;
                                } else if (vacvFio2 == true &&
                                    vacvFio2Value != vacvminValue) {
                                  setState(() {
                                    vacvFio2Value = vacvFio2Value - 1;
                                  });
                                } else if (vacvFlowRamp == true &&
                                    vacvFlowRampValue != vacvminValue) {
                                  setState(() {
                                    vacvFlowRampValue = vacvFlowRampValue - 1;
                                  });
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          Text(
                            vacvparameterName,
                            style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.normal),
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 45,
                            ),
                            onPressed: () {
                              setState(() {
                                if (vacvItrig == true &&
                                    vacvItrigValue != vacvmaxValue) {
                                  setState(() {
                                    vacvItrigValue = vacvItrigValue + 1;
                                    if (vacvPeepValue <= vacvItrigValue) {
                                      if (vacvPeepValue == 0) {
                                        vacvItrigValue = 1;
                                      } else {
                                        vacvItrigValue = vacvPeepValue;
                                      }
                                    }
                                  }); //itrig positive
                                } else if (vacvPeep == true &&
                                    vacvPeepValue != vacvmaxValue) {
                                  setState(() {
                                    vacvPeepValue = vacvPeepValue + 1;
                                    // if (vacvPcMinValue <= vacvPeepValue) {
                                    //   vacvPcMinValue = vacvPeepValue + 1;
                                    //   if (vacvPcMaxValue <= vacvPcMinValue) {
                                    //     vacvPcMaxValue = vacvPcMinValue + 1;
                                    //   }
                                    // }
                                  });
                                } else if (vacvRr == true &&
                                    vacvRrValue != vacvmaxValue) {
                                  setState(() {
                                    vacvRrValue = vacvRrValue + 1;
                                  });
                                } else if (vacvIe == true &&
                                    vacvIeValue != vacvmaxValue) {
                                  setState(() {
                                    vacvIeValue = vacvIeValue + 1;
                                  });
                                } else if (vacvVt == true &&
                                    vacvVtValue != vacvmaxValue) {
                                  setState(() {
                                    vacvVtValue = vacvVtValue + 1;
                                  });
                                } else if (vacvPcMin == true &&
                                    vacvPcMinValue != pacvmaxValue) {
                                  setState(() {
                                    if (vacvPcMaxValue < 90) {
                                      vacvPcMinValue = vacvPcMinValue + 1;
                                      vacvPcMaxValue = vacvPcMinValue + 1;
                                    }
                                  });
                                } else if (vacvPcMax == true &&
                                    vacvPcMaxValue != pacvmaxValue) {
                                  setState(() {
                                    vacvPcMaxValue = vacvPcMaxValue + 1;
                                  });
                                } else if (vacvFio2 == true &&
                                    vacvFio2Value != vacvmaxValue) {
                                  setState(() {
                                    vacvFio2Value = vacvFio2Value + 1;
                                  });
                                } else if (vacvFlowRamp == true &&
                                    vacvFlowRampValue != vacvmaxValue) {
                                  setState(() {
                                    vacvFlowRampValue = vacvFlowRampValue + 1;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              vacvItrig
                                  ? "-" + vacvItrigValue.toInt().toString()
                                  : vacvPeep
                                      ? vacvPeepValue.toInt().toString()
                                      : vacvRr
                                          ? vacvRrValue.toInt().toString()
                                          : vacvIe
                                              ? getIeData(vacvIeValue, 1)
                                              : vacvVt
                                                  ? vacvVtValue
                                                      .toInt()
                                                      .toString()
                                                  : vacvPcMin
                                                      ? vacvPcMinValue
                                                          .toInt()
                                                          .toString()
                                                      : vacvPcMax
                                                          ? vacvPcMaxValue
                                                              .toInt()
                                                              .toString()
                                                          : vacvFio2
                                                              ? vacvFio2Value
                                                                  .toInt()
                                                                  .toString()
                                                              : vacvFlowRamp
                                                                  ? vacvFlowRampValue
                                                                      .toInt()
                                                                      .toString()
                                                                  : "",
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      // vacvFio2
                      //     ? Container()
                      //     :
                      Container(
                          width: 350,
                          child: Slider(
                            min: vacvminValue.toDouble(),
                            max: vacvmaxValue.toDouble(),
                            onChanged: (double value) {
                              if (vacvItrig == true && vacvItrigValue != 10) {
                                setState(() {
                                  vacvItrigValue = vacvItrigValue + 1;
                                  if (vacvPeepValue <= vacvItrigValue) {
                                    if (vacvPeepValue == 0) {
                                      vacvItrigValue = 1;
                                    } else {
                                      vacvItrigValue = vacvPeepValue;
                                    }
                                  }
                                }); // slider itrig
                              } else if (vacvPeep == true) {
                                setState(() {
                                  vacvPeepValue = value.toInt();
                                  if (vacvItrigValue > 1 &&
                                      vacvItrigValue > vacvPeepValue) {
                                    vacvItrigValue = vacvPeepValue;
                                  }
                                });
                              } else if (vacvRr == true) {
                                setState(() {
                                  vacvRrValue = value.toInt();
                                });
                              } else if (vacvIe == true) {
                                setState(() {
                                  vacvIeValue = value.toInt();
                                });
                              } else if (vacvVt == true) {
                                setState(() {
                                  vacvVtValue = value.toInt();
                                });
                              } else if (vacvPcMin == true) {
                                if (value.toInt() < 90) {
                                  vacvPcMinValue = value.toInt();
                                  vacvPcMaxValue = vacvPcMinValue + 1;
                                }
                              } else if (vacvPcMax == true) {
                                setState(() {
                                  if (value.toInt() <= vacvPcMinValue + 1) {
                                    vacvPcMaxValue = vacvPcMinValue + 1;
                                  } else {
                                    vacvPcMaxValue = value.toInt();
                                  }
                                });
                              } else if (vacvFio2 == true) {
                                setState(() {
                                  vacvFio2Value = value.toInt();
                                });
                              } else if (vacvFlowRamp == true) {
                                setState(() {
                                  vacvFlowRampValue = value.toInt();
                                });
                              }
                            },
                            value: vacvItrig
                                ? vacvItrigValue.toDouble()
                                : vacvPeep
                                    ? vacvPeepValue.toDouble()
                                    : vacvRr
                                        ? vacvRrValue.toDouble()
                                        : vacvIe
                                            ? vacvIeValue.toDouble()
                                            : vacvVt
                                                ? vacvVtValue.toDouble()
                                                : vacvPcMin
                                                    ? vacvPcMinValue.toDouble()
                                                    : vacvPcMax
                                                        ? vacvPcMaxValue
                                                            .toDouble()
                                                        : vacvFio2
                                                            ? vacvFio2Value
                                                                .toDouble()
                                                            : vacvFlowRamp
                                                                ? vacvFlowRampValue
                                                                    .toDouble()
                                                                : "",
                          )),
                      SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45.0, right: 45.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(vacvIe
                                ? getIeData(vacvminValue, 1)
                                : vacvItrig
                                    ? "-" + vacvminValue.toString()
                                    : vacvminValue.toString()),
                            Text(
                              vacvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(vacvIe
                                ? getIeData(vacvminValue, 1)
                                : vacvItrig
                                    ? "-" + vacvmaxValue.toString()
                                    : vacvmaxValue.toString())
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  graphs() {
    return Container(
      padding: EdgeInsets.only(left: 170, right: 0, top: 45),
      child: Column(
        children: [
          Container(
            width: 520,
            height: 110,
            child: Stack(
              children: [
                Container(
                    margin: EdgeInsets.only(left: 20, right: 10, top: 10),
                    child: scopeOne),
                Container(
                    margin: EdgeInsets.only(left: 10, top: 8),
                    child: Text(
                      "100" + " cmH\u2082O",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                    margin: EdgeInsets.only(left: 15, top: 93),
                    child: Text(
                      "0",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                  margin: EdgeInsets.only(left: 28, top: 24),
                  width: 1,
                  color: Colors.grey,
                  height: 85,
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: 28,
                    top: 99,
                  ),
                  color: Colors.grey,
                  height: 1,
                  width: 473,
                ),
                Container(
                  margin: EdgeInsets.only(left: 12, top: 35),
                  child: RotatedBox(
                      quarterTurns: 3,
                      child: Text("Pressure",
                          style: TextStyle(color: Colors.grey, fontSize: 10))),
                ),

                // Container(
                //     margin: EdgeInsets.only(left: 450),
                //     child: Text(
                //       "Pressure ",
                //       style: TextStyle(color: Colors.white),
                //     )),
                Container(
                    margin: EdgeInsets.only(left: 502, top: 90),
                    child: Text(
                      "s",
                      style: TextStyle(color: Colors.grey),
                    )),
                // Container(
                //     margin: EdgeInsets.only(left: 60, top: 88),
                //     child: Text(
                //       "|",
                //       style: TextStyle(color: Colors.white),
                //     )),
                // Container(
                //     margin: EdgeInsets.only(left: 106.6, top: 88),
                //     child: Text(
                //       "|",
                //       style: TextStyle(color: Colors.white),
                //     )),
                // Container(
                //     margin: EdgeInsets.only(left: 156, top: 88),
                //     child: Text(
                //       "|",
                //       style: TextStyle(color: Colors.white),
                //     )),
                // Container(
                //     margin: EdgeInsets.only(left: 207.3, top: 88),
                //     child: Text(
                //       "|",
                //       style: TextStyle(color: Colors.white),
                //     )),
                // Container(
                //     margin: EdgeInsets.only(left: 260.6, top: 88),
                //     child: Text(
                //       "|",
                //       style: TextStyle(color: Colors.white),
                //     )),
                // Container(
                //     margin: EdgeInsets.only(left: 310, top: 88),
                //     child: Text(
                //       "|",
                //       style: TextStyle(color: Colors.white),
                //     )),
                // Container(
                //     margin: EdgeInsets.only(left: 363, top: 88),
                //     child: Text(
                //       "|",
                //       style: TextStyle(color: Colors.white),
                //     )),
                // Container(
                //     margin: EdgeInsets.only(left: 415, top: 88),
                //     child: Text(
                //       "|",
                //       style: TextStyle(color: Colors.white),
                //     )),
                // Container(
                //     margin: EdgeInsets.only(left: 460, top: 88),
                //     child: Text(
                //       "|",
                //       style: TextStyle(color: Colors.white),
                //     )),
              ],
            ),
          ),
          Container(
            width: 520,
            height: 150,
            child: Stack(
              children: [
                Container(
                    margin: EdgeInsets.only(
                      left: 20,
                      bottom: 10,
                      top: 10,
                      right: 10,
                    ),
                    child: scopeOne1),
                Container(
                    margin: EdgeInsets.only(left: 10, top: 5),
                    child: Text(
                      "200 Lpm",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                    margin: EdgeInsets.only(left: 10, top: 127),
                    child: Text(
                      "-90 Lpm",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                    margin: EdgeInsets.only(left: 15, top: 66),
                    child: Text(
                      "0",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                  margin: EdgeInsets.only(left: 28, top: 20),
                  width: 1,
                  color: Colors.grey,
                  height: 108,
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: 28,
                    top: 96,
                  ),
                  color: Colors.grey,
                  height: 1,
                  width: 473,
                ),
                Container(
                  margin: EdgeInsets.only(left: 12, top: 35),
                  child: RotatedBox(
                      quarterTurns: 3,
                      child: Text("Flow",
                          style: TextStyle(color: Colors.grey, fontSize: 10))),
                ),

                // Container(
                //     margin: EdgeInsets.only(left: 482),
                //     child: Text(
                //       "Flow ",
                //       style: TextStyle(color: Colors.white),
                //     )),
                Container(
                    margin: EdgeInsets.only(left: 502, top: 86),
                    child: Text(
                      "s",
                      style: TextStyle(color: Colors.grey),
                    ))
              ],
            ),
          ),
          Container(
            width: 520,
            height: 110,
            child: Stack(
              children: [
                Container(
                    margin: EdgeInsets.only(left: 20, right: 10, top: 10),
                    child: scopeOne2),
                Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Text(
                      "1000 mL",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                    margin: EdgeInsets.only(left: 15, top: 89),
                    child: Text(
                      "0",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                  margin: EdgeInsets.only(left: 30, top: 15),
                  width: 1,
                  color: Colors.grey,
                  height: 85,
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: 28,
                    top: 99,
                  ),
                  color: Colors.grey,
                  height: 1,
                  width: 473,
                ),
                Container(
                  margin: EdgeInsets.only(left: 12, top: 35),
                  child: RotatedBox(
                      quarterTurns: 3,
                      child: Text("Volume",
                          style: TextStyle(color: Colors.grey, fontSize: 10))),
                ),
                // Container(
                //     margin: EdgeInsets.only(left: 460),
                //     child: Text(
                //       "Volume ",
                //       style: TextStyle(color: Colors.white),
                //     )),
                Container(
                    margin: EdgeInsets.only(left: 502, top: 89),
                    child: Text(
                      "s",
                      style: TextStyle(color: Colors.grey),
                    ))
              ],
            ),
          ),
          Container(
            width: 480,
            height: 70,
            child: Card(
              color: alarmActive == "1" ? Colors.red : Color(0xFF171e27),
              // priorityNo=="0" ? Colors.red: priorityNo=="1" ? Colors.red : priorityNo=="2" ? Colors.orange : priorityNo=="3" ? Colors.yellow :

              child: Center(
                  child: Align(
                alignment: Alignment.centerLeft,
                child: Center(
                  child: Text(
                    alarmActive == "1" ? alarmMessage.toUpperCase() : "",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Future CommonClick(String value) async {
    var result = await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return CommonDialog(value);
        });

    // Fluttertoast.showToast(msg: result.toString());

    var data = result.split("ab")[1];
    int peepHighL = 0, peepLowL = 0;
    if (data == "peep") {
      int temp = int.tryParse(result.split("ab")[0]);
      peepHighL = ((temp & 0xFF00) >> 8);
      peepLowL = (temp & 0xFF);
      List<int> listObj = [01, 0x10, 00, 101, 0x00, 0x01, 0x02];
      listObj.add(peepHighL);
      listObj.add(peepLowL);
      // Fluttertoast.showToast(msg: listObj.toString());
      // getCrcData(listObj);
    } else if (data == "ps") {
      int temp = int.tryParse(result.split("ab")[0]);
      peepHighL = ((temp & 0xFF00) >> 8);
      peepLowL = (temp & 0xFF);
      List<int> listObj = [01, 0x10, 00, 102, 0x00, 0x01, 0x02];
      listObj.add(peepHighL);
      listObj.add(peepLowL);
      // Fluttertoast.showToast(msg: listObj.toString());
      // getCrcData(listObj);
    } else if (data == "ie") {
      int temp = int.tryParse(result.split("ab")[0]);
      peepHighL = ((temp & 0xFF00) >> 8);
      peepLowL = (temp & 0xFF);
      List<int> listObj = [01, 0x10, 00, 103, 0x00, 0x01, 0x02];
      listObj.add(peepHighL);
      listObj.add(peepLowL);
      // Fluttertoast.showToast(msg: listObj.toString());
      // getCrcData(listObj);
    } else if (data == "rr") {
      int temp = int.tryParse(result.split("ab")[0]);
      peepHighL = ((temp & 0xFF00) >> 8);
      peepLowL = (temp & 0xFF);
      List<int> listObj = [01, 0x10, 00, 104, 0x00, 0x01, 0x02];
      listObj.add(peepHighL);
      listObj.add(peepLowL);
      // Fluttertoast.showToast(msg: listObj.toString());
      // getCrcData(listObj);
    } else if (data == "FiO\u2082") {
      int temp = int.tryParse(result.split("ab")[0]);
      peepHighL = ((temp & 0xFF00) >> 8);
      peepLowL = (temp & 0xFF);
      List<int> listObj = [01, 0x10, 00, 105, 0x00, 0x01, 0x02];
      listObj.add(peepHighL);
      listObj.add(peepLowL);
      // Fluttertoast.showToast(msg: listObj.toString());
      // getCrcData(listObj);
    } else if (data == "tih") {
      int temp = int.tryParse(result.split("ab")[0]);
      peepHighL = ((temp & 0xFF00) >> 8);
      peepLowL = (temp & 0xFF);
      List<int> listObj = [01, 0x10, 00, 106, 0x00, 0x01, 0x02];
      listObj.add(peepHighL);
      listObj.add(peepLowL);
      // Fluttertoast.showToast(msg: listObj.toString());
      // getCrcData(listObj);
    }
    if (result != null) {
      getData();
    }
  }

  getIeData(pccmvIeValue, int res) {
    var data = pccmvIeValue == 1
        ? "4.0:1"
        : pccmvIeValue == 2
            ? "3.9:1"
            : pccmvIeValue == 3
                ? "3.8:1"
                : pccmvIeValue == 4
                    ? "3.7:1"
                    : pccmvIeValue == 5
                        ? "3.6:1"
                        : pccmvIeValue == 6
                            ? "3.5:1"
                            : pccmvIeValue == 7
                                ? "3.4:1"
                                : pccmvIeValue == 8
                                    ? "3.3:1"
                                    : pccmvIeValue == 9
                                        ? "3.2:1"
                                        : pccmvIeValue == 10
                                            ? "3.1:1"
                                            : pccmvIeValue == 11
                                                ? "3.0:1"
                                                : pccmvIeValue == 12
                                                    ? "2.9:1"
                                                    : pccmvIeValue == 13
                                                        ? "2.8:1"
                                                        : pccmvIeValue == 14
                                                            ? "2.7:1"
                                                            : pccmvIeValue == 15
                                                                ? "2.6:1"
                                                                : pccmvIeValue ==
                                                                        16
                                                                    ? "2.5:1"
                                                                    : pccmvIeValue ==
                                                                            17
                                                                        ? "2.4:1"
                                                                        : pccmvIeValue ==
                                                                                18
                                                                            ? "2.3:1"
                                                                            : pccmvIeValue == 19
                                                                                ? "2.2:1"
                                                                                : pccmvIeValue == 20 ? "2.1:1" : pccmvIeValue == 21 ? "2.0:1" : pccmvIeValue == 22 ? "1.9:1" : pccmvIeValue == 23 ? "1.8:1" : pccmvIeValue == 24 ? "1.7:1" : pccmvIeValue == 25 ? "1.6:1" : pccmvIeValue == 26 ? "1.5:1" : pccmvIeValue == 27 ? "1.4:1" : pccmvIeValue == 28 ? "1.3:1" : pccmvIeValue == 29 ? "1.2:1" : pccmvIeValue == 30 ? "1.1:1" : pccmvIeValue == 31 ? "1:1" : pccmvIeValue == 32 ? "1:1.1" : pccmvIeValue == 33 ? "1:1.2" : pccmvIeValue == 34 ? "1:1.3" : pccmvIeValue == 35 ? "1:1.4" : pccmvIeValue == 36 ? "1:1.5" : pccmvIeValue == 37 ? "1:1.6" : pccmvIeValue == 38 ? "1:1.7" : pccmvIeValue == 39 ? "1:1.8" : pccmvIeValue == 40 ? "1:1.9" : pccmvIeValue == 41 ? "1:2.0" : pccmvIeValue == 42 ? "1:2.1" : pccmvIeValue == 43 ? "1:2.2" : pccmvIeValue == 44 ? "1:2.3" : pccmvIeValue == 45 ? "1:2.4" : pccmvIeValue == 46 ? "1:2.5" : pccmvIeValue == 47 ? "1:2.6" : pccmvIeValue == 48 ? "1:2.7" : pccmvIeValue == 49 ? "1:2.8" : pccmvIeValue == 50 ? "1:2.9" : pccmvIeValue == 51 ? "1:3.0" : pccmvIeValue == 52 ? "1:3.1" : pccmvIeValue == 53 ? "1:3.2" : pccmvIeValue == 54 ? "1:3.3" : pccmvIeValue == 55 ? "1:3.4" : pccmvIeValue == 56 ? "1:3.5" : pccmvIeValue == 57 ? "1:3.6" : pccmvIeValue == 58 ? "1:3.7" : pccmvIeValue == 59 ? "1:3.8" : pccmvIeValue == 60 ? "1:3.9" : pccmvIeValue == 61 ? "1:4.0" : "0".toString();

    var dataI = data.split(":")[0];
    var dataE = data.split(":")[1];
    if (res == 1) {
      return data;
    } else if (res == 2) {
      // print(dataI);
      return dataI;
    } else if (res == 3) {
      // print(dataE);
      return dataE;
    }
  }

  modeSetCheck() async {
    setState(() {
      modeWriteList = [];
    });

    if (pccmvEnabled == true) {
      var dataI = getIeData(pccmvIeValue, 2);
      var dataI1 = double.tryParse(dataI);
      var dataI2 = (dataI1 * 10).toInt();

      var dataE = getIeData(pccmvIeValue, 3);
      var dataE1 = double.tryParse(dataE);
      var dataE2 = (dataE1 * 10).toInt();

      // int iEval = int.tryParse((double.tryParse(data))*10.0);

      // // print(iEval.toString());
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(6);

        modeWriteList.add((pccmvRRValue & 0xFF00) >> 8);
        modeWriteList.add((pccmvRRValue & 0x00FF));

        modeWriteList.add((dataI2 & 0x00FF));
        modeWriteList.add((dataE2 & 0x00FF));

        modeWriteList.add((pccmvPeepValue & 0xFF00) >> 8);
        modeWriteList.add((pccmvPeepValue & 0x00FF));

        modeWriteList.add((pccmvPcValue & 0xFF00) >> 8); //12
        modeWriteList.add((pccmvPcValue & 0x00FF)); //13

        modeWriteList.add((pccmvFio2Value & 0xFF00) >> 8);
        modeWriteList.add((pccmvFio2Value & 0x00FF));

        modeWriteList.add((pccmvVtminValue & 0xFF00) >> 8);
        modeWriteList.add((pccmvVtminValue & 0x00FF));

        modeWriteList.add((pccmvVtmaxValue & 0xFF00) >> 8);
        modeWriteList.add((pccmvVtmaxValue & 0x00FF));

        // modeWriteList.add((pccmvFlowRampValue & 0xFF00) >> 8);
        // modeWriteList.add((pccmvFlowRampValue & 0x00FF));
        modeWriteList.add(0x7F);
      });

      preferences = await SharedPreferences.getInstance();
      preferences.setString("mode", "PC-CMV");
      preferences.setString("checkMode", "pccmv");
      preferences.setInt("rr", pccmvRRValue);
      preferences.setInt("ie", pccmvIeValue);
      preferences.setString("i", dataI1.toString());
      preferences.setString("e", dataE1.toString());
      preferences.setInt("peep", pccmvPeepValue);
      preferences.setInt("fio2", pccmvFio2Value);
      preferences.setInt("ps", pccmvPcValue);

      preferences.setInt('pccmvRRValue', pccmvRRValue);
      preferences.setInt('pccmvIeValue', pccmvIeValue);
      preferences.setInt('pccmvPeepValue', pccmvPeepValue);
      preferences.setInt('pccmvPcValue', pccmvPcValue);
      preferences.setInt('pccmvFio2Value', pccmvFio2Value);
      preferences.setInt('pccmvVtminValue', pccmvVtminValue);
      preferences.setInt('pccmvVtmaxValue', pccmvVtmaxValue);
      preferences.setInt('pccmvTihValue', pccmvTihValue);
      preferences.setInt('pccmvFlowRampValue', pccmvFlowRampValue);
      preferences.setInt('pccmvdefaultValue', pccmvdefaultValue);

      //to calculate crc
      // print(modeWriteList.toString());
      // Fluttertoast.showToast(msg: modeWriteList.toString());

      if (_status == "Connected") {
        await _port.write(Uint8List.fromList(modeWriteList));
        writeAlarmsData();
        modesEnabled = false;
      } else {
        Fluttertoast.showToast(msg: "No Communication");
      }
      setState(() {
        playOnEnabled = false;
      });

      getData();

      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (vccmvEnabled == true) {
      var dataI = getIeData(vccmvIeValue, 2);
      var dataI1 = double.tryParse(dataI);
      var dataI2 = (dataI1 * 10).toInt();

      var dataE = getIeData(vccmvIeValue, 3);
      var dataE1 = double.tryParse(dataE);
      var dataE2 = (dataE1 * 10).toInt();

      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(7);
        modeWriteList.add((vccmvRRValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvRRValue & 0x00FF));

        modeWriteList.add((dataI2 & 0x00FF));
        modeWriteList.add((dataE2 & 0x00FF));

        modeWriteList.add((vccmvPeepValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvPeepValue & 0x00FF));

        modeWriteList.add((vccmvVtValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvVtValue & 0x00FF));

        modeWriteList.add((vccmvFio2Value & 0xFF00) >> 8);
        modeWriteList.add((vccmvFio2Value & 0x00FF));

        modeWriteList.add((vccmvPcMinValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvPcMinValue & 0x00FF));

        modeWriteList.add((vccmvPcMaxValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvPcMaxValue & 0x00FF));

        // modeWriteList.add((vccmvFlowRampValue & 0xFF00) >> 8);
        // modeWriteList.add((vccmvFlowRampValue & 0x00FF));
        modeWriteList.add(0x7F);
      });

      preferences = await SharedPreferences.getInstance();
      preferences.setString("mode", "VC-CMV");
      preferences.setString("checkMode", "vccmv");
      preferences.setInt("rr", vccmvRRValue);

      preferences.setString("i", dataI1.toString());
      preferences.setString("e", dataE1.toString());
      preferences.setInt("peep", vccmvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", vccmvFio2Value);
      preferences.setInt("vt", vccmvVtValue);

      preferences.setInt('vccmvRRValue', vccmvRRValue);
      preferences.setInt('vccmvIeValue', vccmvIeValue);
      preferences.setInt('vccmvPeepValue', vccmvPeepValue);
      preferences.setInt('vccmvPcMinValue', vccmvPcMinValue);
      preferences.setInt('vccmvPcMaxValue', vccmvPcMaxValue);
      preferences.setInt('vccmvFio2Value', vccmvFio2Value);
      preferences.setInt('vccmvVtValue', vccmvVtValue);
      preferences.setInt('vccmvTihValue', vccmvTihValue);
      preferences.setInt('vccmvFlowRampValue', vccmvFlowRampValue);
      preferences.setInt('vccmvdefaultValue', vccmvdefaultValue);

      //to calculate crc
      // print(modeWriteList.toString());
      // Fluttertoast.showToast(msg: modeWriteList.toString());
      if (_status == "Connected") {
        await _port.write(Uint8List.fromList(modeWriteList));
        writeAlarmsData();
        modesEnabled = false;
      } else {
        Fluttertoast.showToast(msg: "No Communication");
      }
      setState(() {
        playOnEnabled = false;
      });
      getData();
      newTreatEnabled = false;

      monitorEnabled = false;
    } else if (pacvEnabled == true) {
      var dataI = getIeData(pacvIeValue, 2);
      var dataI1 = double.tryParse(dataI);
      var dataI2 = (dataI1 * 10).toInt();

      var dataE = getIeData(pacvIeValue, 3);
      var dataE1 = double.tryParse(dataE);
      var dataE2 = (dataE1 * 10).toInt();

      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(2);

        modeWriteList.add((-pacvItrigValue & 0xFF00) >> 8);
        modeWriteList.add((-pacvItrigValue & 0x00FF));

        modeWriteList.add((pacvRrValue & 0xFF00) >> 8);
        modeWriteList.add((pacvRrValue & 0x00FF));

        modeWriteList.add((dataI2 & 0x00FF));
        modeWriteList.add((dataE2 & 0x00FF));

        modeWriteList.add((pacvPeepValue & 0xFF00) >> 8);
        modeWriteList.add((pacvPeepValue & 0x00FF));

        modeWriteList.add((pacvPcValue & 0xFF00) >> 8);
        modeWriteList.add((pacvPcValue & 0x00FF));

        modeWriteList.add((pacvVtMinValue & 0xFF00) >> 8);
        modeWriteList.add((pacvVtMinValue & 0x00FF));

        modeWriteList.add((pacvVtMaxValue & 0xFF00) >> 8);
        modeWriteList.add((pacvVtMaxValue & 0x00FF));

        modeWriteList.add((pacvFio2Value & 0xFF00) >> 8);
        modeWriteList.add((pacvFio2Value & 0x00FF));

        // modeWriteList.add((pacvFlowRampValue & 0xFF00) >> 8);
        // modeWriteList.add((pacvFlowRampValue & 0x00FF));

        modeWriteList.add(0x7F);
      });

      preferences = await SharedPreferences.getInstance();
      preferences.setString("checkMode", "pacv");
      preferences.setString("mode", "PACV");
      preferences.setInt("rr", pacvRrValue);
      preferences.setInt("ie", pacvIeValue);
      preferences.setString("i", dataI1.toString());
      preferences.setString("e", dataE1.toString());
      preferences.setInt("peep", pacvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", pacvFio2Value);
      preferences.setInt("ps", pacvPcValue);
      //==
      preferences.setInt('pacvItrigValue', pacvItrigValue);
      preferences.setInt('pacvRrValue', pacvRrValue);
      preferences.setInt('pacvIeValue', pacvIeValue);
      preferences.setInt('pacvPeepValue', pacvPeepValue);
      preferences.setInt('pacvPcValue', pacvPcValue);
      preferences.setInt('pacvVtMinValue', pacvVtMinValue);
      preferences.setInt('pacvVtMaxValue', pacvVtMaxValue);
      preferences.setInt('pacvFio2Value', pacvFio2Value);
      preferences.setInt('pacvFlowRampValue', pacvFlowRampValue);
      preferences.setInt('pacvdefaultValue', pacvdefaultValue);

      //==

      if (_status == "Connected") {
        await _port.write(Uint8List.fromList(modeWriteList));
        writeAlarmsData();
        modesEnabled = false;
      } else {
        Fluttertoast.showToast(msg: "No Communication");
      }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (vacvEnabled == true) {
      var dataI = getIeData(vacvIeValue, 2);
      var dataI1 = double.tryParse(dataI);
      var dataI2 = (dataI1 * 10).toInt();

      var dataE = getIeData(vacvIeValue, 3);
      var dataE1 = double.tryParse(dataE);
      var dataE2 = (dataE1 * 10).toInt();
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(1);
        modeWriteList.add((-vacvItrigValue & 0xFF00) >> 8);
        modeWriteList.add((-vacvItrigValue & 0x00FF));

        modeWriteList.add((vacvRrValue & 0xFF00) >> 8);
        modeWriteList.add((vacvRrValue & 0x00FF));

        modeWriteList.add((dataI2 & 0x00FF));
        modeWriteList.add((dataE2 & 0x00FF));

        modeWriteList.add((vacvPeepValue & 0xFF00) >> 8);
        modeWriteList.add((vacvPeepValue & 0x00FF));

        modeWriteList.add((vacvVtValue & 0xFF00) >> 8);
        modeWriteList.add((vacvVtValue & 0x00FF));

        modeWriteList.add((vacvPcMinValue & 0xFF00) >> 8);
        modeWriteList.add((vacvPcMinValue & 0x00FF));

        modeWriteList.add((vacvPcMaxValue & 0xFF00) >> 8);
        modeWriteList.add((vacvPcMaxValue & 0x00FF));

        modeWriteList.add((vacvFio2Value & 0xFF00) >> 8);
        modeWriteList.add((vacvFio2Value & 0x00FF));

        // modeWriteList.add((vacvFlowRampValue & 0xFF00) >> 8);
        // modeWriteList.add((vacvFlowRampValue & 0x00FF));

        modeWriteList.add(0x7F);
      });

      preferences = await SharedPreferences.getInstance();
      preferences.setString("mode", "VACV");
      preferences.setString("checkMode", "vacv");
      preferences.setInt("rr", vacvRrValue);
      preferences.setInt("ie", vacvIeValue);
      preferences.setString("i", dataI1.toString());
      preferences.setString("e", dataE1.toString());
      preferences.setInt("peep", vacvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", vacvFio2Value);
      preferences.setInt("vt", vacvVtValue);

      preferences.setInt('vacvItrigValue', vacvItrigValue);
      preferences.setInt('vacvRrValue', vacvRrValue);
      preferences.setInt('vacvIeValue', vacvIeValue);
      preferences.setInt('vacvPeepValue', vacvPeepValue);
      preferences.setInt('vacvVtValue', vacvVtValue);
      preferences.setInt('vacvPcMinValue', vacvPcMinValue);
      preferences.setInt('vacvPcMaxValue', vacvPcMaxValue);
      preferences.setInt('vacvFio2Value', vacvFio2Value);
      preferences.setInt('vacvFlowRampValue', vacvFlowRampValue);
      preferences.setInt('vacvdefaultValue', vacvdefaultValue);

      if (_status == "Connected") {
        await _port.write(Uint8List.fromList(modeWriteList));
        writeAlarmsData();
        modesEnabled = false;
      } else {
        Fluttertoast.showToast(msg: "No Communication");
      }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (psimvEnabled == true) {
      var dataI = getIeData(psimvIeValue, 2);
      var dataI1 = double.tryParse(dataI);
      var dataI2 = (dataI1 * 10).toInt();

      var dataE = getIeData(psimvIeValue, 3);
      var dataE1 = double.tryParse(dataE);
      var dataE2 = (dataE1 * 10).toInt();
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(4);

        modeWriteList.add((-psimvItrigValue & 0xFF00) >> 8);
        modeWriteList.add((-psimvItrigValue & 0x00FF));

        modeWriteList.add((psimvRrValue & 0xFF00) >> 8);
        modeWriteList.add((psimvRrValue & 0x00FF));

        modeWriteList.add((dataI2 & 0x00FF));
        modeWriteList.add((dataE2 & 0x00FF));

        modeWriteList.add((psimvPeepValue & 0xFF00) >> 8);
        modeWriteList.add((psimvPeepValue & 0x00FF));

        modeWriteList.add((psimvPcValue & 0xFF00) >> 8);
        modeWriteList.add((psimvPcValue & 0x00FF));

        modeWriteList.add((psimvVtMinValue & 0xFF00) >> 8);
        modeWriteList.add((psimvVtMinValue & 0x00FF));

        modeWriteList.add((psimvVtMaxValue & 0xFF00) >> 8);
        modeWriteList.add((psimvVtMaxValue & 0x00FF));

        modeWriteList.add((psimvFio2Value & 0xFF00) >> 8);
        modeWriteList.add((psimvFio2Value & 0x00FF));

        modeWriteList.add((psimvPsValue & 0xFF00) >> 8);
        modeWriteList.add((psimvPsValue & 0x00FF));
        modeWriteList.add(0x7F);
      });

      preferences = await SharedPreferences.getInstance();
      preferences.setString("mode", "PSIMV");
      preferences.setString("checkMode", "psimv");
      preferences.setInt("rr", psimvRrValue);
      preferences.setInt("ie", psimvIeValue);
      preferences.setString("i", dataI1.toString());
      preferences.setString("e", dataE1.toString());
      preferences.setInt("peep", psimvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", psimvFio2Value);
      preferences.setInt("ps", psimvPsValue);
      preferences.setInt("pc", psimvPcValue);

      preferences.setInt('psimvItrigValue',psimvItrigValue); 
 preferences.setInt('psimvRrValue',psimvRrValue);
preferences.setInt('psimvPsValue',psimvPsValue); 
preferences.setInt('psimvIeValue',psimvIeValue); 
preferences.setInt('psimvPeepValue',psimvPeepValue); 
 preferences.setInt('psimvPcValue',psimvPcValue); 
 preferences.setInt('psimvVtMinValue',psimvVtMinValue);
preferences.setInt('psimvVtMaxValue',psimvVtMaxValue); 
preferences.setInt('psimvFio2Value',psimvFio2Value); 
preferences.setInt('psimvFlowRampValue',psimvFlowRampValue);
preferences.setInt('psimvdefaultValue',psimvdefaultValue); 

      if (_status == "Connected") {
        await _port.write(Uint8List.fromList(modeWriteList));
        writeAlarmsData();
        modesEnabled = false;
      } else {
        Fluttertoast.showToast(msg: "No Communication");
        await _port.write(Uint8List.fromList(modeWriteList));
      }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (vsimvEnabled == true) {
      var dataI = getIeData(vsimvIeValue, 2);
      var dataI1 = double.tryParse(dataI);
      var dataI2 = (dataI1 * 10).toInt();

      var dataE = getIeData(vsimvIeValue, 3);
      var dataE1 = double.tryParse(dataE);
      var dataE2 = (dataE1 * 10).toInt();
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(5);

        modeWriteList.add((-vsimvItrigValue & 0xFF00) >> 8); //5
        modeWriteList.add((-vsimvItrigValue & 0x00FF)); //6

        modeWriteList.add((vsimvRrValue & 0xFF00) >> 8); //7
        modeWriteList.add((vsimvRrValue & 0x00FF)); //8

        modeWriteList.add((dataI2 & 0x00FF));
        modeWriteList.add((dataE2 & 0x00FF));

        modeWriteList.add((vsimvPeepValue & 0xFF00) >> 8); //11
        modeWriteList.add((vsimvPeepValue & 0x00FF)); //12

        modeWriteList.add((vsimvminValue & 0xFF00) >> 8);
        modeWriteList.add((psimvminValue & 0x00FF));

        modeWriteList.add((vsimvmaxValue & 0xFF00) >> 8);
        modeWriteList.add((vsimvmaxValue & 0x00FF));

        modeWriteList.add((vsimvVtValue & 0xFF00) >> 8); //17
        modeWriteList.add((vsimvVtValue & 0x00FF));

        modeWriteList.add((vsimvFio2Value & 0xFF00) >> 8); //19
        modeWriteList.add((vsimvFio2Value & 0x00FF));

        modeWriteList.add((vsimvPsValue & 0xFF00) >> 8); //21
        modeWriteList.add((vsimvPsValue & 0x00FF));

        modeWriteList.add(0x7F); //23
      });

      preferences = await SharedPreferences.getInstance();
      preferences.setString("mode", "VSIMV");
      preferences.setString("checkMode", "vsimv");
      preferences.setInt("rr", vsimvRrValue);
      preferences.setInt("ie", vsimvIeValue);
      preferences.setString("i", dataI1.toString());
      preferences.setString("e", dataE1.toString());
      preferences.setInt("peep", vsimvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", vsimvFio2Value);
      preferences.setInt("vt", vsimvVtValue);
      preferences.setInt("ps", vsimvPcMaxValue);

      preferences.setInt('vsimvItrigValue',vsimvItrigValue);
  preferences.setInt('vsimvRrValue',vsimvRrValue);
  preferences.setInt('vsimvIeValue',vsimvIeValue);
 preferences.setInt('vsimvPeepValue',vsimvPeepValue);
  preferences.setInt('vsimvVtValue',vsimvVtValue);
  preferences.setInt('vsimvPsValue',vsimvPsValue);
  preferences.setInt('vsimvPcMinValue',vsimvPcMinValue);
  preferences.setInt('vsimvPcMaxValue',vsimvPcMaxValue);
 preferences.setInt('vsimvFio2Value',vsimvFio2Value);
  preferences.setInt('vsimvFlowRampValue',vsimvFlowRampValue);
  preferences.setInt('vsimvdefaultValue',vsimvdefaultValue);

      if (_status == "Connected") {
        await _port.write(Uint8List.fromList(modeWriteList));
        writeAlarmsData();
        modesEnabled = false;
      } else {
        Fluttertoast.showToast(msg: "No Communication");
      }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (psvEnabled == true) {
      var dataI = getIeData(psvIeValue, 2);
      var dataI1 = double.tryParse(dataI);
      var dataI2 = (dataI1 * 10).toInt();

      var dataE = getIeData(psvIeValue, 3);
      var dataE1 = double.tryParse(dataE);
      var dataE2 = (dataE1 * 10).toInt();
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(3);

        modeWriteList.add((-psvItrigValue & 0xFF00) >> 8); //5
        modeWriteList.add((-psvItrigValue & 0x00FF)); //6

        modeWriteList.add((psvPeepValue & 0xFF00) >> 8); //7
        modeWriteList.add((psvPeepValue & 0x00FF)); //8

        modeWriteList.add((psvPsValue & 0xFF00) >> 8); //11
        modeWriteList.add((psvPsValue & 0x00FF)); //12

        modeWriteList.add((psvFio2Value & 0xFF00) >> 8); //19
        modeWriteList.add((psvFio2Value & 0x00FF));

        var calAtime = psvAtimeValue * 1000;

        modeWriteList.add((calAtime & 0xFF00) >> 8); //17
        modeWriteList.add((calAtime & 0x00FF));

        modeWriteList.add((dataI2 & 0x00FF));
        modeWriteList.add((dataE2 & 0x00FF));

        var calTi = psvTiValue * 1000;

        modeWriteList.add((calTi & 0xFF00) >> 8); //11
        modeWriteList.add((calTi & 0x00FF)); //12

        modeWriteList.add((psvBackupRrValue & 0xFF00) >> 8); //19
        modeWriteList.add((psvBackupRrValue & 0x00FF));

        modeWriteList.add((psvVtMinValue & 0xFF00) >> 8); //17
        modeWriteList.add((psvVtMinValue & 0x00FF));

        modeWriteList.add((psvVtMaxValue & 0xFF00) >> 8); //17
        modeWriteList.add((psvVtMaxValue & 0x00FF));

        modeWriteList.add((psvMinTeValue & 0xFF00) >> 8); //17
        modeWriteList.add((psvMinTeValue & 0x00FF));

        modeWriteList.add(0x7F); //23
      });

      preferences = await SharedPreferences.getInstance();
      preferences.setString("mode", "PSV");
      preferences.setString("checkMode", "psv");
      preferences.setInt("rr", psvBackupRrValue);
      // preferences.setInt("ie", vsimvIeValue);
      preferences.setString("i", dataI1.toString());
      preferences.setString("e", dataE1.toString());
      preferences.setInt("peep", psvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", psvFio2Value);
      preferences.setInt("ps", psvPsValue);

       preferences.setInt('psvItrigValue',psvItrigValue);
  preferences.setInt('psvPeepValue',psvPeepValue);
  preferences.setInt('psvIeValue',psvIeValue);
 preferences.setInt('psvPsValue',psvPsValue);
 preferences.setInt('psvTiValue',psvTiValue);
  preferences.setInt('psvVtMinValue',psvVtMinValue);
  preferences.setInt('psvVtMaxValue',psvVtMaxValue);
 preferences.setInt('psvFio2Value',psvFio2Value);
  preferences.setInt('psvAtimeValue',psvAtimeValue);
 preferences.setInt('psvEtrigValue',psvEtrigValue);
 preferences.setInt('psvBackupRrValue',psvBackupRrValue);
 preferences.setInt('psvMinTeValue',psvMinTeValue);
  preferences.setInt('psvFlowRampValue',psvFlowRampValue);
 preferences.setInt('psvdefaultValue',psvdefaultValue);
      // preferences.setInt("pc", );

      if (_status == "Connected") {
        await _port.write(Uint8List.fromList(modeWriteList));
        writeAlarmsData();
        modesEnabled = false;
      } else {
        Fluttertoast.showToast(msg: "No Communication");
      }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (prvcEnabled == true) {
      var dataI = getIeData(vacvIeValue, 2);
      var dataI1 = double.tryParse(dataI);
      var dataI2 = (dataI1 * 10).toInt();

      var dataE = getIeData(vacvIeValue, 3);
      var dataE1 = double.tryParse(dataE);
      var dataE2 = (dataE1 * 10).toInt();
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(14);
        modeWriteList.add((-vacvItrigValue & 0xFF00) >> 8);
        modeWriteList.add((-vacvItrigValue & 0x00FF));

        modeWriteList.add((vacvRrValue & 0xFF00) >> 8);
        modeWriteList.add((vacvRrValue & 0x00FF));

        modeWriteList.add((dataI2 & 0x00FF));
        modeWriteList.add((dataE2 & 0x00FF));

        modeWriteList.add((vacvPeepValue & 0xFF00) >> 8);
        modeWriteList.add((vacvPeepValue & 0x00FF));

        modeWriteList.add((vacvVtValue & 0xFF00) >> 8);
        modeWriteList.add((vacvVtValue & 0x00FF));

        modeWriteList.add((vacvPcMinValue & 0xFF00) >> 8);
        modeWriteList.add((vacvPcMinValue & 0x00FF));

        modeWriteList.add((vacvPcMaxValue & 0xFF00) >> 8);
        modeWriteList.add((vacvPcMaxValue & 0x00FF));

        modeWriteList.add((vacvFio2Value & 0xFF00) >> 8);
        modeWriteList.add((vacvFio2Value & 0x00FF));

        // modeWriteList.add((vacvFlowRampValue & 0xFF00) >> 8);
        // modeWriteList.add((vacvFlowRampValue & 0x00FF));

        modeWriteList.add(0x7F);
      });

      preferences = await SharedPreferences.getInstance();
      preferences.setString("mode", "PRVC");
      preferences.setString("checkMode", "prvc");
      preferences.setInt("rr", vacvRrValue);
      preferences.setInt("ie", vacvIeValue);
      preferences.setString("i", dataI1.toString());
      preferences.setString("e", dataE1.toString());
      preferences.setInt("peep", vacvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", vacvFio2Value);
      preferences.setInt("vt", vacvVtValue);

       preferences.setInt('vacvItrigValue',vacvItrigValue);
  preferences.setInt('vacvRrValue',vacvRrValue);
  preferences.setInt('vacvIeValue',vacvIeValue);
  preferences.setInt('vacvPeepValue',vacvPeepValue);
preferences.setInt('vacvVtValue',vacvVtValue);
 preferences.setInt('vacvPcMinValue',vacvPcMinValue);
preferences.setInt('vacvPcMaxValue',vacvPcMaxValue);
 preferences.setInt('vacvFio2Value',vacvFio2Value);
 preferences.setInt('vacvFlowRampValue',vacvFlowRampValue);
 preferences.setInt('vacvdefaultValue',vacvdefaultValue);

      if (_status == "Connected") {
        await _port.write(Uint8List.fromList(modeWriteList));
        writeAlarmsData();
        modesEnabled = false;
      } else {
        Fluttertoast.showToast(msg: "No Communication");
      }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      newTreatEnabled = false;
      monitorEnabled = false;
    }
  }

  writeDataPlay() async {
    // Fluttertoast.showToast(msg: modeWriteList.toString());
    await _port.write(Uint8List.fromList(modeWriteList));
  }

  writeDataPause() async {
    writePlay = [];
    writePlay.add(0x7E);
    writePlay.add(0);
    writePlay.add(20);
    writePlay.add(0);
    writePlay.add(0);
    writePlay.add(0x7F);

    //to calculate crc
    // print(writePlay.toString());
    // Fluttertoast.showToast(msg: writePlay.toString());

    await _port.write(Uint8List.fromList(writePlay));
  }

  void setData() {
    if (pacvEnabled == true) {
      setState(() {
        pacvItrigValue = 3;
        pacvRrValue = 20;
        pacvIeValue = 51;
        pacvPeepValue = 10;
        pacvPcValue = 30;
        pacvVtMinValue = 200;
        pacvVtMaxValue = 1200;
        pacvFio2Value = 21;
        pacvFlowRampValue = 3;
        pacvmaxValue = 10;
        pacvminValue = 1;
        pacvdefaultValue = 6;
        pacvparameterName = "I Trig";
        pacvparameterUnits = "cmH\u2082O Below Peep";
        pacvItrig = true;
        pacvRr = false;
        pacvIe = false;
        pacvPeep = false;
        pacvPc = false;
        pacvVtMin = false;
        pacvVtMax = false;
        pacvFio2 = false;
        pacvFlowRamp = false;
      });
    } else if (pccmvEnabled == true) {
      setState(() {
        pccmvRRValue = 20;
        pccmvIeValue = 51;
        pccmvPeepValue = 10;
        pccmvPcValue = 30;
        pccmvFio2Value = 21;
        pccmvVtminValue = 100;
        pccmvVtmaxValue = 400;
        pccmvTihValue = 50;
        pccmvFlowRampValue = 4;
        pccmvmaxValue = 60;
        pccmvminValue = 1;
        pccmvdefaultValue = 12;
        pccmvparameterName = "RR";
        pccmvparameterUnits = "";
        pccmvRR = true;
        pccmvIe = false;
        pccmvPeep = false;
        pccmvPc = false;
        pccmvFio2 = false;
        pccmvVtmin = false;
        pccmvVtmax = false;
        pccmvFlowRamp = false;
        pccmvTih = false;
      });
    } else if (vccmvEnabled == true) {
      setState(() {
        vccmvRRValue = 20;
        vccmvIeValue = 51;
        vccmvPeepValue = 10;
        vccmvPcMinValue = 20;
        vccmvPcMaxValue = 60;
        vccmvFio2Value = 21;
        vccmvVtValue = 200;
        vccmvTihValue = 50;
        vccmvFlowRampValue = 4;
        vccmvmaxValue = 60;
        vccmvminValue = 1;
        vccmvdefaultValue = 12;
        vccmvparameterName = "RR";
        vccmvparameterUnits = "";
        vccmvRR = true;
        vccmvIe = false;
        vccmvPeep = false;
        vccmvPcMin = false;
        vccmvPcMax = false;
        vccmvFio2 = false;
        vccmvVt = false;
        vccmvFlowRamp = false;
        vccmvTih = false;
      });
    } else if (vacvEnabled == true) {
      setState(() {
        vacvItrigValue = 3;
        vacvRrValue = 20;
        vacvIeValue = 51;
        vacvPeepValue = 10;
        vacvVtValue = 200;
        vacvPcMinValue = 20;
        vacvPcMaxValue = 60;
        vacvFio2Value = 21;
        vacvFlowRampValue = 4;
        vacvmaxValue = 10;
        vacvminValue = 1;
        vacvdefaultValue = 6;
        vacvparameterName = "I Trig";
        vacvparameterUnits = "cmH\u2082O Below Peep";
        vacvItrig = true;
        vacvRr = false;
        vacvIe = false;
        vacvPeep = false;
        vacvVt = false;
        vacvPcMin = false;
        vacvPcMax = false;
        vacvFio2 = false;
        vacvFlowRamp = false;
      });
    } else if (psvEnabled == true) {
      setState(() {
        psvItrigValue = 3;
        psvPeepValue = 10;
        psvIeValue = 51;
        psvPsValue = 30;
        psvTiValue = 5;
        psvVtMinValue = 100;
        psvVtMaxValue = 400;
        psvFio2Value = 21;
        psvAtimeValue = 10;
        psvEtrigValue = 10;
        psvBackupRrValue = 20;
        psvMinTeValue = 1;
        psvFlowRampValue = 4;
        psvItrig = true;
        psvPeep = false;
        psvIe = false;
        psvPs = false;
        psvTi = false;
        psvVtMin = false;
        psvVtMax = false;
        psvFio2 = false;
        psvAtime = false;
        psvEtrig = false;
        psvBackupRr = false;
        psvMinTe = false;
        psvFlowRamp = false;
        psvmaxValue = 10;
        psvminValue = 1;
        psvdefaultValue = 6;
        psvparameterName = "I Trig";
        psvparameterUnits = "cmH\u2082O Below Peep";
      });
    } else if (vsimvEnabled == true) {
      setState(() {
        vsimvItrig = true;
        vsimvRr = false;
        vsimvIe = false;
        vsimvPeep = false;
        vsimvVt = false;
        vsimvPs = false;
        vsimvPcMin = false;
        vsimvPcMax = false;
        vsimvFio2 = false;
        vsimvFlowRamp = false;
        vsimvItrigValue = 3;
        vsimvRrValue = 20;
        vsimvIeValue = 51;
        vsimvPeepValue = 10;
        vsimvVtValue = 200;
        vsimvPsValue = 22;
        vsimvPcMinValue = 20;
        vsimvPcMaxValue = 60;
        vsimvFio2Value = 21;
        vsimvFlowRampValue = 4;
        vsimvmaxValue = 10;
        vsimvminValue = 1;
        vsimvdefaultValue = 6;
        vsimvparameterName = "I Trig";
        vsimvparameterUnits = "cmH\u2082O Below Peep";
      });
    } else if (psimvEnabled == true) {
      setState(() {
        vsimvItrig = true;
        vsimvRr = false;
        vsimvIe = false;
        vsimvPeep = false;
        vsimvVt = false;
        vsimvPs = false;
        vsimvPcMin = false;
        vsimvPcMax = false;
        vsimvFio2 = false;
        vsimvFlowRamp = false;
        vsimvItrigValue = 3;
        vsimvRrValue = 20;
        vsimvIeValue = 51;
        vsimvPeepValue = 10;
        vsimvVtValue = 200;
        vsimvPsValue = 22;
        vsimvPcMinValue = 20;
        vsimvPcMaxValue = 60;
        vsimvFio2Value = 22;
        vsimvFlowRampValue = 4;
        vsimvmaxValue = 10;
        vsimvminValue = 1;
        vsimvdefaultValue = 6;
        vsimvparameterName = "I Trig";
        vsimvparameterUnits = "cmH\u2082O Below Peep";
      });
    }
  }

  writeAlarmsData() async {
    List<int> alarmList = [];
    setState(() {
      alarmList.add(0x7E);
      alarmList.add(0);
      alarmList.add(20);
      alarmList.add(0);
      alarmList.add(10);

      alarmList.add((minRrtotal & 0xFF00) >> 8);
      alarmList.add((minRrtotal & 0x00FF));

      alarmList.add((maxRrtotal & 0xFF00) >> 8);
      alarmList.add((maxRrtotal & 0x00FF));

      alarmList.add((minvte & 0xFF00) >> 8);
      alarmList.add((minvte & 0x00FF));
      alarmList.add((maxvte & 0xFF00) >> 8);
      alarmList.add((maxvte & 0x00FF));

      alarmList.add((minmve & 0xFF00) >> 8);
      alarmList.add((minmve & 0x00FF));
      alarmList.add((maxmve & 0xFF00) >> 8);
      alarmList.add((maxmve & 0x00FF));

      alarmList.add((minppeak & 0xFF00) >> 8);
      alarmList.add((minppeak & 0x00FF));
      alarmList.add((maxppeak & 0xFF00) >> 8);
      alarmList.add((maxppeak & 0x00FF));

      alarmList.add((minpeep & 0xFF00) >> 8);
      alarmList.add((minpeep & 0x00FF));
      alarmList.add((maxpeep & 0xFF00) >> 8);
      alarmList.add((maxpeep & 0x00FF));

      alarmList.add((minfio2 & 0xFF00) >> 8);
      alarmList.add((minfio2 & 0x00FF));
      alarmList.add((maxfio2 & 0xFF00) >> 8);
      alarmList.add((maxfio2 & 0x00FF));

      alarmList.add(0x7F);
      // Fluttertoast.showToast(msg: alarmList.toString());
    });

    preferences = await SharedPreferences.getInstance();
    preferences.setInt("minrr", minRrtotal);
    preferences.setInt("maxrr", maxRrtotal);
    preferences.setInt("minvte", minvte);
    preferences.setInt("maxvte", maxvte);
    preferences.setInt("minppeak", minppeak);
    preferences.setInt("maxppeak", maxppeak);
    preferences.setInt("minpeep", minpeep);
    preferences.setInt("maxpeep", maxpeep);

    await _port.write(Uint8List.fromList(alarmList));
    setState(() {
      alarmConfirmed = true;
    });
  }

  alarmsComponents() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 30),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  alarmmaxValue = 70;
                  alarmminValue = 1;
                  alarmparameterName = "RR Total";

                  alarmRRchanged = true;
                  alarmRR = true;
                  alarmVte = false;
                  alarmPpeak = false;
                  alarmpeep = false;
                  alarmFio2 = false;
                  alarmConfirmed = false;
                });
              },
              child: Center(
                child: Container(
                  color: alarmRRchanged ? Color(0xFFB0BEC5) : Color(0xFF213855),
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: alarmRR ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "RR Total",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: alarmRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: alarmRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "70",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: alarmRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "1",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: alarmRR
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "$minRrtotal - $maxRrtotal",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: alarmRR
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  alarmmaxValue = 2400;
                  alarmminValue = 0;
                  alarmparameterName = "VTe";
                  alarmRR = false;
                  alarmVte = true;
                  alarmVtechanged = true;
                  alarmPpeak = false;
                  alarmpeep = false;
                  alarmFio2 = false;
                  alarmConfirmed = false;
                });
              },
              child: Center(
                child: Container(
                  width: 146,
                  height: 130,
                  color:
                      alarmVtechanged ? Color(0xFFB0BEC5) : Color(0xFF213855),
                  child: Card(
                    elevation: 40,
                    color: alarmVte ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "VTe",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: alarmVte
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: alarmVte
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "2400",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: alarmVte
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: alarmVte
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "$minvte - $maxvte",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: alarmVte
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            // InkWell(
            //   onTap: () {
            //     setState(() {
            //       alarmmaxValue = 100;
            //       alarmminValue = 21;
            //       alarmparameterName = "FiO\u2082";
            //       alarmFio2changed = true;
            //       alarmRR = false;
            //       alarmVte = false;
            //       alarmPpeak = false;
            //       alarmpeep = false;
            //       alarmFio2 = true;
            //       alarmConfirmed = false;
            //     });
            //   },
            //   child: Center(
            //     child: Container(
            //       color:
            //           alarmFio2changed ? Color(0xFFB0BEC5) : Color(0xFF213855),
            //       width: 146,
            //       height: 130,
            //       child: Card(
            //         elevation: 40,
            //         color: alarmFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
            //         child: Padding(
            //           padding: const EdgeInsets.all(6.0),
            //           child: Center(
            //               child: Stack(
            //             children: [
            //               Align(
            //                 alignment: Alignment.topLeft,
            //                 child: Text(
            //                   "FiO\u2082",
            //                   style: TextStyle(
            //                       fontSize: 15,
            //                       fontWeight: FontWeight.bold,
            //                       color: alarmFio2
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.topRight,
            //                 child: Text(
            //                   "",
            //                   style: TextStyle(
            //                       fontSize: 9,
            //                       color: alarmFio2
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomRight,
            //                 child: Text(
            //                   "100",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: alarmFio2
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.bottomLeft,
            //                 child: Text(
            //                   "21",
            //                   style: TextStyle(
            //                       fontSize: 12,
            //                       color: alarmFio2
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 1.0),
            //                   child: Text(
            //                     "$minfio2 - $maxfio2",
            //                     style: TextStyle(
            //                         fontSize: 20,
            //                         color: alarmFio2
            //                             ? Color(0xFF213855)
            //                             : Color(0xFFE0E0E0)),
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           )),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            InkWell(
              onTap: () {
                setState(() {
                  alarmmaxValue = 40;
                  alarmminValue = 0;
                  alarmparameterName = "PEEP";
                  alarmpeepchanged = true;
                  alarmRR = false;
                  alarmVte = false;
                  alarmPpeak = false;
                  alarmpeep = true;
                  alarmFio2 = false;
                  alarmConfirmed = false;
                });
              },
              child: Center(
                child: Container(
                  color:
                      alarmpeepchanged ? Color(0xFFB0BEC5) : Color(0xFF213855),
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: alarmpeep ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "PEEP",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: alarmpeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: alarmpeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "40",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: alarmpeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: alarmpeep
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "$minpeep - $maxpeep",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: alarmpeep
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  alarmmaxValue = 100;
                  alarmminValue = 0;
                  alarmparameterName = "Ppeak";
                  alarmRR = false;
                  alarmVte = false;
                  alarmPpeakchanged = true;
                  alarmPpeak = true;
                  alarmpeep = false;
                  alarmFio2 = false;
                  alarmConfirmed = false;
                });
              },
              child: Center(
                child: Container(
                  color:
                      alarmPpeakchanged ? Color(0xFFB0BEC5) : Color(0xFF213855),
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: alarmPpeak ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Ppeak",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: alarmPpeak
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH\u2082O",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: alarmPpeak
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "100",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: alarmPpeak
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "0",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: alarmPpeak
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "$minppeak - $maxppeak",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: alarmPpeak
                                        ? Color(0xFF213855)
                                        : Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            Container(width: 146),
          ],
        ),
        alarmConfirmed == false
            ? Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE0E0E0)),
                width: 400,
                height: 380,
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 30,
                      ),
                      Text(
                        alarmparameterName,
                        style: TextStyle(fontSize: 36),
                      ),
                      SizedBox(
                        height: 70,
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.remove,
                                color: Colors.black,
                                size: 45,
                              ),
                              onPressed: () {
                                setState(() {
                                  alarmConfirmed = false;
                                  if (alarmRR == true && minRrtotal != 1) {
                                    setState(() {
                                      minRrtotal = minRrtotal - 1;
                                    });
                                  } else if (alarmVte == true && minvte != 0) {
                                    setState(() {
                                      minvte = minvte - 1;
                                    });
                                  } else if (alarmPpeak == true &&
                                      minppeak != 0) {
                                    setState(() {
                                      minppeak = minppeak - 1;
                                    });
                                  } else if (alarmFio2 == true &&
                                      minfio2 != 21) {
                                    setState(() {
                                      minfio2 = minfio2 - 1;
                                    });
                                  } else if (alarmpeep == true &&
                                      minpeep != 0) {
                                    setState(() {
                                      minpeep = minpeep - 1;
                                    });
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              width: 60,
                            ),
                            Text(
                              alarmRR
                                  ? "$minRrtotal - $maxRrtotal"
                                  : alarmVte
                                      ? "$minvte - $maxvte"
                                      : alarmPpeak
                                          ? "$minppeak - $maxppeak"
                                          : alarmFio2
                                              ? "$minfio2 - $maxfio2"
                                              : alarmpeep
                                                  ? "$minpeep - $maxpeep"
                                                  : "0",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: 60,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add,
                                color: Colors.black,
                                size: 45,
                              ),
                              onPressed: () {
                                setState(() {
                                  alarmConfirmed = false;
                                  if (alarmRR == true && maxRrtotal != 70) {
                                    setState(() {
                                      maxRrtotal = maxRrtotal + 1;
                                    });
                                  } else if (alarmVte == true &&
                                      maxvte != 2400) {
                                    setState(() {
                                      maxvte = maxvte + 1;
                                    });
                                  } else if (alarmPpeak == true &&
                                      maxppeak != 100) {
                                    setState(() {
                                      maxppeak = maxppeak + 1;
                                    });
                                  } else if (alarmFio2 == true &&
                                      maxfio2 != 100) {
                                    setState(() {
                                      maxfio2 = maxfio2 + 1;
                                    });
                                  } else if (alarmpeep == true &&
                                      maxpeep != 40) {
                                    setState(() {
                                      maxpeep = maxpeep + 1;
                                    });
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 35,
                      ),
                      Container(
                        width: 350,
                        child: CupertinoRangeSlider(
                          minValue: alarmRR
                              ? minRrtotal.toDouble()
                              : alarmVte
                                  ? minvte.toDouble()
                                  : alarmPpeak
                                      ? minppeak.toDouble()
                                      : alarmFio2
                                          ? minfio2.toDouble()
                                          : alarmpeep
                                              ? minpeep.toDouble()
                                              : 0.0, // Current min value
                          maxValue: alarmRR
                              ? maxRrtotal.toDouble()
                              : alarmVte
                                  ? maxvte.toDouble()
                                  : alarmPpeak
                                      ? maxppeak.toDouble()
                                      : alarmFio2
                                          ? maxfio2.toDouble()
                                          : alarmpeep
                                              ? maxpeep.toDouble()
                                              : 0.0, // Current max value
                          min: alarmRR
                              ? 1
                              : alarmVte
                                  ? 0
                                  : alarmPpeak
                                      ? 0
                                      : alarmFio2
                                          ? 21
                                          : alarmpeep
                                              ? 0
                                              : 0.0, // Min range value
                          max: alarmRR
                              ? 70
                              : alarmVte
                                  ? 2400
                                  : alarmPpeak
                                      ? 100
                                      : alarmFio2
                                          ? 100
                                          : alarmpeep
                                              ? 40
                                              : 0.0, // Max range value
                          onMinChanged: (minVal) {
                            setState(() {
                              alarmConfirmed = false;
                              alarmRR
                                  ? minRrtotal = minVal.toInt()
                                  : alarmVte
                                      ? minvte = minVal.toInt()
                                      : alarmPpeak
                                          ? minppeak = minVal.toInt()
                                          : alarmFio2
                                              ? minfio2 = minVal.toInt()
                                              : alarmpeep
                                                  ? minpeep = minVal.toInt()
                                                  : 0.toInt();
                            });
                          },
                          onMaxChanged: (maxVal) {
                            setState(() {
                              alarmConfirmed = false;
                              alarmRR
                                  ? maxRrtotal = maxVal.toInt()
                                  : alarmVte
                                      ? maxvte = maxVal.toInt()
                                      : alarmPpeak
                                          ? maxppeak = maxVal.toInt()
                                          : alarmFio2
                                              ? maxfio2 = maxVal.toInt()
                                              : alarmpeep
                                                  ? maxpeep = maxVal.toInt()
                                                  : 0.toInt();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45.0, right: 45.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(alarmminValue.toString()),
                            Text(alarmmaxValue.toString())
                          ],
                        ),
                      )
                    ],
                  ),
                ))
            : Container(),
      ],
    );
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
              title: new Text("Enter Patient Data"),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text("Ok"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NewTreatmentScreen()),
                    );
                  },
                ),
              ],
            ));
  }

  sendRRData(int rrValueIE) {
    //  double iData = ((120-rrValueIE)/rrValueIE);
    //  double imul = iData*10;
    //  int itoint = imul.toInt();
    //  double iLimit = itoint.toDouble()/10;

    //  double eData = ((200-rrValueIE)/rrValueIE);
    //  double emul = eData*10;
    //  int etoint = emul.toInt();
    //  double eLimit = etoint.toDouble()/10;

    //  if(iLimit>=4){
    //    iLimit=4.0;
    //  }
    //  if(eLimit>=4){
    //    eLimit=4.0;
    //  }

    // var lowerLevel  = iLimit;
  }

  serializeEventData(Uint8List event) async {
    if (event != null) {
      setState(() {
        respiratoryEnable = true;
        // playOnEnabled = false;
      });
      if (event[0] == 126) {
        list = [];
        listTemp = [];
        int cIndex = 0;
        // turnOnScreen();
        list.addAll(event);
        list.removeAt(0);

        for (int i = 0; i < list.length; i++) {
          if (list[i] == 125) {
            listTemp.insert(cIndex, list[i + 1] ^ 0x20);
            i = i + 1;
          } else {
            listTemp.insert(cIndex, list[i]);
          }
          cIndex = cIndex + 1;
        }
        // print(listTemp.length.toString());
        serialiseReceivedPacket(listTemp);
      } else {
        list = [];
      }
    } else {
      setState(() {
        respiratoryEnable = false;
      });
      //  pressurePoints.clear();
      //  volumePoints.clear();
      //  flowPoints.clear();
      list = [];
    }
  }

  serialiseReceivedPacket(List<int> finalList) {
    if (finalList.isNotEmpty && finalList.length == 114) {
      var now = new DateTime.now();

      lastRecordTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(now).toString();

      // bool data = await checkCrc(finalList, finalList.length);
      // if (data == false) {
      //   finalList.clear();
      // } else {
      // // print("page no " + finalList[112].toString());
      // if (finalList[112] == 1) {
      //   Navigator.pushAndRemoveUntil(
      //       context,
      //       MaterialPageRoute(
      //           builder: (BuildContext context) => SelfTestPage()),
      //       ModalRoute.withName('/'));
      // } else if (finalList[112] == 2) {
      //   Navigator.pushAndRemoveUntil(
      //       context,
      //       MaterialPageRoute(
      //           builder: (BuildContext context) => CallibrationPage()),
      //       ModalRoute.withName('/'));
      // }

      //=========================

      //=========================
      setState(() {
        //=============

        setState(() {
          var now = new DateTime.now();

          int vteValueCheck = ((finalList[4] << 8) + finalList[5]); //5 6
          // // print("vte "+vteValueCheck.toString());

          if ((vteValueCheck != "" || vteValueCheck != null) &&
              vteValueCheck.round() >= 0 &&
              vteValueCheck.round() <= 2500) {
            setState(() {
              vteMinValue = vteValue - vtValue;
              vteValue = ((finalList[4] << 8) + finalList[5]);
            });
          }
          int mvValueCheck = (((finalList[8] << 8) + finalList[9])).toInt();

          // if (mvValueCheck != "" && (mvValue/1000).toDouble() >0 && (mvValue/1000).toDouble()<100) {
          setState(() {
            mvValue = mvValueCheck;
          });
          // }

          leakVolumeDisplay =
              ((finalList[102] << 8) + finalList[103]); //103 104
          peakFlowDisplay = ((finalList[70] << 8) + finalList[71]); //71 72
          spontaneousDisplay = ((finalList[82] << 8) + finalList[83]); //83 84
          // // print("spon "+spontaneousDisplay.toString());

          int rrtotalCheck =
              ((finalList[10] << 8) + finalList[11]).toInt(); //11,12

          if (rrtotalCheck != "" &&
              rrtotalCheck.round() >= 0 &&
              rrtotalCheck.round() <= 100) {
            setState(() {
              rrDisplayValue = rrtotalCheck;
            });
          }
          int pipValueCheck = (((finalList[14] << 8) + finalList[15]) / 100)
              .round()
              .toInt(); //15 16

          if ((((finalList[16] << 8) + finalList[17]) / 100).round().toInt() >=
                  0 &&
              (((finalList[16] << 8) + finalList[17]) / 100).round().toInt() <=
                  150) {
            peepDisplayValue = (((finalList[16] << 8) + finalList[17]) / 100)
                .round()
                .toInt(); //17 18
          }

          if (pipValueCheck != 0 &&
              pipValueCheck.round() >= 0 &&
              pipValueCheck.round() <= 150) {
            setState(() {
              psValue1 = pipValueCheck;
            });
          }
          paw = (((finalList[34] << 8) + finalList[35]) / 100).toInt();

          if (paw > 200) {
            setState(() {
              paw = 0;
            });
          }

          expiratoryPressureR =
              (((finalList[36] << 8) + finalList[37]) / 100).toInt(); //37 38

          if (((finalList[38] << 8) + finalList[39]).round() >= 20 &&
              ((finalList[38] << 8) + finalList[39]).round() <= 100) {
            fio2DisplayParameter =
                ((finalList[38] << 8) + finalList[39]); // 39,40
          }

          checkTempData = finalList[31].toString();

          if (finalList[108] == 1) {
            presentCode = ((finalList[106] << 8) + finalList[107]);
            alarmCounter = finalList[90];
            // if (presentCode != 0 && presentCode > 0 && presentCode <= 23) {
             
            // }
            // Fluttertoast.showToast(msg: presentCode.toString()+" pre "+previousCode.toString() + "\n counter "+alarmCounter.toString()+"pre cnt "+alarmCounter.toString());

            if (presentCode != previousCode) {
              previousCode = presentCode;
               var data = AlarmsList(
                  presentCode.toString(), this.globalCounterNo.toString());
              dbHelpera.saveAlarm(data);
              // alarmPrevCounter = alarmCounter;
              _stopMusic();

              if (presentCode == 5 ||
                  presentCode == 7 ||
                  presentCode == 10 ||
                  presentCode == 11 ||
                  presentCode == 17) {
                _playMusicHigh();
                sendSoundOn();
                audioEnable = true;
              } else if (presentCode == 1 ||
                  presentCode == 2 ||
                  presentCode == 3 ||
                  presentCode == 4 ||
                  presentCode == 6 ||
                  presentCode == 8 ||
                  presentCode == 9 ||
                  presentCode == 12 ||
                  presentCode == 13 ||
                  presentCode == 14 ||
                  presentCode == 15 ||
                  presentCode == 16 ||
                  presentCode == 18 ||
                  presentCode == 19 ||
                  presentCode == 20 ||
                  presentCode == 21 ||
                  presentCode == 22) {
                _playMusicMedium();
                sendSoundOn();

                audioEnable = true;
              } else if (presentCode == 23) {
                _playMusicLower();
                sendSoundOn();
                audioEnable = true;
              }
            } else {
              if (alarmCounter != alarmPrevCounter) {
                alarmPrevCounter = alarmCounter;
                 var data = AlarmsList(
                  presentCode.toString(), this.globalCounterNo.toString());
              dbHelpera.saveAlarm(data);
                _stopMusic();
                if (presentCode == 5 ||
                    presentCode == 7 ||
                    presentCode == 10 ||
                    presentCode == 11 ||
                    presentCode == 17) {
                  _playMusicHigh();
                  sendSoundOn();
                  audioEnable = true;
                } else if (presentCode == 1 ||
                    presentCode == 2 ||
                    presentCode == 3 ||
                    presentCode == 4 ||
                    presentCode == 6 ||
                    presentCode == 8 ||
                    presentCode == 9 ||
                    presentCode == 12 ||
                    presentCode == 13 ||
                    presentCode == 14 ||
                    presentCode == 15 ||
                    presentCode == 16 ||
                    presentCode == 18 ||
                    presentCode == 19 ||
                    presentCode == 20 ||
                    presentCode == 21 ||
                    presentCode == 22) {
                  _playMusicMedium();
                  sendSoundOn();

                  audioEnable = true;
                } else if (presentCode == 23) {
                  _playMusicLower();
                  sendSoundOn();
                  audioEnable = true;
                }
              }
            }
          } else if (finalList[108] == 0) {
            sendSoundOff();
            _stopMusic();
          }

          // cdisplayParameter = ((finalList[106] << 8) + finalList[107]);
          if (!vteValue.isNegative &&
              vteValue != null &&
              vteValue != 0 &&
              !pplateauDisplay.isNegative &&
              pplateauDisplay != null &&
              pplateauDisplay != 0) {
            try {
              var dataC = (double.tryParse(vteValue.toString()) /
                      (pplateauDisplay -
                          double.tryParse(peepDisplayValue.toString())))
                  .toInt();
              if (dataC.isNegative) {
                // cdisplayParameter = 0;
              } else {
                cdisplayParameter = dataC;
              }
            } catch (e) {}
          }

          if (finalList[108] == 1) {
            setState(() {
              if (finalList[109] == 1 || finalList[109] == 0) {
                ((finalList[106] << 8) + finalList[107]) == 5
                    ? alarmMessage = "SYSTEM FAULT"
                    : ((finalList[106] << 8) + finalList[107]) == 7
                        ? alarmMessage = "FiO\u2082 SENSOR MISSING"
                        : ((finalList[106] << 8) + finalList[107]) == 10
                            ? alarmMessage = "HIGH LEAKAGE"
                            : ((finalList[106] << 8) + finalList[107]) == 11
                                ? alarmMessage = "HIGH PRESSURE"
                                : ((finalList[106] << 8) + finalList[107]) == 17
                                    ? alarmMessage = "PATIENT DISCONNECTED"
                                    : alarmMessage = "";
              } else if (finalList[109] == 2) {
                // // print("alarm code "+(((finalList[106] << 8) + finalList[107])).toString());
                ((finalList[106] << 8) + finalList[107]) == 1
                    ? alarmMessage = "POWER SUPPLY DISCONNECTED"
                    : ((finalList[106] << 8) + finalList[107]) == 2
                        ? alarmMessage = " LOW BATTERY"
                        : ((finalList[106] << 8) + finalList[107]) == 3
                            ? alarmMessage = "CALIBRATE FiO2"
                            : ((finalList[106] << 8) + finalList[107]) == 4
                                ? alarmMessage = "CALIBRATION FiO2 FAIL"
                                : ((finalList[106] << 8) + finalList[107]) == 6
                                    ? alarmMessage = "SELF TEST FAIL"
                                    : ((finalList[106] << 8) + finalList[107]) == 8
                                        ? alarmMessage = "HIGH FiO2"
                                        : ((finalList[106] << 8) + finalList[107]) == 9
                                            ? alarmMessage = "LOW FIO2"
                                            : ((finalList[106] << 8) +
                                                        finalList[107]) ==
                                                    12
                                                ? alarmMessage = "LOW PRESSURE"
                                                : ((finalList[106] << 8) +
                                                            finalList[107]) ==
                                                        13
                                                    ? alarmMessage = "LOW VTE"
                                                    : ((finalList[106] << 8) + finalList[107]) == 14
                                                        ? alarmMessage =
                                                            "HIGH VTE"
                                                        : ((finalList[106] << 8) + finalList[107]) == 15
                                                            ? alarmMessage =
                                                                "LOW VTI"
                                                            : ((finalList[106] << 8) + finalList[107]) == 16
                                                                ? alarmMessage =
                                                                    "HIGH VTI"
                                                                : ((finalList[106] << 8) + finalList[107]) == 18
                                                                    ? alarmMessage =
                                                                        "LOW O2  supply"
                                                                    : ((finalList[106] << 8) + finalList[107]) ==
                                                                            19
                                                                        ? alarmMessage =
                                                                            "LOW RR"
                                                                        : ((finalList[106] << 8) + finalList[107]) == 20
                                                                            ? alarmMessage = "HIGH RR"
                                                                            : ((finalList[106] << 8) + finalList[107]) == 21 ? alarmMessage = "HIGH PEEP" : ((finalList[106] << 8) + finalList[107]) == 22 ? alarmMessage = "LOW PEEP" : alarmMessage = "";
              } else if (finalList[109] == 3) {
                ((finalList[106] << 8) + finalList[107]) == 23
                    ? alarmMessage = "Apnea backup"
                    : alarmMessage = "";
              }
            });
          }

          if (paw <= 10) {
            setState(() {
              lungImage = 1;
            });
          } else if (paw <= 20 && paw >= 11) {
            setState(() {
              lungImage = 2;
            });
          } else if (paw <= 30 && paw >= 21) {
            setState(() {
              lungImage = 3;
            });
          } else if (paw <= 40 && paw >= 31) {
            setState(() {
              lungImage = 4;
            });
          } else if (paw <= 100 && paw >= 41) {
            setState(() {
              lungImage = 5;
            });
          }
        });
        setState(() {
          String i = "", e = "", tempIe = "";
          i = finalList[12].toString();
          e = finalList[13].toString();
          tempIe = i + ":" + e;
        });

        var dataOperatingMode = ((finalList[104] << 8) + finalList[105]);
        if (dataOperatingMode >= 0 && dataOperatingMode <= 14) {
          setState(() {
            operatinModeR = ((finalList[104] << 8) + finalList[105]);
          });
        }

        if (operatinModeR == 1) {
          setState(() {
            modeName = "VACV";
          });
        } else if (operatinModeR == 2) {
          setState(() {
            modeName = "PACV";
          });
        } else if (operatinModeR == 3) {
          setState(() {
            modeName = "PSV";
          });
        } else if (operatinModeR == 4) {
          setState(() {
            modeName = "PSIMV";
          });
        } else if (operatinModeR == 5) {
          setState(() {
            modeName = "VSIMV";
          });
        } else if (operatinModeR == 6) {
          setState(() {
            modeName = "PC-CMV";
          });
        } else if (operatinModeR == 7) {
          setState(() {
            modeName = "VC-CMV";
          });
        } else if (operatinModeR == 14) {
          setState(() {
            modeName = "PRVC";
          });
        }

        if ((((finalList[68] << 8) + finalList[69]) / 100).round().toInt() >=
                0 &&
            (((finalList[68] << 8) + finalList[69]) / 100).round().toInt() <=
                150) {
          mapDisplayValue =
              (((finalList[68] << 8) + finalList[69]) / 100).toInt();
        }
        if (finalList[84] == 1) {
          ioreDisplayParamter = "I";
        } else if (finalList[84] == 2) {
          ioreDisplayParamter = "E";
        } else {
          ioreDisplayParamter = "";
        }

        displayTemperature = finalList[88];

        setState(() {
          if (finalList[108] != 0 &&
              ((finalList[106] << 8) + finalList[107]) != null &&
              ((finalList[106] << 8) + finalList[107]) >= 1 &&
              ((finalList[106] << 8) + finalList[107]) <= 23) {
            alarmActive = finalList[108].toString();
          } else {
            alarmActive = 0.toString();
          }
        });

        // pressure graph
        double temp = (((finalList[34] << 8) + finalList[35]))
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

        // if(temp.round()>0 && temp.round()<150)
        // {
        if (pressurePoints.length >= 50) {
          setState(() {
            pressurePoints.removeAt(0);
            pressurePoints.add(temp);
          });
        } else {
          pressurePoints.add(temp);
        }
        // }else{
        //   pressurePoints.add(0);
        // }
        if (((finalList[60] << 8) + finalList[61]).toInt() >= 0 &&
            ((finalList[60] << 8) + finalList[61]).toInt() <= 150) {
          pplateauDisplay = ((finalList[60] << 8) + finalList[61]).toDouble();
        }

        double temp1 = ((finalList[58] << 8) + finalList[59])
            .toDouble(); // volume points 59,60

        // if(temp1.round() >0 && temp1.round() < 2500)
        // {
        if (volumePoints.length >= 50) {
          setState(() {
            volumePoints.removeAt(0);
            volumePoints.add(temp1);
          });
        } else {
          volumePoints.add(temp1);
        }
        // }else{
        //   volumePoints.add(0);
        // }

        double temp3 = ((((finalList[46] << 8) + finalList[47])) -
                (((finalList[48] << 8) + finalList[49])))
            .toDouble();
        temp3 = temp3 * 0.06;

        // if(temp3.round()>-100 && temp3.round()<200){
        if (flowPoints.length >= 50) {
          setState(() {
            flowPoints.removeAt(0);
            flowPoints.add(temp3*1.2);
          });
        } else {
          flowPoints.add(temp3*1.2);
        }
        // }else{
        //   flowPoints.add(0);
        // }

        setState(() {
          powerIndication = finalList[64];
          batteryPercentage = finalList[65];
          batteryStatus = finalList[78];
        });

        if (patientId != "") {
          var data = VentilatorOMode(
              patientId,
              patientName.toString(),
              psValue1.toString(),
              vteValue.toString(),
              peepDisplayValue.toString(),
              rrDisplayValue.toString(),
              fio2DisplayParameter.toString(),
              mapDisplayValue.toString(),
              mvValue.toString(),
              cdisplayParameter.toString(),
              ieDisplayValue.toString(),
              rrValue.toString(),
              checkI(i) + ":" + checkE(e).toString(),
              peepValue.toString(),
              psValue.toString(),
              fio2Value.toString(),
              vtValue.toString(),
              tiValue.toString(),
              teValue.toString(),
              temp,
              temp3,
              temp1,
              operatinModeR.toString(),
              lungImage.toString(),
              paw.toString(),
              globalCounterNo.toString(),
              ((finalList[106] << 8) + finalList[107]).toString(),
              finalList[109].toString(),
              alarmActive);
          saveData(data, patientId);
        } else {
          var data = VentilatorOMode(
              "SWASIT " + globalCounterNo.toString(),
              patientName,
              psValue1.toString(),
              vteValue.toString(),
              peepDisplayValue.toString(),
              rrDisplayValue.toString(),
              fio2DisplayParameter.toString(),
              mapDisplayValue.toString(),
              mvValue.toString(),
              cdisplayParameter.toString(),
              ieDisplayValue.toString(),
              rrValue.toString(),
              checkI(i) + ":" + checkE(e).toString(),
              peepValue.toString(),
              psValue.toString(),
              fio2Value.toString(),
              vtValue.toString(),
              tiValue.toString(),
              teValue.toString(),
              temp,
              temp3,
              temp1,
              operatinModeR.toString(),
              lungImage.toString(),
              paw.toString(),
              globalCounterNo.toString(),
              ((finalList[106] << 8) + finalList[107]).toString(),
              finalList[109].toString(),
              alarmActive);
          saveData(data, patientId);
        }
        finalList = [];
        list = [];
        listTemp = [];
      });
      // }
    }
  }
}
