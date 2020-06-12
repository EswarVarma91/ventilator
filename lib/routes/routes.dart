import 'package:flutter/material.dart';
import 'package:ventilator/activity/Dashboard.dart';
import 'package:ventilator/viewlog/ViewLogPatientList.dart';

Route routes(RouteSettings settings) {
  if (settings.name == '/dashboard') {
    return MaterialPageRoute(
      builder: (context) {
        return Dashboard();
      },
    );
  } else if (settings.name == '/patientsList') {
    return MaterialPageRoute(
      builder: (context) {
        return ViewLogPatientList();
      },
    );
  }
}
