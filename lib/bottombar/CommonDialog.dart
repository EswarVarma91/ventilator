import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonDialog extends StatefulWidget {
  String value;
  CommonDialog(this.value, {Key key}) : super(key: key);

  @override
  _CommonDialogState createState() => _CommonDialogState();
}

class _CommonDialogState extends State<CommonDialog> {
  double commomValue, commomValue1;
  SharedPreferences preferences;
  double min, max;
  bool prefix = false;
  bool suffix = false;
  bool units = false;
  double tiValue = 0, teValue = 0;

  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    preferences = await SharedPreferences.getInstance();//eRR
    if (widget.value.toString() == "RR") {
      setState(() {
        commomValue = preferences.getInt("rr").toDouble();
        commomValue1 = preferences.getInt("ie").toDouble();
        min = 1;
        max = 60;
        prefix = false;
        suffix = false;
        units = false;
      });
    }else if (widget.value.toString() == "eRR") {
      setState(() {
        commomValue = preferences.getInt("rr").toDouble();
        commomValue1 = preferences.getInt("ie").toDouble();
        min = 1;
        max = 30;
        prefix = false;
        suffix = false;
        units = false;
      });
    } else if (widget.value.toString() == "I:E") {
      setState(() {
        commomValue = preferences.getInt("ie").toDouble();
        commomValue1 = preferences.getInt("rr").toDouble();
        min = 1;
        max = 61;
        prefix = true;
        suffix = false;
        units = false;
      });
    } else if (widget.value.toString() == "PEEP") {
      setState(() {
        commomValue = preferences.getInt("peep").toDouble();
        min = 0;
        max = 30;
        prefix = false;
        suffix = false;
        units = true;
      });
    } else if (widget.value.toString() == "PS") {
      setState(() {
        commomValue = preferences.getInt("ps").toDouble();
        min = 1;
        max = 70;
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
    } else if (widget.value.toString() == "PC") {
      setState(() {
        commomValue = preferences.getInt("pc").toDouble();
        min = 1;
        max = 80;
        prefix = false;
        suffix = false;
        units = true;
      });
    } else if (widget.value.toString() == "Vt") {
      setState(() {
        commomValue = preferences.getInt("vt").toDouble();
        min = 200;
        max = 1200;
        prefix = false;
        suffix = false;
        units = true;
      });
    } else if (widget.value.toString() == "Target Vt") {
      setState(() {
        commomValue = preferences.getInt("vt").toDouble();
        min = 200;
        max = 1200;
        prefix = false;
        suffix = false;
        units = true;
      });
    }
    //
    else if (widget.value.toString() == "Backup RR") {
      setState(() {
        commomValue = preferences.getInt("rr").toDouble();
        commomValue1 = preferences.getInt("ie").toDouble();
        min = 1;
        max = 60;
        prefix = false;
        suffix = false;
        units = false;
      });
    } else if (widget.value.toString() == "Backup I:E") {
      setState(() {
        commomValue = preferences.getInt("ie").toDouble();
        commomValue1 = preferences.getInt("rr").toDouble();
        min = 1;
        max = 61;
        prefix = true;
        suffix = false;
        units = false;
      });
    }
  }

  getIeData(int pccmvIeValue, int res) {
    var data = pccmvIeValue == 1
        ? "4.0:1"
        : pccmvIeValue == 2
            ? "3.9:1"
            : pccmvIeValue == 3
                ? "3.8:1"
                : pccmvIeValue == 4
                    ? "3.7:1"
                    : pccmvIeValue == 5
                        ? "3.6:1"
                        : pccmvIeValue == 6
                            ? "3.5:1"
                            : pccmvIeValue == 7
                                ? "3.4:1"
                                : pccmvIeValue == 8
                                    ? "3.3:1"
                                    : pccmvIeValue == 9
                                        ? "3.2:1"
                                        : pccmvIeValue == 10
                                            ? "3.1:1"
                                            : pccmvIeValue == 11
                                                ? "3.0:1"
                                                : pccmvIeValue == 12
                                                    ? "2.9:1"
                                                    : pccmvIeValue == 13
                                                        ? "2.8:1"
                                                        : pccmvIeValue == 14
                                                            ? "2.7:1"
                                                            : pccmvIeValue == 15
                                                                ? "2.6:1"
                                                                : pccmvIeValue ==
                                                                        16
                                                                    ? "2.5:1"
                                                                    : pccmvIeValue ==
                                                                            17
                                                                        ? "2.4:1"
                                                                        : pccmvIeValue ==
                                                                                18
                                                                            ? "2.3:1"
                                                                            : pccmvIeValue == 19
                                                                                ? "2.2:1"
                                                                                : pccmvIeValue == 20 ? "2.1:1" : pccmvIeValue == 21 ? "2.0:1" : pccmvIeValue == 22 ? "1.9:1" : pccmvIeValue == 23 ? "1.8:1" : pccmvIeValue == 24 ? "1.7:1" : pccmvIeValue == 25 ? "1.6:1" : pccmvIeValue == 26 ? "1.5:1" : pccmvIeValue == 27 ? "1.4:1" : pccmvIeValue == 28 ? "1.3:1" : pccmvIeValue == 29 ? "1.2:1" : pccmvIeValue == 30 ? "1.1:1" : pccmvIeValue == 31 ? "1:1" : pccmvIeValue == 32 ? "1:1.1" : pccmvIeValue == 33 ? "1:1.2" : pccmvIeValue == 34 ? "1:1.3" : pccmvIeValue == 35 ? "1:1.4" : pccmvIeValue == 36 ? "1:1.5" : pccmvIeValue == 37 ? "1:1.6" : pccmvIeValue == 38 ? "1:1.7" : pccmvIeValue == 39 ? "1:1.8" : pccmvIeValue == 40 ? "1:1.9" : pccmvIeValue == 41 ? "1:2.0" : pccmvIeValue == 42 ? "1:2.1" : pccmvIeValue == 43 ? "1:2.2" : pccmvIeValue == 44 ? "1:2.3" : pccmvIeValue == 45 ? "1:2.4" : pccmvIeValue == 46 ? "1:2.5" : pccmvIeValue == 47 ? "1:2.6" : pccmvIeValue == 48 ? "1:2.7" : pccmvIeValue == 49 ? "1:2.8" : pccmvIeValue == 50 ? "1:2.9" : pccmvIeValue == 51 ? "1:3.0" : pccmvIeValue == 52 ? "1:3.1" : pccmvIeValue == 53 ? "1:3.2" : pccmvIeValue == 54 ? "1:3.3" : pccmvIeValue == 55 ? "1:3.4" : pccmvIeValue == 56 ? "1:3.5" : pccmvIeValue == 57 ? "1:3.6" : pccmvIeValue == 58 ? "1:3.7" : pccmvIeValue == 59 ? "1:3.8" : pccmvIeValue == 60 ? "1:3.9" : pccmvIeValue == 61 ? "1:4.0" : "0".toString();

    var dataI = data.split(":")[0];
    var dataE = data.split(":")[1];
    if (res == 1) {
      return data;
    } else if (res == 2) {
      // print(dataI);
      return dataI;
    } else if (res == 3) {
      // print(dataE);
      return dataE;
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
        height: 400.0,
        width: 500.0,
        child: commomValue != null
            ? Stack(
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
                        widget.value.toString()=="eRR"?"RR" :widget.value.toString(),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              IconButton(icon: Icon(Icons.remove,size: 50,),onPressed: (){
                                if(commomValue.ceil().toInt()>=min.toInt()){
                                  setState(() {
                                    if(commomValue.toInt()==min.toInt()){
                                      commomValue = min;
                                    }else{
                                    commomValue = commomValue-1.0;
                                    }
                                  });
                                }
                              },),
                              SizedBox(width:120),
                              Text(
                                prefix
                                    ? getIeData(commomValue.toInt(), 1).toString()
                                    : suffix
                                        ? commomValue.ceil().toString() + "%"
                                        : commomValue.ceil().toString(),
                                style: TextStyle(fontSize: 40),
                              ),
                              SizedBox(width:120),
                              IconButton(icon: Icon(Icons.add,size: 50,),onPressed: (){
                                if(commomValue.ceil().toInt()<=max.toInt()){
                                  setState(() {
                                    if(commomValue.ceil().toInt()==max.toInt()){
                                      commomValue = max;
                                    }else{
                                    commomValue = commomValue+1.0;
                                    }
                                  });
                                }
                              },),
                            ],
                          ),
                          Text(widget.value.toString() == "RR" || widget.value.toString() == "eRR"
                              ? "I:E = " +
                                  getIeData(commomValue1.toInt(), 1).toString()
                              : widget.value.toString() == "I:E"
                              ? "RR = " + commomValue1.toInt().toString():""),
                          // Text(widget.value.toString() == "I:E"
                          //     ? "RR = " + commomValue1.toInt().toString()
                          //     : ""),
                          SizedBox(
                            height: 5,
                          ),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(widget.value.toString() == "I:E" ? "Min "+getIeData(min.toInt(),1) :"Min "+min.toInt().toString()),
                              Text(widget.value.toString() == "I:E" ? "Max "+getIeData(max.toInt(),1) :"Max "+max.toInt().toString()),
                            ],
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
                                  ? commomValue.ceil().toString()
                                  : suffix
                                      ? commomValue.ceil().toString() + "%"
                                      : commomValue.ceil().toString(),
                            ),
                          ),
                         
                          Text(
                                  widget.value.toString() == "RR" || widget.value.toString() == "eRR"
                                      ? calculateRrIe(commomValue, commomValue1)
                                      : widget.value.toString() == "I:E"
                                      ? calculateIeRr(commomValue, commomValue1):"",
                                  style: TextStyle(fontSize: 25)),
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
              )
            : Container(),
      ),
    );
  }

  void writeData(double value) async {
    if (widget.value.toString() == "RR") {
      setState(() {
        preferences.setInt("rr", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "rr");
    }else if (widget.value.toString() == "eRR") {
      setState(() {
        preferences.setInt("rr", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "rr");
    }  else if (widget.value.toString() == "Backup RR") {
      setState(() {
        preferences.setInt("rr", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "rr");
    } else if (widget.value.toString() == "I:E") {
      setState(() {
        preferences.setInt("ie", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "ie");
    } else if (widget.value.toString() == "Backup I:E") {
      setState(() {
        preferences.setInt("ie", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "ie");
    } else if (widget.value.toString() == "PEEP") {
      setState(() {
        preferences.setInt("peep", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "peep");
    } else if (widget.value.toString() == "PS") {
      setState(() {
        preferences.setInt("ps", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "ps");
    } else if (widget.value.toString() == "FiO2") {
      setState(() {
        preferences.setInt("fio2", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "fio2");
    } else if (widget.value.toString() == "PC") {
      setState(() {
        preferences.setInt("pc", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "pc");
    } else if (widget.value.toString() == "Vt") {
      setState(() {
        preferences.setInt("vt", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "vt");
    } else if (widget.value.toString() == "Target Vt") {
      setState(() {
        preferences.setInt("vt", value.ceil());
      });
      Navigator.pop(context, value.ceil().toString() + "ab" + "vt");
    }
  }

  String calculateRrIe(double commomValue, double commomValue1) {
    var dataI = getIeData(commomValue1.toInt(), 2);
    var dataI1 = double.tryParse(dataI);

    var dataE = getIeData(commomValue1.toInt(), 3);
    var dataE1 = double.tryParse(dataE);

    tiValue = (((dataI1 / (dataI1 + dataE1)) * (60000 / commomValue)) / 1000);
    // print(tiValue.toString());
    teValue = (((dataE1 / (dataI1 + dataE1)) * (60000 / commomValue)) / 1000);

    return "Ti : " +
        tiValue.toStringAsFixed(1) +
        "s" +
        " : " +
        "Te : " +
        teValue.toStringAsFixed(1) +
        "s";
  }

  calculateIeRr(double commomValue, double commomValue1) {
    var dataI = getIeData(commomValue.toInt(), 2);
    var dataI1 = double.tryParse(dataI);

    var dataE = getIeData(commomValue.toInt(), 3);
    var dataE1 = double.tryParse(dataE);

    tiValue = (((dataI1 / (dataI1 + dataE1)) * (60000 / commomValue1)) / 1000);
    // print(tiValue.toString());
    teValue = (((dataE1 / (dataI1 + dataE1)) * (60000 / commomValue1)) / 1000);

    return "Ti : " +
        tiValue.toStringAsFixed(1) +
        "s" +
        " : " +
        "Te : " +
        teValue.toStringAsFixed(1) +
        "s";
  }
}
