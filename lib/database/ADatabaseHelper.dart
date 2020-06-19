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
  static const String GLOBAL_COUNTER_NO = 'globalCounterNo';
  static const String TABLE_ALARM ='alarmTable';
  static const String DATABASE = 'aalarmDb';

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
    await db.execute('CREATE TABLE $TABLE_ALARM($ID INTEGER PRIMARY KEY AUTOINCREMENT,$ALARM TEXT,$DATE_TIME TEXT,$GLOBAL_COUNTER_NO TEXT)');
  }


  Future<int> saveAlarm(AlarmsList al) async {
    var now = new DateTime.now();
    try{
      var dbClient = await db;
       var res = await dbClient.rawInsert(
          "INSERT into $TABLE_ALARM ($ALARM,$DATE_TIME,$GLOBAL_COUNTER_NO) VALUES (?,?,?)",
          [
            al.alarmCode,
            DateFormat("yyyy-MM-dd HH:mm:ss").format(now),
            al.globalCounterNo
          ]);
          // print("result data 1 : "+res.toString());

          return res;
    }catch(Exception){
      return null;
    }
  }

   Future<List<AlarmsList>> getAllAlarms() async {
     var dbClient = await db;
    List<Map> dataData= await dbClient.rawQuery('SELECT $ID,$ALARM,$DATE_TIME FROM $TABLE_ALARM GROUP BY $ALARM ORDER BY $ID DESC LIMIT 200');
    List<AlarmsList> plist =[];
    if(dataData.length>0){
      for(int i=0; i<dataData.length;i++){
        plist.add(AlarmsList.fromMap(dataData[i]));
      }
    }
    return plist;
  }

  Future<int> delete(int id) async {
    var dbClient = await db;
    var result = await dbClient.rawDelete('DELETE FROM $TABLE_ALARM WHERE $ID = id');
    return result;
  }

  Future<int> delete1Daysdata(String dateS) async {
    // var now = new DateTime.now();
    var now = DateFormat("dd-MM-yyyy HH:mm:ss").format(DateTime.parse(dateS));
    var dbClient = await db;
    String sql = "DELETE FROM $TABLE_ALARM WHERE $DATE_TIME <= date(\'$now\', '-1 day')";
    // DELETE FROM graphPoints WHERE datetimeP <= date('2020-06-19 20:20:12.00', '-1 day')
    var res = await dbClient.rawDelete(sql);
    return res;
  }

  Future close() async {
    var dbClient = await db;
    dbClient.close();
  }
}
