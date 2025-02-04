import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:udp/udp.dart';

import 'package:hearable_device_sdk_sample/widgets.dart';
import 'package:hearable_device_sdk_sample/alert.dart';
import 'package:hearable_device_sdk_sample/nine_axis_sensor_dial.dart';
import 'package:hearable_device_sdk_sample/temperature.dart';
import 'package:hearable_device_sdk_sample/heart_rate.dart';
import 'package:hearable_device_sdk_sample/ppg.dart';
import 'package:hearable_device_sdk_sample/eaa.dart';
import 'package:hearable_device_sdk_sample/battery.dart';
import 'package:hearable_device_sdk_sample/config.dart';
import 'sound_effect.dart';

import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';

class Dial extends StatelessWidget {
  const Dial({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: NineAxisSensor()),
        ChangeNotifierProvider.value(value: Temperature()),
        ChangeNotifierProvider.value(value: HeartRate()),
        ChangeNotifierProvider.value(value: Ppg()),
        ChangeNotifierProvider.value(value: Eaa()),
        ChangeNotifierProvider.value(value: Battery()),
      ],
      child: const _DialView(
        title: 'ダイヤルアプリ',
      ),
    );
  }
}

class _DialView extends StatefulWidget {
  const _DialView({required this.title});
  final String title;
  @override
  State<_DialView> createState() => _DialViewState();
}

class _DialViewState extends State<_DialView> {
  final SoundsModel soundsModel = SoundsModel();

  String _str9axis = '';
  Timer? _timer;

  //計算の道中で，String型に分割して入れるためのリスト
  var valsStr = List<String>.filled(9, '0');
  //List<String>.empty(growable: true); //accX: x1, x2, x3, x4, x5...のデータ

  //最終的な9軸の値を入れるリスト
  var valsDouble = List<double>.filled(9, 0.0);
  //List<double>.empty(growable: true); //valsStrをdoubleに変換してそれぞれの平均値を求めたものを代入したバージョン

  double _roll = 0.0; //ロール回転角
  double _pitch = 0.0; //ピッチ回転角
  double _yaw = 0.0; //ヨー回転角

  final double _deltaTime = 0.1; //サンプリング周期．10Hz
  final double _alpha = 0.98; //フィルタ係数

  // ジャイロセンサの値．繰り返し毎に加算していく
  double gyroRoll = 0.0;
  double gyroPitch = 0.0;
  double gyroYaw = 0.0;

  //前回の角度
  double _preRoll = 0.0;
  double _prePitch = 0.0;
  double _preYaw = 0.0;
  double currentYaw = 0.0;

  double delta = 0.0;

  String _angles = '';

  //0°にキャリブレーションする用の変数
  double adjustedYaw = 0.0;
  double resetDgree = 0.0;

  //入力関連
  bool inputFlag = false;
  String inputNum = ''; //入力した数字を入れる
  //正しい数字．ダイヤルアプリのページが更新するたびに新しくしたい
  int random = Random().nextInt(999);
  String beforeNum = '';

  final Stopwatch _swTimer = Stopwatch();
  String tmp = '';

  double calibMagX = 0.0;
  double calibMagY = 0.0;
  double calibMagZ = 0.0;

  double minMagX = 0.0;
  double maxMagX = 0.0;
  double minMagY = 0.0;
  double maxMagY = 0.0;
  double minMagZ = 0.0;
  double maxMagZ = 0.0;

  double offSetX = 0.0;
  double offSetY = 0.0;
  double offSetZ = 0.0;

  double scaleX = 0.0;
  final double scaleY = 1.0; //Yを基準点にする
  double scaleZ = 0.0;

  int compareStr = 10000;

  // UDP通信でPCへ送信するための関数
  void _udpDataSender(String data) async {
    var sender = await UDP.bind(Endpoint.any());
    // InternetAddressは送信先のPCのIPアドレス．WiFiを変えると変わる
    // Portは受信側で設定したPortと合わせる
    await sender.send(
        "$data\n".codeUnits,
        Endpoint.unicast(InternetAddress("192.168.1.43"),
            port: const Port(9000)));
  }

  //9軸センサの値を取ってくる
  void _getNineAxisSensor() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        //更新？
        NineAxisSensor nas =
            Provider.of<NineAxisSensor>(context, listen: false);

