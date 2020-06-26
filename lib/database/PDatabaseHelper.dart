import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'VentilatorOMode.dart';

class PDatabaseHelper {
  static Database _db;
  static const String ID = "id";
  static const String PATIENT_ID = 'patientId';
  static const String PATIENT_NAME = 'patientName';
  static const String PATIENT_AGE = 'patientAge';
  static const String PATIENT_GENDER = 'patientGender';
  static const String PATIENT_HEIGHT = 'patientHeight';
  static const String DATE_TIME = 'datetime';
  static const String TABLE_NAME ='apatientTb';
  static const String DATABASE = 'apatientDB';

  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  initDb() async {
    Directory directoryD = await getApplicationDocumentsDirectory();
    String path = join(directoryD.path, DATABASE);
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE $TABLE_NAME($ID INTERGER PRIMARY KEY,$PATIENT_ID TEXT,$PATIENT_NAME TEXT,$PATIENT_AGE TEXT,$PATIENT_GENDER TEXT,$PATIENT_HEIGHT TEXT,$DATE_TIME TEXT)');
  }


  Future<int> saveAlarm(PatientsSaveList asl) async {
    var now = new DateTime.now();
    try{
      var dbClient = await db;
       var res = await dbClient.rawInsert(
          "INSERT into $TABLE_NAME ($PATIENT_ID,$PATIENT_NAME,$PATIENT_AGE,$PATIENT_GENDER,$PATIENT_HEIGHT,$DATE_TIME) VALUES (?,?,?,?,?,?)",
          [
            asl.patientId,
            asl.patientName,
            asl.patientAge,
            asl.patientGender,
            asl.patientHeight,
            DateFormat("yyyy-MM-dd HH:mm:ss").format(now)
          ]);
          // print("result data 1 : "+res.toString());

          return res;
    }catch(Exception){
      return null;
    }
  }

  Future close() async {
    var dbClient = await db;
    dbClient.close();
  }
}
