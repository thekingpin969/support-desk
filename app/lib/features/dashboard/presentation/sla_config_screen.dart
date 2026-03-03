import 'package:flutter/material.dart';
import '../../../core/di.dart';
import '../../../core/app_snackbar.dart';
import '../../../core/loading_button.dart';
import '../data/admin_repository.dart';

class SlaConfigScreen extends StatefulWidget {
  const SlaConfigScreen({super.key});

  @override
  State<SlaConfigScreen> createState() => _SlaConfigScreenState();
}

class _SlaConfigScreenState extends State<SlaConfigScreen> {
  List<dynamic> _configs = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    try {
      final data = await sl<AdminRepository>().fetchSlaConfigs();
      setState(() {
        _configs = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveConfigs() async {
    setState(() => _isSaving = true);
    try {
      final List<Map<String, dynamic>> toSave = _configs
          .map(
            (c) => {
              'priority': c['priority'],
              'response_hours': c['response_hours'],
              'warning_hours': c['warning_hours'],
            },
          )
          .toList();

      await sl<AdminRepository>().updateSlaConfigs(toSave);
      if (mounted) {
        AppSnackBar.success(context, 'Saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showEditSheet(int index) {
    final conf = _configs[index];
    final rhCtrl = TextEditingController(
      text: conf['response_hours'].toString(),
    );
    final whCtrl = TextEditingController(
      text: conf['warning_hours'].toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit ${conf['priority']} SLA',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rhCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Response Hours Limit',
              ),
            ),
            TextField(
              controller: whCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Warning Hours Threshold',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _configs[index]['response_hours'] =
                      int.tryParse(rhCtrl.text) ?? 24;
                  _configs[index]['warning_hours'] =
                      int.tryParse(whCtrl.text) ?? 20;
                });
                Navigator.pop(context);
              },
              child: const Text('Update Local'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SLA Configuration'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LoadingButton(
              isLoading: _isSaving,
              label: 'Save',
              icon: Icons.save,
              onPressed: _saveConfigs,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _configs.length,
              itemBuilder: (context, index) {
                final c = _configs[index];
                return ListTile(
                  title: Text('Priority: ${c['priority']}'),
                  subtitle: Text(
                    'SLA Deadline: ${c['response_hours']}h | Warning at: ${c['warning_hours']}h',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showEditSheet(index),
                );
              },
            ),
    );
  }
}
