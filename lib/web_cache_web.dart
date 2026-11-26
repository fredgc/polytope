import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

Future<void> _reloadAssetHttpCache() async {
  final urlsToReload = <String>{
    'favicon.ico',
    'favicon.png',
    'icons/Icon-192.png',
    'icons/Icon-512.png',
    'icons/Icon-maskable-192.png',
    'icons/Icon-maskable-512.png',
    'assets/AssetManifest.bin',
    'assets/AssetManifest.bin.json',
    'assets/FontManifest.json',
  };

  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final assetKey in manifest.listAssets()) {
      urlsToReload.add('assets/$assetKey');
      for (final variant in manifest.getAssetVariants(assetKey) ?? const []) {
        urlsToReload.add('assets/${variant.key}');
      }
    }
  } catch (e) {
    debugPrint("Error loading AssetManifest for cache flush: $e");
  }

  final init = web.RequestInit(cache: 'reload');
  await Future.wait(
    urlsToReload.map((url) async {
      try {
        await web.window.fetch(url.toJS, init).toDart;
      } catch (_) {}
    }),
  );
}

Future<void> reloadAndFlushCache() async {
  try {
    debugPrint("Flushing service workers, caches, and reloading page.");
    final nav = web.window.navigator;
    final serviceWorker = nav.serviceWorker;
    final registrations = await serviceWorker.getRegistrations().toDart;
    final regList = registrations.toDart;
    for (final reg in regList) {
      await reg.unregister().toDart;
    }
    final cacheStorage = web.window.caches;
    final keys = await cacheStorage.keys().toDart;
    final keyList = keys.toDart;
    for (final key in keyList) {
      await cacheStorage.delete(key.toDart).toDart;
    }
    await _reloadAssetHttpCache();
  } catch (e) {
    debugPrint("Error clearing web cache: $e");
  }
  web.window.location.reload();
}

Future<void> checkServerVersionAndReload(String clientVersion) async {
  try {
    final uri = "version.json?nocache=${DateTime.now().millisecondsSinceEpoch}";
    final response = await web.window.fetch(uri.toJS).toDart;
    if (response.status == 200) {
      final text = (await response.text().toDart).toDart;
      final data = jsonDecode(text) as Map<String, dynamic>;
      final serverVer = data['version'] as String?;
      final serverBuild = data['build_number'] as String?;
      final serverVersion =
          (serverBuild != null && serverBuild.isNotEmpty && serverVer != null)
              ? '$serverVer+$serverBuild'
              : serverVer;
      if (serverVersion != null &&
          serverVersion.isNotEmpty &&
          serverVersion != clientVersion) {
        debugPrint(
          "Server version ($serverVersion) differs from client ($clientVersion). Auto reloading...",
        );
        await reloadAndFlushCache();
      }
    }
  } catch (e) {
    debugPrint("Error checking server version: $e");
  }
}
