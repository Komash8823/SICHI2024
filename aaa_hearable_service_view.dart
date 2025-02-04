import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

//import 'package:hearable_device_sdk_sample/size_config.dart';
//import 'package:hearable_device_sdk_sample/widget_config.dart';
import 'package:hearable_device_sdk_sample/widgets.dart';
import 'package:hearable_device_sdk_sample/alert.dart';
import 'package:hearable_device_sdk_sample/nine_axis_sensor.dart';
import 'package:hearable_device_sdk_sample/temperature.dart';
import 'package:hearable_device_sdk_sample/heart_rate.dart';
import 'package:hearable_device_sdk_sample/ppg.dart';
import 'package:hearable_device_sdk_sample/eaa.dart';
import 'package:hearable_device_sdk_sample/battery.dart';
import 'package:hearable_device_sdk_sample/config.dart';

import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';

class HearableServiceView extends StatelessWidget {
  const HearableServiceView({super.key});

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
      child: _HearableServiceView(),
    );
  }
}

class _HearableServiceView extends StatefulWidget {
  @override
  State<_HearableServiceView> createState() => _HearableServiceViewState();
}

class _HearableServiceViewState extends State<_HearableServiceView> {
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

  void _createUuid() {
    userUuid = const Uuid().v4();

    eaa.featureGetCount = 0;
    eaa.registeringUserUuid = userUuid;
    _samplePlugin.cancelEaaRegistration();

    setState(() {});
  }

  void _feature() async {
    eaa.registeringUserUuid = userUuid;
    _showDialog(context, '特徴量取得・登録中...');
    // 特徴量取得、登録
    if (!(await _samplePlugin.registerEaa(uuid: userUuid))) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
  }

  void _deleteRegistration() async {
    _showDialog(context, '登録削除中...');
    // ユーザー削除
    if (!(await _samplePlugin.deleteSpecifiedRegistration(
        uuid: selectedUser))) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
  }

  void _deleteAllRegistration() async {
    _showDialog(context, '登録削除中...');
    // ユーザー全削除
    if (!(await _samplePlugin.deleteAllRegistration())) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
  }

  void _cancelRegistration() async {
    // 特徴量登録キャンセル
    if (!(await _samplePlugin.cancelEaaRegistration())) {
      // エラーダイアログ
      Alert.showAlert(context, 'IllegalStateException');
    }
  }

  void _verify() async {
    _showDialog(context, '照合中...');
    // 照合
    if (!(await _samplePlugin.verifyEaa())) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
  }

