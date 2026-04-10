import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
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

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, ref, filter, pendingCost, itemsAsync),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final filtered = _filterItems(items, filter);
                if (filtered.isEmpty) {
                  return _emptyState(context);
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
              loading: () => _loadingList(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(context, ref, null, service: ref.read(firebaseServiceProvider)!),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  List<ShoppingItem> _filterItems(List<ShoppingItem> items, ShoppingFilter filter) {
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

  Widget _buildHeader(BuildContext context, WidgetRef ref,
      ShoppingFilter filter, double pendingCost,
      AsyncValue<List<ShoppingItem>> itemsAsync) {
    final cs = Theme.of(context).colorScheme;
    final boughtCount = itemsAsync.when(
      data: (items) => items.where((i) => i.bought).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final totalCount = itemsAsync.when(
      data: (items) => items.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shopping Manager',
              style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 12),
          // Budget Summary Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.accentTeal],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Cost',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 11)),
                      Text('₹${pendingCost.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Bought', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                    Text('$boughtCount / $totalCount',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ShoppingFilter.values.map((f) {
                final selected = filter == f;
                const labels = {
                  ShoppingFilter.all: 'All',
                  ShoppingFilter.essential: 'Essential',
                  ShoppingFilter.high: 'High',
                  ShoppingFilter.medium: 'Medium',
                  ShoppingFilter.basic: 'Basic',
                  ShoppingFilter.toBuy: 'To Buy',
                };
                final label = labels[f]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(shoppingFilterProvider.notifier).state = f,
                    selectedColor: AppTheme.primaryPurple.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryPurple,
                    labelStyle: GoogleFonts.inter(
                      color: selected ? AppTheme.primaryPurple : cs.onSurface.withOpacity(0.6),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_rounded,
              size: 64, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No items found',
              style: GoogleFonts.inter(
                  fontSize: 16, color: cs.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _loadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF1A1A2E),
          highlightColor: const Color(0xFF252540),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class ShoppingItemCard extends ConsumerWidget {
  final ShoppingItem item;
  const ShoppingItemCard({super.key, required this.item});

  Color get _priorityColor {
    switch (item.priority) {
      case ItemPriority.essential:
        return const Color(0xFFEE0979);
      case ItemPriority.high:
        return Colors.red;
      case ItemPriority.medium:
        return Colors.orange;
      case ItemPriority.basic:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;
    final cs = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: item.bought ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              Checkbox(
                value: item.bought,
                activeColor: AppTheme.accentTeal,
                onChanged: (v) => service.toggleItemBought(item.id, v!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
          title: Text(
            item.name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              decoration: item.bought ? TextDecoration.lineThrough : null,
              decorationColor: cs.onSurface.withOpacity(0.5),
            ),
          ),
          subtitle: Row(
            children: [
              Text(item.category,
                  style: GoogleFonts.inter(
                      color: cs.onSurface.withOpacity(0.6), fontSize: 12)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.priority.label.toUpperCase(),
                  style: GoogleFonts.inter(
                      color: _priorityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${item.cost.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  Text('qty: ${item.quantity}',
                      style: GoogleFonts.inter(
                          color: cs.onSurface.withOpacity(0.5), fontSize: 11)),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: cs.onSurface.withOpacity(0.5), size: 18),
                onSelected: (v) {
                  if (v == 'edit') {
                    _showAddEditModal(context, null, item, service: service);
                  } else if (v == 'delete') {
                    service.deleteShoppingItem(item.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showAddEditModal(BuildContext context, WidgetRef? ref,
    ShoppingItem? item, {dynamic service}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _ShoppingItemModal(item: item, service: service),
  );
}

class _ShoppingItemModal extends StatefulWidget {
  final ShoppingItem? item;
  final dynamic service;
  const _ShoppingItemModal({this.item, required this.service});

  @override
  State<_ShoppingItemModal> createState() => _ShoppingItemModalState();
}

class _ShoppingItemModalState extends State<_ShoppingItemModal> {
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
    _categoryCtrl = TextEditingController(text: widget.item?.category ?? '');
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
          Text(
            widget.item == null ? 'Add Shopping Item' : 'Edit Shopping Item',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 16),
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
                    decoration: const InputDecoration(labelText: 'Cost (₹)')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ItemPriority>(
            value: _priority,
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
                activeColor: AppTheme.accentTeal,
                onChanged: (v) => setState(() => _bought = v!),
              ),
              Text('Mark as bought', style: GoogleFonts.inter(color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
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
              child: Text(widget.item == null ? 'Add Item' : 'Update Item'),
            ),
          ),
        ],
      ),
    );
  }
}
