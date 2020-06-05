import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ventilator/activity/Dashboard.dart';
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
  bool isNumericMode = false;
  bool keyboardEnable = false;
  bool patientIdEnable = false;
  bool nameEnable = false;
  bool shiftEnabled = false;
  bool maleEnabled = true;
  bool femaleEnabled = false;
  bool ageEnabled = false;
  bool heightEnabled = false;
  bool adultEnabled= true;
  bool pediatricEnabled = false;
  double commonValue = 0;
  String calculatingIn = "cm";
  SharedPreferences preferences;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body:  Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 10,),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left:12.0,),
                    child: IconButton(icon: Icon(Icons.arrow_back,size: 25,),onPressed: (){
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Dashboard()),
                      );
                    },),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left:28.0),
                    child: Text("New Patient",style: TextStyle(color: Colors.black,fontSize: 20),),
                  )
                ],
              ),
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.only(left:25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          keyboardEnable = false;
                          patientIdEnable = false;
                          nameEnable = true;
                          isNumericMode = false;
                          ageEnabled = false;
                          heightEnabled = false;
                        });
                      },
                      child: Container(
                        width: 210,
                        child: TextFormField(
                          showCursor: true,
                          readOnly: true,
                          onTap: () {
                            setState(() {
                              keyboardEnable = false;
                              patientIdEnable = false;
                              nameEnable = true;
                              isNumericMode = false;
                              ageEnabled = false;
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
                          keyboardEnable = false;
                          patientIdEnable = true;
                          nameEnable = false;
                          ageEnabled = false;
                          isNumericMode = false;
                          heightEnabled = false;
                        });
                      },
                      child: Container(
                        width: 210,
                        child: TextFormField(
                          showCursor: true,
                          readOnly: true,
                          onTap: () {
                            setState(() {
                              keyboardEnable = false;
                              patientIdEnable = true;
                              nameEnable = false;
                              ageEnabled = false;
                              isNumericMode = false;
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
                                  keyboardEnable = true;
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
                                  keyboardEnable = true;
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
                          padding: const EdgeInsets.only(left:25.0),
                          child: Container(
                          width: 230,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    adultEnabled = true;
                                    pediatricEnabled = false;
                                    keyboardEnable = true;
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
                                    keyboardEnable = true;
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
                padding: const EdgeInsets.only(left:25.0,top: 36,right: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          keyboardEnable = false;
                          isNumericMode = true;
                          ageEnabled = true;
                          patientIdEnable = false;
                          nameEnable = false;
                          heightEnabled = false;
                        });
                      },
                      child: Container(
                        width: 250,
                        child: TextFormField(
                          showCursor: true,
                          readOnly: true,
                          maxLength: 3,
                          maxLines: 1,
                          controller: ageId,
                          onTap: () {
                            setState(() {
                              keyboardEnable = false;
                              isNumericMode = true;
                              ageEnabled = true;
                              patientIdEnable = false;
                              nameEnable = false;
                            });
                          },
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
                              keyboardEnable = true;
                              isNumericMode = true;
                              ageEnabled = true;
                              patientIdEnable = false;
                              nameEnable = false;
                              heightEnabled = true;
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
                              keyboardEnable = true;
                              isNumericMode = true;
                              ageEnabled = true;
                              patientIdEnable = false;
                              nameEnable = false;
                              heightEnabled = true;
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
              keyboardEnable
                  ? heightEnabled
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
                                        heightId.text = index.toString();
                                        if (index <= 70) {
                                          setState(() {
                                            weightId.text =((0.125 * index) - 0.75).toInt().toString();
                                          });
                                        } else if (70 < index && index <= 128) {
                                          setState(() {
                                            weightId.text =(((0.0037 * index - 0.4018) *index) + 18.62).toInt().toString();
                                          });
                                        } else if (index >= 129) {
                                          setState(() {
                                            maleEnabled == true ? weightId.text =((0.9079 * index) - 88.022).toInt().toString()
                                                : femaleEnabled == true ? weightId.text =((0.9049 * index) -88.022).toInt().toString()
                                                    : 0.toString();
                                          });
                                        }
                                      });
                                    },
                                    children: List.generate(
                                        200,
                                        (index) => Center(
                                              child: Text(index.toString()),
                                            ))),
                              ),
                            ),
                          ],
                        )
                      : Container()
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Color(0xFF171e27),
                        child: VirtualKeyboard(
                            height: 308,
                            textColor: Colors.white,
                            type: isNumericMode
                                ? VirtualKeyboardType.Numeric
                                : VirtualKeyboardType.Alphanumeric,
                            onKeyPress: _onKeyPress),
                      ),
                    )
            ],
          ),
        ),
    );
  }

  /// Fired when the virtual keyboard key is pressed.
  _onKeyPress(VirtualKeyboardKey key) {
    if (patientIdEnable == true) {
      setState(() {
        if (key.keyType == VirtualKeyboardKeyType.String) {
          patientId.text =
              patientId.text + (shiftEnabled ? key.capsText : key.text);
        } else if (key.keyType == VirtualKeyboardKeyType.Action) {
          switch (key.action) {
            case VirtualKeyboardKeyAction.Backspace:
              if (patientId.text.length == 0) return;
              patientId.text =
                  patientId.text.substring(0, patientId.text.length - 1);
              break;
            // case VirtualKeyboardKeyAction.Return:
            //   patientId.text = patientId.text + '\n';
            //   break;
            case VirtualKeyboardKeyAction.Space:
              patientId.text = patientId.text + key.text;
              break;
            case VirtualKeyboardKeyAction.Shift:
              shiftEnabled = !shiftEnabled;
              break;
            default:
          }
        }
      });

      // Update the screen
      setState(() {});
    } else if (nameEnable == true) {
      setState(() {
        if (key.keyType == VirtualKeyboardKeyType.String) {
          nameId.text = nameId.text + (shiftEnabled ? key.capsText : key.text);
        } else if (key.keyType == VirtualKeyboardKeyType.Action) {
          switch (key.action) {
            case VirtualKeyboardKeyAction.Backspace:
              if (nameId.text.length == 0) return;
              nameId.text = nameId.text.substring(0, nameId.text.length - 1);
              break;
            // case VirtualKeyboardKeyAction.Return:
            //   patientId.text = patientId.text + '\n';
            //   break;
            case VirtualKeyboardKeyAction.Space:
              nameId.text = nameId.text + key.text;
              break;
            case VirtualKeyboardKeyAction.Shift:
              shiftEnabled = !shiftEnabled;
              break;
            default:
          }
        }
      });

      // Update the screen
      setState(() {});
    } else if (ageEnabled == true) {
      setState(() {
        if (key.keyType == VirtualKeyboardKeyType.String) {
          ageId.text = ageId.text + (shiftEnabled ? key.capsText : key.text);
        } else if (key.keyType == VirtualKeyboardKeyType.Action) {
          switch (key.action) {
            case VirtualKeyboardKeyAction.Backspace:
              if (ageId.text.length == 0) return;
              ageId.text = ageId.text.substring(0, ageId.text.length - 1);
              break;
            // case VirtualKeyboardKeyAction.Return:
            //   patientId.text = patientId.text + '\n';
            //   break;
            case VirtualKeyboardKeyAction.Space:
              ageId.text = ageId.text + key.text;
              break;
            case VirtualKeyboardKeyAction.Shift:
              shiftEnabled = !shiftEnabled;
              break;
            default:
          }
        }
      });
    }
  }

  savePatientData() async {
    if (patientId.text.isEmpty) {
    } else if (nameId.text.isEmpty) {
    } else if (ageId.text.isEmpty) {
    } else if (maleEnabled == false && femaleEnabled == false) {
    } else if (int.tryParse(heightId.text)<=134 || int.tryParse(heightId.text)>=200) {
      Fluttertoast.showToast(msg: "Enter height between 134cm to 200cm");
    } else {
      preferences = await SharedPreferences.getInstance();
      preferences.setString("pid", patientId.text.toString());
      preferences.setString("pname", nameId.text.toString());
      preferences.setString(
          "pgender", maleEnabled ? "1" : femaleEnabled ? "2" : "0");
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
