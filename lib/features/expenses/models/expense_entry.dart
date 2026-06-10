class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.vendor,
    this.notes,
  });

  final String id;
  final DateTime date;
  final String category;
  final double amount;
  final String? vendor;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'category': category,
    'amount': amount,
    'vendor': vendor,
    'notes': notes,
  };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) => ExpenseEntry(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String).toLocal(),
    category: json['category'] as String,
    amount: (json['amount'] as num).toDouble(),
    vendor: _stringOrNull(json['vendor']),
    notes: _stringOrNull(json['notes']),
  );
}

String? _stringOrNull(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
