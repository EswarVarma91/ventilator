import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

class CalibrationPage extends StatefulWidget {
  UsbPort port;
  CalibrationPage(this.port, {Key key}) : super(key: key);

  @override
  _CalibrationPageState createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Color(0xFF171e27),
      child: Center(
        child: Stack(
          children: [
            Align(
              alignment: Alignment(0.99, -0.99),
              child: RaisedButton(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 28.0, right: 28.0, top: 20, bottom: 20),
                  child: Text(
                    "Calibrate 100%",
                    style: TextStyle(color: Colors.blue, fontSize: 25),
                  ),
                ),
                onPressed: () {
                  // showAlertDialog();
                },
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 500,
                  height: 300,
                  decoration: new BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: new Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                  ),
                  child: new Center(
                    child: new Text(
                      " O\u2082 Sensor \nat \nAtmosphere",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment(-0.99, 0.99),
              child: RaisedButton(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 28.0, right: 28.0, top: 20, bottom: 20),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.blue, fontSize: 25),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Align(
              alignment: Alignment(0.99, 0.99),
              child: RaisedButton(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 28.0, right: 28.0, top: 20, bottom: 20),
                  child: Text(
                    "Calibrate",
                    style: TextStyle(color: Colors.blue, fontSize: 25),
                  ),
                ),
                onPressed: () {
                  showAlertDialog();
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  showAlertDialog() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)), //this right here
            child: Container(
              height: MediaQuery.of(context).size.height / 4,
              width: MediaQuery.of(context).size.width / 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 30,
                    ),
                    Center(
                        child: Text(
                      "Ensure the oxygen unplugged.",
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    )),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 12,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: RaisedButton(
                          onPressed: () async {
                            // await widget.port.write(Uint8List.fromList(obj));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "ok",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          color: const Color(0xFF1BC0C5),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
