import 'package:flutter/foundation.dart';
import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';

class NineAxisSensor extends ChangeNotifier {
  final HearableDeviceSdkSamplePlugin _samplePlugin =
      HearableDeviceSdkSamplePlugin();
  bool isEnabled = false;

  int? _resultCode;
  Uint8List? _data;

  static final NineAxisSensor _instance = NineAxisSensor._internal();

  factory NineAxisSensor() {
    return _instance;
  }

  NineAxisSensor._internal();

  int? get resultCode => _resultCode;
  Uint8List? get data => _data;

  // String getResultString() {
  //   String str = '';
  //   //9軸センサの加速度情報をX,Y,Z軸に分離して表示する準備
  //   int accXoffset = 5;
  //   int accYoffset = 7;
  //   int accZoffset = 9;
  //   int gyrXoffset = 11;
  //   int gyrYoffset = 13;
  //   int gyrZoffset = 15;
  //   int magXoffset = 17;
  //   int magYoffset = 19;
  //   int magZoffset = 21;
  //   String accX = "";
  //   String accY = "";
  //   String accZ = "";
  //   String gyrX = "";
  //   String gyrY = "";
  //   String gyrZ = "";
  //   String magX = "";
  //   String magY = "";
  //   String magZ = "";

  // /*サンプルアプリのオリジナルソースコード*/
  // if (_resultCode != null) {
  //   //str += 'result code: $_resultCode';
  // }

  // if (_data != null) {
  //   //str += '\nbyte[]:\n';
  //   Uint8List data = _data!;
  //   for (int i = 0; i < data.length - 1; i++) {
  //     str += 'X${data[17].toRadixString(10)} ${data[18].toRadixString(10)}, ';
  //     str +=
  //         'Y${data[19].toRadixString(10)} ${data[20].toRadixString(10)}\n ';
  //     //str += 'Z${data[21].toRadixString(10)}${data[22].toRadixString(10)}, ';
  //   }
  //   str += data.last.toRadixString(16);
  // }

  /*
    //9時センサの加速度、角速度、地磁気情報をX,Y,Z軸に分離する処理
    if (_data != null) {
      Uint8List data = _data!;
      for (int i = 0; i < 5; i++) {
        
        accX +=
            '${data[accXoffset + (i * 22)]}${data[accXoffset + 1 + (i * 22)]}';
        accY +=
            '${data[accYoffset + (i * 22)]}${data[accYoffset + 1 + (i * 22)]}';
        accZ +=
            '${data[accZoffset + (i * 22)]}${data[accZoffset + 1 + (i * 22)]}';
        gyrX +=
            '${data[gyrXoffset + (i * 22)]}${data[gyrXoffset + 1 + (i * 22)]}';
        gyrY +=
            '${data[gyrYoffset + (i * 22)]}${data[gyrYoffset + 1 + (i * 22)]}';
        gyrZ +=
            '${data[gyrZoffset + (i * 22)]}${data[gyrZoffset + 1 + (i * 22)]}';
            
        magX +=
            '${data[magXoffset + (i * 22)]}${data[magXoffset + 1 + (i * 22)]}';
        magY +=
            '${data[magYoffset + (i * 22)]}${data[magYoffset + 1 + (i * 22)]}';
        magZ +=
            '${data[gyrZoffset + (i * 22)]}${data[magZoffset + 1 + (i * 22)]}';
        if (i != 4) {
          
          accX += ',';
          accY += ',';
          accZ += ',';
          gyrX += ',';
          gyrY += ',';
          gyrZ += ',';
          
          magX += ',';
          magY += ',';
          magZ += ',';
        }
      }
      str += 'accX:' +
          accX +
          '\n' +
          'accY:' +
          accY +
          '\n' +
          'accZ:' +
          accZ +
          '\n' +
          'gyrX:' +
          gyrX +
          '\n' +
          'gyrY:' +
          gyrY +
          '\n' +
          'gyrZ:' +
          gyrZ +
          '\n' +
          'magX:' +
          magX +
          '\n' +
          'magY:' +
          magY +
          '\n' +
          'magZ:' +
          magZ;
    }*/
  //   return str;
  // }

  String getResultString() {
    print('getResultString called');
    String str = '';
    var agm = new List.generate(9, (i) => "");

    //9軸センサの加速度、角速度、地磁気情報をX,Y,Z軸に分離する処理
    if (_data != null) {
      Uint8List data = _data!;

      for (int j = 0; j < 9; j++) {
        int before = data[(5 + j * 2) + (0 * 22)] * 256 +
            data[(5 + j * 2) + (0 * 22) + 1];
        int after = change(before);
        agm[j] += '${after}';
      }

      str += '${agm[6]},${agm[7]}';
    }
    debugPrint('Result string: ${str}');
    return str;
  }

  int change(num) {
    if (num > 32767) {
      num = num - 65536;
    }
    return num;
  }

  Future<bool> addNineAxisSensorNotificationListener() async {
    final res = await _samplePlugin.addNineAxisSensorNotificationListener(
        onStartNotification: _onStartNotification,
        onStopNotification: _onStopNotification,
        onReceiveNotification: _onReceiveNotification);
    return res;
  }

  void _removeNineAxisSensorNotificationListener() {
    _samplePlugin.removeNineAxisSensorNotificationListener();
  }

  void _onStartNotification(int resultCode) {
    _resultCode = resultCode;
    notifyListeners();
  }

  void _onStopNotification(int resultCode) {
    _removeNineAxisSensorNotificationListener();
    _resultCode = resultCode;
    notifyListeners();
  }

  void _onReceiveNotification(Uint8List? data, int resultCode) {
    _data = data;
    _resultCode = resultCode;
    notifyListeners();
  }
}
