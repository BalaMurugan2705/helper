import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../core/widgets/status_chip.dart';
import '../../models/wish_item.dart';
import '../../providers/providers.dart';
import '../../services/firebase_service.dart';

// ─── Category filter provider ─────────────────────────────────────

final _wishCategoryFilterProvider =
    StateProvider<WishCategory?>((ref) => null); // null = All

// ─── Screen ───────────────────────────────────────────────────────

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishAsync = ref.watch(wishListProvider);
    final filter = ref.watch(_wishCategoryFilterProvider);

    final total = wishAsync.when(
      data: (items) =>
          items.where((i) => i.status == WishStatus.pending).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final totalCost = wishAsync.when(
      data: (items) => items
          .where((i) => i.status == WishStatus.pending)
          .fold(0.0, (s, i) => s + i.totalCost),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final subtitle = totalCost > 0
        ? '$total wishes · ₹${totalCost.toStringAsFixed(0)} est.'
        : '$total wishes';

    return Scaffold(
      body: Column(
        children: [
          // ── Hero + category filter ──────────────────────────
          AuroraHero(
            accent: AppColors.accentWishlist,
            eyebrow: 'HOME · WISHLIST',
            title: 'Wishlist',
            subtitle: subtitle,
          ),
          const SizedBox(height: 8),
          // Category filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    icon: Icons.auto_awesome_rounded,
                    selected: filter == null,
                    color: AppColors.accentWishlist,
                    onTap: () => ref
                        .read(_wishCategoryFilterProvider.notifier)
                        .state = null,
                  ),
                  const SizedBox(width: 8),
                  ...WishCategory.values.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CategoryChip(
                          label: _catLabel(cat),
                          icon: _catIcon(cat),
                          selected: filter == cat,
                          color: _catColor(cat),
                          onTap: () => ref
                              .read(_wishCategoryFilterProvider.notifier)
                              .state = cat,
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ── List ───────────────────────────────────────────
          Expanded(
            child: wishAsync.when(
              data: (items) {
                final pending =
                    items.where((i) => i.status == WishStatus.pending).toList();
                final achieved =
                    items.where((i) => i.status == WishStatus.achieved).toList();

                final filtered = filter == null
                    ? pending
                    : pending.where((i) => i.category == filter).toList();

                if (filtered.isEmpty && achieved.isEmpty) {
                  return _emptyState();
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    if (filtered.isEmpty)
                      _noItemsForFilter()
                    else
                      ...filtered.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WishCard(item: item),
                          )),
                    if (achieved.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _AchievedSection(items: achieved),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final service = ref.read(firebaseServiceProvider);
          if (service != null) _showAddEditModal(context, service, null);
        },
        icon: const Icon(Icons.favorite_rounded),
        label: const Text('Add Wish'),
        backgroundColor: AppColors.accentWishlist,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 64,
              color: AppColors.textSubtle.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No wishes yet', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('Tap + to add the first wish',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _noItemsForFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No wishes in this category yet',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}

// ─── Category helpers ─────────────────────────────────────────────

String _catLabel(WishCategory cat) {
  switch (cat) {
    case WishCategory.buy:
      return 'Buy';
    case WishCategory.travel:
      return 'Travel';
    case WishCategory.experience:
      return 'Experience';
    case WishCategory.food:
      return 'Food';
    case WishCategory.beauty:
      return 'Beauty';
    case WishCategory.home:
      return 'Home';
    case WishCategory.other:
      return 'Other';
  }
}

IconData _catIcon(WishCategory cat) {
  switch (cat) {
    case WishCategory.buy:
      return Icons.shopping_bag_rounded;
    case WishCategory.travel:
      return Icons.flight_rounded;
    case WishCategory.experience:
      return Icons.star_rounded;
    case WishCategory.food:
      return Icons.restaurant_rounded;
    case WishCategory.beauty:
      return Icons.spa_rounded;
    case WishCategory.home:
      return Icons.home_rounded;
    case WishCategory.other:
      return Icons.auto_awesome_rounded;
  }
}

Color _catColor(WishCategory cat) {
  switch (cat) {
    case WishCategory.buy:
      return const Color(0xFFE07B39);
    case WishCategory.travel:
      return const Color(0xFF2196F3);
    case WishCategory.experience:
      return const Color(0xFFFF9800);
    case WishCategory.food:
      return const Color(0xFF4CAF50);
    case WishCategory.beauty:
      return AppColors.accentWishlist;
    case WishCategory.home:
      return const Color(0xFF50A878);
    case WishCategory.other:
      return AppColors.textMuted;
  }
}

// ─── Wish Card ────────────────────────────────────────────────────

class _WishCard extends ConsumerWidget {
  final WishItem item;
  const _WishCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;
    final catColor = _catColor(item.category);

    return Dismissible(
      key: Key(item.id),
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
      onDismissed: (_) => service.deleteWishItem(item.id),
      child: GlassCard(
        accent: AppColors.accentWishlist,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_catIcon(item.category), color: catColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                      // Category chip
                      StatusChip.custom(
                        label: item.categoryLabel,
                        accent: catColor,
                      ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.note,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (item.estimatedCost > 0) ...[
                        Icon(Icons.currency_rupee_rounded,
                            size: 13,
                            color: AppColors.textMuted),
                        Text(
                          item.totalCost.toStringAsFixed(0),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.quantity > 1) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(₹${item.estimatedCost.toStringAsFixed(0)} × ${item.quantity})',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                        const SizedBox(width: 10),
                      ],
                      const Spacer(),
                      // Mark achieved button
                      GestureDetector(
                        onTap: () => service.markWishAchieved(item.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.statusDone.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    AppColors.statusDone.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded,
                                  size: 13, color: AppColors.statusDone),
                              const SizedBox(width: 4),
                              Text(
                                'Achieved',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.statusDone,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            size: 18,
                            color: AppColors.textMuted),
                        onSelected: (v) {
                          if (v == 'edit') {
                            _showAddEditModal(context, service, item);
                          } else if (v == 'delete') {
                            service.deleteWishItem(item.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Achieved Section ─────────────────────────────────────────────

class _AchievedSection extends ConsumerStatefulWidget {
  final List<WishItem> items;
  const _AchievedSection({required this.items});

  @override
  ConsumerState<_AchievedSection> createState() => _AchievedSectionState();
}

class _AchievedSectionState extends ConsumerState<_AchievedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.statusDone, size: 18),
              const SizedBox(width: 8),
              Text(
                'Achieved (${widget.items.length})',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.statusDone),
              ),
              const Spacer(),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 10),
          ...widget.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AchievedTile(item: item),
              )),
        ],
      ],
    );
  }
}

class _AchievedTile extends ConsumerWidget {
  final WishItem item;
  const _AchievedTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusDone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.statusDone.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.statusDone, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textSubtle,
              ),
            ),
          ),
          StatusChip.custom(
            label: item.categoryLabel,
            accent: _catColor(item.category),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 16, color: AppColors.textSubtle),
            onPressed: () => service.deleteWishItem(item.id),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 8),
          ),
        ],
      ),
    );
  }
}

