import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weekly_case.dart';
import 'cloud_sync_service.dart';

class WeeklyCaseService {
  WeeklyCaseService({
    CloudRuntimeConfig? config,
    http.Client? client,
  })  : config = config ?? CloudRuntimeConfig.fromEnvironment(),
        _client = client ?? http.Client();

  static const _cacheKey = 'dataquest_weekly_case_cache_v1';
  static const fallbackAsset =
      'assets/content/weekly_case_fallback_v1.json';

  final CloudRuntimeConfig config;
  final http.Client _client;

  Future<WeeklyCaseLoadResult> load({
    bool refresh = false,
  }) async {
    if (config.weeklyCasesConfigured) {
      try {
        final remote = await _loadRemote();
        await _saveCache(remote);
        return WeeklyCaseLoadResult(
          pack: remote,
          source: 'online',
        );
      } catch (error) {
        final cached = await _loadCache();
        if (cached != null) {
          return WeeklyCaseLoadResult(
            pack: cached,
            source: 'cache',
            message:
                'Online weekly case unavailable; using the last valid cached pack.',
          );
        }
        final fallback = await _loadFallback();
        return WeeklyCaseLoadResult(
          pack: fallback,
          source: 'bundled',
          message:
              'Online weekly case unavailable; using the bundled offline case.',
        );
      }
    }

    final cached = await _loadCache();
    if (cached != null && !refresh) {
      return WeeklyCaseLoadResult(
        pack: cached,
        source: 'cache',
      );
    }
    return WeeklyCaseLoadResult(
      pack: await _loadFallback(),
      source: 'bundled',
      message: config.weeklyCasesConfigured
          ? null
          : 'Online weekly cases are not configured in this build.',
    );
  }

  Future<WeeklyCasePack> _loadRemote() async {
    final response = await _client.get(
      Uri.parse(config.weeklyCaseUrl.trim()),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Weekly case request failed with HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Weekly case root must be an object.');
    }
    return WeeklyCasePack.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<void> _saveCache(WeeklyCasePack pack) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(pack.toJson()));
  }

  Future<WeeklyCasePack?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return WeeklyCasePack.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<WeeklyCasePack> _loadFallback() async {
    final raw = await rootBundle.loadString(fallbackAsset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Bundled weekly case is invalid.');
    }
    return WeeklyCasePack.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  void close() => _client.close();
}
