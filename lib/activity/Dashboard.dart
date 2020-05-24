import 'dart:async';
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
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';
import 'package:ventilator/graphs/Oscilloscope.dart';
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
  Timer _timer, _timer1, _timer2;
  List<int> list = [];
  List<double> traceSine = new List();
  List<double> emptyList = new List();
  List<double> emptyList1 = new List();

  double radians = 0, radians1 = 0;
  int paw, mvValue, rrtotalValue, lastmvValue = 0;
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
      psValue,
      vtValue,
      psValue1 = 0,
      peepDisplayValue = 0,
      fio2Value,
      tiValue = 0,
      teValue = 0,
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

  double mode1rrval = 12,
      mode1ieval = 2,
      mode1peepval = 10,
      mode1psval = 35,
      mode1fio2val = 21,
      mode1tival = 50;

  bool modeEnable = false,
      audioEnable = false,
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

  int pacvItrigValue = 60,
      pacvRrValue = 12,
      pacvIeValue = 3,
      pacvPeepValue = 10,
      pacvPcValue = 30,
      pacvVtMinValue = 100,
      pacvVtMaxValue = 400,
      pacvFio2Value = 22,
      pacvFlowRampValue = 3;

  int pacvmaxValue = 100, pacvminValue = 20, pacvdefaultValue = 60;
  String pacvparameterName = "I Trig", pacvparameterUnits = "cmH20";

  bool vacvItrig = true,
      vacvRr = false,
      vacvIe = false,
      vacvPeep = false,
      vacvVt = false,
      vacvPcMin = false,
      vacvPcMax = false,
      vacvFio2 = false,
      vacvFlowRamp = false;

  int vacvItrigValue = 60,
      vacvRrValue = 12,
      vacvIeValue = 3,
      vacvPeepValue = 10,
      vacvVtValue = 200,
      vacvPcMinValue = 20,
      vacvPcMaxValue = 60,
      vacvFio2Value = 22,
      vacvFlowRampValue = 4;

  int vacvmaxValue = 100, vacvminValue = 20, vacvdefaultValue = 60;
  String vacvparameterName = "I Trig", vacvparameterUnits = "cmH20";

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

  int psvItrigValue = 60,
      psvPeepValue = 10,
      psvIeValue = 3,
      psvPsValue = 30,
      psvTiValue = 5,
      psvVtMinValue = 100,
      psvVtMaxValue = 400,
      psvFio2Value = 22,
      psvAtimeValue = 10,
      psvEtrigValue = 10,
      psvBackupRrValue = 12,
      psvMinTeValue = 1,
      psvFlowRampValue = 4;

  int psvmaxValue = 100, psvminValue = 20, psvdefaultValue = 60;
  String psvparameterName = "I Trig", psvparameterUnits = "cmH20";

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

  int psimvItrigValue = 60,
      psimvRrValue = 12,
      psimvPsValue = 22,
      psimvIeValue = 3,
      psimvPeepValue = 10,
      psimvPcValue = 30,
      psimvVtMinValue = 100,
      psimvVtMaxValue = 300,
      psimvFio2Value = 22,
      psimvFlowRampValue = 3;

  int psimvmaxValue = 100, psimvminValue = 20, psimvdefaultValue = 60;
  String psimvparameterName = "I Trig", psimvparameterUnits = "cmH20";

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

  int vsimvItrigValue = 60,
      vsimvRrValue = 12,
      vsimvIeValue = 3,
      vsimvPeepValue = 10,
      vsimvVtValue = 200,
      vsimvPsValue = 22,
      vsimvPcMinValue = 20,
      vsimvPcMaxValue = 60,
      vsimvFio2Value = 22,
      vsimvFlowRampValue = 4;

  int vsimvmaxValue = 100, vsimvminValue = 20, vsimvdefaultValue = 60;
  String vsimvparameterName = "I Trig", vsimvparameterUnits = "cmH20";

  bool prvcApnea = true;
  int prvcApneaValue = 30;
  int prvcmaxValue = 60, prvcminValue = 1, prvcdefaultValue = 30;
  String prvcparameterName = "Apnea", prvcparameterUnits = "s";

  bool pccmvRR = true,pccmvRRChanged=false;
  bool pccmvIe = false,pccmvIeChanged = false;
  bool pccmvPeep = false,pccmvPeepChanged = false;
  bool pccmvPc = false,pccmvPcChanged = false;
  bool pccmvFio2 = false,pccmvFio2Changed = false;
  bool pccmvVtmin = false,pccmvVtminChanged = false;
  bool pccmvVtmax = false,pccmvVtmaxChanged = false;
  bool pccmvFlowRamp = false,pccmvFlowRampChanged = false;
  bool pccmvTih = false,pccmvValueChanged = false;

  int pccmvRRValue = 12,
      pccmvIeValue = 3,
      pccmvPeepValue = 10,
      pccmvPcValue = 30,
      pccmvFio2Value = 22,
      pccmvVtminValue = 100,
      pccmvVtmaxValue = 400,
      pccmvTihValue = 50,
      pccmvRRValueTemp = 12,
      pccmvIeValueTemp = 3,
      pccmvPeepValueTemp = 10,
      pccmvPcValueTemp = 30,
      pccmvFio2ValueTemp = 22,
      pccmvVtminValueTemp = 100,
      pccmvVtmaxValueTemp = 400,
      pccmvTihValueTemp = 50;
  int pccmvFlowRampValue = 4;

  int pccmvmaxValue = 60, pccmvminValue = 1, pccmvdefaultValue = 12;
  String pccmvparameterName = "RR", pccmvparameterUnits = "";

  bool vccmvRR = true;
  bool vccmvIe = false;
  bool vccmvPeep = false;
  bool vccmvPcMin = false;
  bool vccmvPcMax = false;
  bool vccmvFio2 = false;
  bool vccmvVt = false;
  bool vccmvFlowRamp = false;
  bool vccmvTih = false;

  int vccmvRRValue = 12,
      vccmvIeValue = 3,
      vccmvPeepValue = 10,
      vccmvPcMinValue = 20,
      vccmvPcMaxValue = 60,
      vccmvFio2Value = 22,
      vccmvVtValue = 200,
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
  String lastRecordTime;
  String priorityNo, alarmActive;

  int minRrtotal = 1,
      maxRrtotal = 100,
      minvte = 100,
      maxvte = 900,
      minmve = 0,
      maxmve = 100,
      minppeak = 10,
      maxppeak = 60,
      minpeep = 0,
      maxpeep = 60,
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
  bool newTreatmentEnabled = false, powerButtonEnabled = false;
  int noTimes;

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
      if (event != null) {
        if (event[0] == 126 && event.length > 110) {
          list.addAll(event);
          list.removeAt(0);
        }

        // var length = list.length;
        // bool data = await checkCrc(list, length);
        // if (data == false) {
        //   list.clear();
        // } else {
        setState(() {
          // Fluttertoast.showToast(msg: ((list[112] << 8) + list[113]).toString());
          //=============

          setState(() {
            var now = new DateTime.now();

            tiValue = (((list[74] << 8) + list[75]) / 1000).toInt(); //75 76
            teValue = (((list[76] << 8) + list[77]) / 1000).toInt();
            ibytValue = ((list[90] << 8) + list[91]);

            int vteValueCheck = ((list[4] << 8) + list[5]); //5 6

            // mvValue =

            if (vteValueCheck != 0) {
              setState(() {
                vteValue = vteValueCheck;
              });
            }
            int mvValueCheck = (((list[8] << 8) + list[9])).toInt();

            if (mvValueCheck != "0") {
              setState(() {
                mvValue = mvValueCheck;
              });
            }

            int rrtotalCheck = ((list[10] << 8) + list[11]).toInt();

            if (rrtotalCheck != "0") {
              setState(() {
                rrtotalValue = rrtotalCheck;
              });
            }
            int psValueCheck = (((list[14] << 8) + list[15]) / 100).toInt();
            peepDisplayValue = (((list[16] << 8) + list[17]) / 100).toInt();

            if (psValueCheck != 0) {
              setState(() {
                psValue1 = psValueCheck;
              });
            }
            paw = (((list[34] << 8) + list[35]) / 100).toInt();

            if (paw > 200) {
              setState(() {
                paw = 0;
              });
            }

            expiratoryPressureR =
                (((list[36] << 8) + list[37]) / 100).toInt(); //37 38

            fio2DisplayParameter = ((list[38] << 8) + list[39]); // 39,40

            mixingTankPressureR = ((list[40] << 8) + list[41]);
            // o2ipPressureR = ((list[42] << 8) + list[43]);
            airipPressureR = ((list[44] << 8) + list[45]);

            //flow graph
            inspirationflowR = ((list[46] << 8) + list[47]); //47-48
            exhalationflowR = ((list[48] << 8) + list[49]); //49-50

            o2Valve = ((list[50] << 8) + list[51]);
            airiPValveStatusR = ((list[52] << 8) + list[53]);
            _2by2inhalationValueR = ((list[54] << 8) + list[55]);
            _2by2exhalationValueR = ((list[56] << 8) + list[57]);
            turbineSpeedR = ((list[58] << 8) + list[59]);
            internalTemperatureR = ((list[60] << 8) + list[61]);
            operatinModeR = ((list[104] << 8) + list[105]);

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
            List<double> li = [];

            if (pressurePoints.length >= 100) {
              setState(() {
                // pressurePoints.removeRange(0, 50);
              });
            } else {
              pressurePoints.add(temp);
              // li.add(temp);
            }

            double temp1 = ((list[58] << 8) + list[59]).toDouble(); // volume points 59,60

            if (volumePoints.length >= 100) {
              // volumePoints.removeRange(0, 50);
            } else {
              // Fluttertoast.showToast(msg: temp1.toString(),toastLength: Toast.LENGTH_SHORT);
              volumePoints.add(temp1);
            }

            double temp3 = ((((list[46] << 8) + list[47])) -
                    (((list[48] << 8) + list[49])))
                .toDouble();
            temp3 = temp3 * 0.06;

            if (flowPoints.length >= 100) {
              // flowPoints.removeRange(0, 50);
            } else {
              flowPoints.add(temp3);
            }

            if (patientId != "") {
              dbHelper.save(VentilatorOMode(
                  patientId,
                  patientName,
                  patientAge,
                  patientGender,
                  patientHeight,
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
                  ieValue.toString(),
                  peepValue.toString(),
                  psValue.toString(),
                  fio2Value.toString(),
                  tiValue.toString(),
                  teValue.toString(),
                  temp,
                  temp3,
                  temp1,
                  operatinModeR.toString(),
                  lungImage.toString(),
                  paw.toString()));
            } else {
              dbHelper.save(VentilatorOMode(
                  patientId == "" ? "SWASIT" + noTimes.toString() : "0",
                  patientName,
                  patientAge,
                  patientGender,
                  patientHeight,
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
                  ieValue.toString(),
                  peepValue.toString(),
                  psValue.toString(),
                  fio2Value.toString(),
                  tiValue.toString(),
                  teValue.toString(),
                  temp,
                  temp3,
                  temp1,
                  operatinModeR.toString(),
                  lungImage.toString(),
                  paw.toString()));
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
            i = list[12].toString();
            e = list[13].toString();
            tempIe = i + ":" + e;
            // ieValue = e;
          });

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
          }

          setState(() {
            alarmActive = list[108].toString();
            var data = ((list[106] << 8) + list[107]);
            // Fluttertoast.showToast(msg: alarmActive.toString()+" code : "+data.toString());
          });

          if (list[108] == 1) {
              setState(() {
                ((list[106] << 8) + list[107])  == 01 ? alarmMessage="AC POWER DISCONNECTED"
                :  ((list[106] << 8) + list[107])  == 02 ? alarmMessage=" LOW BATTERY"
                 :  ((list[106] << 8) + list[107])  == 03 ? alarmMessage="CALIBRATE FiO2"
                  :  ((list[106] << 8) + list[107])  == 04 ? alarmMessage="CALIBRATION FiO2 FAIL"
                   :  ((list[106] << 8) + list[107])  == 05 ? alarmMessage="SYSTEM FAULT"
                    :  ((list[106] << 8) + list[107])  == 06 ? alarmMessage="SELF TEST FAIL"
                     :  ((list[106] << 8) + list[107])  == 07 ? alarmMessage="FiO2 SENSOR MISSING"
                      :  ((list[106] << 8) + list[107])  == 08 ? alarmMessage="HIGH FiO2"
                       :  ((list[106] << 8) + list[107])  == 09 ? alarmMessage="LOW FIO2"
                        :  ((list[106] << 8) + list[107])  == 10 ? alarmMessage="HIGH LEAKAGE"
                        :  ((list[106] << 8) + list[107])  == 11 ? alarmMessage="HIGH PRESSURE"
                        :  ((list[106] << 8) + list[107])  == 12 ? alarmMessage="LOW PRESSURE"
                        :  ((list[106] << 8) + list[107])  == 13 ? alarmMessage="LOW VTE"
                        :  ((list[106] << 8) + list[107])  == 14 ? alarmMessage="HIGH VTE"
                        :  ((list[106] << 8) + list[107])  == 15 ? alarmMessage="LOW VTI"
                        :  ((list[106] << 8) + list[107])  == 16 ? alarmMessage="HIGH VTI"
                        :  ((list[106] << 8) + list[107])  == 17 ? alarmMessage="PATIENT DISCONNECTION"
                        :  ((list[106] << 8) + list[107])  == 18 ? alarmMessage="LOW O2  supply"
                        :  ((list[106] << 8) + list[107])  == 19 ? alarmMessage="LOW RR"
                        :  ((list[106] << 8) + list[107])  == 20 ? alarmMessage="HIGH RR"
                        :  ((list[106] << 8) + list[107])  == 21 ? alarmMessage="HIGH PEEP"
                        :  ((list[106] << 8) + list[107])  == 22 ? alarmMessage="LOW PEEP"
                        :  ((list[106] << 8) + list[107])  == 23 ? alarmMessage="Apnea backup"

                        :alarmMessage="0";
              });

            // if (list[109] == 0) {
            // setState(() {
            //   ((((list[106] << 8) + list[107]) << 8) + list[107]) == 24
            //       ? alarmMessage = "Device Fault9 Restart/Srvc"
            //       : ((list[106] << 8) + list[107]) == 25
            //           ? alarmMessage = "Device Fault10 Restart/Srvc"
            //           : ((list[106] << 8) + list[107]) == 26
            //               ? alarmMessage = "Device Fault11 Restart/Srvc"
            //               : ((list[106] << 8) + list[107]) == 27
            //                   ? alarmMessage = "Device Fault12 Restart/Srvc"
            //                   : ((list[106] << 8) + list[107]) == 28
            //                       ? alarmMessage = "Device Fault13 Restart/Srvc"
            //                       : ((list[106] << 8) + list[107]) == 52
            //                           ? alarmMessage = "Power Supply Loss"
            //                           : ((list[106] << 8) + list[107]) == 62
            //                               ? alarmMessage = "Power Disconnected"
            //                               : ((list[106] << 8) + list[107]) == 63
            //                                   ? alarmMessage =
            //                                       "Patient Disconnected"
            //                                   : ((list[106] << 8) + list[107]) == 64
            //                                       ? alarmMessage =
            //                                           "High Inspiratory Pressure"
            //                                       : ((list[106] << 8) + list[107]) == 65
            //                                           ? alarmMessage =
            //                                               "High Peep"
            //                                           : ((list[106] << 8) +
            //                                                       list[107]) ==
            //                                                   66
            //                                               ? alarmMessage =
            //                                                   "High Respiratory Rate"
            //                                               : ((list[106] << 8) +
            //                                                           list[
            //                                                               107]) ==
            //                                                       67
            //                                                   ? alarmMessage =
            //                                                       "Power Sensor Failure"
            //                                                   : ((list[106] << 8) + list[107]) == 68
            //                                                       ? alarmMessage =
            //                                                           "Read / Write Error"
            //                                                       : ((list[106] << 8) + list[107]) == 69
            //                                                           ? alarmMessage =
            //                                                               "Ventilator Temperature Error"
            //                                                           : ((list[106] << 8) + list[107]) ==
            //                                                                   70
            //                                                               ? alarmMessage =
            //                                                                   "System Failure"
            //                                                               : ((list[106] << 8) + list[107]) == 71
            //                                                                   ? alarmMessage = "Low Tidal Volume"
            //                                                                   : "";
            // });
            // // } else if (list[110] == 1) {
            // setState(() {
            //   ((list[106] << 8) + list[107]) == 6
            //       ? alarmMessage = "Buzzer Fault3 Restart/Srvc"
            //       : ((list[106] << 8) + list[107]) == 11
            //           ? alarmMessage = "If Persists Restart/Srvc"
            //           : ((list[106] << 8) + list[107]) == 12
            //               ? alarmMessage = "Check Exh Valve Pressure"
            //               : ((list[106] << 8) + list[107]) == 13
            //                   ? alarmMessage = "CHECK FiO2 SENSOR"
            //                   : ((list[106] << 8) + list[107]) == 17
            //                       ? alarmMessage =
            //                           "CONNECT VALVE OR CHANGE PRESS"
            //                       : ((list[106] << 8) + list[107]) == 21
            //                           ? alarmMessage =
            //                               "DEVICE FAULT3 RESTART/SRVC"
            //                           : ((list[106] << 8) + list[107]) == 23
            //                               ? alarmMessage =
            //                                   "DEVICE FAULT7 RESTART/SRVC"
            //                               : ((list[106] << 8) + list[107]) == 32
            //                                   ? alarmMessage =
            //                                       "FiO2 SENSOR MISSING"
            //                                   : ((list[106] << 8) + list[107]) == 36
            //                                       ? alarmMessage =
            //                                           "HIGH LEAKAGE"
            //                                       : ((list[106] << 8) + list[107]) == 37
            //                                           ? alarmMessage =
            //                                               "HIGH PRESSURE"
            //                                           : ((list[106] << 8) +
            //                                                       list[107]) ==
            //                                                   40
            //                                               ? alarmMessage =
            //                                                   "HIGH VTI"
            //                                               : ((list[106] << 8) +
            //                                                           list[
            //                                                               107]) ==
            //                                                       41
            //                                                   ? alarmMessage =
            //                                                       "INSP FLOW RESTART/SRVC"
            //                                                   : ((list[106] << 8) + list[107]) == 42
            //                                                       ? alarmMessage =
            //                                                           "INTENTIONAL VENT STOP"
            //                                                       : ((list[106] << 8) + list[107]) == 43
            //                                                           ? alarmMessage =
            //                                                               "KEYPAD FAULT RESTART/SRVC* *IF PERSISTS RESTART/SRVC"
            //                                                           : ((list[106] << 8) + list[107]) ==
            //                                                                   48
            //                                                               ? alarmMessage =
            //                                                                   "OCCLUSION CHECK CIRCUIT*  *IF PERSISTS RESTART/SRVC "
            //                                                               : ((list[106] << 8) + list[107]) == 49
            //                                                                   ? alarmMessage = "OCCLUSION CHECK CIRCUIT"
            //                                                                   : ((list[106] << 8) + list[107]) == 50 ? alarmMessage = "PATIENT DISCONNECTION* *IF PERSISTS RESTART/SRVC" : ((list[106] << 8) + list[107]) == 53 ? alarmMessage = "PRES SENS FLT1 RESTART/SRVC" : ((list[106] << 8) + list[107]) == 55 ? alarmMessage = "REMOVE VALVE prvc MODE" : ((list[106] << 8) + list[107]) == 56 ? alarmMessage = "REMOVE VALVE OR CHANGE PRES" : ((list[106] << 8) + list[107]) == 58 ? alarmMessage = "TURB OVERHEAT RESTART/SRVC" : ((list[106] << 8) + list[107]) == 60 ? alarmMessage = "VALVE MISSING CONNECT VALVE" : ((list[106] << 8) + list[107]) == 61 ? alarmMessage = "VTI NOT REACHED* *IF PERSISTS RESTART/SRVC" : "";
            // });
            // // } else if (list[109] == 2) {
            // setState(() {
            //   ((list[106] << 8) + list[107]) == 2
            //       ? alarmMessage = "BATTERY FAULT1 RESTART/SRVC"
            //       : ((list[106] << 8) + list[107]) == 3
            //           ? alarmMessage = "DBATTERY FAULT2 RESTART/SRVC"
            //           : ((list[106] << 8) + list[107]) == 4
            //               ? alarmMessage = "BUZZER FAULT1  RESTART/SRVC"
            //               : ((list[106] << 8) + list[107]) == 5
            //                   ? alarmMessage = "BUZZER FAULT2 RESTART/SRVC"
            //                   : ((list[106] << 8) + list[107]) == 7
            //                       ? alarmMessage = "BUZZER LOW BATTERY"
            //                       : ((list[106] << 8) + list[107]) == 8
            //                           ? alarmMessage = "CALIBRATE FiO2"
            //                           : ((list[106] << 8) + list[107]) == 9
            //                               ? alarmMessage = "CALIBRATION FAIL"
            //                               : ((list[106] << 8) + list[107]) == 10
            //                                   ? alarmMessage =
            //                                       "CHECK BATTERY CHARGE *IF PERSISTS RESTART/SRVC"
            //                                   : ((list[106] << 8) + list[107]) == 14
            //                                       ? alarmMessage =
            //                                           "CHECK PROXIMAL LINE1* *IF PERSISTS RESTART/SRVC"
            //                                       : ((list[106] << 8) + list[107]) == 15
            //                                           ? alarmMessage =
            //                                               "CHECK REMOTE ALARM"
            //                                           : ((list[106] << 8) +
            //                                                       list[107]) ==
            //                                                   16
            //                                               ? alarmMessage =
            //                                                   "CHECK SETTINGS"
            //                                               : ((list[106] << 8) +
            //                                                           list[
            //                                                               107]) ==
            //                                                       22
            //                                                   ? alarmMessage =
            //                                                       "DEVICE FAULT5 RESTART/SRVC"
            //                                                   : ((list[106] << 8) + list[107]) == 29
            //                                                       ? alarmMessage =
            //                                                           "E SENS FAULT OR CIRC LEAK"
            //                                                       : ((list[106] << 8) + list[107]) == 31
            //                                                           ? alarmMessage =
            //                                                               "EXH VALVE LEAKAGE"
            //                                                           : ((list[106] << 8) + list[107]) ==
            //                                                                   33
            //                                                               ? alarmMessage =
            //                                                                   "HIGH / LOW BATTERY TEMP* *IF PERSISTS RESTART/SRVC"
            //                                                               : ((list[106] << 8) + list[107]) == 34
            //                                                                   ? alarmMessage = "HIGH FiO2"
            //                                                                   : ((list[106] << 8) + list[107]) == 35 ? alarmMessage = "HIGH INT TEMP COOL VENT* *IF PERSISTS RESTART/SRVC" : ((list[106] << 8) + list[107]) == 38 ? alarmMessage = "DHIGH RATE" : ((list[106] << 8) + list[107]) == 39 ? alarmMessage = "HIGH VTE" : ((list[106] << 8) + list[107]) == 45 ? alarmMessage = "LOW FiO2" : ((list[106] << 8) + list[107]) == 46 ? alarmMessage = "LOW VTE" : ((list[106] << 8) + list[107]) == 47 ? alarmMessage = "LOW VTI	" : ((list[106] << 8) + list[107]) == 51 ? alarmMessage = "POWER FAULT RESTART/SRVC" : ((list[106] << 8) + list[107]) == 54 ? alarmMessage = "PROX SENS FLT2 RESTART/SRVCC" : ((list[106] << 8) + list[107]) == 59 ? alarmMessage = "UNKNOWN BATTERY" : "";
            // });
            // // } else if (list[109] == 3) {
            // setState(() {
            //   ((list[106] << 8) + list[107]) == 20
            //       ? alarmMessage = "DC POWER DISCONNECTION"
            //       : "";
            // });
            // }
          }

          // setState(() {
          //   var now = new DateTime.now();
          //   lastRecordTime = DateFormat("dd-MM-yyyy H:m:s").format(now);
          // });

          list.clear();

          //==============
        });
        // }
      } else {
        pressurePoints.clear();
        volumePoints.clear();
        flowPoints.clear();
        list.clear();
      }
    });
    setState(() {
      _status = "Connected";
    });
  }

  _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      getData();
      setState(() {
        _status = "Disconnected";
        usbConnected = false;
      });
      // Fluttertoast.showToast(msg: _status);
    }
    print(devices);
    _connectTo(devices[0]);
  }

  int counter = 0, counterlength = 0;
  var presentTime;

  @override
  initState() {
    super.initState();
    getData();
    // _timer1 = Timer.periodic(Duration(seconds: 1), (timer) {
    //   _getTime();
    // });
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
        } else {}
      } else {
        setState(() {
          counter = 0;
        });
      }
    });

    // _timer2 = Timer.periodic(Duration(minutes: 1), (timer) async {
    //   if (_status == "Connected") {
    //     String lastTime = await dbHelper.getLastRecordTime();
    //     String lastRecordTime =
    //         lastTime.split("[{datetimeP: ")[1].split("}]")[0];

    //     var now = new DateTime.now();
    //     setState(() {
    //       presentTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
    //       DateTime date1 = DateFormat("yyyy-MM-dd HH:mm:ss").parse(lastRecordTime);
    //       DateTime date2 = DateFormat("yyyy-MM-dd HH:mm:ss").parse(presentTime);
    //       var differnceD = date2.difference(date1);
    //       if (differnceD.inMinutes > 2) {
    //         // Fluttertoast.showToast(msg: "Timeout.");
    //         // psValue1 = 0;
    //         // mvValue = 0;
    //         // vteValue = 0;
    //         // fio2DisplayParameter = 0;
    //         // pressurePoints = [];
    //         // volumePoints = [];
    //         // flowPoints = [];
    //       }
    //     });
    //   }
    // });
    // _timer = Timer.periodic(Duration(minutes: 5), (timer) async {
    //   if (_status == "Connected") {
    //     String lastTime = await dbHelper.getLastRecordTime();
    //     String lastRecordTime =
    //         lastTime.split("[{datetimeP: ")[1].split("}]")[0];

    //     var now = new DateTime.now();
    //     setState(() {
    //       presentTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
    //       DateTime date1 =
    //           DateFormat("yyyy-MM-dd HH:mm:ss").parse(lastRecordTime);
    //       DateTime date2 = DateFormat("yyyy-MM-dd HH:mm:ss").parse(presentTime);
    //       var differnceD = date2.difference(date1);
    //       if (differnceD.inMinutes > 5) {
    //         setState(() {
    //           powerButtonEnabled = true;
    //         });
    //       } else {
    //         setState(() {
    //           powerButtonEnabled = false;
    //         });
    //       }
    //     });
    //   }
    // });
  }

  Future<void> _sendShutdown() async {
    try {
      var result = await shutdownChannel.invokeMethod('sendShutdowndevice');
      print(result);
    } on PlatformException catch (e) {
      print(e);
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
    print(obj.toString());

    if (_status == "Connected") {
      // Fluttertoast.showToast(msg: obj.toString());
      await _port.write(Uint8List.fromList(obj));
      setState(() {
        // modeWriteList.clear();
      });
    }
  }

  checkCrc(List<int> obj, length) async {
    int index = length - 2;
    int i = 0;
    int crcData = 0;
    int uiCrc = 0, r = 0;
    int temp = 0;

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
    // Fluttertoast.showToast(msg: null)
    // Fluttertoast.showToast(
    //     msg: "received crc : " +
    //         crcData.toString() +
    //         "  \n" +
    //         " calcu crc : " +
    //         uiCrc.toString());

    if (crcData == uiCrc) {
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
      modeName = preferences.getString("mode");
      rrValue = preferences.getInt("rr");
      ieValue = preferences.getInt("ie");
      peepValue = preferences.getInt("peep");
      psValue = preferences.getInt("ps");
      vtValue = preferences.getInt("vt");
      vteValue = preferences.getInt("vte");
      fio2Value = preferences.getInt("fio2");
      tiValue = 0;
      paw = preferences.getInt("paw");
      mvValue = 0;
      rrtotalValue = preferences.getInt("rrtotal");
      patientId = preferences.getString("pid");
      patientName = preferences.getString("pname");
      patientGender = preferences.getString("pgender");
      patientAge = preferences.getString("page");
      patientHeight = preferences.getString("pheight");
      patientWeight = preferences.getString("pweight");
      if(patientWeight==null || patientWeight==""){
        patientWeight="5";
      }
      preferences.getString("noTimes");
      peepHeight = 252 - ((peepValue * 3.71) - 4);
      psHeight = 252 - ((psValue * 3.71) - 4);
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    scopeOne = Oscilloscope(
      showYAxis: true,
      yAxisColor: Colors.grey,
      padding: 10.0,
      backgroundColor: Color(0xFF171e27),
      traceColor: Colors.green,
      yAxisMax: 60,
      yAxisMin: 0.0,
      dataSet: pressurePoints,
    );

    scopeOne1 = Oscilloscope(
        showYAxis: true,
        yAxisColor: Colors.grey,
        padding: 10.0,
        backgroundColor: Color(0xFF171e27),
        traceColor: Colors.yellow,
        yAxisMax: 90.0,
        yAxisMin: -90.0,
        dataSet: flowPoints);

    scopeOne2 = Oscilloscope(
      showYAxis: true,
      yAxisColor: Colors.grey,
      padding: 10.0,
      backgroundColor: Color(0xFF171e27),
      traceColor: Colors.blue,
      yAxisMax: 700.0,
      yAxisMin: 0.0,
      dataSet: volumePoints,
    );

    return Scaffold(
        resizeToAvoidBottomPadding: false,
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
                padding: const EdgeInsets.only(right: 120.0),
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
                        width: 904,
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
                                                  setData();
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
                                                  setData();
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
                                                  setData();
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
                                                  setData();
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
                                                  // pccmvEnabled = false;
                                                  // vccmvEnabled = false;
                                                  // pacvEnabled = false;
                                                  // vacvEnabled = false;
                                                  // psimvEnabled = false;
                                                  // vsimvEnabled = false;
                                                  // psvEnabled = false;
                                                  // prvcEnabled = true;
                                                });
                                              },
                                              child: Card(
                                                color: prvcEnabled
                                                    ? Colors.blue
                                                    : Colors.grey,
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
                                                      setState(() {
                                                        writeAlarmsData();
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
                  "V1.1",
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
                Container(
                  width: 60,
                  child: LinearPercentIndicator(
                    animation: true,
                    lineHeight: 20.0,
                    animationDuration: 2500,
                    percent: batteryPercentageValue,
                    center: Text(
                        (batteryPercentageValue * 100).toInt().toString() +
                            " %"),
                    linearStrokeCap: LinearStrokeCap.roundAll,
                    progressColor: Colors.green,
                  ),
                ),
                SizedBox(
                  height: 2,
                ),
                powerButtonEnabled
                    ? Padding(
                        padding: const EdgeInsets.only(right: 40.0, bottom: 20),
                        child: IconButton(
                          icon: Icon(Icons.power_settings_new,
                              size: 70, color: Colors.red),
                          onPressed: () {
                            _sendShutdown();
                          },
                        ),
                      )
                    : Container(),
                //  Padding(
                //   padding: const EdgeInsets.only(right: 40.0, bottom: 20),
                //   child: IconButton(
                //     icon: Icon(Icons.power_settings_new,
                //         size: 70, color: Colors.red),
                //     onPressed: () {
                //       _sendShutdown();
                //     },
                //   ),
                // ),
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
                    // _status == "Connected"
                    //     ? Padding(
                    //         padding:
                    //             const EdgeInsets.only(right: 5.0, top: 5.0),
                    //         child: Image.asset(
                    //           "assets/images/usbconnected.png",
                    //           width: 38,
                    //           color: Colors.white,
                    //         ),
                    //       )
                    //     : Padding(
                    //         padding:
                    //             const EdgeInsets.only(right: 5.0, top: 5.0),
                    //         child: Image.asset(
                    //           "assets/images/usbdisconnected.png",
                    //           width: 38,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    SizedBox(
                      height: 5,
                    ),
                    audioEnable
                        ? InkWell(
                            onTap: () {
                              setState(() {
                                audioEnable = !audioEnable;
                              });
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 12.0, top: 5.0),
                              child: Image.asset(
                                "assets/images/audioon.png",
                                color: Colors.white,
                                width: 38,
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              setState(() {
                                audioEnable = !audioEnable;
                              });
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 12.0, top: 5.0),
                              child: Image.asset(
                                "assets/images/audiooff.png",
                                color: Colors.grey,
                                width: 38,
                              ),
                            ),
                          ),
                    SizedBox(
                      height:
                          playOnEnabled ? 242 : powerButtonEnabled ? 241 : 340,
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
                          InkWell(
                            onTap: () {
                              setState(() {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ViewLogPatientList()));
                              });
                            },
                            child: Center(
                              child: Container(
                                width: 120,
                                child: Card(
                                  color: monitorEnabled
                                      ? Colors.blue
                                      : Colors.white,
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
                          // InkWell(
                          //   onTap: () {
                          //     setState(() {
                          //       Navigator.push(
                          //         context,
                          //         new MaterialPageRoute(
                          //             builder: (context) =>
                          //                 CalibrationPage(_port)),
                          //       );
                          //     });
                          //   },
                          //   child: Center(
                          //     child: Container(
                          //       width: 120,
                          //       child: Card(
                          //         color: monitorEnabled
                          //             ? Colors.blue
                          //             : Colors.white,
                          //         child: Padding(
                          //           padding: const EdgeInsets.all(12.0),
                          //           child: Center(
                          //               child: Text("Calibration",
                          //                   style: TextStyle(
                          //                       fontWeight: FontWeight.bold,
                          //                       color: monitorEnabled
                          //                           ? Colors.white
                          //                           : Colors.black))),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      )
                    : Container(),

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
                                                    mapDisplayValue.toString(),
                                                    // "000",
                                                    style: TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 40),
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
                                                alignment: Alignment.topRight,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text("l/m",
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
                                                    (mvValue/1000).toStringAsFixed(3),
                                                    // "0000",
                                                    style: TextStyle(
                                                        color: Colors.yellow,
                                                        fontSize: 40),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: 60, left: 4),
                                                  child: Text(
                                                    "MV",
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
                                                alignment: Alignment.topRight,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text("ml/cmH2O",
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
                                                    cdisplayParameter
                                                        .toString(),
                                                    // "0000",
                                                    style: TextStyle(
                                                        color: Colors.pink,
                                                        fontSize: 40),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: 60, left: 4),
                                                  child: Text(
                                                    "C",
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
                                          padding: const EdgeInsets.all(5.0),
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
                                                    ieDisplayValue.toString(),
                                                    // "0000",
                                                    style: TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 40),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: 50, left: 4),
                                                  child: Text(
                                                    "I:E",
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
                                  ],
                                ),
                                SizedBox(
                                  height: 6,
                                ),
                                Stack(
                                  children: [
                                    Align(
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
                                                              : lungImage == 5
                                                                  ? "assets/lungs/5.png"
                                                                  : "assets/lungs/1.png",
                                              width: 120),
                                          Text(ioreDisplayParamter,
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
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
                  height: 90,
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
                                  TextStyle(color: Colors.green, fontSize: 40),
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
                          padding: const EdgeInsets.only(top: 0),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH2O",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
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
                  height: 90,
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
                                  TextStyle(color: Colors.yellow, fontSize: 40),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 0.0, bottom: 60),
                            child: Text(
                              "VT",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "ml",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
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
                  height: 90,
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
                                  TextStyle(color: Colors.pink, fontSize: 40),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 0.0, bottom: 60),
                            child: Text(
                              "Peep",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "cmH2O",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
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
                  height: 90,
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
                                  TextStyle(color: Colors.blue, fontSize: 40),
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
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "bpm",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
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
                  height: 90,
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
                                  TextStyle(color: Colors.teal, fontSize: 40),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 0.0, bottom: 55, right: 0.0),
                            child: Text(
                              "FiO2",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.topRight,
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
                              "b/min",
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
                                    fontSize: 25, color: Colors.white),
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
                                "1:" + ieValue.toString(),
                                style: TextStyle(
                                    fontSize: 25, color: Colors.white),
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
                                    fontSize: 25, color: Colors.white),
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
            InkWell(
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
                              operatinModeR == 6 ||
                                      operatinModeR == 2 ||
                                      operatinModeR == 4 ||
                                      operatinModeR == 3
                                  ? "PS"
                                  : operatinModeR == 7 ||
                                          operatinModeR == 1 ||
                                          operatinModeR == 5
                                      ? "Vt"
                                      : modeName == "PC-CMV" ||
                                              modeName == "PACV" ||
                                              modeName == "PSIMV" ||
                                              modeName == "PSV"
                                          ? "PS"
                                          : modeName == "VC-CMV" ||
                                                  modeName == "VACV" ||
                                                  modeName == "VSIMV"
                                              ? "Vt"
                                              : "PS",
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
                                        operatinModeR == 4 ||
                                        operatinModeR == 3
                                    ? psValue.toString()
                                    : operatinModeR == 7 ||
                                            operatinModeR == 1 ||
                                            operatinModeR == 5
                                        ? vtValue.toString()
                                        : modeName == "PC-CMV" ||
                                                modeName == "PACV" ||
                                                modeName == "PSIMV" ||
                                                modeName == "PSV"
                                            ? psValue.toString()
                                            : modeName == "VC-CMV" ||
                                                    modeName == "VACV" ||
                                                    modeName == "VSIMV"
                                                ? vtValue.toString()
                                                : psValue.toString(),
                                style: TextStyle(
                                    fontSize: 25, color: Colors.white),
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
            InkWell(
              onTap: () {
                CommonClick("FiO2") ;
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
                              "FiO2",
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
                                    fontSize: 25, color: Colors.white),
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
        // prvcEnabled ? prvcData() : Container(),
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
                  psvmaxValue = 100;
                  psvminValue = 20;
                  psvparameterName = "I Trig";
                  psvparameterUnits = "cmH20";
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
                              "",
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
                              "100",
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
                              "20",
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
                                psvItrigValue.toString(),
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
                                    ? psvItrigValue / 100
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
                  psvmaxValue = 30;
                  psvminValue = 1;
                  psvparameterName = "Peep";
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
                              "Peep",
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
                              "",
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
            InkWell(
              onTap: () {
                setState(() {
                  psvmaxValue = 60;
                  psvminValue = 0;
                  psvparameterName = "PS";
                  psvparameterUnits = "";
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
                              "Ps",
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
                              "cmH20",
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
                              "60",
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
                              "0",
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
                                  psvPs ? Color(0xFF213855) : Color(0xFFE0E0E0),
                                ),
                                value: psvPsValue != null ? psvPsValue / 60 : 0,
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
                  psvmaxValue = 100;
                  psvminValue = 21;
                  psvparameterName = "FiO2";
                  psvparameterUnits = "";
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
                              "FiO2",
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
                              "",
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
                              "20",
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
                  psvmaxValue = 30;
                  psvminValue = 5;
                  psvparameterName = "A Time";
                  psvparameterUnits = "";
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
                              "",
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
                              "4",
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
                              "0",
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
                  psvmaxValue = 4;
                  psvminValue = 1;
                  psvparameterName = "Apnea I:E";
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
                              "Apnea I:E",
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
                              "4",
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
                              "1",
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
                                "1:" + psvIeValue.toString(),
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
                                value: psvIeValue != null ? psvIeValue / 4 : 0,
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
                    psvminValue = 0;
                    psvparameterName = "Ti";
                    psvparameterUnits = "";
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
                                "",
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
                    psvmaxValue = 30;
                    psvminValue = 1;
                    psvparameterName = "Apnea RR";
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
                      color:
                          psvBackupRr ? Color(0xFFE0E0E0) : Color(0xFF213855),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Apnea RR",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: psvBackupRr
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
                                    color: psvBackupRr
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
                                      ? psvBackupRrValue / 30
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
                    psvmaxValue = 2000;
                    psvminValue = 50;
                    psvparameterName = "Vt Min";
                    psvparameterUnits = "ml";
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
                                "",
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
                                "2000",
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
                                "50",
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
                                      ? psvVtMinValue / 2000
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
            ]),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    psvmaxValue = 2000;
                    psvminValue = 50;
                    psvparameterName = "Vt Max";
                    psvparameterUnits = "";
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
                                "",
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
                                "2000",
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
                                "50",
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
                                      ? psvVtMaxValue / 2000
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
                    psvmaxValue = 5;
                    psvminValue = 1;
                    psvparameterName = "Min Te";
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
                                "",
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
                height: 130,
              )
            ]),
        SizedBox(
          width: 10,
        ),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 28.0),
                                child: Column(
                                  children: [
                                    Text("Peep"),
                                    Text("$minpeep-$maxpeep"),
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
                                    Text("FiO2"),
                                    Text("$minfio2-$maxfio2"),
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
          patientId!="" ? Text("") :  Container(
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
                    Text("IBW : "+patientWeight.toString()),
                      Text("Ideal Vt : "+(int.tryParse(patientWeight) * 6).toString() +
                          " - " +
                          (int.tryParse(patientWeight) * 8).toString())
                    ],
                  ),
                )),
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
                      Text(
                        psvparameterName,
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.normal),
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
                                  if (psvItrig == true &&
                                      psvItrigValue != psvminValue) {
                                    setState(() {
                                      psvItrigValue = psvItrigValue - 1;
                                    });
                                  } else if (psvPeep == true &&
                                      psvPeepValue != psvminValue) {
                                    setState(() {
                                      psvPeepValue = psvPeepValue - 1;
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
                                    });
                                  } else if (psvVtMax == true &&
                                      psvVtMaxValue != psvminValue) {
                                    setState(() {
                                      psvVtMaxValue = psvVtMaxValue - 1;
                                    });
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
                              width: 60,
                            ),
                            Text(
                              psvItrig
                                  ? psvItrigValue.toInt().toString()
                                  : psvPeep
                                      ? psvPeepValue.toInt().toString()
                                      : psvPs
                                          ? psvPsValue.toInt().toString()
                                          : psvIe
                                              ? psvIeValue.toInt().toString()
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
                                  if (psvItrig == true &&
                                      psvItrigValue != psvmaxValue) {
                                    setState(() {
                                      psvItrigValue = psvItrigValue + 1;
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
                                      psvVtMinValue != psvmaxValue) {
                                    setState(() {
                                      psvVtMinValue = psvVtMinValue + 1;
                                    });
                                  } else if (psvVtMax == true &&
                                      psvVtMaxValue != psvmaxValue) {
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
                              if (psvItrig == true) {
                                setState(() {
                                  psvItrigValue = value.toInt();
                                });
                              } else if (psvPeep == true) {
                                setState(() {
                                  psvPeepValue = value.toInt();
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
                                setState(() {
                                  psvVtMinValue = value.toInt();
                                });
                              } else if (psvVtMax == true) {
                                setState(() {
                                  psvVtMaxValue = value.toInt();
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
                            Text(psvminValue.toString()),
                            Text(
                              psvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(psvmaxValue.toString())
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
                  pacvmaxValue = 100;
                  pacvminValue = 20;
                  pacvparameterName = "I Trig";
                  pacvparameterUnits = "cmH20";
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
                              "",
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
                              "100",
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
                              "20",
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
                                pacvItrigValue.toString() + "%",
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
                                    ? pacvItrigValue / 100
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
                  pacvmaxValue = 30;
                  pacvminValue = 1;
                  pacvparameterName = "RR";
                  pacvparameterUnits = "";
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
                              "",
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
                              "30",
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
                                    pacvRrValue != null ? pacvRrValue / 30 : 0,
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
                  pacvmaxValue = 4;
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
                              "4",
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
                              "1",
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
                                "1:" + pacvIeValue.toString(),
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
                                    pacvIeValue != null ? pacvIeValue / 4 : 0,
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
                  pacvmaxValue = 30;
                  pacvminValue = 0;
                  pacvparameterName = "PEEP";
                  pacvparameterUnits = "";
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
                              "cmH20",
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
            InkWell(
              onTap: () {
                setState(() {
                  pacvmaxValue = 60;
                  pacvminValue = 10;
                  pacvparameterName = "Pc";
                  pacvparameterUnits = "";
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
                              "Pc",
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
                              "",
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
                              "60",
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
                              "10",
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
                                    pacvPcValue != null ? pacvPcValue / 60 : 0,
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
                  pacvmaxValue = 2000;
                  pacvminValue = 50;
                  pacvparameterName = "Vt Min";
                  pacvparameterUnits = "";
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
                              "",
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
                              "2000",
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
                              "50",
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
                                    ? pacvVtMinValue / 2000
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
                  pacvmaxValue = 2000;
                  pacvminValue = 50;
                  pacvparameterName = "Vt Max";
                  pacvparameterUnits = "";
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
                              "",
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
                              "2000",
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
                              "50",
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
                                    ? pacvVtMaxValue / 2000
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
                  pacvmaxValue = 100;
                  pacvminValue = 21;
                  pacvparameterName = "FiO2";
                  pacvparameterUnits = "";
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
                              "FiO2",
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
                              "",
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
                              "20",
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
        SizedBox(
          width: 10,
        ),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 28.0),
                                child: Column(
                                  children: [
                                    Text("Peep"),
                                    Text("$minpeep-$maxpeep"),
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
                                    Text("FiO2"),
                                    Text("$minfio2-$maxfio2"),
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
            patientId!="" ? Text("") :Container(
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
                      Text("IBW : "+patientWeight.toString()),
                      Text("Ideal Vt : "+(int.tryParse(patientWeight) * 6).toString() +
                          " - " +
                          (int.tryParse(patientWeight) * 8).toString())
                    ],
                  ),
                )),
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
                      Text(
                        pacvparameterName,
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.normal),
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
                                  if (pacvItrig == true &&
                                      pacvItrigValue != pacvminValue) {
                                    setState(() {
                                      pacvItrigValue = pacvItrigValue - 1;
                                    });
                                  } else if (pacvPeep == true &&
                                      pacvPeepValue != pacvminValue) {
                                    setState(() {
                                      pacvPeepValue = pacvPeepValue - 1;
                                      if (pacvPeepValue >= pacvPcValue) {
                                        pacvPcValue = pacvPcValue - 1;
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
                                      pacvPcValue != pacvPeepValue + 1) {
                                    setState(() {
                                      pacvPcValue = pacvPcValue - 1;
                                    });
                                  } else if (pacvVtMin == true &&
                                      pacvVtMinValue != pacvminValue) {
                                    setState(() {
                                      pacvVtMinValue = pacvVtMinValue - 1;
                                    });
                                  } else if (pacvVtMax == true &&
                                      pacvVtMaxValue != pacvminValue) {
                                    setState(() {
                                      pacvVtMaxValue = pacvVtMaxValue - 1;
                                    });
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
                              pacvItrig
                                  ? pacvItrigValue.toInt().toString()
                                  : pacvPeep
                                      ? pacvPeepValue.toInt().toString()
                                      : pacvRr
                                          ? pacvRrValue.toInt().toString()
                                          : pacvIe
                                              ? pacvIeValue.toInt().toString()
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
                                    });
                                  } else if (pacvPeep == true &&
                                      pacvPeepValue != pacvmaxValue) {
                                    setState(() {
                                      pacvPeepValue = pacvPeepValue + 1;
                                      if (pacvPcValue <= pacvPeepValue) {
                                        pacvPcValue = pacvPeepValue + 1;
                                      }
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
                                      pacvVtMinValue = pacvVtMinValue + 1;
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
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      pacvFio2
                          ? Container()
                          : Container(
                              width: 350,
                              child: Slider(
                                min: pacvPc
                                    ? (pacvPeepValue + 1).toDouble()
                                    : pacvminValue.toDouble(),
                                max: pacvmaxValue.toDouble(),
                                onChanged: (double value) {
                                  if (pacvItrig == true) {
                                    setState(() {
                                      pacvItrigValue = value.toInt();
                                    });
                                  } else if (pacvPeep == true) {
                                    if (pacvPcValue <= pacvPeepValue) {
                                      pacvPcValue = value.toInt();
                                      pacvPeepValue = value.toInt();
                                    } else {
                                      pacvPeepValue = value.toInt();
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
                                    setState(() {
                                      pacvVtMinValue = value.toInt();
                                    });
                                  } else if (pacvVtMax == true) {
                                    setState(() {
                                      pacvVtMaxValue = value.toInt();
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
                                                        ? pacvVtMinValue
                                                            .toDouble()
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
                            Text(pacvminValue.toString()),
                            Text(
                              pacvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(pacvmaxValue.toString())
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
                  psimvmaxValue = 100;
                  psimvminValue = 20;
                  psimvparameterName = "I Trig";
                  psimvparameterUnits = "cmH20";
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
                              "",
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
                              "100",
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
                              "20",
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
                                psimvItrigValue.toString() + "%",
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
                                    ? psimvItrigValue / 100
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
                  psimvminValue = 1;
                  psimvparameterName = "RR";
                  psimvparameterUnits = "";
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
                              "",
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
                              "30",
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
                                    ? psimvRrValue / 30
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
                  psimvmaxValue = 4;
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
                              "4",
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
                              "1",
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
                                "1:" + psimvIeValue.toString(),
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
                                value:
                                    psimvIeValue != null ? psimvIeValue / 4 : 0,
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
                  psimvmaxValue = 30;
                  psimvminValue = 0;
                  psimvparameterName = "PEEP";
                  psimvparameterUnits = "";
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
                              "cmH20",
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
            InkWell(
              onTap: () {
                setState(() {
                  psimvmaxValue = 60;
                  psimvminValue = 10;
                  psimvparameterName = "Pc";
                  psimvparameterUnits = "";
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
                              "Pc",
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
                              "",
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
                              "60",
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
                              "10",
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
                                    ? psimvPcValue / 60
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
                  psimvmaxValue = 2000;
                  psimvminValue = 50;
                  psimvparameterName = "Vt Min";
                  psimvparameterUnits = "";
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
                              "",
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
                              "2000",
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
                              "50",
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
                                    ? psimvVtMinValue / 2000
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
                  psimvmaxValue = 2000;
                  psimvminValue = 50;
                  psimvparameterName = "Vt Max";
                  psimvparameterUnits = "";
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
                              "",
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
                              "2000",
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
                              "50",
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
                                    ? psimvVtMaxValue / 2000
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
                  psimvparameterName = "FiO2";
                  psimvparameterUnits = "";
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
                              "FiO2",
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
                              "",
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
                              "20",
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
                  psimvmaxValue = 60;
                  psimvminValue = 0;
                  psimvparameterName = "PS";
                  psimvparameterUnits = "";
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
                              "",
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
                              "60",
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
                              "0",
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
                                    ? psimvPsValue / 60
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
        SizedBox(
          width: 10,
        ),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 28.0),
                                child: Column(
                                  children: [
                                    Text("Peep"),
                                    Text("$minpeep-$maxpeep"),
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
                                    Text("FiO2"),
                                    Text("$minfio2-$maxfio2"),
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
           patientId!="" ? Text("") : Container(
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
                      Text("IBW : "+patientWeight.toString()),
                      Text("Ideal Vt : "+(int.tryParse(patientWeight) * 6).toString() +
                          " - " +
                          (int.tryParse(patientWeight) * 8).toString())
                    ],
                  ),
                )),
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
                      Text(
                        psimvparameterName,
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.normal),
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
                                  if (psimvItrig == true &&
                                      psimvItrigValue != psimvminValue) {
                                    setState(() {
                                      psimvItrigValue = psimvItrigValue - 1;
                                    });
                                  } else if (psimvPeep == true &&
                                      psimvPeepValue != psimvminValue) {
                                    setState(() {
                                      psimvPeepValue = psimvPeepValue - 1;
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
                                    });
                                  } else if (psimvVtMax == true &&
                                      psimvVtMaxValue != psimvminValue) {
                                    setState(() {
                                      psimvVtMaxValue = psimvVtMaxValue - 1;
                                    });
                                  } else if (psimvFio2 == true &&
                                      psimvFio2Value != psimvminValue) {
                                    setState(() {
                                      psimvFio2Value = psimvFio2Value - 1;
                                    });
                                  } else if (psimvFlowRamp == true &&
                                      psimvFlowRampValue != psimvminValue) {
                                    setState(() {
                                      psimvFlowRampValue =
                                          psimvFlowRampValue - 1;
                                    });
                                  } else if (psimvPs == true &&
                                      psimvPsValue != psimvPeepValue) {
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
                              psimvItrig
                                  ? psimvItrigValue.toInt().toString()
                                  : psimvPeep
                                      ? psimvPeepValue.toInt().toString()
                                      : psimvRr
                                          ? psimvRrValue.toInt().toString()
                                          : psimvIe
                                              ? psimvIeValue.toInt().toString()
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
                                      psimvVtMinValue != psimvmaxValue) {
                                    setState(() {
                                      psimvVtMinValue = psimvVtMinValue + 1;
                                    });
                                  } else if (psimvVtMax == true &&
                                      psimvVtMaxValue != psimvmaxValue) {
                                    setState(() {
                                      psimvVtMaxValue = psimvVtMaxValue + 1;
                                    });
                                  } else if (psimvFio2 == true &&
                                      psimvFio2Value != psimvmaxValue) {
                                    setState(() {
                                      psimvFio2Value = psimvFio2Value + 1;
                                    });
                                  } else if (psimvFlowRamp == true &&
                                      psimvFlowRampValue != psimvmaxValue) {
                                    setState(() {
                                      psimvFlowRampValue =
                                          psimvFlowRampValue + 1;
                                    });
                                  } else if (psimvPs == true &&
                                      psimvPsValue != psimvPcValue) {
                                    setState(() {
                                      psimvPsValue = psimvPsValue + 1;
                                    });
                                  }
                                });
                              },
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
                            min: psimvminValue.toDouble(),
                            max: psimvmaxValue.toDouble(),
                            onChanged: (double value) {
                              if (psimvItrig == true) {
                                setState(() {
                                  psimvItrigValue = value.toInt();
                                });
                              } else if (psimvPeep == true) {
                                setState(() {
                                  psimvPeepValue = value.toInt();
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
                                setState(() {
                                  psimvVtMinValue = value.toInt();
                                });
                              } else if (psimvVtMax == true) {
                                setState(() {
                                  psimvVtMaxValue = value.toInt();
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
                                  if (value.toInt() <= psimvPcValue &&
                                      value.toInt() >= psimvPeepValue) {
                                    psimvPsValue = value.toInt();
                                  }
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
                            Text(psimvminValue.toString()),
                            Text(
                              psimvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(psimvmaxValue.toString())
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
                  pccmvparameterUnits = "";
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
                              "",
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
                  pccmvmaxValue = 4;
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
                              "4",
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
                              "1",
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
                                "1:" + pccmvIeValue.toString(),
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
                                value:
                                    pccmvIeValue != null ? pccmvIeValue / 4 : 0,
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
                  pccmvparameterUnits = "";
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
                              "cmH20",
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
                  pccmvmaxValue = 40;
                  pccmvminValue = 0;
                  pccmvparameterName = "PC";
                  pccmvparameterUnits = "";
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
                              "cmH20",
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
                              "60",
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
                              "0",
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
                                    ? pccmvPcValue / 60
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
                  pccmvparameterName = "FiO2";
                  pccmvparameterUnits = "";
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
                              "FiO2",
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
                              "",
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
            InkWell(
              onTap: () {
                setState(() {
                  pccmvmaxValue = 2000;
                  pccmvminValue = 50;
                  pccmvparameterName = "VTmin";
                  pccmvparameterUnits = "";
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
                              "",
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
                              "2000",
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
                              "50",
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
                                    ? pccmvVtminValue / 1250
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
                  pccmvmaxValue = 2000;
                  pccmvminValue = 50;
                  pccmvparameterName = "VTmax";
                  pccmvparameterUnits = "";
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
                              "",
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
                              "2000",
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
                              "50",
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
                                    ? pccmvVtmaxValue / 2000
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
          ],
        ),
        SizedBox(width: 15),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 28.0),
                                child: Column(
                                  children: [
                                    Text("Peep"),
                                    Text("$minpeep-$maxpeep"),
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
                                    Text("FiO2"),
                                    Text("$minfio2-$maxfio2"),
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
           patientId!="" ? Text("") : Container(
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
                      Text("IBW : "+patientWeight??0.toString()),
                      Text("Ideal Vt : "+(int.tryParse(patientWeight??0) * 6).toString() +
                          " - " +
                          (int.tryParse(patientWeight??0) * 8).toString())
                    ],
                  ),
                )),
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
                      Text(
                        pccmvparameterName,
                        style: TextStyle(fontSize: 36),
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
                                  if (pccmvRR == true &&
                                      pccmvRRValue != pccmvminValue) {
                                    setState(() {
                                      // pccmvTempValue = pccmvTempValue-1;
                                      pccmvRRValue = pccmvRRValue - 1;
                                    });
                                  } else if (pccmvIe == true &&
                                      pccmvIeValue != pccmvminValue) {
                                    setState(() {
                                      pccmvIeValue = pccmvIeValue - 1;
                                    });
                                  } else if (pccmvPeep == true &&
                                      pccmvPeepValue != pccmvminValue) {
                                    setState(() {
                                      pccmvPeepValue = pccmvPeepValue - 1;
                                      if (pccmvPeepValue >= pccmvPcValue) {
                                        pccmvPcValue = pccmvPcValue - 1;
                                      }
                                    });
                                  } else if (pccmvPc == true &&
                                      pccmvPcValue != pccmvPeepValue + 1) {
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
                                    });
                                  } else if (pccmvVtmax == true &&
                                      pccmvVtmaxValue != pccmvminValue) {
                                    setState(() {
                                      pccmvVtmaxValue = pccmvVtmaxValue - 1;
                                    });
                                  } else if (pccmvFlowRamp == true &&
                                      pccmvFlowRampValue != pccmvminValue) {
                                    setState(() {
                                      pccmvFlowRampValue =
                                          pccmvFlowRampValue - 1;
                                    });
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              width: 60,
                            ),
                            Text(
                              pccmvRR
                                  ? pccmvRRValue.toInt().toString()
                                  : pccmvIe
                                      ? "1:" + pccmvIeValue.toInt().toString()
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
                                  if (pccmvRR == true &&
                                      pccmvRRValue != pccmvmaxValue) {
                                    setState(() {
                                      pccmvRRValue = pccmvRRValue + 1;
                                    });
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
                                      pccmvVtminValue = pccmvVtminValue + 1;
                                    });
                                  } else if (pccmvVtmax == true &&
                                      pccmvVtmaxValue != pccmvmaxValue) {
                                    setState(() {
                                      pccmvVtmaxValue = pccmvVtmaxValue + 1;
                                    });
                                  } else if (pccmvFlowRamp == true &&
                                      pccmvFlowRampValue != pccmvmaxValue) {
                                    setState(() {
                                      pccmvFlowRampValue =
                                          pccmvFlowRampValue + 1;
                                    });
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      pccmvFio2
                          ? Container()
                          : Container(
                              width: 350,
                              child: Slider(
                                min: pccmvPc
                                    ? (pccmvPeepValue + 1).toDouble()
                                    : pccmvminValue.toDouble(),
                                max: pccmvmaxValue.toDouble(),
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
                                                        ? pccmvVtminValue
                                                            .toDouble()
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
                                    } else if (pccmvIe == true) {
                                      setState(() {
                                        pccmvIeValue = value.toInt();
                                      });
                                    } else if (pccmvPeep == true) {
                                      if (pccmvPcValue <= pccmvPeepValue) {
                                        setState(() {
                                          pccmvPcValue = value.toInt() + 1;
                                          pccmvPeepValue = value.toInt();
                                        });
                                      } else {
                                        pccmvPeepValue = value.toInt();
                                      }
                                    } else if (pccmvPc == true) {
                                      setState(() {
                                        pccmvPcValue = value.toInt();
                                      });
                                    } else if (pccmvFio2 == true) {
                                      setState(() {
                                        pccmvFio2Value = value.toInt();
                                      });
                                    } else if (pccmvVtmin == true) {
                                      setState(() {
                                        pccmvVtminValue = value.toInt();
                                      });
                                    } else if (pccmvVtmax == true) {
                                      setState(() {
                                        pccmvVtmaxValue = value.toInt();
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
                            Text(pccmvminValue.toString()),
                            Text(
                              pccmvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(pccmvmaxValue.toString())
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
                  vccmvparameterUnits = "";
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
                              "",
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
                  vccmvmaxValue = 4;
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
                              "4",
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
                              "1",
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
                                "1:" + vccmvIeValue.toString(),
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
                                value:
                                    vccmvIeValue != null ? vccmvIeValue / 4 : 0,
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
                  vccmvparameterUnits = "";
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
                              "cmH20",
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
                  vccmvmaxValue = 600;
                  vccmvminValue = 100;
                  vccmvparameterName = "VT";
                  vccmvparameterUnits = "";
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
                              "",
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
                              "600",
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
                              "100",
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
                                    ? vccmvVtValue / 600
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
                  vccmvparameterName = "FiO2";
                  vccmvparameterUnits = "";
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
                              "FiO2",
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
                              "",
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
            InkWell(
              onTap: () {
                setState(() {
                  vccmvmaxValue = 60;
                  vccmvminValue = 10;
                  vccmvparameterName = "PC Min";
                  vccmvparameterUnits = "";
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
                              "cmH20",
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
                              "60",
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
                                    ? vccmvPcMinValue / 60
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
                  vccmvmaxValue = 60;
                  vccmvminValue = 10;
                  vccmvparameterName = "PC Max";
                  vccmvparameterUnits = "";
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
                              "cmH20",
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
                              "60",
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
                                    ? vccmvPcMaxValue / 60
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
            //       vccmvmaxValue = 4;
            //       vccmvminValue = 0;
            //       vccmvparameterName = "Flow Ramp";
            //       vccmvparameterUnits = "";
            //       vccmvRR = false;
            //       vccmvIe = false;
            //       vccmvPeep = false;
            //       vccmvVt = false;
            //       vccmvPcMax = false;
            //       vccmvPcMin = false;
            //       vccmvFio2 = false;
            //       vccmvFlowRamp = true;
            //       vccmvTih = false;

            //       vccmvVt = false;
            //       vccmvFlowRamp = true;
            //       vccmvTih = false;
            //     });
            //   },
            //   child: Center(
            //     child: Container(
            //       width: 146,
            //       height: 130,
            //       child: Card(
            //         elevation: 40,
            //         color:
            //             vccmvFlowRamp ? Color(0xFFE0E0E0) : Color(0xFF213855),
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
            //                       color: vccmvFlowRamp
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
            //                       color: vccmvFlowRamp
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
            //                       color: vccmvFlowRamp
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
            //                       color: vccmvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0)),
            //                 ),
            //               ),
            //               Align(
            //                 alignment: Alignment.center,
            //                 child: Padding(
            //                   padding: const EdgeInsets.only(top: 1.0),
            //                   child: Text(
            //                     vccmvFlowRampValue.toString() == "0"
            //                         ? "AF"
            //                         : vccmvFlowRampValue.toString() == "1"
            //                             ? "AS"
            //                             : vccmvFlowRampValue.toString() == "2"
            //                                 ? "DF"
            //                                 : vccmvFlowRampValue.toString() ==
            //                                         "3"
            //                                     ? "DS"
            //                                     : vccmvFlowRampValue
            //                                                 .toString() ==
            //                                             "4"
            //                                         ? "S"
            //                                         : "S",
            //                     style: TextStyle(
            //                         fontSize: 35,
            //                         color: vccmvFlowRamp
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
            //                       vccmvFlowRamp
            //                           ? Color(0xFF213855)
            //                           : Color(0xFFE0E0E0),
            //                     ),
            //                     value: vccmvFlowRampValue != null
            //                         ? vccmvFlowRampValue / 4
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 28.0),
                                child: Column(
                                  children: [
                                    Text("Peep"),
                                    Text("$minpeep-$maxpeep"),
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
                                    Text("FiO2"),
                                    Text("$minfio2-$maxfio2"),
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
           patientId!="" ? Text("") : Container(
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
                      Text("IBW : "+patientWeight.toString()),
                      Text("Ideal Vt : "+(int.tryParse(patientWeight) * 6).toString() +
                          " - " +
                          (int.tryParse(patientWeight) * 8).toString())
                    ],
                  ),
                )),
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
                      Text(
                        vccmvparameterName,
                        style: TextStyle(fontSize: 36),
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
                                      if (vccmvPcMinValue <= vccmvPeepValue) {
                                        vccmvPcMinValue = vccmvPeepValue + 1;
                                        if (vccmvPcMaxValue <=
                                            vccmvPcMinValue) {
                                          vccmvPcMaxValue = vccmvPcMinValue + 1;
                                        }
                                      }
                                    });
                                  } else if (vccmvPcMax == true &&
                                      vccmvPcMaxValue != vccmvPcMinValue) {
                                    setState(() {
                                      vccmvPcMaxValue = vccmvPcMaxValue - 1;
                                    });
                                  } else if (vccmvFio2 == true &&
                                      vccmvFio2Value != vccmvminValue) {
                                    setState(() {
                                      vccmvFio2Value = vccmvFio2Value - 1;
                                    });
                                  } else if (vccmvPcMin == true &&
                                      vccmvPcMinValue != vccmvPeepValue) {
                                    setState(() {
                                      vccmvPcMinValue = vccmvPcMinValue - 1;
                                      if (vccmvPcMinValue >= vccmvPcMaxValue) {
                                        vccmvPcMaxValue = vccmvPcMaxValue - 1;
                                      }
                                    });
                                  } else if (vccmvVt == true &&
                                      vccmvVtValue != vccmvminValue) {
                                    setState(() {
                                      vccmvVtValue = vccmvVtValue - 1;
                                    });
                                  } else if (vccmvFlowRamp == true &&
                                      vccmvFlowRampValue != vccmvminValue) {
                                    setState(() {
                                      vccmvFlowRampValue =
                                          vccmvFlowRampValue - 1;
                                    });
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              width: 60,
                            ),
                            Text(
                              vccmvRR
                                  ? vccmvRRValue.toInt().toString()
                                  : vccmvIe
                                      ? "1:" + vccmvIeValue.toInt().toString()
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
                                      if (vccmvPcMinValue <= vccmvPeepValue) {
                                        vccmvPcMinValue = vccmvPeepValue + 1;
                                        if (vccmvPcMaxValue <=
                                            vccmvPcMinValue) {
                                          vccmvPcMaxValue = vccmvPcMinValue + 1;
                                        }
                                      }
                                    });
                                  } else if (vccmvPcMax == true &&
                                      vccmvPcMaxValue != vccmvPcMinValue) {
                                    setState(() {
                                      vccmvPcMaxValue = vccmvPcMaxValue + 1;
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
                                      vccmvPcMinValue != vccmvPeepValue) {
                                    setState(() {
                                      vccmvPcMinValue = vccmvPcMinValue + 1;
                                      if (vccmvPcMaxValue <= vccmvPcMinValue) {
                                        vccmvPcMaxValue = vccmvPcMinValue + 1;
                                      }
                                    });
                                  } else if (vccmvFlowRamp == true &&
                                      vccmvFlowRampValue != vccmvmaxValue) {
                                    setState(() {
                                      vccmvFlowRampValue =
                                          vccmvFlowRampValue + 1;
                                    });
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      vccmvFio2
                          ? Container()
                          : Container(
                              width: 350,
                              child: Slider(
                                min: vccmvPcMax
                                    ? vccmvPcMinValue.toDouble()
                                    : vccmvPcMin
                                        ? vccmvPeepValue.toDouble()
                                        : vccmvminValue.toDouble(),
                                max: vccmvmaxValue.toDouble(),
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
                                                        ? vccmvVtValue
                                                            .toDouble()
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
                                        if (vccmvPcMinValue <= vccmvPeepValue) {
                                          vccmvPcMinValue = value.toInt() + 1;
                                          if (vccmvPcMaxValue <=
                                              vccmvPcMinValue) {
                                            vccmvPcMaxValue = value.toInt() + 1;
                                          }
                                        }
                                      });
                                    } else if (vccmvPcMax == true) {
                                      setState(() {
                                        vccmvPcMaxValue = value.toInt();
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
                                      setState(() {
                                        vccmvPcMinValue = value.toInt();
                                        if (vccmvPcMaxValue <=
                                            vccmvPcMinValue) {
                                          if ((vccmvPcMaxValue >= 60) ==
                                              false) {
                                            vccmvPcMaxValue = value.toInt() + 1;
                                          }
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
                            Text(vccmvminValue.toString()),
                            Text(
                              vccmvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(vccmvmaxValue.toString())
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
                  vsimvmaxValue = 100;
                  vsimvminValue = 20;
                  vsimvparameterName = "I Trig";
                  vsimvparameterUnits = "cmH20";
                  vsimvItrig = true;
                  vsimvRr = false;
                  vsimvIe = false;
                  vsimvPeep = false;
                  vsimvVt = false;
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
                              "",
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
                              "100",
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
                              "20",
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
                                vsimvItrigValue.toString() + "%",
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
                                    ? vsimvItrigValue / 100
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
                  vsimvminValue = 1;
                  vsimvparameterName = "RR";
                  vsimvparameterUnits = "";
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
                              "",
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
                              "30",
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
                                    ? vsimvRrValue / 30
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
                  vsimvmaxValue = 4;
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
                              "4",
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
                              "1",
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
                                "1:" + vsimvIeValue.toString(),
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
                                value:
                                    vsimvIeValue != null ? vsimvIeValue / 4 : 0,
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
                  vsimvmaxValue = 30;
                  vsimvminValue = 0;
                  vsimvparameterName = "PEEP";
                  vsimvparameterUnits = "";
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
                              "cmH20",
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
            InkWell(
              onTap: () {
                setState(() {
                  vsimvmaxValue = 2000;
                  vsimvminValue = 50;
                  vsimvparameterName = "Vt";
                  vsimvparameterUnits = "";
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
                              "",
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
                              "2000",
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
                              "50",
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
                  vsimvmaxValue = 60;
                  vsimvminValue = 10;
                  vsimvparameterName = "PC Min";
                  vsimvparameterUnits = "";
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
                              "",
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
                              "60",
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
                                    ? vsimvPcMinValue / 60
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
                  vsimvmaxValue = 60;
                  vsimvminValue = 10;
                  vsimvparameterName = "PC Max";
                  vsimvparameterUnits = "";
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
                              "",
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
                              "60",
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
                                    ? vsimvPcMaxValue / 60
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
                  vsimvminValue = 20;
                  vsimvparameterName = "FiO2";
                  vsimvparameterUnits = "";
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
                              "FiO2",
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
                              "",
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
                              "20",
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
                  vsimvmaxValue = 60;
                  vsimvminValue = 0;
                  vsimvparameterName = "PS";
                  vsimvparameterUnits = "";
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
                              "",
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
                              "60",
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
                              "0",
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
                                    ? vsimvPsValue / 100
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
          ],
        ),
        SizedBox(
          width: 10,
        ),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 28.0),
                                child: Column(
                                  children: [
                                    Text("Peep"),
                                    Text("$minpeep-$maxpeep"),
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
                                    Text("FiO2"),
                                    Text("$minfio2-$maxfio2"),
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
            Container(
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
                      Text("IBW : "+patientWeight.toString()),
                      Text("Ideal Vt : "+(int.tryParse(patientWeight) * 6).toString() +
                          " - " +
                          (int.tryParse(patientWeight) * 8).toString())
                    ],
                  ),
                )),
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
                      Text(
                        vsimvparameterName,
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.normal),
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
                                  if (vsimvItrig == true &&
                                      vsimvItrigValue != vsimvminValue) {
                                    setState(() {
                                      vsimvItrigValue = vsimvItrigValue - 1;
                                    });
                                  } else if (vsimvPeep == true &&
                                      vsimvPeepValue != vsimvminValue) {
                                    setState(() {
                                      vsimvPeepValue = vsimvPeepValue - 1;
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
                                    });
                                  } else if (vsimvPcMax == true &&
                                      vsimvPcMaxValue != vsimvminValue) {
                                    setState(() {
                                      vsimvPcMaxValue = vsimvPcMaxValue - 1;
                                    });
                                  } else if (vsimvFio2 == true &&
                                      vsimvFio2Value != vsimvminValue) {
                                    setState(() {
                                      vsimvFio2Value = vsimvFio2Value - 1;
                                    });
                                  } else if (vsimvFlowRamp == true &&
                                      vsimvFlowRampValue != vsimvminValue) {
                                    setState(() {
                                      vsimvFlowRampValue =
                                          vsimvFlowRampValue - 1;
                                    });
                                  } else if (vsimvPs == true &&
                                      vsimvPsValue != vsimvPeepValue) {
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
                              vsimvItrig
                                  ? vsimvItrigValue.toInt().toString()
                                  : vsimvPeep
                                      ? vsimvPeepValue.toInt().toString()
                                      : vsimvRr
                                          ? vsimvRrValue.toInt().toString()
                                          : vsimvIe
                                              ? vsimvIeValue.toInt().toString()
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
                                      vsimvPcMinValue != vsimvmaxValue) {
                                    setState(() {
                                      vsimvPcMinValue = vsimvPcMinValue + 1;
                                    });
                                  } else if (vsimvPcMax == true &&
                                      vsimvPcMaxValue != vsimvmaxValue) {
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
                                      vsimvFlowRampValue =
                                          vsimvFlowRampValue + 1;
                                    });
                                  } else if (vsimvPs == true &&
                                      vsimvPsValue != vsimvPcMaxValue) {
                                    setState(() {
                                      vsimvPsValue = vsimvPsValue + 1;
                                    });
                                  }
                                });
                              },
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
                            min: vsimvminValue.toDouble(),
                            max: vsimvmaxValue.toDouble(),
                            onChanged: (double value) {
                              if (vsimvItrig == true) {
                                setState(() {
                                  vsimvItrigValue = value.toInt();
                                });
                              } else if (vsimvPeep == true) {
                                setState(() {
                                  vsimvPeepValue = value.toInt();
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
                                setState(() {
                                  vsimvPcMinValue = value.toInt();
                                });
                              } else if (vsimvPcMax == true) {
                                setState(() {
                                  vsimvPcMaxValue = value.toInt();
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
                                  if (value.toInt() <= vsimvPcMaxValue &&
                                      value.toInt() >= vsimvPeepValue) {
                                    vsimvPsValue = value.toInt();
                                  }
                                  //
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
                            Text(vsimvminValue.toString()),
                            Text(
                              vsimvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(vsimvmaxValue.toString())
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
                  vacvmaxValue = 100;
                  vacvminValue = 20;
                  vacvparameterName = "I Trig";
                  vacvparameterUnits = "cmH20";
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
                              "",
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
                              "100",
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
                              "20",
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
                                vacvItrigValue.toString() + "%",
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
                                    ? vacvItrigValue / 100
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
                  vacvmaxValue = 30;
                  vacvminValue = 1;
                  vacvparameterName = "RR";
                  vacvparameterUnits = "";
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
                              "",
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
                              "30",
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
                                    vacvRrValue != null ? vacvRrValue / 30 : 0,
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
                  vacvmaxValue = 4;
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
                              "4",
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
                              "1",
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
                                "1:" + vacvIeValue.toString(),
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
          ],
        ),
        Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 30;
                  vacvminValue = 0;
                  vacvparameterName = "PEEP";
                  vacvparameterUnits = "";
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
                              "cmH20",
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
            InkWell(
              onTap: () {
                setState(() {
                  vacvmaxValue = 600;
                  vacvminValue = 100;
                  vacvparameterName = "Vt";
                  vacvparameterUnits = "";
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
                              "",
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
                              "600",
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
                              "100",
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
                                value:
                                    vacvVtValue != null ? vacvVtValue / 600 : 0,
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
                  vacvmaxValue = 60;
                  vacvminValue = 10;
                  vacvparameterName = "PC Min";
                  vacvparameterUnits = "";
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
                              "",
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
                              "60",
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
                                    ? vacvPcMinValue / 60
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
                  vacvmaxValue = 60;
                  vacvminValue = 10;
                  vacvparameterName = "PC Max";
                  vacvparameterUnits = "";
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
                              "",
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
                              "60",
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
                                    ? vacvPcMaxValue / 60
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
                  vacvminValue = 20;
                  vacvparameterName = "FiO2";
                  vacvparameterUnits = "";
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
                              "FiO2",
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
                              "",
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
                              "20",
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
            Container(
              width: 146,
            )
          ],
        ),
        SizedBox(
          width: 10,
        ),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 28.0),
                                child: Column(
                                  children: [
                                    Text("Peep"),
                                    Text("$minpeep-$maxpeep"),
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
                                    Text("FiO2"),
                                    Text("$minfio2-$maxfio2"),
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
            Container(
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
                      Text("IBW : "+patientWeight.toString()),
                      Text("Ideal Vt : "+(int.tryParse(patientWeight) * 6).toString() +
                          " - " +
                          (int.tryParse(patientWeight) * 8).toString())
                    ],
                  ),
                )),
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
                      Text(
                        vacvparameterName,
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.normal),
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
                                  if (vacvItrig == true &&
                                      vacvItrigValue != vacvminValue) {
                                    setState(() {
                                      vacvItrigValue = vacvItrigValue - 1;
                                    });
                                  } else if (vacvPeep == true &&
                                      vacvPeepValue != vacvminValue) {
                                    setState(() {
                                      vacvPeepValue = vacvPeepValue - 1;
                                      if (vacvPcMinValue <= vacvPeepValue) {
                                        vacvPcMinValue = vacvPeepValue + 1;
                                        if (vacvPcMaxValue <= vacvPcMinValue) {
                                          vacvPcMaxValue = vacvPcMinValue + 1;
                                        }
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
                                      vacvPcMinValue != vacvPeepValue) {
                                    setState(() {
                                      vacvPcMinValue = vacvPcMinValue - 1;
                                      if (vacvPcMinValue >= vacvPcMaxValue) {
                                        vacvPcMaxValue = vacvPcMaxValue - 1;
                                      }
                                    });
                                  } else if (vacvPcMax == true &&
                                      vacvPcMaxValue != vacvPcMinValue) {
                                    setState(() {
                                      vacvPcMaxValue = vacvPcMaxValue - 1;
                                    });
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
                              vacvItrig
                                  ? vacvItrigValue.toInt().toString()
                                  : vacvPeep
                                      ? vacvPeepValue.toInt().toString()
                                      : vacvRr
                                          ? vacvRrValue.toInt().toString()
                                          : vacvIe
                                              ? vacvIeValue.toInt().toString()
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
                                    });
                                  } else if (vacvPeep == true &&
                                      vacvPeepValue != vacvmaxValue) {
                                    setState(() {
                                      vacvPeepValue = vacvPeepValue + 1;
                                      if (vacvPcMinValue <= vacvPeepValue) {
                                        vacvPcMinValue = vacvPeepValue + 1;
                                        if (vacvPcMaxValue <= vacvPcMinValue) {
                                          vacvPcMaxValue = vacvPcMinValue + 1;
                                        }
                                      }
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
                                      vacvPcMinValue != vacvPeepValue) {
                                    setState(() {
                                      vacvPcMinValue = vacvPcMinValue + 1;
                                      if (vacvPcMaxValue <= vacvPcMinValue) {
                                        vacvPcMaxValue = vacvPcMinValue + 1;
                                      }
                                    });
                                  } else if (vacvPcMax == true &&
                                      vacvPcMaxValue != vacvPcMinValue) {
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
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      vacvFio2
                          ? Container()
                          : Container(
                              width: 350,
                              child: Slider(
                                min: vacvPcMax
                                    ? vacvPcMinValue.toDouble()
                                    : vacvPcMin
                                        ? vacvPeepValue.toDouble()
                                        : vacvminValue.toDouble(),
                                max: vacvmaxValue.toDouble(),
                                onChanged: (double value) {
                                  if (vacvItrig == true) {
                                    setState(() {
                                      vacvItrigValue = value.toInt();
                                    });
                                  } else if (vacvPeep == true) {
                                    setState(() {
                                      vacvPeepValue = value.toInt();
                                      if (vacvPcMinValue <= vacvPeepValue) {
                                        vacvPcMinValue = value.toInt() + 1;
                                        if (vacvPcMaxValue <= vacvPcMinValue) {
                                          vacvPcMaxValue = value.toInt() + 1;
                                        }
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
                                    setState(() {
                                      vacvPcMinValue = value.toInt();
                                      if (vacvPcMaxValue <= vacvPcMinValue) {
                                        if ((vacvPcMaxValue >= 60) == false) {
                                          vacvPcMaxValue = value.toInt() + 1;
                                        }
                                      }
                                    });
                                  } else if (vacvPcMax == true) {
                                    setState(() {
                                      vacvPcMaxValue = value.toInt();
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
                                                        ? vacvPcMinValue
                                                            .toDouble()
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
                            Text(vacvminValue.toString()),
                            Text(
                              vacvparameterUnits,
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(vacvmaxValue.toString())
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
      padding: EdgeInsets.only(left: 170, right: 0, top: 20),
      child: Column(
        children: [
          Container(
            width: 520,
            height: 120,
            child: Stack(
              children: [
                Container(
                    margin: EdgeInsets.only(left: 20, right: 10, top: 10),
                    child: scopeOne),
                Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Text(
                      "60" + " cmH2O",
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
                    top: 109,
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
                    margin: EdgeInsets.only(left: 502, top: 93),
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
            height: 160,
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
                      "90 lpm",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                    margin: EdgeInsets.only(left: 10, top: 135),
                    child: Text(
                      "-90 lpm",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                    margin: EdgeInsets.only(left: 15, top: 66),
                    child: Text(
                      "0",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                  margin: EdgeInsets.only(left: 28, top: 26),
                  width: 1,
                  color: Colors.grey,
                  height: 108,
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: 28,
                    top: 79,
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
                    margin: EdgeInsets.only(left: 502, top: 66),
                    child: Text(
                      "s",
                      style: TextStyle(color: Colors.grey),
                    ))
              ],
            ),
          ),
          Container(
            width: 520,
            height: 120,
            child: Stack(
              children: [
                Container(
                    margin: EdgeInsets.only(left: 20, right: 10, top: 10),
                    child: scopeOne2),
                Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Text(
                      "700 ml",
                      style: TextStyle(color: Colors.grey),
                    )),
                Container(
                    margin: EdgeInsets.only(left: 15, top: 89),
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
                    top: 109,
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
              color: alarmActive == "1"
                  ? Colors.red
                  :
                  // priorityNo=="0" ? Colors.red: priorityNo=="1" ? Colors.red : priorityNo=="2" ? Colors.orange : priorityNo=="3" ? Colors.yellow :
                  Color(0xFF171e27),
              child: Center(
                  child: Align(
                alignment: Alignment.centerLeft,
                child: Center(
                  child: Text(
                    alarmActive == "1" ? alarmMessage : "",
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
    } else if (data == "fio2") {
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

  modeSetCheck() async {
    setState(() {
      modeWriteList = [];
    });

    if (pccmvEnabled == true) {
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(6);

        modeWriteList.add((pccmvRRValue & 0xFF00) >> 8);
        modeWriteList.add((pccmvRRValue & 0x00FF));

        modeWriteList.add(1);
        modeWriteList.add((pccmvIeValue & 0x00FF));

        modeWriteList.add((pccmvPeepValue & 0xFF00) >> 8);
        modeWriteList.add((pccmvPeepValue & 0x00FF));

        modeWriteList.add((pccmvPcValue & 0xFF00) >> 8);
        modeWriteList.add((pccmvPcValue & 0x00FF));

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
      preferences.setInt("rr", pccmvRRValue);
      preferences.setInt("ie", pccmvIeValue);
      preferences.setInt("i", 1);
      preferences.setInt("e", pccmvIeValue);
      preferences.setInt("peep", pccmvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", pccmvFio2Value);
      // preferences.setInt("tih", 50);
      // preferences.setInt("paw", 0);
      // preferences.setInt("rrtotal", 0);
      preferences.setInt("ps", pccmvPcValue);
      // preferences.setInt("te", 20);
      // preferences.setInt("vte", 0 );

      // Fluttertoast.showToast(msg: modeWriteList.toString());

      //to calculate crc
      print(modeWriteList.toString());
      // Fluttertoast.showToast(msg: modeWriteList.toString());
      
       if(_status == "Connected"){
      await _port.write(Uint8List.fromList(modeWriteList));
          modesEnabled =false;
       }else{
         Fluttertoast.showToast(msg: "No Communication");
       }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      
      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (vccmvEnabled == true) {
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(7);
        modeWriteList.add((vccmvRRValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvRRValue & 0x00FF));

        modeWriteList.add(1);
        modeWriteList.add((vccmvIeValue & 0x00FF));

        modeWriteList.add((vccmvPeepValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvPeepValue & 0x00FF));

        modeWriteList.add((vccmvVtValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvVtValue & 0x00FF));

        modeWriteList.add((vccmvFio2Value & 0xFF00) >> 8);
        modeWriteList.add((vccmvFio2Value & 0x00FF));

        modeWriteList.add((vccmvPcMaxValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvPcMaxValue & 0x00FF));

        modeWriteList.add((vccmvPcMinValue & 0xFF00) >> 8);
        modeWriteList.add((vccmvPcMinValue & 0x00FF));

        // modeWriteList.add((vccmvFlowRampValue & 0xFF00) >> 8);
        // modeWriteList.add((vccmvFlowRampValue & 0x00FF));
        modeWriteList.add(0x7F);
      });

      preferences = await SharedPreferences.getInstance();
      preferences.setString("mode", "VC-CMV");
      preferences.setInt("rr", vccmvRRValue);

      preferences.setInt("e", vccmvIeValue);
      preferences.setInt("peep", vccmvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", vccmvFio2Value);
      // preferences.setInt("tih", 50);
      // preferences.setInt("paw", 0);
      // preferences.setInt("rrtotal", 0);
      preferences.setInt("vt", vccmvVtValue);
      // preferences.setInt("te", 20);
      // preferences.setInt("vte", 0 );

      // Fluttertoast.showToast(msg: modeWriteList.toString());

      //to calculate crc
      print(modeWriteList.toString());
      // Fluttertoast.showToast(msg: modeWriteList.toString());
      if(_status == "Connected"){
      await _port.write(Uint8List.fromList(modeWriteList));
      modesEnabled =false;
       }else{
         Fluttertoast.showToast(msg: "No Communication");
       }
      setState(() {
        playOnEnabled = false;
      });
      getData();
      newTreatEnabled = false;

      monitorEnabled = false;
    } else if (pacvEnabled == true) {
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(2);

        modeWriteList.add((pacvItrigValue & 0xFF00) >> 8);
        modeWriteList.add((pacvItrigValue & 0x00FF));

        modeWriteList.add((pacvRrValue & 0xFF00) >> 8);
        modeWriteList.add((pacvRrValue & 0x00FF));

        modeWriteList.add(1);
        modeWriteList.add((pacvIeValue));

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
      preferences.setString("mode", "PACV");
      preferences.setInt("rr", pacvRrValue);
      preferences.setInt("ie", pacvIeValue);
      preferences.setInt("i", 1);
      preferences.setInt("e", pacvIeValue);
      preferences.setInt("peep", pacvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", pacvFio2Value);
      // preferences.setInt("tih", 50);
      // preferences.setInt("paw", 0);
      // preferences.setInt("rrtotal", 0);
      preferences.setInt("ps", pacvPcValue);
      // preferences.setInt("te", 20);
      // preferences.setInt("vte", 0 );

      // Fluttertoast.showToast(msg: modeWriteList.toString());

      //to calculate crc
      // print(modeWriteList.toString());
      // Fluttertoast.showToast(msg: modeWriteList.toString());

      if(_status == "Connected"){
      await _port.write(Uint8List.fromList(modeWriteList));
      modesEnabled =false;
       }else{
         Fluttertoast.showToast(msg: "No Communication");
       }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (vacvEnabled == true) {
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(1);
        modeWriteList.add((vacvItrigValue & 0xFF00) >> 8);
        modeWriteList.add((vacvItrigValue & 0x00FF));

        modeWriteList.add((vacvRrValue & 0xFF00) >> 8);
        modeWriteList.add((vacvRrValue & 0x00FF));

        modeWriteList.add(1);
        modeWriteList.add((vacvIeValue & 0x00FF));

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
      preferences.setInt("rr", vacvRrValue);
      preferences.setInt("ie", vacvIeValue);
      preferences.setInt("i", 1);
      preferences.setInt("e", vacvIeValue);
      preferences.setInt("peep", vacvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", vacvFio2Value);
      // preferences.setInt("tih", 50);
      // preferences.setInt("paw", 0);
      // preferences.setInt("rrtotal", 0);
      preferences.setInt("vt", vacvVtValue);
      // preferences.setInt("te", 20);
      // preferences.setInt("vte", 0 );

      // Fluttertoast.showToast(msg: modeWriteList.toString());

      //to calculate crc
      // print(modeWriteList.toString());
      // Fluttertoast.showToast(msg: modeWriteList.toString());

      if(_status == "Connected"){
      await _port.write(Uint8List.fromList(modeWriteList));
      modesEnabled =false;
       }else{
         Fluttertoast.showToast(msg: "No Communication");
       }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (psimvEnabled == true) {
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(4);

        modeWriteList.add((psimvItrigValue & 0xFF00) >> 8);
        modeWriteList.add((psimvItrigValue & 0x00FF));

        modeWriteList.add((psimvRrValue & 0xFF00) >> 8);
        modeWriteList.add((psimvRrValue & 0x00FF));

        modeWriteList.add(1);
        modeWriteList.add(psimvIeValue);

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
      preferences.setInt("rr", psimvRrValue);
      preferences.setInt("ie", psimvIeValue);
      preferences.setInt("i", 1);
      preferences.setInt("e", psimvIeValue);
      preferences.setInt("peep", psimvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", psimvFio2Value);
      // preferences.setInt("tih", 50);
      // preferences.setInt("paw", 0);
      // preferences.setInt("rrtotal", 0);
      preferences.setInt("ps", psimvPcValue);
      // preferences.setInt("te", 20);
      // preferences.setInt("vte", 0 );

      // Fluttertoast.showToast(msg: modeWriteList.toString());

      //to calculate crc
      // print(modeWriteList.toString());
      // Fluttertoast.showToast(msg: modeWriteList.toString());

      if(_status == "Connected"){
      await _port.write(Uint8List.fromList(modeWriteList));
      modesEnabled =false;
       }else{
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
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(5);

        modeWriteList.add((vsimvItrigValue & 0xFF00) >> 8); //5
        modeWriteList.add((vsimvItrigValue & 0x00FF)); //6

        modeWriteList.add((vsimvRrValue & 0xFF00) >> 8); //7
        modeWriteList.add((vsimvRrValue & 0x00FF)); //8

        modeWriteList.add(1); //9
        modeWriteList.add(vsimvIeValue); //10

        modeWriteList.add((vsimvPeepValue & 0xFF00) >> 8); //11
        modeWriteList.add((vsimvPeepValue & 0x00FF)); //12

        modeWriteList.add((vsimvPcMinValue & 0xFF00) >> 8);
        modeWriteList.add((vsimvPcMinValue & 0x00FF));

        modeWriteList.add((vsimvPcMaxValue & 0xFF00) >> 8);
        modeWriteList.add((vsimvPcMaxValue & 0x00FF));

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
      preferences.setInt("rr", vsimvRrValue);
      preferences.setInt("ie", vsimvIeValue);
      preferences.setInt("i", 1);
      preferences.setInt("e", vsimvIeValue);
      preferences.setInt("peep", vsimvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", vsimvFio2Value);
      // preferences.setInt("tih", 50);
      // preferences.setInt("paw", 0);
      preferences.setInt("vt", vsimvVtValue);
      preferences.setInt("ps", vsimvPcMaxValue);
      // preferences.setInt("te", 20);
      // preferences.setInt("vte", 0 );

      // Fluttertoast.showToast(msg: modeWriteList.toString());

      //to calculate crc
      // print(modeWriteList.toString());
      // Fluttertoast.showToast(msg: modeWriteList.toString());

      if(_status == "Connected"){
      await _port.write(Uint8List.fromList(modeWriteList));
      modesEnabled =false;
       }else{
         Fluttertoast.showToast(msg: "No Communication");
       }
      setState(() {
        playOnEnabled = false;
      });

      getData();
      newTreatEnabled = false;
      monitorEnabled = false;
    } else if (psvEnabled == true) {
      setState(() {
        modeWriteList.add(0x7E);
        modeWriteList.add(0);
        modeWriteList.add(20);
        modeWriteList.add(0);
        modeWriteList.add(3);

        modeWriteList.add((psvItrigValue & 0xFF00) >> 8); //5
        modeWriteList.add((psvItrigValue & 0x00FF)); //6

        modeWriteList.add((psvPeepValue & 0xFF00) >> 8); //7
        modeWriteList.add((psvPeepValue & 0x00FF)); //8

        modeWriteList.add((psvPsValue & 0xFF00) >> 8); //11
        modeWriteList.add((psvPsValue & 0x00FF)); //12

        modeWriteList.add((psvFio2Value & 0xFF00) >> 8); //19
        modeWriteList.add((psvFio2Value & 0x00FF));

        var calAtime = psvAtimeValue * 1000;

        modeWriteList.add((calAtime & 0xFF00) >> 8); //17
        modeWriteList.add((calAtime & 0x00FF));

        modeWriteList.add(1); //17
        modeWriteList.add((psvIeValue & 0x00FF));

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
      preferences.setString("mode", "VSIMV");
      preferences.setInt("rr", vsimvRrValue);
      preferences.setInt("ie", vsimvIeValue);
      preferences.setInt("i", 1);
      preferences.setInt("e", vsimvIeValue);
      preferences.setInt("peep", vsimvPeepValue);
      // preferences.setInt("ps", 40);
      preferences.setInt("fio2", vsimvFio2Value);
      // preferences.setInt("tih", 50);
      // preferences.setInt("paw", 0);
      // preferences.setInt("rrtotal", 0);
      preferences.setInt("ps", vsimvPcMaxValue);
      // preferences.setInt("te", 20);
      // preferences.setInt("vte", 0 );

      // Fluttertoast.showToast(msg: modeWriteList.toString());

      //to calculate crc
      // print(modeWriteList.toString());
      // Fluttertoast.showToast(msg: modeWriteList.toString());

      if(_status == "Connected"){
      await _port.write(Uint8List.fromList(modeWriteList));
      modesEnabled =false;
       }else{
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
    print(writePlay.toString());
    // Fluttertoast.showToast(msg: writePlay.toString());

    await _port.write(Uint8List.fromList(writePlay));
  }

  void setData() {
    if (pacvEnabled == true) {
      setState(() {
        pacvItrigValue = 60;
        pacvRrValue = 12;
        pacvIeValue = 3;
        pacvPeepValue = 10;
        pacvPcValue = 30;
        pacvVtMinValue = 100;
        pacvVtMaxValue = 400;
        pacvFio2Value = 22;
        pacvFlowRampValue = 3;
        pacvmaxValue = 100;
        pacvminValue = 20;
        pacvdefaultValue = 60;
        pacvparameterName = "I Trig";
        pacvparameterUnits = "cmH20";
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
        pccmvRRValue = 12;
        pccmvIeValue = 3;
        pccmvPeepValue = 10;
        pccmvPcValue = 30;
        pccmvFio2Value = 22;
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
        vccmvRRValue = 12;
        vccmvIeValue = 3;
        vccmvPeepValue = 10;
        vccmvPcMinValue = 20;
        vccmvPcMaxValue = 60;
        vccmvFio2Value = 22;
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
        vacvItrigValue = 60;
        vacvRrValue = 12;
        vacvIeValue = 3;
        vacvPeepValue = 10;
        vacvVtValue = 200;
        vacvPcMinValue = 20;
        vacvPcMaxValue = 60;
        vacvFio2Value = 22;
        vacvFlowRampValue = 4;
        vacvmaxValue = 100;
        vacvminValue = 20;
        vacvdefaultValue = 60;
        vacvparameterName = "I Trig";
        vacvparameterUnits = "cmH20";
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
        psvItrigValue = 60;
        psvPeepValue = 10;
        psvIeValue = 3;
        psvPsValue = 30;
        psvTiValue = 5;
        psvVtMinValue = 100;
        psvVtMaxValue = 400;
        psvFio2Value = 22;
        psvAtimeValue = 10;
        psvEtrigValue = 10;
        psvBackupRrValue = 12;
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
        psvmaxValue = 100;
        psvminValue = 20;
        psvdefaultValue = 60;
        psvparameterName = "I Trig";
        psvparameterUnits = "cmH20";
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
                  alarmmaxValue = 100;
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
                              "",
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
                              "100",
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
                  alarmmaxValue = 900;
                  alarmminValue = 100;
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
                              "",
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
                              "900",
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
                              "100",
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
            InkWell(
              onTap: () {
                setState(() {
                  alarmmaxValue = 60;
                  alarmminValue = 10;
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
                              "cmH20",
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
                              "30",
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
            InkWell(
              onTap: () {
                setState(() {
                  alarmmaxValue = 100;
                  alarmminValue = 21;
                  alarmparameterName = "FiO2";
                  alarmFio2changed = true;
                  alarmRR = false;
                  alarmVte = false;
                  alarmPpeak = false;
                  alarmpeep = false;
                  alarmFio2 = true;
                  alarmConfirmed = false;
                });
              },
              child: Center(
                child: Container(
                  color:
                      alarmFio2changed ? Color(0xFFB0BEC5) : Color(0xFF213855),
                  width: 146,
                  height: 130,
                  child: Card(
                    elevation: 40,
                    color: alarmFio2 ? Color(0xFFE0E0E0) : Color(0xFF213855),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                          child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "FiO2",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: alarmFio2
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
                                  color: alarmFio2
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
                                  color: alarmFio2
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
                                  color: alarmFio2
                                      ? Color(0xFF213855)
                                      : Color(0xFFE0E0E0)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(
                                "$minfio2 - $maxfio2",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: alarmFio2
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
                  alarmmaxValue = 60;
                  alarmminValue = 0;
                  alarmparameterName = "Peep";
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
                              "Peep",
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
                              "",
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
                              "60",
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
                                  } else if (alarmVte == true &&
                                      minvte != 100) {
                                    setState(() {
                                      minvte = minvte - 1;
                                    });
                                  } else if (alarmPpeak == true &&
                                      minppeak != 10) {
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
                                  if (alarmRR == true && maxRrtotal != 100) {
                                    setState(() {
                                      maxRrtotal = maxRrtotal + 1;
                                    });
                                  } else if (alarmVte == true &&
                                      maxvte != 900) {
                                    setState(() {
                                      maxvte = maxvte + 1;
                                    });
                                  } else if (alarmPpeak == true &&
                                      maxppeak != 60) {
                                    setState(() {
                                      maxppeak = maxppeak + 1;
                                    });
                                  } else if (alarmFio2 == true &&
                                      maxfio2 != 100) {
                                    setState(() {
                                      maxfio2 = maxfio2 + 1;
                                    });
                                  } else if (alarmpeep == true &&
                                      maxpeep != 60) {
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
                                  ? 100
                                  : alarmPpeak
                                      ? 10
                                      : alarmFio2
                                          ? 21
                                          : alarmpeep
                                              ? 0
                                              : 0.0, // Min range value
                          max: alarmRR
                              ? 100
                              : alarmVte
                                  ? 900
                                  : alarmPpeak
                                      ? 60
                                      : alarmFio2
                                          ? 100
                                          : alarmpeep
                                              ? 60
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
}
