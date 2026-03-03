import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'bloc/tickets_bloc.dart';
import '../data/ticket_repository.dart';
import '../../../core/di.dart';
import '../../../core/app_snackbar.dart';
import '../../../core/loading_button.dart';

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

  // Tracks the current upload phase label shown inside the button
  String _loadingLabel = 'Submit Ticket';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
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
        AppSnackBar.error(context, 'Failed to load categories: $e');
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      if (_selectedImages.length + pickedFiles.length > 5) {
        if (!mounted) return;
        AppSnackBar.warning(context, 'You can only attach up to 5 images.');
        return;
      }
      setState(() {
        _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  void _removeImage(File file) {
    setState(() => _selectedImages.remove(file));
  }

  void _submit(BuildContext context) {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      AppSnackBar.warning(context, 'Please enter a title for the ticket.');
      return;
    }
    if (desc.isEmpty) {
      AppSnackBar.warning(context, 'Please enter a description.');
      return;
    }
    if (_categoryId == null) {
      AppSnackBar.warning(context, 'Please select a category.');
      return;
    }

    // Set phase label before dispatching
    setState(() {
      _loadingLabel = _selectedImages.isNotEmpty
          ? 'Uploading images…'
          : 'Submitting…';
    });

    context.read<TicketsBloc>().add(
      CreateTicket(
        title,
        desc,
        _categoryId!,
        _priority,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      ),
    );
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
              // Reset label before showing error
              setState(() => _loadingLabel = 'Submit Ticket');
              AppSnackBar.error(context, state.message);
            } else if (state is TicketsLoading &&
                _selectedImages.isNotEmpty &&
                _loadingLabel == 'Uploading images…') {
              // Images uploaded, now submitting
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) setState(() => _loadingLabel = 'Submitting…');
              });
            } else if (state is TicketsLoaded) {
              AppSnackBar.success(context, '🎉 Ticket submitted successfully!');
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
                  // ── Title ─────────────────────────────────────────────
                  TextField(
                    controller: _titleController,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Brief summary of the issue',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Description ───────────────────────────────────────
                  TextField(
                    controller: _descController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the problem in detail…',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // ── Priority ──────────────────────────────────────────
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
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

                  // ── Category ──────────────────────────────────────────
                  if (_isLoadingCategories)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
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

                  // ── Attach Images ─────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: isLoading || _selectedImages.length >= 5
                        ? null
                        : _pickImages,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _selectedImages.isEmpty
                          ? 'Attach Images (Max 5)'
                          : 'Add More (${_selectedImages.length}/5)',
                    ),
                  ),

                  // ── Image Thumbnails ──────────────────────────────────
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final file = _selectedImages[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  file,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Delete overlay button
                              if (!isLoading)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(file),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Submit Button ─────────────────────────────────────
                  LoadingButton(
                    isLoading: isLoading,
                    label: isLoading ? _loadingLabel : 'Submit Ticket',
                    icon: Icons.send_outlined,
                    onPressed: () => _submit(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
