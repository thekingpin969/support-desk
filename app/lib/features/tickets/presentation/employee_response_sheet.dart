import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants.dart';
import '../../../core/loading_button.dart';
import 'bloc/tickets_bloc.dart';
import '../domain/ticket_model.dart';

class EmployeeResponseSheet extends StatefulWidget {
  final TicketModel ticket;

  const EmployeeResponseSheet({super.key, required this.ticket});

  @override
  State<EmployeeResponseSheet> createState() => _EmployeeResponseSheetState();
}

class _EmployeeResponseSheetState extends State<EmployeeResponseSheet> {
  final _contentController = TextEditingController();
  final List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    // Pre-load existing draft or revision-requested response text
    final responses = widget.ticket.responses;
    if (responses.isNotEmpty) {
      final draft = responses.lastWhere(
        (r) =>
            r.type == 'DRAFT' ||
            r.type == 'draft' ||
            r.type == 'REVISION_REQUESTED' ||
            r.type == 'revision_requested',
        orElse: () => responses.last,
      );
      // Only pre-fill if it's a draft or revision-requested
      if (draft.type == 'DRAFT' ||
          draft.type == 'draft' ||
          draft.type == 'REVISION_REQUESTED' ||
          draft.type == 'revision_requested') {
        _contentController.text = draft.content;
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      if (_selectedImages.length + pickedFiles.length > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 images allowed.')),
          );
        }
        return;
      }
      setState(() {
        _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  void _submit({required bool saveDraft}) {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response cannot be empty.')),
      );
      return;
    }
    context.read<TicketsBloc>().add(
      CreateResponse(
        ticketId: widget.ticket.id,
        content: _contentController.text.trim(),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
        saveDraft: saveDraft,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasRevision = widget.ticket.responses.any(
      (r) => r.type == 'REVISION_REQUESTED' || r.type == 'revision_requested',
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Write Response',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (hasRevision) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin requested revision. Update your response below.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Enter your response...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Image picker row
            OutlinedButton.icon(
              onPressed: _selectedImages.length >= 5 ? null : _pickImages,
              icon: const Icon(Icons.image),
              label: Text(
                _selectedImages.isEmpty
                    ? 'Attach Images (Max 5)'
                    : 'Add More Images (${_selectedImages.length}/5)',
              ),
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedImages.map((file) {
                  return Chip(
                    label: Text(
                      file.path.split('/').last,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: () =>
                        setState(() => _selectedImages.remove(file)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                // Save Draft
                Expanded(
                  child: BlocBuilder<TicketsBloc, TicketsState>(
                    builder: (context, state) {
                      final isLoading = state is TicketsLoading;
                      return LoadingButton(
                        isLoading: isLoading,
                        label: 'Save Draft',
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.primary,
                        onPressed: isLoading
                            ? null
                            : () => _submit(saveDraft: true),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Submit for Review
                Expanded(
                  flex: 2,
                  child: BlocBuilder<TicketsBloc, TicketsState>(
                    builder: (context, state) {
                      final isLoading = state is TicketsLoading;
                      return LoadingButton(
                        isLoading: isLoading,
                        label: 'Submit for Review',
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        onPressed: isLoading
                            ? null
                            : () => _submit(saveDraft: false),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
