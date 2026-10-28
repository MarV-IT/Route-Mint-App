import 'package:flutter/widgets.dart';

import '../../app/app.dart';
import 'app_strings.dart';

/// Makes the active [AppStrings] reachable from widgets that should not need
/// strings passed down to them — such as HelpHint, which takes only a topic.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  /// Falls back to English outside the app shell, e.g. a screen pumped on its
  /// own in a test.
  static AppStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStringsScope>()?.strings ??
      const AppStrings(AppLanguage.english);

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      oldWidget.strings.currentLanguage != strings.currentLanguage;
}
