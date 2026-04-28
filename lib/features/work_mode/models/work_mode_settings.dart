import 'work_shift.dart';

class WorkModeSettings {
  final bool isEnabled;
  final List<WorkShift> shifts;

  const WorkModeSettings({required this.isEnabled, required this.shifts});

  factory WorkModeSettings.defaults() =>
      const WorkModeSettings(isEnabled: false, shifts: []);

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'shifts': shifts.map((s) => s.toJson()).toList(),
  };

  factory WorkModeSettings.fromJson(Map<String, dynamic> json) {
    final shiftsJson = json['shifts'];

    return WorkModeSettings(
      isEnabled: json['isEnabled'] is bool ? json['isEnabled'] as bool : false,
      shifts: shiftsJson is List<dynamic> ? _parseShifts(shiftsJson) : [],
    );
  }

  WorkModeSettings copyWith({bool? isEnabled, List<WorkShift>? shifts}) =>
      WorkModeSettings(
        isEnabled: isEnabled ?? this.isEnabled,
        shifts: shifts ?? this.shifts,
      );

  @override
  String toString() =>
      'WorkModeSettings(isEnabled: $isEnabled, shifts: $shifts)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkModeSettings &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          shifts == other.shifts;

  @override
  int get hashCode => isEnabled.hashCode ^ shifts.hashCode;
}

List<WorkShift> _parseShifts(List<dynamic> items) {
  final shifts = <WorkShift>[];

  for (final item in items) {
    if (item is! Map<String, dynamic>) continue;

    try {
      shifts.add(WorkShift.fromJson(item));
    } catch (_) {
      // Skip malformed saved entries without discarding valid shifts.
    }
  }

  return shifts;
}
