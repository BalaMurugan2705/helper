import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
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

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, ref, wishAsync, filter),
          Expanded(
            child: wishAsync.when(
              data: (items) {
                final pending =
                    items.where((i) => i.status == WishStatus.pending).toList();
                final achieved =
                    items.where((i) => i.status == WishStatus.achieved).toList();

                final filtered = filter == null
                    ? pending
                    : pending
                        .where((i) => i.category == filter)
                        .toList();

                if (filtered.isEmpty && achieved.isEmpty) {
                  return _emptyState(context);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    if (filtered.isEmpty)
                      _noItemsForFilter(context)
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
              loading: () => _loadingList(),
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
        backgroundColor: const Color(0xFFE91E63),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref,
      AsyncValue<List<WishItem>> wishAsync, WishCategory? filter) {
    final cs = Theme.of(context).colorScheme;
    final total = wishAsync.when(
      data: (items) => items.where((i) => i.status == WishStatus.pending).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final achieved = wishAsync.when(
      data: (items) => items.where((i) => i.status == WishStatus.achieved).length,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFFFF6B9D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Wife's Wish List",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _BannerChip(
                    icon: Icons.favorite_border_rounded,
                    label: '$total wishes',
                  ),
                  const SizedBox(width: 8),
                  _BannerChip(
                    icon: Icons.check_circle_rounded,
                    label: '$achieved achieved',
                  ),
                  const SizedBox(width: 8),
                  if (totalCost > 0)
                    _BannerChip(
                      icon: Icons.currency_rupee_rounded,
                      label: '₹${totalCost.toStringAsFixed(0)} est.',
                    ),
                ],
              ),
            ],
          ),
        ),
        // Category filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All',
                  icon: Icons.auto_awesome_rounded,
                  selected: filter == null,
                  color: const Color(0xFFE91E63),
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 64, color: cs.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No wishes yet',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Tap + to add the first wish',
              style: GoogleFonts.inter(
                  fontSize: 13, color: cs.onSurface.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _noItemsForFilter(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No wishes in this category yet',
          style: GoogleFonts.inter(
              color: cs.onSurface.withOpacity(0.4), fontSize: 14),
        ),
      ),
    );
  }

  Widget _loadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF1A1A2E),
          highlightColor: const Color(0xFF252540),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
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
      return const Color(0xFF7C4DFF);
    case WishCategory.travel:
      return const Color(0xFF2196F3);
    case WishCategory.experience:
      return const Color(0xFFFF9800);
    case WishCategory.food:
      return const Color(0xFF4CAF50);
    case WishCategory.beauty:
      return const Color(0xFFE91E63);
    case WishCategory.home:
      return const Color(0xFF00BFA5);
    case WishCategory.other:
      return const Color(0xFF9E9E9E);
  }
}

// ─── Wish Card ────────────────────────────────────────────────────

class _WishCard extends ConsumerWidget {
  final WishItem item;
  const _WishCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final service = ref.read(firebaseServiceProvider)!;
    final catColor = _catColor(item.category);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 24),
      ),
      onDismissed: (_) => service.deleteWishItem(item.id),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: catColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: catColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_catIcon(item.category),
                    color: catColor, size: 22),
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
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.categoryLabel,
                            style: GoogleFonts.inter(
                              color: catColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.note,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.4),
                          fontStyle: FontStyle.italic,
                        ),
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
                              color: cs.onSurface.withOpacity(0.5)),
                          Text(
                            item.totalCost.toStringAsFixed(0),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                          if (item.quantity > 1) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(₹${item.estimatedCost.toStringAsFixed(0)} × ${item.quantity})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: cs.onSurface.withOpacity(0.4),
                              ),
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
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_rounded,
                                    size: 13, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Achieved',
                                  style: GoogleFonts.inter(
                                    color: Colors.green,
                                    fontSize: 11,
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
                              color: cs.onSurface.withOpacity(0.4)),
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Achieved (${widget.items.length})',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: cs.onSurface.withOpacity(0.4),
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
    final cs = Theme.of(context).colorScheme;
    final service = ref.read(firebaseServiceProvider)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.6),
                decoration: TextDecoration.lineThrough,
                decorationColor: cs.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _catColor(item.category).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.categoryLabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: _catColor(item.category),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 16, color: cs.onSurface.withOpacity(0.3)),
            onPressed: () => service.deleteWishItem(item.id),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 8),
          ),
        ],
      ),
    );
  }
}

// ─── Banner chip ──────────────────────────────────────────────────

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BannerChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
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
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? color : color.withOpacity(0.6)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: selected ? color : color.withOpacity(0.7),
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _WishModal(service: service, item: item),
  );
}

class _WishModal extends StatefulWidget {
  final FirebaseService service;
  final WishItem? item;
  const _WishModal({required this.service, this.item});

  @override
  State<_WishModal> createState() => _WishModalState();
}

class _WishModalState extends State<_WishModal> {
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
    _qtyCtrl = TextEditingController(
        text: '${widget.item?.quantity ?? 1}');
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE91E63), size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.item == null ? 'New Wish' : 'Edit Wish',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5))),
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
                          ? color.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? color : color.withOpacity(0.3),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_catIcon(cat),
                            size: 13,
                            color: selected ? color : color.withOpacity(0.6)),
                        const SizedBox(width: 5),
                        Text(
                          _catLabel(cat),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                selected ? color : color.withOpacity(0.7),
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
                  backgroundColor: const Color(0xFFE91E63),
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
                        widget.item == null ? 'Add to Wish List' : 'Update Wish',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
