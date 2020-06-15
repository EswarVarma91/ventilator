import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'VentilatorOMode.dart';

class CounterDatabaseHelper {
  static Database _db;
  static const String ID = "id";
  static const String COUNTER_NO = 'counterNo';
  static const String DATE_TIME = 'datetime';
  static const String TABLE_NAME ='counterV';
  static const String DATABASE = 'counterDB';

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
    await db.execute('CREATE TABLE $TABLE_NAME($ID INTERGER PRIMARY KEY,$COUNTER_NO TEXT,$DATE_TIME TEXT)');
  }


  Future<int> saveCounter(CounterValue cl) async {
    var now = new DateTime.now();
    try{
      var dbClient = await db;
       var res = await dbClient.rawInsert(
          "INSERT into $TABLE_NAME ($ID, $COUNTER_NO,$DATE_TIME) VALUES (?,?,?)",
          [
            1,
            cl.counterValue,
            DateFormat("yyyy-MM-dd HH:mm:ss").format(now)
          ]);
          // print("result data 1 : "+res.toString());
          return res;
    }catch(Exception){
      return null;
    }
  }

  Future<List<CounterValue>> getCounterNo() async {
    var dbClient = await db;
    List<Map> data = await dbClient.rawQuery('SELECT * FROM $TABLE_NAME');
    // print(data);
    List<CounterValue> plist = [];
    if(data.length>0){
      for(int i=0; i<data.length;i++){
        plist.add(CounterValue.fromMap(data[i]));
      } 
    }
    return plist;
  }

  Future<String> updateCounterNo(String numberC) async{
     var now = new DateTime.now();
    var dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
    var dbClient = await db;
    var res =  await dbClient.rawUpdate('UPDATE $TABLE_NAME SET $COUNTER_NO=\'$numberC\',$DATE_TIME=\'$dateTime\' WHERE $ID=1');

    return res.toString();
  }



  //  Future<List<AlarmsList>> getAllAlarms() async {
  //    var dbClient = await db;
  //   List<Map> dataData= await dbClient.rawQuery('SELECT $ID,$ALARM,$DATE_TIME FROM $TABLE_ALARM group by $ALARM ORDER BY $ID ASC LIMIT 200');
  //   List<AlarmsList> plist =[];
  //   if(dataData.length>0){
  //     for(int i=0; i<dataData.length;i++){
  //       plist.add(AlarmsList.fromMap(dataData[i]));
  //     }
  //   }
  //   return plist;
  // }

  // Future<int> delete(int id) async {
  //   var dbClient = await db;
  //   var result = await dbClient.rawDelete('DELETE FROM $TABLE_ALARM WHERE $ID = id');
  //   return result;
  // }

  Future close() async {
    var dbClient = await db;
    dbClient.close();
  }
}
