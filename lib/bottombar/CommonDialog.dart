import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ventilator/activity/Dashboard.dart';

class CommonDialog extends StatefulWidget {
  String value;
  CommonDialog(this.value, {Key key}) : super(key: key);

  @override
  _CommonDialogState createState() => _CommonDialogState();
}

class _CommonDialogState extends State<CommonDialog> {
  double commomValue;
  SharedPreferences preferences;
  double min, max;
  bool prefix = false;
  bool suffix = false;
  bool units = false;

  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    preferences = await SharedPreferences.getInstance();
    if (widget.value.toString() == "RR") {
      setState(() {
        commomValue = preferences.getInt("rr").toDouble();
        min = 1;
        max = 60;
        prefix = false;
        suffix = false;
        units = false;
      });
    } else if (widget.value.toString() == "I:E") {
      setState(() {
        commomValue = preferences.getInt("ie").toDouble();
        min = 1;
        max = 4;
        prefix = true;
        suffix = false;
        units = false;
      });
    } else if (widget.value.toString() == "PEEP") {
      setState(() {
        commomValue = preferences.getInt("peep").toDouble();
        min = 0;
        max = 20;
        prefix = false;
        suffix = false;
        units = true;
      });
    } else if (widget.value.toString() == "PS") {
      setState(() {
        commomValue = preferences.getInt("ps").toDouble();
        min = 20;
        max = 60;
        prefix = false;
        suffix = false;
        units = true;
      });
    } else if (widget.value.toString() == "FiO2") {
      setState(() {
        commomValue = preferences.getInt("fio2").toDouble();
        min = 21;
        max = 100;
        prefix = false;
        suffix = true;
        units = false;
      });
    } else if (widget.value.toString() == "Tih") {
      setState(() {
        commomValue = preferences.getInt("tih").toDouble();
        min = 0;
        max = 75;
        prefix = false;
        suffix = true;
        units = false;
      });
    }else if (widget.value.toString() == "Te") {
      setState(() {
        commomValue = preferences.getInt("te").toDouble();
        min = 0;
        max = 60;
        prefix = false;
        suffix = true;
        units = false;
      });
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
        ),
        height: 350.0,
        width: 500.0,
        child: Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  widget.value.toString(),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Container(
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: 90,
                    ),
                    Text(
                      prefix
                          ? "1:" + commomValue.floor().toString()
                          : suffix
                              ? commomValue.floor().toString() + "%"
                              : commomValue.floor().toString(),
                      style: TextStyle(fontSize: 40),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Container(
                      width: 450,
                      child: Slider(
                        value: commomValue?.toDouble(),
                        onChanged: (val) {
                          setState(() {
                            commomValue = double.tryParse(val.toString());
                          });
                        },
                        max: max,
                        min: min,
                        label: prefix
                            ? "1:" + commomValue.floor().toString()
                            : suffix
                                ? commomValue.floor().toString() + "%"
                                : commomValue.floor().toString(),
                      ),
                    ),
                    SizedBox(
                      height: 0,
                    ),
                    units
                        ? Text(
                            "cmH2O",
                            style: TextStyle(fontSize: 16),
                          )
                        : Text(""),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 190,
                        height: 60,
                        decoration: BoxDecoration(
                            color: Color(0xFF424242),
                            borderRadius: BorderRadius.circular(5)),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: InkWell(
                      onTap: () {
                        writeData(commomValue);
                      },
                      child: Container(
                        width: 190,
                        height: 60,
                        decoration: BoxDecoration(
                            color: Color(0xFF424242),
                            borderRadius: BorderRadius.circular(5)),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Confirm",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 0,
            ),
            Align(
              alignment: Alignment(1.05, -1.05),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void writeData(double value) async {
    if (widget.value.toString() == "RR") {
      setState(() {
        preferences.setInt("rr", value.floor());
      });
       Navigator.pop(context, value.floor().toString()+"ab"+"rr");
    } else if (widget.value.toString() == "I:E") {
      setState(() {
        preferences.setInt("ie", value.floor());
      });
       Navigator.pop(context, value.floor().toString()+"ab"+"ie");
    } else if (widget.value.toString() == "PEEP") {
      setState(() {
        preferences.setInt("peep", value.floor());
      });
       Navigator.pop(context, value.floor().toString()+"ab"+"peep");
    } else if (widget.value.toString() == "PS") {
      setState(() {
        preferences.setInt("ps", value.floor());
      });
       Navigator.pop(context, value.floor().toString()+"ab"+"ps");
    } else if (widget.value.toString() == "FiO2") {
      setState(() {
        preferences.setInt("fio2", value.floor());
      });
       Navigator.pop(context, value.floor().toString()+"ab"+"fio2");
    } else if (widget.value.toString() == "Tih") {
      setState(() {
        preferences.setInt("tih", value.floor());
      });
       Navigator.pop(context, value.floor().toString()+"ab"+"tih");
    }

   
  }
}
