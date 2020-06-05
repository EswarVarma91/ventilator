import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:screen/screen.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';
import 'package:ventilator/viewlog/AlarmLog.dart';
import 'package:ventilator/viewlog/ViewLogDataDisplayPage.dart';
import 'package:ventilator/viewlog/patientsDates.dart';

class ViewLogPatientList extends StatefulWidget {
  ViewLogPatientList({Key key}) : super(key: key);

  @override
  _ViewLogPatientListState createState() => _ViewLogPatientListState();
}

class _ViewLogPatientListState extends State<ViewLogPatientList> {
  Future<List<PatientsList>> patientList;
  String name, price;
  DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    Screen.keepOn(true);
    dbHelper = DatabaseHelper();
    getPatientData();
  }

  getPatientData() async {
    patientList = dbHelper.getAllPatients();
    print(patientList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text("Patient List"),
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
          future: patientList,
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
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => patientsDates(snapshot.data[index].pId)));
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
                                    Row(
                                      children: [
                                        Text(
                                          snapshot.data[index].pName != null || snapshot.data[index].pName != ""  ? snapshot.data[index].pName.toString()
                                              : "NA",
                                          style: TextStyle(fontSize: 22),
                                        ),
                                        SizedBox(
                                          width: 30,
                                        ),
                                        Text(
                                          snapshot.data[index].pId != null ? snapshot.data[index].pId.toString().toUpperCase()
                                              : "NA",
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    // Row(
                                    //   children: [
                                    //     Text(
                                    //       snapshot.data[index].minTime != null
                                    //           ? snapshot.data[index].minTime
                                    //               .toString()
                                    //           : "",
                                    //       style: TextStyle(fontSize: 10),
                                    //     ),
                                    //     Text("  -  "),
                                    //     Text(
                                    //       snapshot.data[index].maxTime != null
                                    //           ? snapshot.data[index].maxTime
                                    //               .toString()
                                    //           : "",
                                    //       style: TextStyle(fontSize: 10),
                                    //     ),
                                    //   ],
                                    // )
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
