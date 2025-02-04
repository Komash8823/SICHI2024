import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundpool/soundpool.dart';

final soundsProvider = ChangeNotifierProvider((ref) => SoundsModel());

class SoundsModel extends ChangeNotifier {
  final Soundpool _soundpool = Soundpool.fromOptions();
  int? _seStreamId;
  late Future<int> _seId;
  String display = "";

  SoundsModel() {
    loadSounds();
  }

  Future<int> _loadSound() async {
    var assets = await rootBundle.load("assets/dial.mp3");
    return await _soundpool.load(assets);
  }

  Future<void> playSound() async {
    var _seSound = await _seId;
    _seStreamId = await _soundpool.play(_seSound);
    display = "se now";
    notifyListeners();
  }

  Future<void> stopSound() async {
    if (_seStreamId != null) {
      await _soundpool.stop(_seStreamId!);
      display = "";
    }
  }

  void loadSounds() {
    _seId = _loadSound();
  }
}