// ─── Category filter chip ─────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? color : color.withValues(alpha: 0.6)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? color : color.withValues(alpha: 0.7),
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add / Edit Modal ─────────────────────────────────────────────

void _showAddEditModal(
    BuildContext context, FirebaseService service, WishItem? item) {
  showGlassSheet(
    context: context,
    title: 'Add to Wishlist',
    content: _WishModalContent(service: service, item: item),
  );
}

class _WishModalContent extends StatefulWidget {
  final FirebaseService service;
  final WishItem? item;
  const _WishModalContent({required this.service, this.item});

  @override
  State<_WishModalContent> createState() => _WishModalContentState();
}

class _WishModalContentState extends State<_WishModalContent> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _noteCtrl;
  late WishCategory _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item?.title ?? '');
    _descCtrl =
        TextEditingController(text: widget.item?.description ?? '');
    _costCtrl = TextEditingController(
        text: widget.item != null && widget.item!.estimatedCost > 0
            ? widget.item!.estimatedCost.toStringAsFixed(0)
            : '');
    _qtyCtrl =
        TextEditingController(text: '${widget.item?.quantity ?? 1}');
    _noteCtrl = TextEditingController(text: widget.item?.note ?? '');
    _category = widget.item?.category ?? WishCategory.buy;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final wish = WishItem(
      id: widget.item?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      estimatedCost: double.tryParse(_costCtrl.text) ?? 0,
      quantity: int.tryParse(_qtyCtrl.text) ?? 1,
      status: widget.item?.status ?? WishStatus.pending,
      addedDate: widget.item?.addedDate ?? DateTime.now(),
      note: _noteCtrl.text.trim(),
    );
    if (widget.item == null) {
      await widget.service.addWishItem(wish);
    } else {
      await widget.service.updateWishItem(wish);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'What do you wish for? *',
              prefixIcon: Icon(Icons.stars_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          // Category selector
          Text('Category',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WishCategory.values.map((cat) {
              final selected = _category == cat;
              final color = _catColor(cat);
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? color : color.withValues(alpha: 0.3),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_catIcon(cat),
                          size: 13,
                          color: selected
                              ? color
                              : color.withValues(alpha: 0.6)),
                      const SizedBox(width: 5),
                      Text(
                        _catLabel(cat),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: selected
                              ? color
                              : color.withValues(alpha: 0.7),
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _costCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Est. Cost (₹)',
                    prefixIcon:
                        Icon(Icons.currency_rupee_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    prefixIcon: Icon(Icons.format_list_numbered_rounded,
                        size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note',
              prefixIcon: Icon(Icons.note_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentWishlist,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.item == null
                          ? 'Add to Wish List'
                          : 'Update Wish',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
