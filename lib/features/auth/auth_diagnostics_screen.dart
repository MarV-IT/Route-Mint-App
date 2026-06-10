import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/auth_service.dart';

class AuthDiagnosticsScreen extends StatefulWidget {
  const AuthDiagnosticsScreen({super.key});

  @override
  State<AuthDiagnosticsScreen> createState() => _AuthDiagnosticsScreenState();
}

class _AuthDiagnosticsScreenState extends State<AuthDiagnosticsScreen> {
  final _authService = AuthService();
  Future<Map<String, String>>? _diagnosticsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _diagnosticsFuture = _authService.diagnostics();
    });
  }

  Future<void> _copy(Map<String, String> values) async {
    final text = values.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Diagnostics copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth diagnostics')),
      body: FutureBuilder<Map<String, String>>(
        future: _diagnosticsFuture,
        builder: (context, snapshot) {
          final values = snapshot.data;
          if (values == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Use this screen after closing and reopening the app. It shows whether Firebase restored the saved account.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    for (final entry in values.entries)
                      ListTile(
                        dense: true,
                        title: Text(entry.key),
                        subtitle: SelectableText(entry.value),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _copy(values),
                icon: const Icon(Icons.copy),
                label: const Text('Copy diagnostics'),
              ),
            ],
          );
        },
      ),
    );
  }
}
