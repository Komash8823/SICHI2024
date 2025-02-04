import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:udp/udp.dart';
import 'package:speech_balloon/speech_balloon.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:hearable_device_sdk_sample/alert.dart';
import 'package:hearable_device_sdk_sample/nine_axis_sensor_wand.dart';
import 'package:hearable_device_sdk_sample/temperature.dart';
import 'package:hearable_device_sdk_sample/heart_rate.dart';
import 'package:hearable_device_sdk_sample/ppg.dart';
import 'package:hearable_device_sdk_sample/eaa.dart';
import 'package:hearable_device_sdk_sample/battery.dart';
import 'package:hearable_device_sdk_sample/config.dart';
import 'package:hearable_device_sdk_sample/sound_wand.dart';

import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';

// 各画面で共通の効果音を使うことを考慮し、外部変数として定義
Sound se = Sound();

// 画面表示文字列用変数
String order = "";
// 初めの数回は攻撃判定しない
int counter = 0;
// ドラゴンのHPについて使用
int hp0Flag = 0;
int hp = 100;
// 外にあったほうが都合よさそう
List<double> agmDoubleList = [];
// 攻撃判定開始/終了用フラグ
int attackFlag = 0;

// 開始ボタンの表示/非表示
bool _buttonIsVisible = true;

// 吹き出しの表示/非表示
bool _bubbleIsVisible = false;

class Wand extends StatelessWidget {
  const Wand({super.key});
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
      child: _Wand(),
    );
  }
}

class _Wand extends StatefulWidget {
  @override
  State<_Wand> createState() => _WandState();
}

class _WandState extends State<_Wand> {
  Timer? _timer;
  bool _canChangeText = true; // 文字列変更を制御するフラグ
  //String tmp = NineAxisSensor();

  // コマンドをランダムに選ぶ
  void _showRandomCommand() {
    List<String> commands = [
      "杖を縦に振ろう！",
      "杖を横に振ろう！",
      "杖を突き出そう！"
    ];
    var random = Random();
    // _canChangeText==Trueにならないと文字列変えられないようにする
    // その処理は攻撃判定の時に行う
    if (_canChangeText) {
      setState(() {
        order = commands[random.nextInt(commands.length)];
        _canChangeText = false; // フラグを変更して一定時間文字を保持する
      });
    }
  }

  void _getData(){
    _timer = Timer.periodic(Duration(milliseconds: 150), (timer) {
      setState(() {
        NineAxisSensor _nas = Provider.of<NineAxisSensor>(context, listen: false);
        // ここで条件をチェック
        if (_nas.isEnabled) {
          // データ取得とグラフ用に変換
          String dataString = _nas.getResultString();
          if(NineAxisSensor().isEnabled == true && counter < 66){
            if(counter == 65){
              _udpDataSender("2");
              _bubbleIsVisible = true;
            }
            counter++;
          }
          print('faaaa: ${dataString}');
          // _udpDataSender(dataString);
          // _udpDataSender("123\n");
          if (dataString.isNotEmpty) {
            // カンマで区切り、String型のリストに変換
            List<String> agmStringList = dataString.split(',');
            // String型のリストをdouble型のリストに変換
            agmDoubleList = agmStringList.map((e) => double.tryParse(e) ?? 0.0).toList();
          } else {
            print("No Data!");
          }
        }

        // udpDataSenderの番号
        // 100:falseSword 101:trueSword 200:falseThunder 201:trueThunder 300:falseExplosion 301:trueExplosion
        // 一番最初にデータが入らないっぽいから，取得から66回目まではここから下に入らないようにする(counter)
        if(counter >= 66){
          if(hp0Flag == 0){
            _showRandomCommand();
            if(attackFlag == 0){
              if(agmDoubleList[20] > 7000 || agmDoubleList[20] < -7000){ // 縦振り
                attackFlag = 1;
                debugPrint("\n\n\nsword effect!!\n\n\n\n");
                if(order == "杖を縦に振ろう！"){ // 正しかったか判定
                  _udpDataSender("101");
                  hp -= 20;
                }else{
                  _udpDataSender("100");
                  hp -= 5;
                }
                se.playSe(SoundIds.sword, 1);
                Future.delayed(Duration(seconds: 2), () {
                  if(hp <= 0){
                    hp0Flag = 1;
                    _udpDataSender("3");
                    se.playSe(SoundIds.endAnimation, 1);
                    order = "おめでとう！";
                  }else{
                    order = "次の攻撃は...";
                    Future.delayed(Duration(seconds: 1), () {
                      _canChangeText = true;
                      attackFlag = 0;
                    });
                  }
                });
              }else if(agmDoubleList[15] > 7000 || agmDoubleList[15] < -7000){ // 横振り
                attackFlag = 1;
                debugPrint("\n\n\nthunder effect!!\n\n\n\n");
                if(order == "杖を横に振ろう！"){ // 正しかったか判定
                  _udpDataSender("201");
                  hp -= 20;
                }else{
                  _udpDataSender("200");
                  hp -= 5;
                }
                se.playSe(SoundIds.thunder, 1);
                Future.delayed(Duration(seconds: 2), () {
                  if(hp <= 0){
                    hp0Flag = 1;
                    _udpDataSender("3");
                    se.playSe(SoundIds.endAnimation, 1);
                    order = "おめでとう！";
                  }else{
                    order = "次の攻撃は...";
                    Future.delayed(Duration(seconds: 1), () {
                      _canChangeText = true;
                      attackFlag = 0;
                    });
                  }
                });
              }else if((agmDoubleList[10] > 7000) && (agmDoubleList[15] < 5000) && (agmDoubleList[20] < 5000 )){ // 突き
                attackFlag = 1;
                debugPrint("\n\n\nexplosion effect!!\n\n\n\n");
                if(order == "杖を突き出そう！"){ // 正しかったか判定
                  _udpDataSender("301");
                  hp -= 20;
                }else{
                  _udpDataSender("300");
                  hp -= 5;
                }
                se.playSe(SoundIds.explosion, 1);
                Future.delayed(Duration(seconds: 2), () {
                  if(hp <= 0){
                    hp0Flag = 1;
                    _udpDataSender("3");
                    se.playSe(SoundIds.endAnimation, 1);
                    order = "おめでとう！";
                  }else{
                    order = "次の攻撃は...";
                    Future.delayed(Duration(seconds: 1), () {
                      _canChangeText = true;
                      attackFlag = 0;
                    });
                  }
                });
              }
            }
          }
        }
      });
    });
  }

