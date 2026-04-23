import 'work_shift.dart';

class WorkModeSettings {
  final bool isEnabled;
  final List<WorkShift> shifts;

  const WorkModeSettings({
    required this.isEnabled,
    required this.shifts,
  });

  factory WorkModeSettings.defaults() => const WorkModeSettings(
        isEnabled: false,
        shifts: [],
      );

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'shifts': shifts.map((s) => s.toJson()).toList(),
      };

  factory WorkModeSettings.fromJson(Map<String, dynamic> json) =>
    WorkModeSettings(
      isEnabled: json['isEnabled'] as bool? ?? false,
      shifts: (json['shifts'] as List<dynamic>? ?? [])
          .map((item) => WorkShift.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

  WorkModeSettings copyWith({
    bool? isEnabled,
    List<WorkShift>? shifts,
  }) =>
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
