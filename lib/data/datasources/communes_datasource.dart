import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/commune.dart';

abstract class ICommunesDataSource {
  Future<List<Commune>> getAllCommunes();
  Future<List<Commune>> getCommunesForWilaya(int wilayaCode);
  Future<Commune?> getCommuneByCode(int communeCode);
}

class BundledCommunesDataSource implements ICommunesDataSource {
  static const String assetPath = 'assets/data/algerian_communes.json';

  final AssetBundle? _bundle;
  List<Commune>? _cache;

  BundledCommunesDataSource({AssetBundle? bundle}) : _bundle = bundle;

  Future<void> preload() async {
    if (_cache != null) return;
    final bundle = _bundle ?? rootBundle;
    final jsonStr = await bundle.loadString(assetPath);
    final list = json.decode(jsonStr) as List<dynamic>;
    _cache = list.map((e) => Commune.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Commune>> getAllCommunes() async {
    if (_cache == null) await preload();
    return _cache ?? [];
  }

  @override
  Future<List<Commune>> getCommunesForWilaya(int wilayaCode) async {
    final all = await getAllCommunes();
    return all.where((c) => c.wilayaCode == wilayaCode).toList();
  }

  @override
  Future<Commune?> getCommuneByCode(int communeCode) async {
    final all = await getAllCommunes();
    try {
      return all.firstWhere((c) => c.code == communeCode);
    } catch (_) {
      return null;
    }
  }
}