  // UDP通信でPCへ送信するための関数
  void _udpDataSender(String data) async{
    var sender = await UDP.bind(Endpoint.any());
    // InternetAddressは使用しているネットワークに合わせて自分で設定してね
    // Portは受信側で設定したPortと合わせる
    await sender.send("$data\n".codeUnits, Endpoint.unicast(InternetAddress("192.168.1.80"), port: Port(9000)));
  }

  @override
  void initState() {
    super.initState();
    _getData();
    se.playSe(SoundIds.noSound, 0);
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

  void _resetSelection() {
    selectedIndex = -1;
    selectedUser = '';
  }

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

  void _registerCallback() {
    Navigator.of(context).pop();
  }

  void _deleteRegistrationCallback() {
    Navigator.of(context).pop();
    _resetSelection();
  }

  void _verifyCallback() {
    Navigator.of(context).pop();
  }

  void _getRegistrationStatusCallback() {
    Navigator.of(context).pop();
    _resetSelection();
  }

  @override
  Widget build(BuildContext context) {
    _setRequiredNumText();
    _setBatteryIntervalText();

    if (!isSetEaaCallback) {
      eaa.addEaaListener(
          registerCallback: _registerCallback,
          cancelRegistrationCallback: null,
          deleteRegistrationCallback: _deleteRegistrationCallback,
          verifyCallback: _verifyCallback,
          getRegistrationStatusCallback: _getRegistrationStatusCallback);
      isSetEaaCallback = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('センサデータ確認', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => {_saveInput(context)},
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 20), //変更
            child: Center( // 画面全体を中央に配置
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 縦方向の中央配置
                children: <Widget>[
                  const SizedBox(height: 300),
                  Column(
                    children: <Widget>[
                      Visibility(
                        visible: _bubbleIsVisible,
                        // child: Bubble(
                        //   margin: BubbleEdges.only(top: 10),
                        //   alignment: Alignment.center,
                        //   nip: BubbleNip.leftTop,
                        //   child: Text(order, textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
                        // ),
                        child: SpeechBalloon(
                          width: 250,
                          color: Colors.white, // 中身の色これはデフォルトで白になっています
                          borderColor: Colors.black, // 境界線のカラーです、これを指定すると境界線の設定が有効になります
                          nipLocation: NipLocation.bottomRight, // 向きを設定デフォルトは下です
                          nipHeight: 20.0, // 棘の部分の長さを指定出来ますデフォルトは１０ポイントです
                          // offset:  基本的に指定しなくてもいいですが、場合によってはずれてしまうのでその時は指定してください
                          // innerBorderRadius: 基本的に指定しなくてもいいです、場合によってはずれてしまうのでその時は指定してください 
                          child: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              order,
                              textAlign: TextAlign.center, 
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Visibility(
                        visible: _bubbleIsVisible,
                        child: Image.asset('assets/images/dogSmile.png'),
                      ),
                    ]
                  ),
                  const SizedBox(height: 20),
                  Visibility(
                    visible: _buttonIsVisible,
                    child: ElevatedButton(
                      onPressed: () {
                        _switch9AxisSensor(true);
                        _buttonIsVisible = false;
                        _udpDataSender("1");
                        se.playSe(SoundIds.startAnimation, 1);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        backgroundColor: Colors.green,
                        minimumSize: Size(150, 50),
                      ),
                      child: const Text(
                        '戦闘開始',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
