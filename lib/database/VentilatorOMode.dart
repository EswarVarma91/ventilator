import 'dart:developer';

class VentilatorOMode {
   int id;
    String  operatingMode,lungImage,paw,
      pipD,
      vtD,
      peepD,
      rrD,
      fio2D,
      mapD,
      mvD,
      complainceD,
      ieD,
      rrS,
      ieS,
      peepS,
      psS,
      fio2S,
      tiS,
      teS,globalCounterNo,vtValue;
  double pressureValues, flowValues, volumeValues;
  String dateTime;
  String patientName,patientId,alarmC,alarmP,alarmActive;

  VentilatorOMode(
      this.patientId,
      this.patientName,
      this.pipD,
      this.vtD,
      this.peepD,
      this.rrD,
      this.fio2D,
      this.mapD,
      this.mvD,
      this.complainceD,
      this.ieD,
      this.rrS,
      this.ieS,
      this.peepS,
      this.psS,
      this.fio2S,
      this.vtValue,
      this.tiS,
      this.teS,
      this.pressureValues,
      this.flowValues,
      this.volumeValues,this.operatingMode,this.lungImage,this.paw,this.globalCounterNo,this.alarmC,this.alarmP,this.alarmActive);

  // Map<String, dynamic> toMap() {
  //   var map = <String, dynamic>{
  //     'id': id,
  //     'patientId': patientId,
  //     'patientName': patientName,
  //     'patientAge': patientAge,
  //     'patientGender': patientGender,
  //     'patientHeight': patientHeight,
  //     'pipD': pipD,
  //     'vtD': vtD,
  //     'peepD': peepD,
  //     'fio2D': fio2D,
  //     'mapD': mapD,
  //     'mvD': mvD,
  //     'complainceD': complainceD,
  //     'ieD': ieD,
  //     'rrS': rrS,
  //     'ieS': ieS,
  //     'peepS': peepS,
  //     'psS': psS,
  //     'fio2S': fio2S,
  //     'tiS': tiS,
  //     'teS': teS,
  //     'pressureP': pressureValues,
  //     'flowValues': flowValues,
  //     'volumeValues': volumeValues,
  //     'dateTime': dateTime,
  //   };
  //   return map;
  // }

  VentilatorOMode.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    patientId = map['patientId'];
    patientName = map['patientName'];
    pipD = map['pipD'];
    vtD = map['vtD'];
    peepD = map['peepD'];
    rrD = map['rrD'];
    fio2D = map['fio2D'];
    mapD = map['mapD'];
    mvD = map['mvD'];
    complainceD = map['complainceD'];
    ieD = map['ieD'];
    rrS = map['rrS'];
    ieS = map['ieS'];
    peepS = map['peepS'];
    psS = map['psS'];
    fio2S = map['fio2S'];
    vtValue = map['vtValueS'];
    tiS = map['tiS'];
    teS = map['teS'];
    pressureValues = map['pressureP'];
    flowValues = map['flowP'];
    volumeValues = map['volumeP'];
    dateTime = map['datetimeP'];
    operatingMode = map['operatingMode'];
    lungImage = map['lungImage'];
    paw = map['paw'];//
    globalCounterNo = map['globalCounterNo'];
    alarmC = map['alarmCodes'];
    alarmP = map['alarmPriority'];
    alarmActive = map['alarmActive'];
    
  }

  VentilatorOMode.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        patientId = json['patientId'],
        patientName = json['patientName'],
        pipD = json['pipD'],
        vtD = json['vtD'],
        peepD = json['peepD'],
        fio2D = json['fio2D'],
        mapD = json['mapD'],
        mvD = json['mvD'],
        complainceD = json['complainceD'],
        ieD = json['ieD'],
        rrS = json['rrS'],
        ieS = json['ieS'],
        peepS = json['peepS'],
        psS = json['psS'],
        fio2S = json['fio2S'],
        vtValue = json['vtValueS'],
        tiS = json['tiS'],
        teS = json['teS'],
        pressureValues = json['pressureValues'],
        flowValues = json['flowValues'],
        volumeValues = json['volumeValues'],
        dateTime = json['dateTime'],
         globalCounterNo = json['globalCounterNo'],
          alarmC = json['alarmCodes'],
    alarmP = json['alarmPriority'],
    alarmActive = json['alarmActive']
    
        ;

  VentilatorOMode.map(dynamic obj) {
    this.id = obj['id'];
    this.patientId = obj['patientId'];
    this.patientName = obj['patientName'];
    this.pipD = obj['pipD'];
    this.vtD = obj['vtD'];
    this.peepD = obj['peepD'];
    this.fio2D = obj['fio2D'];
    this.mapD = obj['mapD'];
    this.mvD = obj['mvD'];
    this.complainceD = obj['complainceD'];
    this.ieD = obj['ieD'];
    this.rrS = obj['rrS'];
    this.ieS = obj['ieS'];
    this.peepS = obj['peepS'];
    this.psS = obj['psS'];
    this.fio2S = obj['fio2S'];
    this.vtValue = obj['vtValueS'];
    this.tiS = obj['tiS'];
    this.teS = obj['teS'];
    this.pressureValues = obj['pressureValues'];
    this.flowValues = obj['flowValues'];
    this.volumeValues = obj['volumeValues'];
    this.dateTime = obj['dateTime'];
    this.globalCounterNo = obj['globalCounterNo'];
    this.alarmC = obj['alarmCodes'];
    this.alarmP = obj['alarmPriority'];
    this.alarmActive = obj['alarmActive'];

  }
}

class PatientsList {
  String pId;
  String pName;
  String minTime;
  String maxTime;
  String datetimeP;

  PatientsList(this.pId,this.pName,this.minTime,this.maxTime,this.datetimeP);

   PatientsList.fromMap(Map<String, dynamic> map) {
    pId = map['patientId'];
    pName = map['patientName'];
    minTime = map['minTime'];
    maxTime = map['maxTime'];
    datetimeP = map['dates'];
  }
}


class AlarmsList {
  String alarmId;
  String alarmCode;
  String datetime;
  String globalCounterNo;

  AlarmsList(this.alarmCode,this.globalCounterNo);

   AlarmsList.fromMap(Map<String, dynamic> map) {
    alarmId = map['id'].toString();
    alarmCode = map['alarmCodes'].toString();
    datetime = map['datetime'].toString();
    // globalCounterNo = map['globalCounterNo'];
  }
}



class PatientsSaveList {
  String patientId;
  String patientName;
  String patientAge;
  String patientGender;
  String patientHeight;
  String datetime;

  PatientsSaveList(this.patientId,this.patientName,this.patientAge,this.patientGender,this.patientHeight);

   PatientsSaveList.fromMap(Map<String, dynamic> map) {
    patientId = map['patientId'];
    patientName = map['patientName'];
    patientAge = map['patientAge'];
    patientGender = map['patientGender'];
    patientHeight = map['patientHeight'];
    datetime = map['datetime'];
  }
}


class CounterValue {
  int id;
  String counterValue;

  CounterValue(this.counterValue);

  CounterValue.fromMap(Map<String,dynamic> map) {
    id = map['id'];
    counterValue = map['counterNo'];
  }
}
