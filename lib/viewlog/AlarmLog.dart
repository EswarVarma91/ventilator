import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:screen/screen.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/database/ADatabaseHelper.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';
import 'package:ventilator/viewlog/ViewLogDataDisplayPage.dart';
import 'package:ventilator/viewlog/ViewLogPatientList.dart';

class AlarmLog extends StatefulWidget {
  AlarmLog({Key key}) : super(key: key);

  @override
  _AlarmLogListState createState() => _AlarmLogListState();
}

class _AlarmLogListState extends State<AlarmLog> {
  Future<List<AlarmsList>> alarmList;
  String name, price;
  ADatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    Screen.keepOn(true);
    dbHelper = ADatabaseHelper();
    getPatientData();
  }

  getPatientData() async {
    alarmList = dbHelper.getAllAlarms();
    print(alarmList);
  }

  getAlarmCode(int res){

    var  data = res == 1
                  ? "AC POWER DISCONNECTED"
                  : res == 2
                      ? " LOW BATTERY"
                      : res == 3
                          ? "CALIBRATE FiO2"
                          : res == 04
                              ? "CALIBRATION FiO2 FAIL"
                              : res == 05
                                  ? "SYSTEM FAULT"
                                  : res == 06
                                      ? "SELF TEST FAIL"
                                      : res == 07
                                          ? "FiO2 SENSOR MISSING"
                                          : res == 08
                                              ? "HIGH FiO2"
                                              : res == 09
                                                  ? "LOW FIO2"
                                                  : res == 10
                                                      ? 
                                                          "HIGH LEAKAGE"
                                                      : res ==
                                                              11
                                                          ? 
                                                              "HIGH PRESSURE"
                                                          : res ==
                                                                  12
                                                              ? 
                                                                  "LOW PRESSURE"
                                                              : res == 13
                                                                  ? 
                                                                      "LOW VTE"
                                                                  : res == 14
                                                                      ? 
                                                                          "HIGH VTE"
                                                                      : res ==
                                                                              15
                                                                          ? 
                                                                              "LOW VTI"
                                                                          : res == 16
                                                                              ? "HIGH VTI"
                                                                              : res == 17 ? "PATIENT DISCONNECTED" : res == 18 ? "LOW O2  supply" : res == 19 ? "LOW RR" : res == 20 ? "HIGH RR" : res == 21 ? "HIGH PEEP" : res == 22 ? "LOW PEEP" : res == 23 ? "Apnea backup" : "0";
  return data;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Alarm List"),
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViewLogPatientList()),
          );
        },
        child: FutureBuilder<List>(
          future: alarmList,
          initialData: List(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());
            else if (snapshot.data.isEmpty)
              return Center(
                child: Text("No Data Found"),
              ); //CIRCULAR INDICATOR
            else {
              return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      height: 100,
                      child: Card(
                          child: ListTile(
                        onTap: () {
                          // selectDateandTimeRange();
                          //  Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => ViewLogChooseDateandTime(snapshot.data[index].pId,
                          //         snapshot.data[index].pName,
                          //         snapshot.data[index].minTime,
                          //         snapshot.data[index].maxTime)));
                        },
                        leading: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.alarm,
                            size: 35,
                          ),
                        ),
                        // trailing: IconButton(icon: Icon(Icons.delete,size: 35,),onPressed: (){

                        // },),
                        title: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              // Container(height: 50,width: 1,color: Colors.black,),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                   Text(snapshot.data[index].alarmCode != null
                                              ? getAlarmCode(int.tryParse(snapshot. data[index].alarmCode))
                                                  .toString().toUpperCase()
                                              : "",
                                          style: TextStyle(fontSize: 22),
                                        ),
                                        SizedBox(
                                          width: 30,
                                        ),
                                      Text(snapshot.data[index].datetime != null
                                              ? snapshot.data[index].datetime
                                                  .toString().toUpperCase()
                                              : "",
                                          style: TextStyle(fontSize: 10),
                                        ),
                                   
                                  ],
                                ),
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.all(15.0),
                              //   child: Column(
                              //     crossAxisAlignment: CrossAxisAlignment.start,
                              //     mainAxisAlignment: MainAxisAlignment.start,
                              //     children: [
                              //       Text(
                              //         snapshot.data[index].pName != null
                              //             ? snapshot.data[index].pName
                              //                 .toString()
                              //             : "",
                              //         style: TextStyle(fontSize: 22),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      )),
                    );
                  });
            }
          },
        ),
      ),
    );
  }

  // selectDateandTimeRange() {
  //   DateTime now = new DateTime.now();

  //   DatePicker.showDateTimePicker(context,
  //       showTitleActions: true,
  //       minTime: DateTime(now.year, now.month, now.day-6, now.hour, now.minute,now.second),
  //       maxTime: DateTime(now.year, now.month, now.day, now.hour, now.minute,now.second), 
  //     onChanged: (date) {
  //     print('change $date in time zone ' +
  //         date.timeZoneOffset.inHours.toString());
  //   }, onConfirm: (date) {
  //     print('confirm $date');
  //   }, locale: LocaleType.zh);
  // }
}
