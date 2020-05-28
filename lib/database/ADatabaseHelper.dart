import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'VentilatorOMode.dart';

class ADatabaseHelper {
  static Database _db;
  static const String ID = "id";
  static const String ALARM = 'alarmCodes';
  static const String DATE_TIME = 'datetime';
  static const String TABLE_ALARM ='alarms';
  static const String DATABASE = 'alarmDb';

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
    // await db.execute('CREATE TABLE $TABLE($ID INTEGER PRIMARY KEY AUTOINCREMENT, $PATIENTID TEXT, $PATIENTNAME TEXT, $PATIENTAGE TEXT, $PATIENTGENDER TEXT,$PATIENTHEIGHT TEXT,$PIPD TEXT, $VTD TEXT,$PEEPD TEXT, $RRD TEXT,$FIO2D TEXT,$MAPD TEXT,$MVD TEXT,$COMPLAINCED TEXT, $IED TEXT,$RRS TEXT,$IES TEXT,$PEEPS TEXT,$PSS TEXT,$FIO2S TEXT,$TIS TEXT,$TES TEXT,$PRESSURE_POINTS REAL, $FLOW_POINTS REAL, $VOLUME_POINTS REAL, $DATE_TIME TEXT,$OPERATING_MODE TEXT,$LUNG_IMAGE TEXT,$PAW TEXT)');
    await db.execute('CREATE TABLE $TABLE_ALARM($ID INTERGER PRIMARY KEY,$ALARM TEXT,$DATE_TIME TEXT)');
    // await db.execute("CREATE TABLE "+TABLE_ALARM+" ("+ID+" INTEGER PRIMARY KEY AUTOINCREMENT)",$ALARM)
  }


  Future<int> saveAlarm(AlarmsList al) async {
    var now = new DateTime.now();
    try{
      var dbClient = await db;
       var res = await dbClient.rawInsert(
          "INSERT into $TABLE_ALARM ($ALARM,$DATE_TIME) VALUES (?,?)",
          [
            al.alarmCode,
            DateFormat("yyyy-MM-dd HH:mm:ss").format(now)
          ]);
          print("result data 1 : "+res.toString());

          return res;
    }catch(Exception){
      return null;
    }
  }

   Future<List<AlarmsList>> getAllAlarms() async {
     var dbClient = await db;
    List<Map> dataData= await dbClient.rawQuery('SELECT $ID,$ALARM,$DATE_TIME FROM $TABLE_ALARM group by $ALARM ORDER BY $ID ASC LIMIT 200');
    List<AlarmsList> plist =[];
    if(dataData.length>0){
      for(int i=0; i<dataData.length;i++){
        plist.add(AlarmsList.fromMap(dataData[i]));
      }
    }
    return plist;
  }



  // Future<String> getLastRecordTime() async {
  //    var dbClient = await db;
  //   var dataData= await dbClient.rawQuery('SELECT $DATE_TIME FROM $TABLE ORDER BY $ID DESC LIMIT 1');
  //   return dataData.toString();
  // }

  // Future<List<PatientsList>> getAllPatients() async {
  //    var dbClient = await db;
  //   List<Map> dataData= await dbClient.rawQuery('SELECT DISTINCT $PATIENTID, $PATIENTNAME, MIN($DATE_TIME) minTime, MAX($DATE_TIME) maxTime FROM $TABLE group by $PATIENTID ORDER BY $ID ASC');
  //   List<PatientsList> plist =[];
  //   if(dataData.length>0){
  //     for(int i=0; i<dataData.length;i++){
  //       plist.add(PatientsList.fromMap(dataData[i]));
  //     }
  //   }
  //   return plist;
  // }

  

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
    var result = await dbClient.rawDelete('DELETE FROM $TABLE_ALARM WHERE $ID = id');
    return result;
  }

  Future close() async {
    var dbClient = await db;
    dbClient.close();
  }
}
