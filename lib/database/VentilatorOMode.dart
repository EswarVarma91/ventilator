class VentilatorOMode {
   int id;
    String  patientAge,operatingMode,lungImage,paw,
      patientGender,
      patientHeight,
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
      teS;
  double pressureValues, flowValues, volumeValues;
  String dateTime;
  String patientName,patientId;

  VentilatorOMode(
      this.patientId,
      this.patientName,
      this.patientAge,
      this.patientGender,
      this.patientHeight,
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
      this.tiS,
      this.teS,
      this.pressureValues,
      this.flowValues,
      this.volumeValues,this.operatingMode,this.lungImage,this.paw);

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
    patientAge = map['patientAge'];
    patientGender = map['patientGender'];
    patientHeight = map['patientHeight'];
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
    tiS = map['tiS'];
    teS = map['teS'];
    pressureValues = map['pressureP'];
    flowValues = map['flowP'];
    volumeValues = map['volumeP'];
    dateTime = map['datetimeP'];
    operatingMode = map['operatingMode'];
    lungImage = map['lungImage'];
    paw = map['paw'];//
  }

  VentilatorOMode.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        patientId = json['patientId'],
        patientName = json['patientName'],
        patientAge = json['patientAge'],
        patientGender = json['patientGender'],
        patientHeight = json['patientHeight'],
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
        tiS = json['tiS'],
        teS = json['teS'],
        pressureValues = json['pressureValues'],
        flowValues = json['flowValues'],
        volumeValues = json['volumeValues'],
        dateTime = json['dateTime'];

  VentilatorOMode.map(dynamic obj) {
    this.id = obj['id'];
    this.patientId = obj['patientId'];
    this.patientName = obj['patientName'];
    this.patientAge = obj['patientAge'];
    this.patientGender = obj['patientGender'];
    this.patientHeight = obj['patientHeight'];
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
    this.tiS = obj['tiS'];
    this.teS = obj['teS'];
    this.pressureValues = obj['pressureValues'];
    this.flowValues = obj['flowValues'];
    this.volumeValues = obj['volumeValues'];
    this.dateTime = obj['dateTime'];
  }
}

class PatientsList {
  String pId;
  String pName;
  String minTime;
  String maxTime;

  PatientsList(this.pId,this.pName,this.minTime,this.maxTime);

   PatientsList.fromMap(Map<String, dynamic> map) {
    pId = map['patientId'];
    pName = map['patientName'];
    minTime = map['minTime'];
    maxTime = map['maxTime'];
  }
}
