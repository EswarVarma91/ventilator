import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:screen/screen.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';
import 'package:ventilator/graphs/Oscilloscope.dart';
import 'package:ventilator/viewlog/ViewLogPatientList.dart';

class ViewLogDataDisplayPage extends StatefulWidget {
  var patientID, fromDateC, toDateC;
  ViewLogDataDisplayPage( this.fromDateC, this.toDateC);

  @override
  StateViewLogPage createState() => StateViewLogPage();
}

class StateViewLogPage extends State<ViewLogDataDisplayPage> {
  List<double> pressurePoints = [];
  List<double> flowPoints = [];
  List<double> volumePoints = [];
  Oscilloscope scopeOne, scopeOne1, scopeOne2;
  int currentValue = 0;
  bool dataAvailable = false, isPlaying = false;
  String psValue1 = "00",
      mvValue = "00",
      vteValue = "00",
      modeName = "PC-CMV",
      fio2Value = "0",
      tiValue = "0",
      patientName = "",
      alarmActive = "0",
      alarmMessage = "0",
      alarmPriority ="5",
      paw = "0",
      dateTime = "0";

  
  String ioreDisplayParamter = "I/E";
  DatabaseHelper dbHelper;
  List<VentilatorOMode> vomL;
  String operatinModeR,
      ieValue = "0",
      fio2DisplayParameter = "0",
      mapDisplayValue = "0",
      ieDisplayValue = "0",
      cdisplayParameter = "0",
      peepDisplayValue = "0",
      rrDisplayValue = "0",
      lungImage = "0",
      rrValue = "0",
      peepValue = "0",
      psValue = "0",
      vtValue = "0";

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

  @override
  void initState() {
    super.initState();
    vomL=[];
    Screen.keepOn(true);
    dbHelper = DatabaseHelper();
    getPatientData(widget.fromDateC, widget.toDateC);
  }

  runData(data) async {
    for (currentValue = data==null || data=="" ? 0 : data; currentValue < vomL.length; currentValue++) {
      dataPack(currentValue, 1);
      await justWait(numberOfMilliseconds: 100);
    }
  }

  void justWait({@required int numberOfMilliseconds}) async {
    await Future.delayed(Duration(milliseconds: numberOfMilliseconds));
  }

  getPatientData(var fromDate, var toDate) async {
    
    vomL = await dbHelper.getPatientsData(fromDate.toString(), toDate.toString());
    // print(vomL);
    pressurePoints = [];
    volumePoints=[];
    flowPoints=[];
    

    if (vomL.isNotEmpty) {
      setState(() {
        dataAvailable = true;
      });
    } else {
      setState(() {
        dataAvailable = false;
      });
    }
    // isPlaying ?
    runData(0);
    // : Container();
    // setState(() {
    //   isPlaying = false;
    // });
  }

