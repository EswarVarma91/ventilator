import 'package:flutter/material.dart';
import 'package:screen/screen.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';

import 'PatientsDataByDate.dart';

class patientsDates extends StatefulWidget {
  String patientId;
  patientsDates(this.patientId);
  @override
  _patientsDatesState createState() => _patientsDatesState();
}

class _patientsDatesState extends State<patientsDates> {
   Future<List<PatientsList>> patientdatesList;
  
  DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    Screen.keepOn(true);
    dbHelper = DatabaseHelper();
    getPatientDatesData();
  }

  getPatientDatesData() async {
    patientdatesList = dbHelper.patientDatesById(widget.patientId);
    print(patientdatesList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(widget.patientId),
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
                      height: 100,
                      child: Card(
                          child: ListTile(
                        onTap: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PatientsDataByDate(snapshot.data[index].datetimeP,widget.patientId)));
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
                                          snapshot.data[index].datetimeP != null || snapshot.data[index].datetimeP != ""  ? snapshot.data[index].datetimeP.toString()
                                              : "NA",
                                          style: TextStyle(fontSize: 22),
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
                    );
                  });
            }
          },
        ),
      ),
    );
  }

}