  void _requestRegisterStatus() async {
    _showDialog(context, '登録状態取得中...');
    // 登録状態取得
    if (!(await _samplePlugin.requestRegisterStatus())) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
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

  void _switchTemperature(bool enabled) async {
    Temperature().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await Temperature().addTemperatureNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        Temperature().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startTemperatureNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Temperature().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopTemperatureNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Temperature().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  void _switchHeartRate(bool enabled) async {
    HeartRate().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await HeartRate().addHeartRateNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        HeartRate().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startHeartRateNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        HeartRate().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopHeartRateNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        HeartRate().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  void _switchPpg(bool enabled) async {
    Ppg().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await Ppg().addPpgNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        Ppg().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startPpgNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Ppg().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopPpgNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Ppg().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  void _switchBattery(bool enabled) async {
    Battery().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await Battery().addBatteryNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        Battery().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startBatteryNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Battery().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopBatteryNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Battery().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  // 選択可能なListView
  ListView _createUserListView(BuildContext context) {
    return ListView.builder(
        // 登録ユーザー数
        itemCount: eaa.uuids.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              selected: selectedIndex == index ? true : false,
              selectedTileColor: Colors.grey.withOpacity(0.3),
              title: Widgets.uuidText(eaa.uuids[index]),
              onTap: () {
                if (index == selectedIndex) {
                  _resetSelection();
                } else {
                  selectedIndex = index;
                  selectedUser = eaa.uuids[index];
                }
                setState(() {});
              },
            ),
          );
        });
  }

  void _showDialog(BuildContext context, String text) {
    showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        pageBuilder: (BuildContext context, Animation animation,
            Animation secondaryAnimation) {
          return AlertDialog(
            content: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(text)
                  ],
                )
              ],
            ),
          );
        });
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

  void _onSavedFeatureRequiredNum(String? numStr) {
    if (numStr != null) {
      config.featureRequiredNumber = int.parse(numStr);
      _setRequiredNumText();
    }
    setState(() {});
  }

  void _onSavedBatteryInterval(String? intervalStr) {
    if (intervalStr != null) {
      config.batteryNotificationInterval = int.parse(intervalStr);
      _setBatteryIntervalText();
    }
    setState(() {});
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

  void __cancelRegistrationCallback() {
    eaa.featureGetCount = 0;
    setState(() {});
  }

  void _verifyCallback() {
    Navigator.of(context).pop();
  }

  void _getRegistrationStatusCallback() {
    Navigator.of(context).pop();
    _resetSelection();
  }

  String jadge1() {
    String resultString = NineAxisSensor().getResultString();

    List<String> values = resultString.split(',');

    int x = int.parse(values[0].trim());
    int y = int.parse(values[1].trim());

    // x が正か負かで判定を行う
    if (x < -200 && y > 450) {
      return '正解！';
    } else {
      return '不正解';
    }
  }

  String jadge2() {
    String resultString = NineAxisSensor().getResultString();

    List<String> values = resultString.split(',');

    int x = int.parse(values[0].trim());
    int y = int.parse(values[1].trim());

    // x が正か負かで判定を行う
    if (x < -200 && y > 450) {
      return '正解！';
    } else {
      return '不正解';
    }
  }

  String jadge3() {
    String resultString = NineAxisSensor().getResultString();

    List<String> values = resultString.split(',');

    int x = int.parse(values[0].trim());
    int y = int.parse(values[1].trim());

    // x が正か負かで判定を行う
    if (x < -200 && y > 450) {
      return '正解！';
    } else {
      return '不正解';
    }
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
        title: const Text('クイズ', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.lightGreen,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => {_saveInput(context)},
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 10),
                const Text('\nクイズに挑戦！\n',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),

                //9軸
                const SizedBox(
                  height: 20,
                ),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.switchContainer(
                            title: '第１問:真ん中の□に入る文字は何でしょう\n',
                            enable: nineAxisSensor.isEnabled,
                            function: _switch9AxisSensor))),
                Image.asset('assets/Q1.png'),
                const SizedBox(height: 15),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.resultContainer(
                            verticalRatio: 20,
                            controller: nineAxisSensorResultController,
                            text: '1: ら\n2: に\n3: た'))),
                const SizedBox(height: 20),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.resultContainer(
                            verticalRatio: 8,
                            controller: nineAxisSensorResultController,
                            text: jadge1()))),
                const SizedBox(height: 20),

                const SizedBox(
                  height: 20,
                ),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.switchContainer(
                            title: '第２問:?に入る二字熟語は\n',
                            enable: nineAxisSensor.isEnabled,
                            function: _switch9AxisSensor))),
                Image.asset('assets/Q2.png'),
                const SizedBox(height: 15),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.resultContainer(
                            verticalRatio: 40,
                            controller: nineAxisSensorResultController,
                            text: '1: チェックメイト\n2: 網羅\n3: カード'))),
                const SizedBox(height: 20),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.resultContainer(
                            verticalRatio: 40,
                            controller: nineAxisSensorResultController,
                            text: jadge2()))),
                const SizedBox(height: 20),

                const SizedBox(
                  height: 20,
                ),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.switchContainer(
                            title: '第３問:?に入るものは\n',
                            enable: nineAxisSensor.isEnabled,
                            function: _switch9AxisSensor))),
                Image.asset('assets/Q3.png'),
                const SizedBox(height: 15),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.resultContainer(
                            verticalRatio: 40,
                            controller: nineAxisSensorResultController,
                            text: '1: 乗り物\n2: トランプ\n3: スライス'))),
                const SizedBox(height: 20),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.resultContainer(
                            verticalRatio: 40,
                            controller: nineAxisSensorResultController,
                            text: jadge3()))),
                const SizedBox(height: 20),

                // 装着適正度
                /*
                Consumer<Ppg>(
                    builder: ((context, ppg, _) => Widgets.switchContainer(
                        title: '第１問:真ん中の□に入る文字は何でしょう\n', //答え：ら
                        enable: ppg.isEnabled,
                        function: _switchPpg))),
                Image.asset('assets/cross.png'),
                const SizedBox(height: 10),
                Consumer<Ppg>(
                    builder: ((context, ppg, _) => Widgets.resultContainer3(
                        verticalRatio: 18,
                        controller: ppgResultController,
                        text: ppg.getResultString()))),
                const SizedBox(height: 10),

                Consumer<Ppg>(
                    builder: ((context, ppg, _) => Widgets.switchContainer(
                        title: '第２問:?に入る二字熟語は\n', //答え：網羅
                        enable: ppg.isEnabled,
                        function: _switchPpg))),
                Image.asset('assets/card.png'),
                const SizedBox(height: 10),
                Consumer<Ppg>(
                    builder: ((context, ppg, _) => Widgets.resultContainer3(
                        verticalRatio: 18,
                        controller: ppgResultController,
                        text: ppg.getResultString()))),
                const SizedBox(height: 10),

                Consumer<Ppg>(
                    builder: ((context, ppg, _) => Widgets.switchContainer(
                        title: '第３問:?に入るものは\n', //答え：スライス
                        enable: ppg.isEnabled,
                        function: _switchPpg))),
                Image.asset('assets/slice.png'),
                const SizedBox(height: 10),
                Consumer<Ppg>(
                    builder: ((context, ppg, _) => Widgets.resultContainer3(
                        verticalRatio: 18,
                        controller: ppgResultController,
                        text: ppg.getResultString()))),
                const SizedBox(height: 20),*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}
