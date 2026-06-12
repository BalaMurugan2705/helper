import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_tile.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../models/shopping_item.dart';
import '../../providers/providers.dart';

enum ShoppingFilter { all, essential, high, medium, basic, toBuy }

final shoppingFilterProvider = StateProvider<ShoppingFilter>((ref) => ShoppingFilter.all);

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingItemsProvider);
    final filter = ref.watch(shoppingFilterProvider);
    final pendingCost = ref.watch(pendingShoppingCostProvider);

    final boughtCount = itemsAsync.when(
      data: (items) => items.where((i) => i.bought).length,
      loading: () => 0, error: (_, __) => 0);
    final totalCount = itemsAsync.when(
      data: (items) => items.length,
      loading: () => 0, error: (_, __) => 0);

    final subtitle = totalCount > 0
        ? '$totalCount items · $boughtCount bought'
        : 'Nothing added yet';

    return Scaffold(
      body: Column(
        children: [
          // ── Aurora Hero header ───────────────────────────────
          AuroraHero(
            accent: AppColors.accentShopping,
            eyebrow: 'HOME · SHOPPING',
            title: 'Shopping',
            subtitle: subtitle,
            trailing: pendingCost > 0
                ? GlassCard(
                    accent: AppColors.accentShopping,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PENDING', style: AppTextStyles.labelLarge),
                        Text(
                          '₹${pendingCost.toStringAsFixed(0)}',
                          style: AppTextStyles.statDisplay
                              .copyWith(color: AppColors.accentShopping),
                        ),
                        Text('cost', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                : null,
          ),
          // ── Summary row ─────────────────────────────────────
          if (totalCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: GlassCard(
                accent: AppColors.accentShopping,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PENDING COST',
                              style: AppTextStyles.labelLarge),
                          Text(
                            '₹${pendingCost.toStringAsFixed(0)}',
                            style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.accentShopping),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: context.appColors.glassBorder,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BOUGHT',
                                style: AppTextStyles.labelLarge),
                            Text(
                              '$boughtCount / $totalCount',
                              style: AppTextStyles.headlineMedium.copyWith(
                                  color: AppColors.statusDone),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // ── Filter pills ─────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ShoppingFilter.values.map((f) {
                final selected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(shoppingFilterProvider.notifier).state = f,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accentShopping.withValues(alpha: 0.18)
                            : context.appColors.glassCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.accentShopping
                                  .withValues(alpha: 0.50)
                              : context.appColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        _filterLabel(f),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: selected
                              ? AppColors.accentShopping
                              : context.appColors.textMuted,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // ── List ─────────────────────────────────────────────
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final filtered = _filterItems(items, filter);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            color: context.appColors.textSubtle, size: 48),
                        const SizedBox(height: 12),
                        Text('Nothing here',
                            style: AppTextStyles.bodyMedium),
                        Text('Tap + to add shopping items',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShoppingItemCard(item: filtered[i]),
                  ),
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
        onPressed: () => _showAddEditModal(context, ref, null,
            service: ref.read(firebaseServiceProvider)!),
        icon: const Icon(Icons.add),
        label: Text('Add Item',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.accentShopping,
        foregroundColor: Colors.white,
      ),
    );
  }

  String _filterLabel(ShoppingFilter f) {
    switch (f) {
      case ShoppingFilter.all:       return 'All';
      case ShoppingFilter.toBuy:     return 'To Buy';
      case ShoppingFilter.essential: return 'Essential';
      case ShoppingFilter.high:      return 'High';
      case ShoppingFilter.medium:    return 'Medium';
      case ShoppingFilter.basic:     return 'Basic';
    }
  }

  List<ShoppingItem> _filterItems(
      List<ShoppingItem> items, ShoppingFilter filter) {
    switch (filter) {
      case ShoppingFilter.essential:
        return items.where((i) => i.priority == ItemPriority.essential).toList();
      case ShoppingFilter.high:
        return items.where((i) => i.priority == ItemPriority.high).toList();
      case ShoppingFilter.medium:
        return items.where((i) => i.priority == ItemPriority.medium).toList();
      case ShoppingFilter.basic:
        return items.where((i) => i.priority == ItemPriority.basic).toList();
      case ShoppingFilter.toBuy:
        return items.where((i) => !i.bought).toList();
      case ShoppingFilter.all:
        return items;
    }
  }
}

class ShoppingItemCard extends ConsumerWidget {
  final ShoppingItem item;
  const ShoppingItemCard({super.key, required this.item});

  Color _priorityColor() {
    switch (item.priority) {
      case ItemPriority.essential: return AppColors.statusOverdue;
      case ItemPriority.high:      return AppColors.statusPending;
      case ItemPriority.medium:    return AppColors.statusPending; // amber — semantic for medium priority
      case ItemPriority.basic:     return AppColors.statusDone;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;

    return AnimatedOpacity(
      opacity: item.bought ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: GlassTile(
        dotColor: _priorityColor(),
        title: item.name,
        subtitle: '${item.category} · ${item.priority.label.toUpperCase()}'
            ' · ₹${item.cost.toStringAsFixed(0)} · qty: ${item.quantity}',
        leading: Checkbox(
          value: item.bought,
          activeColor: AppColors.accentShopping,
          onChanged: (v) => service.toggleItemBought(item.id, v!),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: context.appColors.glassBorder),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            item.bought
                ? const StatusChip.done()
                : StatusChip.custom(
                    label: 'To Buy',
                    accent: context.appColors.textMuted,
                  ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: context.appColors.textSubtle, size: 18),
              onSelected: (v) {
                if (v == 'edit') {
                  _showAddEditModal(context, null, item,
                      service: service);
                } else if (v == 'delete') {
                  service.deleteShoppingItem(item.id);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit',   child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: () =>
            _showAddEditModal(context, null, item, service: service),
      ),
    );
  }
}

Future<void> _showAddEditModal(BuildContext context, WidgetRef? ref,
    ShoppingItem? item, {dynamic service}) async {
  await showGlassSheet(
    context: context,
    title: item == null ? 'Add Shopping Item' : 'Edit Shopping Item',
    content: _ShoppingItemForm(item: item, service: service),
  );
}

class _ShoppingItemForm extends StatefulWidget {
  final ShoppingItem? item;
  final dynamic service;
  const _ShoppingItemForm({this.item, required this.service});

  @override
  State<_ShoppingItemForm> createState() => _ShoppingItemFormState();
}

class _ShoppingItemFormState extends State<_ShoppingItemForm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _quantityCtrl;
  late ItemPriority _priority;
  late bool _bought;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _categoryCtrl =
        TextEditingController(text: widget.item?.category ?? '');
    _costCtrl = TextEditingController(
        text: widget.item?.cost.toStringAsFixed(0) ?? '');
    _quantityCtrl =
        TextEditingController(text: '${widget.item?.quantity ?? 1}');
    _priority = widget.item?.priority ?? ItemPriority.medium;
    _bought = widget.item?.bought ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _costCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Item Name')),
        const SizedBox(height: 12),
        TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(labelText: 'Category')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                  controller: _costCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Cost (₹)')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Quantity')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ItemPriority>(
          initialValue: _priority,
          decoration: const InputDecoration(labelText: 'Priority'),
          dropdownColor: Theme.of(context).cardColor,
          items: ItemPriority.values
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.label),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _priority = v!),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _bought,
              activeColor: AppColors.accentShopping,
              onChanged: (v) => setState(() => _bought = v!),
            ),
            Text('Mark as bought',
                style: AppTextStyles.bodyMedium),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentShopping,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_nameCtrl.text.isEmpty) return;
              final newItem = ShoppingItem(
                id: widget.item?.id ?? '',
                name: _nameCtrl.text.trim(),
                category: _categoryCtrl.text.trim(),
                priority: _priority,
                cost: double.tryParse(_costCtrl.text) ?? 0,
                bought: _bought,
                quantity: int.tryParse(_quantityCtrl.text) ?? 1,
              );
              if (widget.item == null) {
                await widget.service.addShoppingItem(newItem);
              } else {
                await widget.service.updateShoppingItem(newItem);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
                widget.item == null ? 'Add Item' : 'Update Item'),
          ),
        ),
      ],
    );
  }
}
