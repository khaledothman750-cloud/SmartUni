// Author / Project Supervisor : Omar Terro
// GitHub                      : https://github.com/IOTERRO
// Website                     : https://omarterro.fr
// Student (FYP)               : Khaled Othman
// Date                        : 19 October 2026
// Project                     : SmartUni - Smart University CityU
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Default camera for CityU / Abi Samra (matches assets/maps MBTiles bounds).
class CampusMapDefaults {
  CampusMapDefaults._();

  static const LatLng center = LatLng(34.418, 35.836);
  static const double zoom = 15.5;
  static const String assetPath = 'assets/maps/cityu_abisamra.mbtiles';
}

/// Loads offline MBTiles (mobile/desktop) or online OSM-FR tiles (web).
class OfflineCampusMapSource {
  OfflineCampusMapSource._();

  static MbTiles? _mbtiles;

  /// Call once before building the map. Safe to call multiple times.
  static Future<void> ensureReady() async {
    if (kIsWeb) return;
    if (_mbtiles != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cityu_abisamra.mbtiles'));
    final bytes = await rootBundle.load(CampusMapDefaults.assetPath);
    await file.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    _mbtiles = MbTiles(mbtilesPath: file.path, gzip: false);
  }

  static void dispose() {
    _mbtiles?.dispose();
    _mbtiles = null;
  }

  /// Baselayer for [FlutterMap].
  static TileLayer buildTileLayer() {
    if (kIsWeb || _mbtiles == null) {
      // Cap at 17 — higher zooms often 404 on free tile mirrors and spam the console.
      return TileLayer(
        urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.smartuni.cityu',
        maxZoom: 17,
        minZoom: 13,
        errorTileCallback: (tile, error, stackTrace) {},
      );
    }
    return TileLayer(
      tileProvider: _MbtilesRasterTileProvider(_mbtiles!),
      maxZoom: 17,
      minZoom: 14,
      errorTileCallback: (tile, error, stackTrace) {},
    );
  }

  static String get modeLabel =>
      (kIsWeb || _mbtiles == null) ? 'Online map tiles (web)' : 'Offline MBTiles';
}

/// Reads raster PNG tiles from MBTiles (flip XYZ Y → TMS row).
class _MbtilesRasterTileProvider extends TileProvider {
  _MbtilesRasterTileProvider(this._mbtiles);

  final MbTiles _mbtiles;

  static final Uint8List _emptyPng = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final z = coordinates.z;
    final x = coordinates.x;
    final tmsY = (1 << z) - 1 - coordinates.y;
    final data = _mbtiles.getTile(z: z, x: x, y: tmsY);
    return MemoryImage(data ?? _emptyPng);
  }
}
