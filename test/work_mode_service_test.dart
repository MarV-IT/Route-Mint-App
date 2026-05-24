import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/features/work_mode/models/work_mode_settings.dart';
import 'package:route_mint_app/features/work_mode/models/work_shift.dart';
import 'package:route_mint_app/features/work_mode/services/work_mode_service.dart';

void main() {
  group('WorkModeService matchingShiftAt', () {
    final service = WorkModeService();

    test('returns the matching daytime shift', () {
      const settings = WorkModeSettings(
        isEnabled: true,
        shifts: [
          WorkShift(
            id: 'spark',
            platformName: 'Spark Driver',
            isCustomPlatform: false,
            startHour: 14,
            startMinute: 0,
            endHour: 22,
            endMinute: 0,
          ),
        ],
      );

      final match = service.matchingShiftAt(
        settings,
        DateTime(2026, 5, 22, 15, 30),
      );

      expect(match?.platformName, 'Spark Driver');
    });

    test('supports overnight shifts', () {
      const settings = WorkModeSettings(
        isEnabled: true,
        shifts: [
          WorkShift(
            id: 'uber',
            platformName: 'Uber',
            isCustomPlatform: false,
            startHour: 22,
            startMinute: 0,
            endHour: 6,
            endMinute: 0,
          ),
        ],
      );

      expect(
        service.matchingShiftAt(settings, DateTime(2026, 5, 22, 23, 30))?.id,
        'uber',
      );
      expect(
        service.matchingShiftAt(settings, DateTime(2026, 5, 23, 5, 30))?.id,
        'uber',
      );
      expect(
        service.matchingShiftAt(settings, DateTime(2026, 5, 23, 12, 0)),
        isNull,
      );
    });

    test('does not match when work mode is disabled', () {
      const settings = WorkModeSettings(
        isEnabled: false,
        shifts: [
          WorkShift(
            id: 'lyft',
            platformName: 'Lyft',
            isCustomPlatform: false,
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 0,
          ),
        ],
      );

      expect(
        service.matchingShiftAt(settings, DateTime(2026, 5, 22, 10, 0)),
        isNull,
      );
    });
  });
}
