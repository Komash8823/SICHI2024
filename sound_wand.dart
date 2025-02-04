import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'dart:io';

enum SoundIds {
  sword,
  thunder,
  explosion,
  noSound,
  startAnimation,
  endAnimation
}

class Sound {
  String os = Platform.operatingSystem;
  bool isIOS = Platform.isIOS;
  late Soundpool _soundPool;

  final Map<SoundIds, int> _seContainer = Map<SoundIds, int>();
  final Map<int, int> _streamContainer = Map<int, int>();

  Sound() {
    // インスタンス生成
    this._soundPool = Soundpool.fromOptions(options: SoundpoolOptions(
        streamType: StreamType.music,
        maxStreams: 1 // 何音まで同時に鳴らせるようにするか設定
    ));
    // 以降、非同期で実施
        () async {
      // 読み込んだ効果音をバッファに保持
      var sword = await rootBundle.load("assets/sounds/sword.mp3").then((value) => this._soundPool.load(value));
      var thunder = await rootBundle.load("assets/sounds/thunder.mp3").then((value) => this._soundPool.load(value));
      var explosion = await rootBundle.load("assets/sounds/explosion.mp3").then((value) => this._soundPool.load(value));
      var noSound = await rootBundle.load("assets/sounds/noSound.mp3").then((value) => this._soundPool.load(value));
      var startAnimation = await rootBundle.load("assets/sounds/startAnimation.mp3").then((value) => this._soundPool.load(value));
      var endAnimation = await rootBundle.load("assets/sounds/endAnimation.mp3").then((value) => this._soundPool.load(value));
      // バッファに保持した効果音のIDを以下のコンテナに入れておく
      this._seContainer[SoundIds.sword] = sword;
      this._seContainer[SoundIds.thunder] = thunder;
      this._seContainer[SoundIds.explosion] = explosion;
      this._seContainer[SoundIds.noSound] = noSound;
      this._seContainer[SoundIds.startAnimation] = startAnimation;
      this._seContainer[SoundIds.endAnimation] = endAnimation;
      // 効果音を鳴らしたときに保持するためのstreamIdのコンテナを初期化
      // 対象の効果音を強制的に停止する際に使用する
      this._streamContainer[sword] = 0;
      this._streamContainer[thunder] = 0;
      this._streamContainer[explosion] = 0;
      this._streamContainer[noSound] = 0;
      this._streamContainer[startAnimation] = 0;
      this._streamContainer[endAnimation] = 0;
    }();
  }

  // 効果音を鳴らすときに本メソッドをEnum属性のSoundIdsを引数として実行する
  void playSe(SoundIds ids, int volume) async {
    // 効果音のIDを取得
    var seId = this._seContainer[ids];
    if (seId != null) {
      // 効果音として存在していたら、以降を実施
      // streamIdを取得
      var streamId = this._streamContainer[seId] ?? 0;
      if (streamId > 0 && isIOS) {
        // streamIdが存在し、かつOSがiOSだった場合、再生中の効果音を強制的に停止させる
        // iOSの場合、再生中は再度の効果音再生に対応していないため、ボタン連打しても再生されないため
        await _soundPool.stop(streamId);
      }

      // 効果音のIDをplayメソッドに渡して再生処理を実施
      // 再生処理の戻り値をstreamIdのコンテナに設定する
      // 第2引数が0の時，無音で効果音を再生する
      if(volume == 0){
        // 効果音のIDをplayメソッドに渡して再生処理を実施
        streamId = await _soundPool.play(seId);
        // 音量を設定 (0から1までの範囲で指定)
        await _soundPool.setVolume(streamId: streamId, volume: 0);
        // 再生したstreamIdをコンテナに保持
        this._streamContainer[seId] = streamId;
      }else{
        this._streamContainer[seId] = await _soundPool.play(seId);
      }
    } else {
      print("se resource not found! ids: $ids");
    }
  }

  Future<void> dispose() async {
    // 終了時の後始末処理
    await _soundPool.release();
    _soundPool.dispose();
    return Future.value(0);
  }

}