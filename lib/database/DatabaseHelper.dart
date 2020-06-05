import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'VentilatorOMode.dart';

class DatabaseHelper {
  static Database _db;
  static const String ID = 'id';
  static const String PATIENTID = 'patientId';
  static const String PATIENTNAME = 'patientName';
  static const String ALARM = 'alarmCodes';
  static const String PIPD = 'pipD';
  static const String VTD = 'vtD';
  static const String PEEPD = 'peepD';
  static const String RRD = 'rrD';
  static const String FIO2D = 'fio2D';
  static const String MAPD = 'mapD';
  static const String MVD = 'mvD';
  static const String COMPLAINCED = 'complainceD';
  static const String IED = 'ieD';
  static const String RRS = 'rrS';
  static const String IES = 'ieS';
  static const String PEEPS = 'peepS';
  static const String PSS = 'psS';
  static const String FIO2S = 'fio2S';
  static const String TIS = 'tiS';
  static const String TES = 'teS';
  static const String PRESSURE_POINTS = 'pressureP';
  static const String FLOW_POINTS = 'flowP';
  static const String VOLUME_POINTS = 'volumeP';
  static const String DATE_TIME = 'datetimeP';
  static const String OPERATING_MODE = 'operatingMode';
  static const String LUNG_IMAGE = 'lungImage';
  static const String PAW = 'paw';
  static const String GLOBAL_COUNTER_NO = 'globalCounterNo';

