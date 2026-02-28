import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'bloc/tickets_bloc.dart';
import '../../../core/di.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'MEDIUM';
  String _categoryId =
      'general'; // In a real app, fetch from /v1/admin/categories
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TicketsBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Ticket')),
        body: BlocConsumer<TicketsBloc, TicketsState>(
          listener: (context, state) {
            if (state is TicketsError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is TicketsLoaded) {
              // Successfully created, emit loaded state implies refresh done.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ticket created successfully')),
              );
              context.pop();
            }
          },
          builder: (context, state) {
            final isLoading = state is TicketsLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 4,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      DropdownMenuItem(
                        value: 'CRITICAL',
                        child: Text('Critical'),
                      ),
                    ],
                    onChanged: isLoading
                        ? null
                        : (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 16),
                  // Categories mock
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(
                        value: 'general',
                        child: Text('General Inquiry'),
                      ),
                      DropdownMenuItem(
                        value: 'billing',
                        child: Text('Billing'),
                      ),
                      DropdownMenuItem(
                        value: 'technical',
                        child: Text('Technical Support'),
                      ),
                    ],
                    onChanged: isLoading
                        ? null
                        : (v) => setState(() => _categoryId = v!),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(
                      _selectedImage == null ? 'Attach Image' : 'Change Image',
                    ),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selected: ${_selectedImage!.path.split('/').last}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_titleController.text.isEmpty ||
                                _descController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Title and Description required',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<TicketsBloc>().add(
                              CreateTicket(
                                _titleController.text,
                                _descController.text,
                                _categoryId, // assuming UUID in real scenario
                                _priority,
                                imagePath: _selectedImage?.path,
                              ),
                            );
                          },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Ticket'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
