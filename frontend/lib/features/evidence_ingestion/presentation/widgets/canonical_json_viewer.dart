import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class CanonicalJsonViewer extends StatefulWidget {
  final Map<String, dynamic> data;

  const CanonicalJsonViewer({super.key, required this.data});

  @override
  State<CanonicalJsonViewer> createState() => _CanonicalJsonViewerState();
}

class _CanonicalJsonViewerState extends State<CanonicalJsonViewer> {
  bool _isExpanded = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(widget.data);

    // Filter lines if search query is provided
    String displayContent = formatted;
    if (_searchQuery.trim().isNotEmpty) {
      final lines = formatted.split('\n');
      final matchedLines = lines.where((l) => l.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
      displayContent = matchedLines.isNotEmpty
          ? '// Filtered view matching "$_searchQuery":\n\n${matchedLines.join('\n')}'
          : '// No matches found for "$_searchQuery" in canonical payload.';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.data_object_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Universal CanonicalObservation v1 Payload', style: AppTextStyles.headingSmall),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, size: 18),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      tooltip: _isExpanded ? 'Collapse' : 'Expand',
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: formatted));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Canonical JSON copied to clipboard')),
                        );
                      },
                      tooltip: 'Copy JSON',
                    ),
                  ],
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // Search Filter Bar
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Search inside payload (e.g. timestamps, PS1, median, sha256)...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, size: 16),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 380),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    displayContent,
                    style: AppTextStyles.monoSmall.copyWith(
                      color: const Color(0xFFE2E8F0),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
