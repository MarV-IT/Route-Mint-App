import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_entry.dart';

class ExpenseService {
  static const _storageKey = 'expense_entries';

  Future<List<ExpenseEntry>> loadExpenseEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final entries = <ExpenseEntry>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          entries.add(ExpenseEntry.fromJson(item));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[ExpenseService] skipped malformed entry: $e');
          }
        }
      }
      return entries;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ExpenseService] corrupted expense JSON: $e');
      }
      return [];
    }
  }

  Future<void> saveExpenseEntries(List<ExpenseEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> addExpenseEntry(ExpenseEntry entry) async {
    final entries = await loadExpenseEntries();
    entries.add(entry);
    await saveExpenseEntries(entries);
  }

  Future<void> deleteExpenseEntry(String id) async {
    final entries = await loadExpenseEntries();
    entries.removeWhere((entry) => entry.id == id);
    await saveExpenseEntries(entries);
  }
}
