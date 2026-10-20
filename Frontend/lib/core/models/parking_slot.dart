/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
class ParkingSlot {
  final String id;
  final String code;
  final bool isOccupied;
  final String? zone;
  final DateTime? updatedAt;

  const ParkingSlot({
    required this.id,
    required this.code,
    required this.isOccupied,
    this.zone,
    this.updatedAt,
  });

  /// Maps ESP / Firebase RTDB spot JSON → app model.
  factory ParkingSlot.fromFirebaseJson(String key, Map<String, dynamic> json) {
    final id = (json['spot_id'] ?? key).toString();
    final label = (json['label'] as String?)?.trim();
    final status = (json['status'] as String? ?? '').toLowerCase();
    return ParkingSlot(
      id: id,
      code: (label != null && label.isNotEmpty) ? '$id · $label' : id,
      isOccupied: status == 'occupied',
      zone: 'Lot A',
      updatedAt: _parseUpdatedAt(json['updated_at']),
    );
  }

  /// ESP writes Unix seconds; ignore old millis()-style `timestamp`.
  static DateTime? _parseUpdatedAt(Object? raw) {
    if (raw == null) return null;
    final n = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    if (n == null) return null;
    // Seconds since epoch (after ~2023) or millis.
    if (n > 1e12) {
      return DateTime.fromMillisecondsSinceEpoch(n.round(), isUtc: true);
    }
    if (n > 1e9) {
      return DateTime.fromMillisecondsSinceEpoch((n * 1000).round(), isUtc: true);
    }
    return null;
  }
}

class ParkingSummary {
  final List<ParkingSlot> slots;

  const ParkingSummary(this.slots);

  int get total => slots.length;

  int get occupied => slots.where((s) => s.isOccupied).length;

  int get available => total - occupied;

  /// Freshest ESP write across bays (null if firmware never sent `updated_at`).
  DateTime? get lastEspUpdate {
    DateTime? best;
    for (final s in slots) {
      final t = s.updatedAt;
      if (t == null) continue;
      if (best == null || t.isAfter(best)) best = t;
    }
    return best;
  }

  /// True when ESP published recently (see [staleAfter]).
  bool isEspOnline({Duration staleAfter = const Duration(seconds: 45)}) {
    final last = lastEspUpdate;
    if (last == null) return false;
    return DateTime.now().toUtc().difference(last) <= staleAfter;
  }
}
