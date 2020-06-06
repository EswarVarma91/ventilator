import 'package:flutter/material.dart';
import 'package:screen/screen.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';

import 'PatientsDatainSlots.dart';

class PatientsDataByDate extends StatefulWidget {
  String datetimeW,patientId;
  PatientsDataByDate(this.datetimeW,this.patientId);
  @override
  _PatientsDataByDateState createState() => _PatientsDataByDateState();
}

class _PatientsDataByDateState extends State<PatientsDataByDate> {
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
    patientdatesList = dbHelper.patientDataByDateId(widget.patientId,widget.datetimeW);
    // l = dbHelper.splitData(widget.patientId,widget.datetimeW);
    // print(l);
    // print(patientdatesList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(widget.patientId + " "+ widget.datetimeW),
       actions: <Widget>[
        FlatButton(
          textColor: Colors.white,
          onPressed: () {
          //   Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => AlarmLog()),
          // );
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
            MaterialPageRoute(builder: (context) => Dashboard()),
          );
        },
        child: FutureBuilder<List>(
          future: patientdatesList,
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
                      height: 140,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Card(
                            child: ListTile(
                          onTap: () {
                            // l = dbHelper.splitData(widget.patientId,widget.datetimeW);
                            // print(l);
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PatientsDatainSlots(snapshot.data[index].minTime,snapshot.data[index].maxTime,)));
                            },
                          leading: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.person,
                              size: 35,
                            ),
                          ),
                          // trailing: IconButton(icon: Icon(Icons.delete,size: 35,),onPressed: (){

                          // },),
                          title: Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: Row(

                              children: [
                                // Container(height: 50,width: 1,color: Colors.black,),
                                Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            snapshot.data[index].pId != null || snapshot.data[index].pId != ""  ? snapshot.data[index].pId.toString()
                                                : "NA",
                                            style: TextStyle(fontSize: 22),
                                          ),
                                          
                                        ],
                                      ),
                                      SizedBox(height:20),
                                       Row(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: <Widget>[
                                              Text("From : ",style:TextStyle(color: Colors.grey)),
                                              Text(
                                                snapshot.data[index].minTime != null || snapshot.data[index].minTime != ""  ? snapshot.data[index].minTime.toString()
                                                    : "NA",
                                                style: TextStyle(fontSize: 22),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width:30),
                                          Row(
                                            children: <Widget>[
                                              Text("To : ",style:TextStyle(color: Colors.grey)),
                                              Text(
                                                snapshot.data[index].maxTime != null || snapshot.data[index].maxTime != ""  ? snapshot.data[index].maxTime.toString()
                                                    : "NA",
                                                style: TextStyle(fontSize: 22),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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