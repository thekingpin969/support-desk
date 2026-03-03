import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di.dart';
import '../data/admin_repository.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  List<dynamic> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final emps = await sl<AdminRepository>().fetchEmployees();
      setState(() {
        _employees = emps;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddEmployeeDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final deptCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Employee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(
                  labelText: 'Department (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await sl<AdminRepository>().createEmployee({
                  'email': emailCtrl.text,
                  'password': passCtrl.text,
                  'full_name': nameCtrl.text,
                  if (deptCtrl.text.isNotEmpty) 'department': deptCtrl.text,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadEmployees();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(dynamic employee) {
    bool isActive = employee['is_active'];
    final maxCapCtrl = TextEditingController(
      text: employee['employee_profile']['max_capacity'].toString(),
    );
    final deptCtrl = TextEditingController(
      text: employee['employee_profile']['department'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: Text('Edit ${employee['full_name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                TextField(
                  controller: maxCapCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Capacity'),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (val) => setStateBuilder(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await sl<AdminRepository>().updateEmployee(employee['id'], {
                    'department': deptCtrl.text,
                    'max_capacity': int.tryParse(maxCapCtrl.text) ?? 10,
                    'is_active': isActive,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadEmployees();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final emp = _employees[index];
                final profile = emp['employee_profile'];
                return ListTile(
                  title: Text(emp['full_name']),
                  subtitle: Text(
                    '${emp['email']} | Dept: ${profile['department'] ?? 'N/A'}\nOpen Tickets: ${profile['open_ticket_count']}/${profile['max_capacity']}',
                  ),
                  isThreeLine: true,
                  trailing: Icon(
                    emp['is_active'] ? Icons.check_circle : Icons.cancel,
                    color: emp['is_active'] ? Colors.green : Colors.red,
                  ),
                  onTap: () =>
                      context.push('/admin/employee-detail', extra: emp),
                  onLongPress: () => _showEditEmployeeDialog(emp),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
