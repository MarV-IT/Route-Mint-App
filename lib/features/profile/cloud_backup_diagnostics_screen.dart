import 'package:flutter/material.dart';

import '../../core/backup/cloud_backup_service.dart';

class CloudBackupDiagnosticsScreen extends StatelessWidget {
  const CloudBackupDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CloudBackupService();

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud backup diagnostics')),
      body: FutureBuilder<CloudBackupStatus>(
        future: service.getServerBackupStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DiagnosticsBody(
              rows: const [_DiagnosticRow('Server backup', 'check failed')],
            );
          }

          final status = snapshot.data;
          if (status == null) {
            return _DiagnosticsBody(
              rows: const [_DiagnosticRow('Server backup', 'unknown')],
            );
          }

          return _DiagnosticsBody(
            rows: [
              _DiagnosticRow('User ID', status.uid),
              _DiagnosticRow(
                'Server backup',
                status.exists ? 'found' : 'not found',
              ),
              if (status.exists) ...[
                _DiagnosticRow('Trips', status.tripCount.toString()),
                _DiagnosticRow('Expenses', status.expenseCount.toString()),
                _DiagnosticRow('Fuel entries', status.fuelCount.toString()),
                _DiagnosticRow(
                  'Updated at',
                  _formatDateTime(status.updatedAt ?? status.exportedAt),
                ),
                _DiagnosticRow(
                  'Backup version',
                  status.backupVersion?.toString() ?? 'unknown',
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) return 'unknown';
    final local = value.toLocal();
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class _DiagnosticsBody extends StatelessWidget {
  const _DiagnosticsBody({required this.rows});

  final List<_DiagnosticRow> rows;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(row.label),
          subtitle: Text(row.value),
        );
      },
    );
  }
}

class _DiagnosticRow {
  const _DiagnosticRow(this.label, this.value);

  final String label;
  final String value;
}
