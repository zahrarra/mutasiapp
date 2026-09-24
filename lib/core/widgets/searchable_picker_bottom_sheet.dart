// lib/core/widgets/searchable_picker_bottom_sheet.dart

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Modal bottom sheet yang menampilkan dropdown searchable.
/// Saat dibuka hanya menampilkan beberapa item teratas (scrollable),
/// dan dilengkapi dengan search bar untuk mencari item lainnya.
class SearchablePickerBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedItem;
  final String searchHint;
  final List<String>? quickActions;

  const SearchablePickerBottomSheet({
    super.key,
    required this.title,
    required this.items,
    this.selectedItem,
    this.searchHint = 'Cari...',
    this.quickActions,
  });

  /// Helper statis untuk membuka picker.
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required List<String> items,
    String? selectedItem,
    String searchHint = 'Cari...',
    List<String>? quickActions,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchablePickerBottomSheet(
        title: title,
        items: items,
        selectedItem: selectedItem,
        searchHint: searchHint,
        quickActions: quickActions,
      ),
    );
  }

  @override
  State<SearchablePickerBottomSheet> createState() =>
      _SearchablePickerBottomSheetState();
}

class _SearchablePickerBottomSheetState
    extends State<SearchablePickerBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.65;

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        margin: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Title & Close Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Quick actions (e.g. Gunakan PIC Lama)
            if (widget.quickActions != null &&
                widget.quickActions!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: widget.quickActions!.map((qa) {
                    return ActionChip(
                      avatar: const Icon(Icons.history, size: 16),
                      label: Text(
                        qa,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      onPressed: () => Navigator.of(context).pop(qa),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),

            const Divider(height: 12),

            // Scrollable List of Items
            Flexible(
              child: _filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tidak ada data yang sesuai "${_searchCtrl.text}"',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_searchCtrl.text.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ActionChip(
                                avatar: const Icon(Icons.check, size: 16),
                                label: Text('Gunakan "${_searchCtrl.text.trim()}"'),
                                onPressed: () => Navigator.of(context)
                                    .pop(_searchCtrl.text.trim()),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (ctx, index) {
                        final item = _filteredItems[index];
                        final isSelected = item == widget.selectedItem;

                        return ListTile(
                          dense: true,
                          title: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                  size: 18,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
