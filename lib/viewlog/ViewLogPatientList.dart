import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';
import 'package:ventilator/viewlog/AlarmLog.dart';
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
    // print(patientList);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      appBar: AppBar(
        title: Text("Patient List"),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.alarm),onPressed: (){
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlarmLog()),
              );
          },)
          // FlatButton(
          //   textColor: Colors.white,
          //   onPressed: () {
          //       
          //   },
          //   child: Icon(Icons.alarm),
          //   shape: CircleBorder(side: BorderSide(color: Colors.transparent)),
          // ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () {
          // Navigator.pop(context);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Dashboard()), ModalRoute.withName('/'));
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => Dashboard()),
          // );
        },
        child: FutureBuilder<List>(
          future: patientList,
          initialData: List(),
          builder: (context, snapshot) {
             if(snapshot.data.isEmpty)
             return Center(child: CircularProgressIndicator());
            else {
              return GridView.builder(
                  itemCount: snapshot.data.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,mainAxisSpacing: 0,crossAxisSpacing: 0),
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: (){
                        Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      patientsDates(snapshot.data[index].pId)));
                      },
                        child: Card(
                            elevation: 10.0,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Text(
                                      //   snapshot.data[index].pName != null ||
                                      //           snapshot.data[index].pName != ""
                                      //       ? snapshot.data[index].pName.toString()
                                      //       : "NA",
                                      //   style: TextStyle(fontSize: 18),
                                      // ),
                                      // SizedBox(
                                      //   height: 30,
                                      // ),
                                      Text(
                                        snapshot.data[index].pId != null
                                            ? snapshot.data[index].pId
                                                .toString()
                                                .toUpperCase()
                                            : "NA",
                                        style: TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                            ),
                                ),
                              ),
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


