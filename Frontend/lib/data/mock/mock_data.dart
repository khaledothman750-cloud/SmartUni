/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import '../../core/models/campus_location.dart';
import '../../core/models/parking_slot.dart';

/// Fallback sample data when AppConfig live API flags are off.
class MockData {
  MockData._();

  static const List<CampusLocation> locations = [
    CampusLocation(
      id: '1',
      name: 'Main Gate',
      type: 'entrance',
      floor: 0,
      building: 'Campus',
      description: 'Primary entrance of Abi Samra Campus',
    ),
    CampusLocation(
      id: '2',
      name: 'Engineering Building',
      type: 'building',
      floor: 0,
      building: 'ENG',
      description: 'Faculty of Engineering',
    ),
    CampusLocation(
      id: '3',
      name: 'Lab 2 — Networking',
      type: 'lab',
      floor: 2,
      building: 'ENG',
      description: 'Networking laboratory',
    ),
    CampusLocation(
      id: '4',
      name: 'Dean Office',
      type: 'office',
      floor: 3,
      building: 'Admin',
      description: 'Faculty Dean office',
    ),
    CampusLocation(
      id: '5',
      name: 'Library',
      type: 'facility',
      floor: 1,
      building: 'LIB',
      description: 'Central campus library',
    ),
    CampusLocation(
      id: '6',
      name: 'Parking Lot A',
      type: 'parking',
      floor: 0,
      building: 'Outdoor',
      description: 'Student parking zone A',
    ),
  ];

  static NavigationRoutePreview sampleRoute({
    required CampusLocation from,
    required CampusLocation to,
  }) {
    return NavigationRoutePreview(
      path: [from, locations[1], to],
      totalDistanceMeters: 185,
    );
  }

  static ParkingSummary parkingSummary() {
    final now = DateTime.now();
    return ParkingSummary([
      ParkingSlot(id: 'p1', code: 'A-01', isOccupied: true, zone: 'Lot A', updatedAt: now),
      ParkingSlot(id: 'p2', code: 'A-02', isOccupied: false, zone: 'Lot A', updatedAt: now),
      ParkingSlot(id: 'p3', code: 'A-03', isOccupied: true, zone: 'Lot A', updatedAt: now),
      ParkingSlot(id: 'p4', code: 'B-01', isOccupied: false, zone: 'Lot B', updatedAt: now),
      ParkingSlot(id: 'p5', code: 'B-02', isOccupied: false, zone: 'Lot B', updatedAt: now),
      ParkingSlot(id: 'p6', code: 'B-03', isOccupied: true, zone: 'Lot B', updatedAt: now),
    ]);
  }
}
