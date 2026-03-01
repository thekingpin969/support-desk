import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'bloc/tickets_bloc.dart';
import '../data/ticket_repository.dart';
import '../../../core/di.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'medium';
  String? _categoryId;
  Map<String, String> _categories = {};
  bool _isLoadingCategories = true;
  final List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await sl<TicketRepository>().fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          if (_categories.isNotEmpty) {
            _categoryId = _categories.keys.first;
          }
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      if (_selectedImages.length + pickedFiles.length > 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only attach up to 5 images.')),
        );
        return;
      }
      setState(() {
        _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
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
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(
                        value: 'critical',
                        child: Text('Critical'),
                      ),
                    ],
                    onChanged: isLoading
                        ? null
                        : (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingCategories)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (v) => setState(() => _categoryId = v),
                    ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: isLoading || _selectedImages.length >= 5
                        ? null
                        : _pickImages,
                    icon: const Icon(Icons.image),
                    label: Text(
                      _selectedImages.isEmpty
                          ? 'Attach Images (Max 5)'
                          : 'Add More Images',
                    ),
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _selectedImages.map((file) {
                        return Chip(
                          label: Text(
                            file.path.split('/').last,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedImages.remove(file);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_titleController.text.isEmpty ||
                                _descController.text.isEmpty ||
                                _categoryId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Title, Description, and Category are required',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<TicketsBloc>().add(
                              CreateTicket(
                                _titleController.text,
                                _descController.text,
                                _categoryId!,
                                _priority,
                                imagePaths: _selectedImages
                                    .map((f) => f.path)
                                    .toList(),
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