        if (nas.isEnabled) {
          String dataString = nas.getResultString();
          _str9axis = dataString;
          //debugPrint('9axis sensor in dial.dart:\n $_str9axis');

          //string型の９軸センサの値を各値に分割して，Doubleに変換してリストに保存して角度に変換
          _calcAngle(_str9axis);
        } else {
          debugPrint('No 9axis Data.');
        }
      });
    });
  }

  //string型の９軸センサの値を各値に分割して，Doubleに変換してリストに保存して角度に変換
  //0-2:acc, 3-5:gyr, 6-8:mag x,y,z
  void _calcAngle(String originData) {
    if (originData.isNotEmpty) {
      List<String> valStrList = originData.split('\n'); //改行でsplitして各軸毎に分割

      //各軸をコロンで区切ってデータだけを取り出す．この時点ではString 0:accX ~ 8:magZ
      for (int i = 0; i < valStrList.length; i++) {
        valsStr[i] = valStrList[i].split(':').last;
      }
      //debugPrint('valsStrList: $valsStr');

      //取り出した値をdoubleに変換してリストにする
      //reduce()でリストの合計を出して，lengthで割り，各軸の5つの値の平均値を求める
      for (int i = 0; i < valsStr.length; i++) {
        List<double> doubleList = valsStr[i]
            .split(',')
            .map((e) => double.tryParse(e) ?? 0.0)
            .toList();
        //debugPrint('double list valsStr[$i]: $doubleList');

        valsDouble[i] = doubleList.reduce((a, b) => a + b) / doubleList.length;
      }
      //感度4096LSB/gなので4096で割る
      valsDouble[0] /= 4096;
      valsDouble[1] /= 4096;
      valsDouble[2] /= 4096;
      valsDouble[2] -= 0.98;
      //debugPrint('valsDouble list:\n$valsDouble\n');

      //感度16.383LSB/(º/s)なので16.383で割る
      valsDouble[3] /= 16.3835;
      valsDouble[4] /= 16.3835;
      valsDouble[5] /= 16.3835;

      //感度0.149975574μT/LSBなので0.149975574をかける
      valsDouble[6] *= 0.149975574;
      valsDouble[7] *= 0.149975574;
      valsDouble[8] *= 0.149975574;

      // _angles =
      //     'magX: ${valsDouble[3]}\nmagY: ${valsDouble[4]}\nmagZ: ${valsDouble[5]}\n';

      //地磁気センサのオフセットとスケールを計算
      //setOffset(valsDouble[6], valsDouble[7], valsDouble[8]);
      //setScale();
      // valsDouble[6] -= offSetX;
      // valsDouble[7] -= offSetY;
      // valsDouble[8] -= offSetZ;
      // valsDouble[6] *= scaleX;
      // valsDouble[8] *= scaleZ;

      //加速度から計算したピッチとロール
      double accRoll = atan2(valsDouble[1], valsDouble[2]);
      double accPitch = atan2(-1 * valsDouble[0],
          sqrt(valsDouble[1] * valsDouble[1] + valsDouble[2] * valsDouble[2]));

      //角速度を積分して角度を計算
      gyroRoll = valsDouble[3] * (pi / 180);
      gyroPitch = valsDouble[4] * (pi / 180);
      gyroYaw = valsDouble[5] * (pi / 180);

      //相補フィルタを適用
      _roll =
          _alpha * (_roll + gyroRoll * _deltaTime) + (1.0 - _alpha) * accRoll;
      _pitch = _alpha * (_pitch + gyroPitch * _deltaTime) +
          (1.0 - _alpha) * accPitch;

      _preRoll = _roll;
      _prePitch = _pitch;

      //ヨー回転を計算
      double magXprime =
          valsDouble[6] * cos(_pitch) + valsDouble[8] * sin(_pitch);
      double magYprime = valsDouble[6] * sin(_roll) * sin(_pitch) +
          valsDouble[7] * cos(_roll) -
          valsDouble[8] * sin(_roll) * cos(_pitch);

      double magYaw =
          -1 * atan2(magYprime, magXprime); //回転が逆の場合，ここの正負を変える 左：マイナス，右：プラス
      magYaw = _normAngle(magYaw);
      _yaw = _alpha * (_yaw + gyroYaw * _deltaTime) + (1.0 - _alpha) * magYaw;

      double deltaYaw = _minAngleDiff(_yaw, _preYaw);
      currentYaw += deltaYaw;
      currentYaw = _normAngle(currentYaw);

      adjustedYaw = currentYaw;
      adjustedYaw = currentYaw - resetDgree;

      adjustedYaw = _normAngle(adjustedYaw);

      //前回の角度を更新
      double filterAlpha = 0.2;
      _preYaw = _preYaw + filterAlpha * (_yaw - _preYaw);

      _preYaw = _yaw;

      tmp = _checkInput();

      //数字の入力を受け付ける
      if (inputFlag) {
        if (!_swTimer.isRunning) {
          _swTimer.start();
        }
        double checkDegree = adjustedYaw * (180 / pi) % 36;
        if (tmp != beforeNum) {
          _swTimer.reset();
        }
        if (_swTimer.elapsed >= const Duration(seconds: 2)) {
          if (checkDegree > 33 || checkDegree < 3) {
            inputNum += tmp;
            _swTimer.stop();
            _swTimer.reset();
          }

          //_swTimer.start();
        }
      }

      _angles =
          'yaw: ${_yaw * (180 / pi)}\nresetDegree: ${resetDgree * (180 / pi)}\n';

      _angles += 'currentYaw: $currentYaw\n';

      _angles += 'adjustedYaw: ${adjustedYaw * (180 / pi)}\n';

      debugPrint("angles: $_angles");

      tickAudio(adjustedYaw);
      beforeNum = tmp;
      compareStr = inputNum.compareTo(random.toString());
    } else {
      debugPrint('data is empty.');
    }
  }

  double _normAngle(double angle) {
    angle = angle % (2 * pi);
    if (angle < 0) {
      angle += 2 * pi;
    }
    return angle;
  }

  double _minAngleDiff(double current, double pre) {
    double diff = current - pre;
    diff = (diff + pi) % (2 * pi) - pi;
    return diff;
  }

  void _setZeroDegree() {
    resetDgree = _yaw;
  }

  void _defaultDegree() {
    resetDgree = 0.0;
  }

  void setOffset(double magX, double magY, double magZ) {
    minMagX = min(minMagX, magX);
    minMagY = min(minMagY, magY);
    minMagZ = min(minMagZ, magZ);

    maxMagX = max(maxMagX, magX);
    maxMagY = max(maxMagY, magY);
    maxMagZ = max(maxMagZ, magZ);

    offSetX = (maxMagX + minMagX) / 2;
    offSetY = (maxMagY + minMagY) / 2;
    offSetZ = (maxMagZ + minMagZ) / 2;
  }

  void setScale() {
    scaleX = (maxMagY - minMagY) / (maxMagX - minMagX);
    scaleZ = (maxMagY - minMagY) / (maxMagZ - minMagZ);
  }

  void tickAudio(double yaw) {
    double checkDegree = yaw * (180 / pi) % 36;
    //if (beforeNum != tmp) {
    if (checkDegree > 34 || checkDegree < 2) {
      soundsModel.playSound();
      // await Future.delayed(const Duration(seconds: 1));
    }
    //}
  }

  void _startInput() {
    _swTimer.stop();
    _swTimer.reset();
    _swTimer.start();
    inputFlag = true;
  }

  void _resetInput() {
    inputFlag = false;
    inputNum = '';
    _swTimer.stop();
    _swTimer.reset();
  }

  String _checkInput() {
    double devide36Degree = (adjustedYaw * (180 / pi)) / 36;
    String returnNum = '';

    if (-0.5 <= devide36Degree && devide36Degree < 0.5) {
      returnNum = '0';
    } else if (0.5 <= devide36Degree && devide36Degree < 1.5) {
      returnNum = '9';
    } else if (1.5 <= devide36Degree && devide36Degree < 2.5) {
      returnNum = '8';
    } else if (2.5 <= devide36Degree && devide36Degree < 3.5) {
      returnNum = '7';
    } else if (3.5 <= devide36Degree && devide36Degree < 4.5) {
      returnNum = '6';
    } else if (-1.5 <= devide36Degree && devide36Degree < -0.5) {
      returnNum = '1';
    } else if (-2.5 <= devide36Degree && devide36Degree < -1.5) {
      returnNum = '2';
    } else if (-3.5 <= devide36Degree && devide36Degree < -2.5) {
      returnNum = '3';
    } else if (-4.5 <= devide36Degree && devide36Degree < -3.5) {
      returnNum = '4';
    } else if (4.5 <= devide36Degree || devide36Degree < -4.5) {
      returnNum = '5';
    }

    return returnNum;
  }

  void _confirmInput() {
    inputFlag = false;
    _swTimer.stop();
    _swTimer.reset();
    String correctNum = random.toString();
    //入力数字＋カンマ＋正解　で送信
    _udpDataSender("$inputNum,$correctNum");
  }

  @override
  void initState() {
    super.initState();
    _getNineAxisSensor();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  final HearableDeviceSdkSamplePlugin _samplePlugin =
      HearableDeviceSdkSamplePlugin();
  String userUuid = (Eaa().featureGetCount == 0)
      ? const Uuid().v4()
      : Eaa().registeringUserUuid;
  var selectedIndex = -1;
  var selectedUser = '';
  bool isSetEaaCallback = false;

  var config = Config();
  Eaa eaa = Eaa();

  TextEditingController featureRequiredNumController = TextEditingController();
  TextEditingController featureCountController = TextEditingController();
  TextEditingController eaaResultController = TextEditingController();

  TextEditingController nineAxisSensorResultController =
      TextEditingController();
  TextEditingController temperatureResultController = TextEditingController();
  TextEditingController heartRateResultController = TextEditingController();
  TextEditingController ppgResultController = TextEditingController();

  TextEditingController batteryIntervalController = TextEditingController();
  TextEditingController batteryResultController = TextEditingController();

  void _saveInput(BuildContext context) {
    var num = featureRequiredNumController.text;
    var interval = batteryIntervalController.text;

    if (num.isNotEmpty) {
      var num0 = int.parse(num);
      if (num0 >= 10 && num0 != config.featureRequiredNumber) {
        config.featureRequiredNumber = num0;
        _samplePlugin.setHearableEaaConfig(featureRequiredNumber: num0);
      }
    }
    _setRequiredNumText();

    if (interval.isNotEmpty) {
      var interval0 = int.parse(interval);
      if (interval0 >= 10 && interval0 != config.batteryNotificationInterval) {
        config.batteryNotificationInterval = interval0;
        _samplePlugin.setBatteryNotificationInterval(interval: interval0);
      }
    }
    _setBatteryIntervalText();

    setState(() {});
    FocusScope.of(context).unfocus();
  }

  void _setRequiredNumText() {
    featureRequiredNumController.text = config.featureRequiredNumber.toString();
    featureRequiredNumController.selection = TextSelection.fromPosition(
        TextPosition(offset: featureRequiredNumController.text.length));
  }

  void _setBatteryIntervalText() {
    batteryIntervalController.text =
        config.batteryNotificationInterval.toString();
    batteryIntervalController.selection = TextSelection.fromPosition(
        TextPosition(offset: batteryIntervalController.text.length));
  }

  void _switch9AxisSensor(bool enabled) async {
    NineAxisSensor().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await NineAxisSensor().addNineAxisSensorNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        NineAxisSensor().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startNineAxisSensorNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        NineAxisSensor().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopNineAxisSensorNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        NineAxisSensor().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    //_getNineAxisSensor();

    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(fontSize: 18),
          ),
          centerTitle: true,
          backgroundColor: Colors.grey,
        ),

        //body
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => {_saveInput(context)},
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  //センサのスイッチ
                  const SizedBox(height: 2),
                  Consumer<NineAxisSensor>(
                      builder: ((context, nineAxisSensor, _) =>
                          Widgets.switchContainer(
                              title: "9軸センサ",
                              enable: nineAxisSensor.isEnabled,
                              function: _switch9AxisSensor))),
                  //センサの値を出力するテキストボックス
                  const SizedBox(height: 5),
                  Consumer<NineAxisSensor>(
                      builder: ((context, nineAxisSensor, _) =>
                          Widgets.resultContainer(
                              verticalRatio: 15,
                              controller: nineAxisSensorResultController,
                              text: _angles))),
                  //正解の数字
                  const SizedBox(height: 5),
                  Text(random.toString(),
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        shadows: [
                          Shadow(
                            offset: Offset(0, -6),
                          ),
                        ],
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blueGrey,
                        decorationThickness: 3.0,
                        decorationStyle: TextDecorationStyle.dashed,
                      )),
                  //入力した数字
                  const SizedBox(height: 10),
                  Text(
                    '入力した数字：$inputNum, $delta',
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  //目盛り
                  const SizedBox(height: 10),
                  Center(
                    child: Image.asset(
                      'assets/tick.png',
                      //fit: BoxFit.cover,
                      height: 35,
                    ),
                  ),
                  //ダイヤル画像
                  Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationZ(adjustedYaw),
                      child: Image.asset(
                        height: 320,
                        'assets/dial.png',
                        //fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  //ボタン達
                  //回転のOffsetを設定，リセットするボタン
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(
                            width: 5,
                            color: Colors.lightGreen,
                          ),
                        ),
                        onPressed: _setZeroDegree,
                        child: const Text('0°にセット'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(
                            width: 5,
                            color: Colors.red,
                          ),
                        ),
                        onPressed: _defaultDegree,
                        child: const Text('デフォルトに戻す'),
                      ),
                    ],
                  ),
                  //数字入力に関するボタン
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(
                            width: 5,
                            color: Colors.lime,
                          ),
                        ),
                        onPressed: _startInput,
                        child: const Text('数字入力開始'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(
                            width: 5,
                            color: Colors.redAccent,
                          ),
                        ),
                        onPressed: _resetInput,
                        child: const Text('入力数字リセット'),
                      ),
                    ],
                  ),
                  //数字確定ボタン
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(
                            width: 8,
                            color: Colors.grey,
                          ),
                        ),
                        onPressed: _confirmInput,
                        child: const Text('数字確定'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
