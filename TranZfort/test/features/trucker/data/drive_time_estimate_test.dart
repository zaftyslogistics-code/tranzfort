import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/trucker/data/drive_time_estimate.dart';

void main() {
  group('DriveTimeEstimate', () {
    test('estimates days at 300 km per day', () {
      expect(DriveTimeEstimate.estimateDays(600), 2);
      expect(DriveTimeEstimate.estimateDays(842), closeTo(2.81, 0.01));
      expect(DriveTimeEstimate.estimateDays(0), 0);
    });

    test('formats day count for display', () {
      expect(DriveTimeEstimate.formatDayCount(2), '2');
      expect(DriveTimeEstimate.formatDayCount(2.8), '2.8');
      expect(DriveTimeEstimate.formatDayCount(0), '0');
    });
  });
}
