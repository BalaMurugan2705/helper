import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/html_file.dart';
import '../../providers/providers.dart';
import '../../services/firebase_service.dart';

// Firestore documents are capped at 1 MiB; leave headroom for the other fields.
const int _maxHtmlFileBytes = 900 * 1024;

class HtmlFilesScreen extends ConsumerWidget {
  const HtmlFilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(htmlFilesProvider);

    final count = filesAsync.when(
      data: (files) => files.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      body: Column(
        children: [
          AuroraHero(
            accent: AppColors.accentHtmlFiles,
            eyebrow: 'HOME · HTML FILES',
            title: 'HTML Files',
            subtitle: count == 1 ? '1 file saved' : '$count files saved',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filesAsync.when(
              data: (files) {
                if (files.isEmpty) return _emptyState();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _HtmlFileCard(file: files[i]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final service = ref.read(firebaseServiceProvider);
          if (service != null) _pickAndAddFile(context, service);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add HTML'),
        backgroundColor: AppColors.accentHtmlFiles,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code_rounded,
              size: 64, color: AppColors.textSubtle.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No HTML files yet', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('Tap + to add your first file', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

Future<void> _pickAndAddFile(
    BuildContext context, FirebaseService service) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['html', 'htm'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;
  if (!context.mounted) return;

  final picked = result.files.single;
  final bytes = picked.bytes;
  if (bytes == null) {
    _showError(context, 'Could not read the selected file.');
    return;
  }
  if (bytes.lengthInBytes > _maxHtmlFileBytes) {
    _showError(context, 'File is too large (max 900 KB).');
    return;
  }

  String content;
  try {
    content = utf8.decode(bytes);
  } catch (_) {
    _showError(context, 'That file does not look like valid text/HTML.');
    return;
  }

  final defaultName = picked.name.replaceAll(RegExp(r'\.html?$'), '');

  showGlassSheet(
    context: context,
    title: 'Save HTML File',
    content: _SaveFileForm(
      service: service,
      defaultName: defaultName,
      content: content,
      sizeBytes: bytes.lengthInBytes,
    ),
  );
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

// ─── Save form ──────────────────────────────────────────────────────

class _SaveFileForm extends StatefulWidget {
  final FirebaseService service;
  final String defaultName;
  final String content;
  final int sizeBytes;

  const _SaveFileForm({
    required this.service,
    required this.defaultName,
    required this.content,
    required this.sizeBytes,
  });

  @override
  State<_SaveFileForm> createState() => _SaveFileFormState();
}

class _SaveFileFormState extends State<_SaveFileForm> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await widget.service.addHtmlFile(HtmlFile(
      id: '',
      name: name.toLowerCase().endsWith('.html') ? name : '$name.html',
      content: widget.content,
      sizeBytes: widget.sizeBytes,
      createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'File name *',
            prefixIcon: Icon(Icons.description_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentHtmlFiles,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Save File',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── File card ──────────────────────────────────────────────────────

class _HtmlFileCard extends ConsumerWidget {
  final HtmlFile file;
  const _HtmlFileCard({required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;

    return Dismissible(
      key: Key(file.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.statusOverdue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.statusOverdue, size: 24),
      ),
      onDismissed: (_) => service.deleteHtmlFile(file.id),
      child: GestureDetector(
        onTap: () => context.push('/html-files/view', extra: file),
        child: GlassCard(
          accent: AppColors.accentHtmlFiles,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentHtmlFiles.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.code_rounded,
                    color: AppColors.accentHtmlFiles, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('MMM d, yyyy').format(file.createdAt)} · ${_formatSize(file.sizeBytes)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  return '${(bytes / 1024).toStringAsFixed(1)} KB';
}
