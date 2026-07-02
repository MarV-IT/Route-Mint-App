import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../core/localization/app_strings.dart';
import '../../core/preferences/user_preferences.dart';
import '../../shared/utils/currency_utils.dart';
import 'models/expense_entry.dart';
import 'services/expense_service.dart';

const _parking = 'parking';
const _tolls = 'tolls';
const _repair = 'repair';
const _service = 'service';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.preferences,
  });

  final AppStrings strings;
  final AppUnit unit;
  final UserPreferences preferences;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _expenseService = ExpenseService();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();

  List<ExpenseEntry> _entries = [];
  String _category = _parking;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final entries = await _expenseService.loadExpenseEntries();
    entries.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _date,
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _saveExpense() async {
    if (_isSaving) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.expenseAmountMustBePositive)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _expenseService.addExpenseEntry(
        ExpenseEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: _date,
          category: _category,
          amount: amount,
          vendor: _vendorController.text.trim().isEmpty
              ? null
              : _vendorController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
      );
      if (!mounted) return;
      _amountController.clear();
      _vendorController.clear();
      _notesController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.expenseSaved)));
      await _loadEntries();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteExpense(ExpenseEntry entry) async {
    await _expenseService.deleteExpenseEntry(entry.id);
    if (!mounted) return;
    await _loadEntries();
  }

  String _categoryLabel(String category) => switch (category) {
    _parking => widget.strings.parking,
    _tolls => widget.strings.tolls,
    _repair => widget.strings.repair,
    _service => widget.strings.serviceExpense,
    _ => category,
  };

  String _fmtDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;

    return Scaffold(
      appBar: AppBar(title: Text(s.addExpense)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.expenseType, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _categoryChip(_parking, s.parking),
              _categoryChip(_tolls, s.tolls),
              _categoryChip(_repair, s.repair),
              _categoryChip(_service, s.serviceExpense),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('${s.date}: ${_fmtDate(_date)}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.amount,
              border: const OutlineInputBorder(),
              prefixText: '${widget.preferences.currencyCode} ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vendorController,
            decoration: InputDecoration(
              labelText: s.vendor,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: s.notes,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveExpense,
            icon: const Icon(Icons.save_outlined),
            label: Text(_isSaving ? s.saving : s.saveExpense),
          ),
          const SizedBox(height: 24),
          Text(s.recentExpenses, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_entries.isEmpty)
            Text(
              s.noExpenses,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ..._entries
                .take(8)
                .map(
                  (entry) => Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(_categoryLabel(entry.category)),
                      subtitle: Text(
                        [
                          _fmtDate(entry.date),
                          if (entry.vendor != null) entry.vendor!,
                        ].join(' · '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatCurrency(
                              entry.amount,
                              widget.preferences.currencyCode,
                            ),
                          ),
                          IconButton(
                            tooltip: s.delete,
                            onPressed: () => _deleteExpense(entry),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _categoryChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _category == value,
      onSelected: (_) => setState(() => _category = value),
    );
  }
}
