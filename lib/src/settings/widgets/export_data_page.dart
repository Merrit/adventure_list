import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tasks/tasks.dart';

/// A page that allows the user to export their tasks data.
class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  static const String routeName = '/settings/export_data';

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  bool success = false;

  @override
  Widget build(BuildContext context) {
    final Widget contents;

    if (success) {
      contents = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, color: Colors.green),
              SizedBox(width: 8),
              Text('Data exported successfully!'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Return to Settings'),
          ),
        ],
      );
    } else {
      contents = ElevatedButton(
        onPressed: () => exportData(context),
        child: const Text('Export Data'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: Center(
        child: contents,
      ),
    );
  }

  Future<void> exportData(BuildContext context) async {
    final successful = await context.read<TasksCubit>().exportTasks();
    setState(() => success = successful);
  }
}
