import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

class ConnectionPage extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionPage> {
  UsbPort _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  StreamSubscription<String> _subscription;
  Transaction<String> _transaction;
  int _deviceId;

  Future<bool> _connectTo(device) async {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port.close();
      _port = null;
    }

    if (device == null) {
      _deviceId = null;
      setState(() {
        _status = "Disconnected";
      });
      return true;
    }

    _port = await device.create();
    if (!await _port.open()) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }

    _deviceId = device.deviceId;
    await _port.setDTR(true);
    await _port.setRTS(true);
    await _port.setPortParameters(
        19200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    Transaction<Uint8List> transaction =
        Transaction.terminated(_port.inputStream, Uint8List.fromList([127]));

    transaction.stream.listen((event) async {
      eventSaveList(event);
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    _connectTo(devices[0]);
  }

  @override
  void initState() {
    super.initState();
    UsbSerial.usbEventStream.listen((UsbEvent event) {
      _getPorts();
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(),
    );
  }

  void eventSaveList(Uint8List event) {}
}
