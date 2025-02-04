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

  //   /*サンプルアプリのオリジナルソースコード
  //   if (_resultCode != null) {
  //     str += 'result code: $_resultCode';
  //   }

  //   if (_data != null) {
  //     str += '\nbyte[]:\n';
  //     Uint8List data = _data!;
  //     for (int i = 0; i < data.length - 1; i++) {
  //       str += '${data[i].toRadixString(16)}, ';
  //     }
  //     str += data.last.toRadixString(16);
  //   }*/

  //   //9軸センサの加速度、角速度、地磁気情報をX,Y,Z軸に分離する処理
  //   if (_data != null) {
  //     Uint8List data = _data!;
  //     for (int i = 0; i < 5; i++) {
  //       accX += '${data[accXoffset + (i * 22) + 1]}';
  //       accY += '${data[accYoffset + (i * 22) + 1]}';
  //       accZ += '${data[accZoffset + (i * 22) + 1]}';
  //       gyrX += '${data[gyrXoffset + (i * 22) + 1]}';
  //       gyrY += '${data[gyrYoffset + (i * 22) + 1]}';
  //       gyrZ += '${data[gyrZoffset + (i * 22) + 1]}';
  //       magX += '${data[magXoffset + (i * 22) + 1]}';
  //       magY += '${data[magYoffset + (i * 22) + 1]}';
  //       magZ += '${data[magZoffset + (i * 22) + 1]}';
  //       //元のコード（値が見やすいように10進数、2つのデータの内片方に変更した）
  //       //magZ +=
  //       //    '${data[gyrZoffset + (i * 22)].toRadixString(16)}${data[magZoffset + 1 + (i * 22)].toRadixString(16)}';
  //       if (i != 4) {
  //         accX += ',';
  //         accY += ',';
  //         accZ += ',';
  //         gyrX += ',';
  //         gyrY += ',';
  //         gyrZ += ',';
  //         magX += ',';
  //         magY += ',';
  //         magZ += ',';
  //       }
  //     }
  //     str += 'accX:' +
  //         accX +
  //         '\n' +
  //         'accY:' +
  //         accY +
  //         '\n' +
  //         'accZ:' +
  //         accZ +
  //         '\n' +
  //         'gyrX:' +
  //         gyrX +
  //         '\n' +
  //         'gyrY:' +
  //         gyrY +
  //         '\n' +
  //         'gyrZ:' +
  //         gyrZ +
  //         '\n' +
  //         'magX:' +
  //         magX +
  //         '\n' +
  //         'magY:' +
  //         magY +
  //         '\n' +
  //         'magZ:' +
  //         magZ;
  //   }
  //   debugPrint('Result string: ${str}');
  //   return str;
  // }

  String getResultString() {
    print('getResultString called');
    String str = '';
    var agm = new List.generate(9, (i) => "");

    //9軸センサの加速度、角速度、地磁気情報をX,Y,Z軸に分離する処理
    if (_data != null) {
      Uint8List data = _data!;
      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 9; j++) {
          int before = data[(5 + j * 2) + (i * 22)] * 256 +
              data[(5 + j * 2) + (i * 22) + 1];
          int after = change(before);
          agm[j] += '${after}';
          if (i != 4) {
            agm[j] += ',';
          }
        }
      }
      str +=
          '${agm[0]},${agm[1]},${agm[2]},${agm[3]},${agm[4]},${agm[5]},${agm[6]},${agm[7]},${agm[8]}';
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
    print('Notification received: resultCode = $resultCode, data = $data');
    _data = data;
    _resultCode = resultCode;
    notifyListeners();
  }
}