  static const String COUNTER_NO = 'counterNo';
  // static const String DATE_TIME = 'datetime';
  static const String PATIENT_ID = 'patientId';
  static const String PATIENT_NAME = 'patientName';
  static const String PATIENT_AGE = 'patientAge';
  static const String PATIENT_GENDER = 'patientGender';
  static const String PATIENT_HEIGHT = 'patientHeight';
  static const String TABLE_PATIENT = 'patientTb';
  static const String TABLE_NAME = 'counterV';
  static const String TABLE_ALARM = 'alarms';
  static const String TABLE = 'graphPoints';
  static const String DATABASE = 'vdb';

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
    await db.execute(
        'CREATE TABLE $TABLE($ID INTEGER PRIMARY KEY AUTOINCREMENT, $PATIENTID TEXT, $PATIENTNAME TEXT,$PIPD TEXT, $VTD TEXT,$PEEPD TEXT, $RRD TEXT,$FIO2D TEXT,$MAPD TEXT,$MVD TEXT,$COMPLAINCED TEXT, $IED TEXT,$RRS TEXT,$IES TEXT,$PEEPS TEXT,$PSS TEXT,$FIO2S TEXT,$TIS TEXT,$TES TEXT,$PRESSURE_POINTS REAL, $FLOW_POINTS REAL, $VOLUME_POINTS REAL, $DATE_TIME TEXT,$OPERATING_MODE TEXT,$LUNG_IMAGE TEXT,$PAW TEXT,$GLOBAL_COUNTER_NO TEXT)');
    // await db.execute('CREATE TABLE $TABLE_ALARM($ID INTERGER PRIMARY KEY AUTOINCREMENT,$ALARM TEXT,$DATE_TIME TEXT)');
    await db.execute(
        'CREATE TABLE $TABLE_NAME($ID INTERGER PRIMARY KEY,$COUNTER_NO TEXT,$DATE_TIME TEXT)');
    await db.execute(
        'CREATE TABLE $TABLE_PATIENT($ID INTERGER PRIMARY KEY,$PATIENT_ID TEXT,$PATIENT_NAME TEXT,$PATIENT_AGE TEXT,$PATIENT_GENDER TEXT,$PATIENT_HEIGHT TEXT,$DATE_TIME TEXT)');
    await db.execute(
        'CREATE TABLE $TABLE_ALARM($ID INTERGER PRIMARY KEY,$ALARM TEXT,$DATE_TIME TEXT)');
  }

  Future<int> save(VentilatorOMode vom) async {
    var now = new DateTime.now();
    try {
      var dbClient = await db;
      var res = await dbClient.rawInsert(
          "INSERT into $TABLE ($PATIENTID,$PATIENTNAME,$PIPD,$VTD, $PEEPD, $RRD, $FIO2D, $MAPD, $MVD, $COMPLAINCED,$IED, $RRS, $IES, $PEEPS, $PSS, $FIO2S,$TIS, $TES,$PRESSURE_POINTS,$FLOW_POINTS, $VOLUME_POINTS,$DATE_TIME,$OPERATING_MODE,$LUNG_IMAGE,$PAW,$GLOBAL_COUNTER_NO) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
          [
            vom.patientId,
            vom.patientName,
            vom.pipD,
            vom.vtD,
            vom.peepD,
            vom.rrD,
            vom.fio2D,
            vom.mapD,
            vom.mvD,
            vom.complainceD,
            vom.ieD,
            vom.rrS,
            vom.ieS,
            vom.peepS,
            vom.psS,
            vom.fio2S,
            vom.tiS,
            vom.teS,
            vom.pressureValues,
            vom.flowValues,
            vom.volumeValues,
            DateFormat("yyyy-MM-dd HH:mm:ss").format(now),
            vom.operatingMode,
            vom.lungImage,
            vom.paw,
            vom.globalCounterNo
          ]);
      // print("result data : " + res.toString());
      // Fluttertoast.showToast(msg: " data saved in db "+res.toString());
      return res;
    } catch (Exception) {
      return null;
    }
  }

  Future<List<PatientsList>> getAllPatients() async {
    var dbClient = await db;
     // List<Map> dataData = await dbClient.rawQuery('SELECT DISTINCT $PATIENTID, $PATIENTNAME, MIN($DATE_TIME) minTime, MAX($DATE_TIME) maxTime FROM $TABLE group by $PATIENTID ORDER BY $ID ASC');
          List<Map> dataData = await dbClient.rawQuery('SELECT $PATIENTID,$PATIENTNAME from $TABLE GROUP BY $GLOBAL_COUNTER_NO ORDER BY $ID DESC');
    List<PatientsList> plist = [];
    if (dataData.length > 0) {
      for (int i = 0; i < dataData.length; i++) {
        plist.add(PatientsList.fromMap(dataData[i]));
      }
    }
    return plist;
  }


  // Future<List<PatientsList>> getAllPatients() async {
  //   var dbClient = await db;
  //   List<Map> dataData = await dbClient.rawQuery(
  //       'SELECT DISTINCT $PATIENTID, $PATIENTNAME, MIN($DATE_TIME) minTime, MAX($DATE_TIME) maxTime FROM $TABLE group by $PATIENTID ORDER BY $ID ASC');
  //   List<PatientsList> plist = [];
  //   if (dataData.length > 0) {
  //     for (int i = 0; i < dataData.length; i++) {
  //       plist.add(PatientsList.fromMap(dataData[i]));
  //     }
  //   }
  //   return plist;
  // }

  Future<List<VentilatorOMode>> getPatientsDates(String patientIdD) async {
    var dbClient = await db;
    //  SELECT * FROM graphPoints WHERE patientId="p002" and datetimeP BETWEEN "24-01-2010 09:02:23"  AND "24-01-2010 09:02:54"
    List<Map> dataData = await dbClient.rawQuery(
        'SELECT $DATE_TIME FROM (SELECT $DATE_TIME FROM $TABLE GROUP BY $GLOBAL_COUNTER_NO WHERE $PATIENTID=\'$patientIdD\') gcn WHERE GROUP BY $DATE_TIME');
    List<VentilatorOMode> plist = [];
    if (dataData.length > 0) {
      for (int i = 0; i < dataData.length; i++) {
        plist.add(VentilatorOMode.fromMap(dataData[i]));
      }
    }
    return plist;
  }

  // Future<List<VentilatorOMode>> getPatientsData(String patientIdD,String fromDate,String toDate) async {
  //    var dbClient = await db;
  //   //  SELECT * FROM graphPoints WHERE patientId="p002" and datetimeP BETWEEN "24-01-2010 09:02:23"  AND "24-01-2010 09:02:54"
  //   List<Map> dataData= await dbClient.rawQuery('SELECT * FROM $TABLE where $PATIENTID=\'$patientIdD\' AND $DATE_TIME BETWEEN \'$fromDate\' AND \'$toDate\'');
  //   List<VentilatorOMode> plist =[];
  //   if(dataData.length>0){
  //     for(int i=0; i<dataData.length;i++){
  //       plist.add(VentilatorOMode.fromMap(dataData[i]));
  //     }
  //   }
  //   return plist;
  // }

  Future<int> delete(int id) async {
    var dbClient = await db;
    var result = await dbClient.rawDelete('DELETE FROM $TABLE WHERE $ID = id');
    return result;
  }

  Future close() async {
    var dbClient = await db;
    dbClient.close();
  }
}
