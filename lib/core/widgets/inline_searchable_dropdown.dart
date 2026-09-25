// lib/core/widgets/inline_searchable_dropdown.dart
//
// Widget dropdown inline dengan pencarian terintegrasi di bawah field.
// Tidak menggunakan popup atau bottom sheet modal.

import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class InlineSearchableDropdown extends StatefulWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final List<String> items;
  final String? Function(String?)? validator;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;

  const InlineSearchableDropdown({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.controller,
    required this.items,
    this.validator,
    this.fieldKey,
    this.onChanged,
  });

  @override
  State<InlineSearchableDropdown> createState() =>
      _InlineSearchableDropdownState();
}

class _InlineSearchableDropdownState extends State<InlineSearchableDropdown> {
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return widget.items;
    }
    return widget.items
        .where(
          (item) => item.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _selectItem(String item) {
    widget.controller.text = item;
    widget.onChanged?.call(item);
    setState(() {
      _isExpanded = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Utama
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (!_isExpanded) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
          onChanged: (val) {
            widget.onChanged?.call(val);
            if (_isExpanded) {
              setState(() {
                _searchQuery = val;
              });
            }
          },
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            suffixIcon: IconButton(
              icon: Icon(
                _isExpanded
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
                color: AppColors.primary,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                  if (!_isExpanded) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),

        // Panel Dropdown Langsung di Bawah Field
        if (_isExpanded) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Input di dalam Panel
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari lokasi...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Daftar Lokasi (Maksimal tinggi 180 agar nyaman)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'Lokasi tidak ditemukan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isSelected =
                                widget.controller.text.trim() == item;
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: AppColors.primary,
                                      )
                                    : null,
                                onTap: () => _selectItem(item),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
