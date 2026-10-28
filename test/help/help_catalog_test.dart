import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/help/help_catalog.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';

/// Words are tokens with at least one letter or digit, so a standalone dash
/// or a French « » is not counted.
int wordCount(String text) => text
    .trim()
    .split(RegExp(r'\s+'))
    .where((t) => RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(t))
    .length;

int sentenceCount(String text) =>
    RegExp(r'[.!?؟](?=\s|$)').allMatches(text.trim()).length;

void main() {
  test('every topic has a text in every language', () {
    for (final topic in HelpTopic.values) {
      for (final language in AppLanguage.values) {
        final entry = helpCatalog[topic]?[language];
        expect(entry, isNotNull, reason: '${topic.id} / $language missing');
        expect(entry!.body.trim(), isNotEmpty);
        expect(entry.example?.trim(), isNot(''));
        expect(
          helpTitle(topic, AppStrings(language)).trim(),
          isNotEmpty,
          reason: '${topic.id} / $language title',
        );
      }
    }
  });

  test('an explanation fits in 60 words, example included', () {
    for (final topic in HelpTopic.values) {
      for (final language in AppLanguage.values) {
        final entry = helpEntry(topic, language);
        final words =
            wordCount(entry.body) + wordCount(entry.example ?? '');
        expect(
          words,
          lessThanOrEqualTo(60),
          reason: '${topic.id} / $language has $words words',
        );
      }
    }
  });

  test('an explanation is two to four sentences', () {
    for (final topic in HelpTopic.values) {
      for (final language in AppLanguage.values) {
        final sentences = sentenceCount(helpEntry(topic, language).body);
        expect(
          sentences,
          inInclusiveRange(2, 4),
          reason: '${topic.id} / $language has $sentences sentences',
        );
      }
    }
  });

  test('a topic has an example in every language or in none', () {
    // Keeps translations from drifting apart.
    for (final topic in HelpTopic.values) {
      final withExample = AppLanguage.values
          .where((l) => helpEntry(topic, l).example != null)
          .length;
      expect(
        withExample,
        anyOf(0, AppLanguage.values.length),
        reason: topic.id,
      );
    }
  });

  test('analytics topic ids are unique and stable', () {
    final ids = HelpTopic.values.map((t) => t.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, [
      'home',
      'trips',
      'add_trip',
      'platforms',
      'reports',
      'charts',
      'premium',
    ]);
  });

  test('the counters behave on the tricky cases', () {
    expect(wordCount('Тут — «Особисті» : 3 хвилини.'), 4);
    expect(sentenceCount('Один. Два! Три? چهار؟'), 4);
    expect(sentenceCount('Uber from 6:00 PM to 2:00 AM'), 0);
  });
}
