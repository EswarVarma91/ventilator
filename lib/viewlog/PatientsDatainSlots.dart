import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screen/screen.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';
import 'package:ventilator/viewlog/ViewLogPatientList.dart';

import 'AlarmLog.dart';
import 'ViewLogDataDisplayPage.dart';

class PatientsDatainSlots extends StatefulWidget {
  String minTime,maxTime,minT,maxT;
  PatientsDatainSlots(this.minTime,this.maxTime, this.minT, this.maxT);
  @override
  _PatientsDatainSlotsState createState() => _PatientsDatainSlotsState();
}

class _PatientsDatainSlotsState extends State<PatientsDatainSlots> {
  Future<List<PatientsList>> patientdatesList,l;
  
  DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    Screen.keepOn(true);
    dbHelper = DatabaseHelper();
    getPatientDatesData();
  }

  getPatientDatesData() async {
    patientdatesList = dbHelper.splitData(widget.minTime,widget.maxTime);
    // print(patientdatesList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(widget.minT + " - "+ widget.maxT),
       actions: <Widget>[
        FlatButton(
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AlarmLog()),
          );
          },
          child: Icon(Icons.alarm),
          shape: CircleBorder(side: BorderSide(color: Colors.transparent)),
        ),
      ],
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViewLogPatientList()),
          );
        },
        child: FutureBuilder<List>(
          future: patientdatesList,
          initialData: List(),
          builder: (context, snapshot) {
             if(snapshot.data.isEmpty)
             return Center(child: CircularProgressIndicator());
            else {
              return GridView.builder(
                  itemCount: snapshot.data.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,crossAxisSpacing: 4.0, mainAxisSpacing: 4.0),
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      height: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                            child: ListTile(
                          onTap: () {
                            // l = dbHelper.splitData(widget.patientId,widget.datetimeW);
                            // print(l);
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ViewLogDataDisplayPage(snapshot.data[index].minTime,snapshot.data[index].maxTime,)));
                            },
                          
                          title: Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // dateFormate = DateFormat("dd-MM-yyyy").format(DateTime.parse("2019-09-30"));
                                Text("From",style:TextStyle(fontSize: 12)),
                                Text(snapshot.data[index].minTime != null || snapshot.data[index].minTime != ""  ? DateFormat("HH:mm:ss").format(DateTime.parse(snapshot.data[index].minTime.toString())).toString():"",style:TextStyle(color: Colors.green)),

                                Text("To",style:TextStyle(fontSize: 12)),
                                Text(snapshot.data[index].maxTime != null || snapshot.data[index].maxTime != ""  ? DateFormat("HH:mm:ss").format(DateTime.parse(snapshot.data[index].maxTime.toString())).toString():"",style:TextStyle(color: Colors.green)),
                             
                              ],
                            ),
                          ),
                        )),
                      ),
                    );
                  });
            }
          },
        ),
      ),
    );
  }
}