  dataPack(int currentValue, int status) {
    if (status == 1) {
      pressurePoints.add(vomL[currentValue].pressureValues != null
          ? vomL[currentValue].pressureValues
          : 0);
      flowPoints.add(vomL[currentValue].flowValues != null
          ? vomL[currentValue].flowValues
          : 0);
      volumePoints.add(vomL[currentValue].volumeValues != null
          ? vomL[currentValue].volumeValues
          : 0);
    }
    setState(() {
      psValue1 = vomL[currentValue].pipD;
      vteValue = vomL[currentValue].vtD;
      peepDisplayValue = vomL[currentValue].peepD;
      rrDisplayValue = vomL[currentValue].rrD;
      fio2DisplayParameter = vomL[currentValue].fio2D;
      mapDisplayValue = vomL[currentValue].mapD;
      mvValue = vomL[currentValue].mvD;
      cdisplayParameter = vomL[currentValue].complainceD;
      ieDisplayValue = vomL[currentValue].ieD;
      rrValue = vomL[currentValue].rrS;
      ieValue = vomL[currentValue].ieS;
      peepValue = vomL[currentValue].peepS;
      psValue = vomL[currentValue].psS;
      fio2Value = vomL[currentValue].fio2S;
      operatinModeR = vomL[currentValue]?.operatingMode ?? "0";
      patientName = vomL[currentValue]?.patientName ?? "";
      paw = vomL[currentValue]?.paw ?? "0";
      dateTime = vomL[currentValue].dateTime;
      alarmActive = vomL[currentValue].alarmActive;
      alarmMessage =vomL[currentValue].alarmC;
      alarmPriority= vomL[currentValue].alarmP;

      if (operatinModeR == "1") {
        setState(() {
          modeName = "VACV";
        });
      } else if (operatinModeR == "2") {
        setState(() {
          modeName = "PACV";
        });
      } else if (operatinModeR == "3") {
        setState(() {
          modeName = "PSV";
        });
      } else if (operatinModeR == "4") {
        setState(() {
          modeName = "PSIMV";
        });
      } else if (operatinModeR == "5") {
        setState(() {
          modeName = "VSIMV";
        });
      } else if (operatinModeR == "6") {
        setState(() {
          modeName = "PC-CMV";
        });
      } else if (operatinModeR == "7") {
        setState(() {
          modeName = "VC-CMV";
        });
      }

      if (int.tryParse(paw) <= 10) {
        setState(() {
          lungImage = "1";
        });
      } else if (int.tryParse(paw) <= 20 && int.tryParse(paw) >= 11) {
        setState(() {
          lungImage = "2";
        });
      } else if (int.tryParse(paw) <= 30 && int.tryParse(paw) >= 21) {
        setState(() {
          lungImage = "3";
        });
      } else if (int.tryParse(paw) <= 40 && int.tryParse(paw) >= 31) {
        setState(() {
          lungImage = "4";
        });
      } else if (int.tryParse(paw) <= 100 && int.tryParse(paw) >= 41) {
        setState(() {
          lungImage = "5";
        });
      }

      if (alarmActive == '1') {
              setState(() {
                if (alarmPriority == '1' || alarmPriority == '0') {
                  alarmMessage == '5'
                      ? alarmMessage = "SYSTEM FAULT"
                      : alarmMessage == '7'
                          ? alarmMessage = "FiO\u2082 SENSOR MISSING"
                          : alarmMessage == '10'
                              ? alarmMessage = "HIGH LEAKAGE"
                              : alarmMessage == '11'
                                  ? alarmMessage = "HIGH PRESSURE"
                                  : alarmMessage == '17'
                                      ? alarmMessage = "PATIENT DISCONNECTED"
                                      : alarmMessage = "";
                } else if (alarmPriority == '2') {
                  // print("alarm code "+((alarmMessage).toString());
                  alarmMessage == '1'
                      ? alarmMessage = "AC POWER DISCONNECTED"
                      : alarmMessage == '2'
                          ? alarmMessage = " LOW BATTERY"
                          : alarmMessage == '3'
                              ? alarmMessage = "CALIBRATE FiO2"
                              : alarmMessage == '4'
                                  ? alarmMessage = "CALIBRATION FiO2 FAIL"
                                  : alarmMessage == '6'
                                      ? alarmMessage = "SELF TEST FAIL"
                                      : alarmMessage == '8'
                                          ? alarmMessage = "HIGH FiO2"
                                          : alarmMessage == '9'
                                              ? alarmMessage = "LOW FIO2"
                                              : alarmMessage == '12'
                                                  ? alarmMessage =
                                                      "LOW PRESSURE"
                                                  : alarmMessage == '13'
                                                      ? alarmMessage = "LOW VTE"
                                                      : alarmMessage ==
                                                              '14'
                                                          ? alarmMessage =
                                                              "HIGH VTE"
                                                          : alarmMessage ==
                                                                  '15'
                                                              ? alarmMessage =
                                                                  "LOW VTI"
                                                              : alarmMessage == '16'
                                                                  ? alarmMessage =
                                                                      "HIGH VTI"
                                                                  : alarmMessage == "18"
                                                                      ? alarmMessage =
                                                                          "LOW O2  supply"
                                                                      : alarmMessage ==
                                                                              '19'
                                                                          ? alarmMessage =
                                                                              "LOW RR"
                                                                          : alarmMessage == '20'
                                                                              ? alarmMessage = "HIGH RR"
                                                                              : alarmMessage == '21' ? alarmMessage = "HIGH PEEP" : alarmMessage == '22' ? alarmMessage = "LOW PEEP" : alarmMessage = "";
                } else if (alarmPriority == '3') {
                  alarmMessage == '23'
                      ? alarmMessage = "Apnea backup"
                      : alarmMessage = "";
                }
              });
            }
      
      // ieValue
      // Fluttertoast.showToast(msg: psValue1, toastLength: Toast.LENGTH_SHORT);
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
        // appBar: AppBar(title: Text(widget.patientID),),
        body: dataAvailable
            ? Container(
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
                    dataAvailable
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: Text(
                              dateTime,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ))
                        : Container(),
                    dataAvailable
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              width: 1000,
                              height: 40,
                              child: Container(
                                child: CupertinoSlider(
                                  onChanged: (value) {
                                    pressurePoints=[];
                                    volumePoints=[];
                                    flowPoints=[];
                                    // if (isPlaying == false) {
                                    setState(() {
                                      currentValue = value.toInt();
                                    });
                                    dataPack(currentValue, 0);
                                    // } else {
                                    //   Fluttertoast.showToast(msg: "Press Pause");
                                    // }
                                  },
                                  value: currentValue.toDouble(),
                                  max: vomL.length.toDouble(),
                                  min: 0.0,
                                ),
                              ),
                            ),
                          )
                        : Container()
                  ],
                ),
              )
            : Center(child: CircularProgressIndicator()));
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
                SizedBox(
                  height: 5,
                ),
                IconButton(
                  icon: Icon(
                    Icons.exit_to_app,
                    size: 45,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ViewLogPatientList()),
                    );
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                // IconButton(
                //   icon: Icon(
                //     Icons.queue_play_next,
                //     size: 45,
                //     color: Colors.green,
                //   ),
                //   onPressed: () {
                //     next10min(
                //         widget.patientID, widget.fromDateC, widget.toDateC);
                //   },
                // ),
                // Padding(
                //   padding: const EdgeInsets.only(
                //       top: 8.0, bottom: 8.0, left: 16.0, right: 4.0),
                //   child: Text("Next 10 Min",
                //       style: TextStyle(color: Colors.white, fontSize: 14)),
                // )
                // isPlaying==true ?
                // IconButton(
                //   icon: Icon(
                //     Icons.play_circle_filled,
                //     size: 45,
                //     color: Colors.green,
                //   ),
                //   onPressed: () {
                //    setState(() {
                //      isPlaying = true;
                //      runData();
                //    });
                //   },
                // )
                // : IconButton(
                //   icon: Icon(
                //     Icons.pause_circle_filled,
                //     size: 45,
                //     color: Colors.blue,
                //   ),
                //   onPressed: () {
                //     setState(() {
                //       isPlaying = false;
                //      stopData();
                //    });
                //   },
                // )
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
                                                    (int.tryParse(mvValue) / 1000)
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
                                                    // pplateauDisplay
                                                    //     .toStringAsFixed(0),
                                                    "0",
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
                                        // Center(
                                        //   child: Container(
                                        //     color: Color(0xFF171e27),
                                        //     width: 85,
                                        //     height: 81,
                                        //     child: Padding(
                                        //       padding:
                                        //           const EdgeInsets.all(5.0),
                                        //       child: Center(
                                        //           child: Stack(
                                        //         children: [
                                        //           Align(
                                        //             alignment:
                                        //                 Alignment.topLeft,
                                        //             child: Padding(
                                        //               padding:
                                        //                   const EdgeInsets.all(
                                        //                       2.0),
                                        //               child: Text("",
                                        //                   style: TextStyle(
                                        //                       color:
                                        //                           Colors.green,
                                        //                       fontSize: 10)),
                                        //             ),
                                        //           ),
                                        //           Align(
                                        //             alignment:
                                        //                 Alignment.bottomLeft,
                                        //             child: Padding(
                                        //               padding:
                                        //                   const EdgeInsets.all(
                                        //                       2.0),
                                        //               child: Text(
                                        //                 "ms",
                                        //                 style: TextStyle(
                                        //                     color: Colors.white,
                                        //                     fontSize: 10),
                                        //               ),
                                        //             ),
                                        //           ),
                                        //           Align(
                                        //             alignment: Alignment.center,
                                        //             child: Padding(
                                        //               padding:
                                        //                   const EdgeInsets.only(
                                        //                       right: 8.0),
                                        //               child: Text(
                                        //                 double.tryParse(tiValue)
                                        //                     .toStringAsFixed(0),
                                        //                 // "0000",
                                        //                 style: TextStyle(
                                        //                     color: Colors.blue,
                                        //                     fontSize: 18),
                                        //               ),
                                        //             ),
                                        //           ),
                                        //           Align(
                                        //             alignment:
                                        //                 Alignment.topLeft,
                                        //             child: Container(
                                        //               margin: EdgeInsets.only(
                                        //                   bottom: 50, left: 4),
                                        //               child: Text(
                                        //                 "Ti",
                                        //                 style: TextStyle(
                                        //                     color: Colors.white,
                                        //                     fontSize: 12),
                                        //               ),
                                        //             ),
                                        //           ),
                                        //           Align(
                                        //               alignment: Alignment
                                        //                   .bottomCenter,
                                        //               child: Padding(
                                        //                 padding:
                                        //                     const EdgeInsets
                                        //                             .only(
                                        //                         top: 18.0),
                                        //                 child: Divider(
                                        //                   color: Colors.white,
                                        //                   height: 1,
                                        //                 ),
                                        //               ))
                                        //         ],
                                        //       )),
                                        //     ),
                                        //   ),
                                        // ),
                                        // Center(
                                        //   child: Container(
                                        //     color: Color(0xFF171e27),
                                        //     width: 85,
                                        //     height: 81,
                                        //     child: Padding(
                                        //       padding:
                                        //           const EdgeInsets.all(5.0),
                                        //       child: Center(
                                        //           child: Stack(
                                        //         children: [
                                        //           Align(
                                        //             alignment:
                                        //                 Alignment.topLeft,
                                        //             child: Padding(
                                        //               padding:
                                        //                   const EdgeInsets.all(
                                        //                       2.0),
                                        //               child: Text("",
                                        //                   style: TextStyle(
                                        //                       color:
                                        //                           Colors.green,
                                        //                       fontSize: 10)),
                                        //             ),
                                        //           ),
                                        //           Align(
                                        //             alignment:
                                        //                 Alignment.bottomLeft,
                                        //             child: Padding(
                                        //               padding:
                                        //                   const EdgeInsets.all(
                                        //                       2.0),
                                        //               child: Text(
                                        //                 "ms",
                                        //                 style: TextStyle(
                                        //                     color: Colors.white,
                                        //                     fontSize: 10),
                                        //               ),
                                        //             ),
                                        //           ),
                                        //           Align(
                                        //             alignment: Alignment.center,
                                        //             child: Padding(
                                        //               padding:
                                        //                   const EdgeInsets.only(
                                        //                       right: 8.0),
                                        //               child: Text(
                                        //                 teValue
                                        //                     .toStringAsFixed(0),
                                        //                 // "0000",
                                        //                 style: TextStyle(
                                        //                     color: Colors.blue,
                                        //                     fontSize: 18),
                                        //               ),
                                        //             ),
                                        //           ),
                                        //           Align(
                                        //             alignment:
                                        //                 Alignment.topLeft,
                                        //             child: Container(
                                        //               margin: EdgeInsets.only(
                                        //                   bottom: 50, left: 4),
                                        //               child: Text(
                                        //                 "Te",
                                        //                 style: TextStyle(
                                        //                     color: Colors.white,
                                        //                     fontSize: 12),
                                        //               ),
                                        //             ),
                                        //           ),
                                        //           Align(
                                        //               alignment: Alignment
                                        //                   .bottomCenter,
                                        //               child: Padding(
                                        //                 padding:
                                        //                     const EdgeInsets
                                        //                             .only(
                                        //                         top: 18.0),
                                        //                 child: Divider(
                                        //                   color: Colors.white,
                                        //                   height: 1,
                                        //                 ),
                                        //               ))
                                        //         ],
                                        //       )),
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    )
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
    return Stack(
      children: [
        Container(
          color: Color(0xFF171e27),
          width: 904,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {},
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
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
                            ],
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
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
                            ],
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),
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
                            ],
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
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
                                  operatinModeR == "6" ||
                                          operatinModeR == "2" ||
                                          operatinModeR == "4" ||
                                          operatinModeR == "3"
                                      ? "PS"
                                      : operatinModeR == "7" ||
                                              operatinModeR == "1" ||
                                              operatinModeR == "5"
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 17.0),
                                  child: Text(
                                    operatinModeR == "6" ||
                                            operatinModeR == "2" ||
                                            operatinModeR == "4" ||
                                            operatinModeR == "3"
                                        ? psValue.toString()
                                        : operatinModeR == "7" ||
                                                operatinModeR == "1" ||
                                                operatinModeR == "5"
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
                            ],
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),
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
                            ],
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        ],
      ),
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

  next10min(patientID, fromDateC, toDateC) {
    var dateFrom =  DateFormat("yyyy-MM-dd HH:mm:ss").parse(fromDateC);
    var dateTo =  DateFormat("yyyy-MM-dd HH:mm:ss").parse(toDateC);
    var dateFromSend = DateTime(dateFrom.year, dateFrom.month, dateFrom.day,
        dateFrom.hour, dateFrom.minute + 10, dateFrom.second);
    var dateToSend = DateTime(dateTo.year, dateTo.month, dateTo.day,
        dateTo.hour, dateTo.minute + 10, dateTo.second);

    var finalFrom = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateFromSend.toString().split(".")[0]);
    var finalTo = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateToSend.toString().split(".")[0]);

    vomL.clear();

    getPatientData(finalFrom , finalTo);
  }
}
