import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:ventilator/viewlog/ViewLogDataDisplayPage.dart';

class ViewLogChooseDateandTime extends StatefulWidget {
  String pId, pName, pmin, pmax;
  ViewLogChooseDateandTime(this.pId, this.pName, this.pmin, this.pmax,
      {Key key})
      : super(key: key);

  @override
  _ViewLogChooseDateandTimeState createState() =>
      _ViewLogChooseDateandTimeState();
}

class _ViewLogChooseDateandTimeState extends State<ViewLogChooseDateandTime> {
  TextEditingController patientIdC = TextEditingController();
  TextEditingController nameC = TextEditingController();
  TextEditingController minC = TextEditingController();
  TextEditingController maxC = TextEditingController();
  TextEditingController fromDateC = TextEditingController();
  TextEditingController toDateC = TextEditingController();
  int dateY, dateM, dateD, timeH, timeM, timeS;

  @override
  void initState() {
    super.initState();
    patientIdC = TextEditingController(text: widget.pId);
    nameC = TextEditingController(text: widget.pName);
    minC = TextEditingController(text: widget.pmin);
    maxC = TextEditingController(text: widget.pmax);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose min and max"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Container(
                width: 200,
                margin: EdgeInsets.all(22),
                child: TextFormField(
                  showCursor: true,
                  readOnly: true,
                  enabled: false,
                  maxLines: 1,
                  controller: patientIdC,
                  decoration: InputDecoration(
                    labelText: "Patinet Id",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              Container(
                width: 200,
                margin: EdgeInsets.all(22),
                child: TextFormField(
                  showCursor: true,
                  readOnly: true,
                  enabled: false,
                  maxLines: 1,
                  controller: nameC,
                  decoration: InputDecoration(
                    labelText: "Patient Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              Container(
                width: 200,
                margin: EdgeInsets.all(22),
                child: TextFormField(
                  showCursor: true,
                  readOnly: true,
                  enabled: false,
                  maxLines: 1,
                  controller: minC,
                  decoration: InputDecoration(
                    labelText: "Min Time",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              Container(
                width: 200,
                margin: EdgeInsets.all(22),
                child: TextFormField(
                  showCursor: true,
                  readOnly: true,
                  enabled: false,
                  maxLines: 1,
                  controller: maxC,
                  decoration: InputDecoration(
                    labelText: "Max Time",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  fromDateTimeDialog();
                },
                child: Container(
                  width: 200,
                  margin: EdgeInsets.all(22),
                  child: TextFormField(
                    showCursor: true,
                    readOnly: true,
                    enabled: false,
                    maxLines: 1,
                    controller: fromDateC,
                    onTap: () {
                      fromDateTimeDialog();
                    },
                    decoration: InputDecoration(
                      labelText: "From Date",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  toDateTimeDialog();
                },
                child: Container(
                  width: 200,
                  margin: EdgeInsets.all(22),
                  child: TextFormField(
                    showCursor: true,
                    readOnly: true,
                    enabled: false,
                    maxLines: 1,
                    controller: toDateC,
                    onTap: () {
                      toDateTimeDialog();
                    },
                    decoration: InputDecoration(
                      labelText: "To Date",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 200,
                margin: EdgeInsets.all(22),
              ),
              InkWell(
                onTap: () {
                   Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ViewLogDataDisplayPage(patientIdC.text,fromDateC.text,toDateC.text)));
                },
                child: Container(
                    width: 200,
                    margin: EdgeInsets.all(22),
                    child: Card(
                        child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Center(child: Text("Confirm")),
                    ))),
              ),
            ],
          )
        ],
      ),
    );
  }

  fromDateTimeDialog() {
    var now = new DateTime.now();
    DatePicker.showDateTimePicker(context,
        showTitleActions: true,
        minTime: DateTime(
            now.year, now.month, now.day - 6, now.hour, now.minute, now.second),
        maxTime: DateTime(
            now.year, now.month, now.day, now.hour, now.minute, now.second - 1),
        theme: DatePickerTheme(
            backgroundColor: Colors.white,
            itemStyle: TextStyle(
              color: Colors.blue,
              fontSize: 20,
            ),
            doneStyle: TextStyle(color: Colors.blue, fontSize: 12)),
        onChanged: (date) {
      setState(() {
        fromDateC.text = date.toString().split(".")[0];
      });
      changeDateTime(date);
    }, onConfirm: (date) {
      setState(() {
        fromDateC.text = date.toString().split(".")[0];
      });
      changeDateTime(date);
    },
        currentTime: DateTime(
            now.year, now.month, now.day, now.hour, now.minute, now.second),
        locale: LocaleType.en);
  }

  toDateTimeDialog() {
    DatePicker.showDateTimePicker(context,
        showTitleActions: true,
        minTime: DateTime(dateY, dateM, dateD, timeH, timeM, timeS),
        maxTime: DateTime(dateY, dateM, dateD, timeH, timeM + 10, timeS),
        theme: DatePickerTheme(
            backgroundColor: Colors.white,
            itemStyle: TextStyle(
              color: Colors.blue,
              fontSize: 20,
            ),
            doneStyle: TextStyle(color: Colors.blue, fontSize: 12)),
        onChanged: (date) {
      setState(() {
        toDateC.text = date.toString().split(".")[0];
      });
    }, onConfirm: (date) {
      setState(() {
        toDateC.text = date.toString().split(".")[0];
      });
    },
        currentTime: DateTime(dateY, dateM, dateD, timeH, timeM, timeS + 10),
        locale: LocaleType.en);
  }

  changeDateTime(DateTime date) {
    String dateDdata = date.toString().split(".")[0].split(" ")[0];
    String dateTdata = date.toString().split(".")[0].split(" ")[1];
    setState(() {
      dateY = int.tryParse(dateDdata.split("-")[0]);
      dateM = int.tryParse(dateDdata.split("-")[1]);
      dateD = int.tryParse(dateDdata.split("-")[2]);
      timeH = int.tryParse(dateTdata.split(":")[0]);
      timeM = int.tryParse(dateTdata.split(":")[1]);
      timeS = int.tryParse(dateTdata.split(":")[2]);
    });
  }
}
