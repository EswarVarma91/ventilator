import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/database/DatabaseHelper.dart';
import 'package:ventilator/database/VentilatorOMode.dart';
import 'package:virtual_keyboard/virtual_keyboard.dart';

class NewTreatmentScreen extends StatefulWidget {
  @override
  _NewTreatmentScreenState createState() => _NewTreatmentScreenState();
}

class _NewTreatmentScreenState extends State<NewTreatmentScreen> {
  TextEditingController patientId = TextEditingController();
  TextEditingController nameId = TextEditingController();
  TextEditingController ageId = TextEditingController();
  TextEditingController heightId = TextEditingController();
  TextEditingController weightId = TextEditingController();
  // bool isNumericMode = false;
  // bool keyboardEnable = false;
  // bool patientIdEnable = false;
  // bool nameEnable = false;
  // bool shiftEnabled = false;
  bool maleEnabled = true;
  bool femaleEnabled = false;
  // bool ageEnabled = false;
  bool heightEnabled = false;
  bool adultEnabled = true;
  bool pediatricEnabled = false;
  double commonValue = 0;
  String calculatingIn = "cm";
  SharedPreferences preferences;
  var dbHelper = DatabaseHelper();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      size: 25,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Dashboard()),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 28.0),
                  child: Text(
                    "New Patient",
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        heightEnabled = false;
                      });
                    },
                    child: Container(
                      width: 210,
                      child: TextFormField(
                        autofocus: true,
                        showCursor: true,
                        onTap: () {
                          setState(() {
                            heightEnabled = false;
                          });
                        },
                        controller: nameId,
                        decoration: InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        heightEnabled = false;
                      });
                    },
                    child: Container(
                      width: 210,
                      child: TextFormField(
                        showCursor: true,
                        onTap: () {
                          setState(() {
                            heightEnabled = false;
                          });
                        },
                        controller: patientId,
                        cursorColor: Color(0xFF171e27),
                        decoration: InputDecoration(
                          labelText: "Patient ID",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                      width: 200,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                maleEnabled = true;
                                femaleEnabled = false;
                                // keyboardEnable = true;
                              });
                            },
                            child: Material(
                              child: Card(
                                  color: maleEnabled
                                      ? Color(0xFF171e27)
                                      : Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(22.0),
                                    child: Text(
                                      "Male",
                                      style: TextStyle(
                                          color: maleEnabled
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                                  )),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                maleEnabled = false;
                                femaleEnabled = true;
                                // keyboardEnable = true;
                              });
                            },
                            child: Material(
                              child: Card(
                                  color: femaleEnabled
                                      ? Color(0xFF171e27)
                                      : Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(22.0),
                                    child: Text(
                                      "Female",
                                      style: TextStyle(
                                          color: femaleEnabled
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                                  )),
                            ),
                          ),
                        ],
                      )),
                  Padding(
                    padding: const EdgeInsets.only(left: 25.0),
                    child: Container(
                        width: 230,
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  adultEnabled = true;
                                  pediatricEnabled = false;
                                  // keyboardEnable = true;
                                });
                              },
                              child: Material(
                                child: Card(
                                    color: adultEnabled
                                        ? Color(0xFF171e27)
                                        : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(22.0),
                                      child: Text(
                                        "Adult",
                                        style: TextStyle(
                                            color: adultEnabled
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    )),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  adultEnabled = false;
                                  pediatricEnabled = true;
                                  // keyboardEnable = true;
                                });
                              },
                              child: Material(
                                child: Card(
                                    color: pediatricEnabled
                                        ? Color(0xFF171e27)
                                        : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(22.0),
                                      child: Text(
                                        "Pediatric",
                                        style: TextStyle(
                                            color: pediatricEnabled
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    )),
                              ),
                            ),
                          ],
                        )),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 36, right: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        heightEnabled = false;
                        // FocusScope.of(context).unfocus();
                      });
                    },
                    child: Container(
                      width: 250,
                      child: TextFormField(
                        showCursor: true,
                        maxLength: 3,
                        maxLines: 1,
                        keyboardType: TextInputType.number,
                        controller: ageId,
                        onTap: () {},
                        onChanged: (value) {
                          if (value.length >= 3) {
                            Fluttertoast.showToast(
                                msg: "Only 3 digits allowed");
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Age",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            heightEnabled = true;
                            FocusScope.of(context).unfocus();
                          });
                        },
                        child: Container(
                          width: 120,
                          child: TextFormField(
                            showCursor: true,
                            readOnly: true,
                            enabled: false,
                            maxLines: 1,
                            controller: heightId,
                            decoration: InputDecoration(
                              labelText: "Height",
                              suffixText: calculatingIn,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            heightEnabled = true;
                            FocusScope.of(context).unfocus();
                          });
                        },
                        child: Container(
                          width: 120,
                          child: TextFormField(
                            showCursor: true,
                            readOnly: true,
                            enabled: false,
                            maxLines: 1,
                            controller: weightId,
                            decoration: InputDecoration(
                              labelText: "IBW",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      savePatientData();
                    },
                    child: Container(
                      width: 250,
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
                ],
              ),
            ),
            Container(
              height: heightEnabled ? 0 : 21,
            ),
            // keyboardEnable
            //     ?
            heightEnabled
                ? Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 310,
                          child: CupertinoPicker(
                              itemExtent: 30,
                              onSelectedItemChanged: (int index) {
                                setState(() {
                                  heightId.text =
                                      getDataheight(index).toString();
                                  if (getDataheight(index) <= 70) {
                                    setState(() {
                                      weightId.text =
                                          ((0.125 * getDataheight(index)) -
                                                  0.75)
                                              .toInt()
                                              .toString();
                                    });
                                  } else if (70 < getDataheight(index) &&
                                      getDataheight(index) <= 128) {
                                    setState(() {
                                      weightId.text =
                                          (((0.0037 * getDataheight(index) -
                                                          0.4018) *
                                                      getDataheight(index)) +
                                                  18.62)
                                              .toInt()
                                              .toString();
                                    });
                                  } else if (getDataheight(index) >= 129) {
                                    setState(() {
                                      maleEnabled == true
                                          ? weightId.text =
                                              ((0.9079 * getDataheight(index)) -
                                                      88.022)
                                                  .toInt()
                                                  .toString()
                                          : femaleEnabled == true
                                              ? weightId.text = ((0.9049 *
                                                          getDataheight(
                                                              index)) -
                                                      88.022)
                                                  .toInt()
                                                  .toString()
                                              : 0.toString();
                                    });
                                  }
                                });
                              },
                              children: List.generate(
                                  67,
                                  (index) => Center(
                                        child: Text(
                                            (getDataheight(index)).toString()),
                                      ))),
                        ),
                      ),
                    ],
                  )
                : Container()
            // : Align(
            //     alignment: Alignment.bottomCenter,
            //     child: Container(
            //       color: Color(0xFF171e27),
            //       child: VirtualKeyboard(
            //           height: 308,
            //           textColor: Colors.white,
            //           type: isNumericMode
            //               ? VirtualKeyboardType.Numeric
            //               : VirtualKeyboardType.Alphanumeric,
            //           onKeyPress: _onKeyPress),
            //     ),
            //   )
          ],
        ),
      ),
    );
  }

  getDataheight(index) {
    return index == 0
        ? 134
        : index == 1
            ? 135
            : index == 2
                ? 136
                : index == 3
                    ? 137
                    : index == 4
                        ? 138
                        : index == 5
                            ? 139
                            : index == 6
                                ? 140
                                : index == 7
                                    ? 141
                                    : index == 8
                                        ? 142
                                        : index == 9
                                            ? 143
                                            : index == 10
                                                ? 144
                                                : index == 12
                                                    ? 145
                                                    : index == 12
                                                        ? 146
                                                        : index == 13
                                                            ? 147
                                                            : index == 14
                                                                ? 148
                                                                : index == 15
                                                                    ? 149
                                                                    : index ==
                                                                            16
                                                                        ? 150
                                                                        : index ==
                                                                                17
                                                                            ? 151
                                                                            : index == 18
                                                                                ? 152
                                                                                : index == 19 ? 153 : index == 20 ? 154 : index == 21 ? 155 : index == 22 ? 156 : index == 23 ? 157 : index == 24 ? 158 : index == 25 ? 159 : index == 26 ? 160 : index == 27 ? 161 : index == 28 ? 162 : index == 29 ? 163 : index == 30 ? 164 : index == 31 ? 165 : index == 32 ? 166 : index == 33 ? 167 : index == 34 ? 168 : index == 35 ? 169 : index == 36 ? 170 : index == 37 ? 171 : index == 38 ? 172 : index == 39 ? 173 : index == 40 ? 174 : index == 41 ? 175 : index == 42 ? 176 : index == 43 ? 177 : index == 44 ? 178 : index == 45 ? 179 : index == 46 ? 170 : index == 47 ? 181 : index == 48 ? 182 : index == 49 ? 183 : index == 50 ? 184 : index == 51 ? 185 : index == 52 ? 186 : index == 53 ? 187 : index == 54 ? 188 : index == 55 ? 189 : index == 56 ? 190 : index == 57 ? 191 : index == 58 ? 192 : index == 59 ? 193 : index == 60 ? 194 : index == 61 ? 195 : index == 62 ? 196 : index == 63 ? 197 : index == 64 ? 198 : index == 65 ? 199 : index == 66 ? 200 : "";
  }

  // /// Fired when the virtual keyboard key is pressed.
  // _onKeyPress(VirtualKeyboardKey key) {
  //   if (patientIdEnable == true) {
  //     setState(() {
  //       if (key.keyType == VirtualKeyboardKeyType.String) {
  //         patientId.text =
  //             patientId.text + (shiftEnabled ? key.capsText : key.text);
  //       } else if (key.keyType == VirtualKeyboardKeyType.Action) {
  //         switch (key.action) {
  //           case VirtualKeyboardKeyAction.Backspace:
  //             if (patientId.text.length == 0) return;
  //             patientId.text =
  //                 patientId.text.substring(0, patientId.text.length - 1);
  //             break;
  //           // case VirtualKeyboardKeyAction.Return:
  //           //   patientId.text = patientId.text + '\n';
  //           //   break;
  //           case VirtualKeyboardKeyAction.Space:
  //             patientId.text = patientId.text + key.text;
  //             break;
  //           case VirtualKeyboardKeyAction.Shift:
  //             shiftEnabled = !shiftEnabled;
  //             break;
  //           default:
  //         }
  //       }
  //     });

  //     // Update the screen
  //     setState(() {});
  //   } else if (nameEnable == true) {
  //     setState(() {
  //       if (key.keyType == VirtualKeyboardKeyType.String) {
  //         nameId.text = nameId.text + (shiftEnabled ? key.capsText : key.text);
  //       } else if (key.keyType == VirtualKeyboardKeyType.Action) {
  //         switch (key.action) {
  //           case VirtualKeyboardKeyAction.Backspace:
  //             if (nameId.text.length == 0) return;
  //             nameId.text = nameId.text.substring(0, nameId.text.length - 1);
  //             break;
  //           // case VirtualKeyboardKeyAction.Return:
  //           //   patientId.text = patientId.text + '\n';
  //           //   break;
  //           case VirtualKeyboardKeyAction.Space:
  //             nameId.text = nameId.text + key.text;
  //             break;
  //           case VirtualKeyboardKeyAction.Shift:
  //             shiftEnabled = !shiftEnabled;
  //             break;
  //           default:
  //         }
  //       }
  //     });

  //     // Update the screen
  //     setState(() {});
  //   } else if (ageEnabled == true) {
  //     setState(() {
  //       if (key.keyType == VirtualKeyboardKeyType.String) {
  //         ageId.text = ageId.text + (shiftEnabled ? key.capsText : key.text);
  //       } else if (key.keyType == VirtualKeyboardKeyType.Action) {
  //         switch (key.action) {
  //           case VirtualKeyboardKeyAction.Backspace:
  //             if (ageId.text.length == 0) return;
  //             ageId.text = ageId.text.substring(0, ageId.text.length - 1);
  //             break;
  //           // case VirtualKeyboardKeyAction.Return:
  //           //   patientId.text = patientId.text + '\n';
  //           //   break;
  //           case VirtualKeyboardKeyAction.Space:
  //             ageId.text = ageId.text + key.text;
  //             break;
  //           case VirtualKeyboardKeyAction.Shift:
  //             shiftEnabled = !shiftEnabled;
  //             break;
  //           default:
  //         }
  //       }
  //     });
  //   }
  // }

  savePatientData() async {
    if (patientId.text.isEmpty) {
    } else if (nameId.text.isEmpty) {
    } else {
      dbHelper.savePatient(PatientsSaveList(patientId.text, nameId.text,
          ageId.text, maleEnabled ? "1" : "2", heightId.text));
      preferences = await SharedPreferences.getInstance();
      preferences.setString("pid", patientId.text.toString());
      preferences.setString("pname", nameId.text.toString());
      preferences.setString(
          "pgender", maleEnabled ? "1" : femaleEnabled ? "2" : "0");
      preferences.setString(
          "pmode", adultEnabled ? "1" : pediatricEnabled ? "2" : "0");
      preferences.setString("page", ageId.text.toString());
      preferences.setString("pheight", heightId.text.toString());
      preferences.setString("pweight", weightId.text.toString());
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Dashboard()),
      );
    }
  }
}
