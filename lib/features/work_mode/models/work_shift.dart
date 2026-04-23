class WorkShift {
  final String id;
  final String platformName;
  final bool isCustomPlatform;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const WorkShift({
    required this.id,
    required this.platformName,
    required this.isCustomPlatform,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  factory WorkShift.createDefault() => WorkShift(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        platformName: 'Uber',
        isCustomPlatform: false,
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'platformName': platformName,
        'isCustomPlatform': isCustomPlatform,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  factory WorkShift.fromJson(Map<String, dynamic> json) => WorkShift(
        id: json['id'] as String,
        platformName: json['platformName'] as String,
        isCustomPlatform: json['isCustomPlatform'] as bool,
        startHour: json['startHour'] as int,
        startMinute: json['startMinute'] as int,
        endHour: json['endHour'] as int,
        endMinute: json['endMinute'] as int,
      );

  WorkShift copyWith({
    String? id,
    String? platformName,
    bool? isCustomPlatform,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) =>
      WorkShift(
        id: id ?? this.id,
        platformName: platformName ?? this.platformName,
        isCustomPlatform: isCustomPlatform ?? this.isCustomPlatform,
        startHour: startHour ?? this.startHour,
        startMinute: startMinute ?? this.startMinute,
        endHour: endHour ?? this.endHour,
        endMinute: endMinute ?? this.endMinute,
      );

  @override
  String toString() =>
      'WorkShift(id: $id, platformName: $platformName, '
      'isCustomPlatform: $isCustomPlatform, '
      'start: $startHour:${startMinute.toString().padLeft(2, '0')}, '
      'end: $endHour:${endMinute.toString().padLeft(2, '0')})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkShift &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
