import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ai/ai_service.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import 'ai_menu_sheet.dart' show friendlyAIError;
import 'ai_menu_sheet.dart' show AIMenuSheet;

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;
  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen>
    with SingleTickerProviderStateMixin {
  final NoteService _noteService = NoteService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  TextSelection _descriptionSelection = const TextSelection.collapsed(
    offset: 0,
  );

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSaving = false;
  bool _isContinuing = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.note?.description ?? '',
    );
    _descriptionSelection = TextSelection.collapsed(
      offset: _descriptionController.text.length,
    );
    _descriptionController.addListener(_syncSelection);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_syncSelection);
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _syncSelection() {
    _descriptionSelection = _descriptionController.selection;
  }

  String _textBeforeCursor() {
    final sel = _descriptionSelection;
    final clamped = sel.start.clamp(0, _descriptionController.text.length);
    return _descriptionController.text.substring(0, clamped);
  }

  Future<void> _continueWriting() async {
    final textBeforeCursor = _textBeforeCursor().trim();
    if (textBeforeCursor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Place your cursor where you want the AI to continue.'),
        ),
      );
      return;
    }
    setState(() => _isContinuing = true);
    final ai = context.read<AIService>();
    final buffer = StringBuffer();
    try {
      await ai.continueWriting(
        textBeforeCursor: textBeforeCursor,
        onDelta: (delta) {
          buffer.write(delta);
          final currentText = _descriptionController.text;
          final insertAt = _descriptionSelection.start.clamp(
            0,
            currentText.length,
          );
          final newText =
              currentText.substring(0, insertAt) +
              delta +
              currentText.substring(insertAt);
          _descriptionController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: insertAt + delta.length),
          );
        },
      );
      if (buffer.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No continuation was generated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyAIError(e))));
      }
    } finally {
      if (mounted) setState(() => _isContinuing = false);
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newTitle = _titleController.text.trim();
      final newDescription = _descriptionController.text.trim();
      String? savedId;
      if (_isEditing) {
        await _noteService.updateNote(
          widget.note!.id,
          newTitle,
          newDescription,
        );
        savedId = widget.note!.id;
      } else {
        savedId = await _noteService.createNote(newTitle, newDescription);
      }

      if (savedId != null) {
        _refreshEmbedding(savedId, newTitle, newDescription);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Note updated successfully'
                  : 'Note created successfully',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF43E97B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF6584),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _refreshEmbedding(
    String id,
    String title,
    String description,
  ) async {
    final ai = context.read<AIService>();
    if (ai.config.apiKey == null || ai.config.apiKey!.isEmpty) return;
    try {
      final combined = '$title\n\n$description';
      final embedding = await ai.embed(combined);
      if (embedding.isEmpty) return;
      await _noteService.updateEmbedding(id, embedding);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildForm()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isEditing ? 'Edit Note' : 'Create Note',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (_isEditing)
            IconButton(
              tooltip: 'AI actions',
              onPressed: () => AIMenuSheet.show(context, widget.note!),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 4),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveNote,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: _isSaving
              ? LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.5),
                    const Color(0xFF4834DF).withValues(alpha: 0.5),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isSaving
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionLabel('Title', Icons.title_rounded),
          const SizedBox(height: 10),
          _buildTitleField(),
          const SizedBox(height: 28),
          _buildSectionLabel('Description', Icons.description_rounded),
          const SizedBox(height: 10),
          _buildDescriptionField(),
          const SizedBox(height: 14),
          _buildContinueWritingRow(),
          const SizedBox(height: 32),
          _buildBottomSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF6C63FF).withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Enter note title...',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 17,
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6584), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6584), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6584)),
      ),
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
      decoration: InputDecoration(
        hintText: 'Write your note here...',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 15,
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6584), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6584), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6584)),
        counterStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 12,
        ),
      ),
      maxLines: 12,
      minLines: 6,
      maxLength: 1000,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildContinueWritingRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Place your cursor and tap to let the AI keep writing.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
        GestureDetector(
          onTap: _isContinuing ? null : _continueWriting,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.45),
              ),
            ),
            child: _isContinuing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B83FF),
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF8B83FF),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Continue writing',
                        style: TextStyle(
                          color: Color(0xFF8B83FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveNote,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isSaving
              ? LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.5),
                    const Color(0xFF4834DF).withValues(alpha: 0.5),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isSaving
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  _isEditing ? 'Update Note' : 'Create Note',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
