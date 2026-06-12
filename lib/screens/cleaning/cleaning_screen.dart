import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../models/cleaning_task.dart';
import '../../providers/providers.dart';

// ── providers ─────────────────────────────────────────────────────
enum RoomFilter { allRooms, hasOverdue, allDone, pending }

final roomFilterProvider =
    StateProvider<RoomFilter>((ref) => RoomFilter.allRooms);
final cleaningSearchProvider = StateProvider<String>((ref) => '');

// ── design tokens ─────────────────────────────────────────────────
const _green  = Color(0xFF34D399);
const _rose   = Color(0xFFFB7185);
const _amber  = Color(0xFFFB923C);

class _Cl {
  final Color card;
  final Color border;
  final Color title;
  final Color muted;

  const _Cl({
    required this.card,
    required this.border,
    required this.title,
    required this.muted,
  });

  factory _Cl.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appColors;
    return _Cl(
      card:   isDark ? const Color(0xFF0D1F3C) : ext.surface,
      border: isDark ? const Color(0x1A38BDF8) : ext.glassBorder,
      title:  isDark ? const Color(0xFFEFF6FF) : const Color(0xFF0F172A),
      muted:  isDark ? const Color(0xFF7096B8) : const Color(0xFF6B7280),
    );
  }

  Color roomBorder(List<CleaningTask> tasks) =>
      tasks.any((t) => t.isOverdue)
          ? _rose.withValues(alpha: 0.40)
          : border;
}

IconData _roomIcon(String room) {
  final r = room.toLowerCase();
  if (r.contains('bath') || r.contains('toilet')) return Icons.bathtub_rounded;
  if (r.contains('kitchen') || r.contains('cook')) return Icons.kitchen_rounded;
  if (r.contains('bed'))    return Icons.bed_rounded;
  if (r.contains('living') || r.contains('hall') || r.contains('lounge')) {
    return Icons.weekend_rounded;
  }
  if (r.contains('door'))   return Icons.door_front_door_rounded;
  if (r.contains('window')) return Icons.window_rounded;
  if (r.contains('all') || r.contains('entire')) return Icons.home_rounded;
  return Icons.cleaning_services_rounded;
}

// ─────────────────────────────────────────────────────────────────
class CleaningScreen extends ConsumerWidget {
  const CleaningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(cleaningTasksProvider);
    final filter     = ref.watch(roomFilterProvider);
    final search     = ref.watch(cleaningSearchProvider);
    final c          = _Cl.of(context);

    return Scaffold(
      body: tasksAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: _green)),
        error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: _rose))),
        data: (tasks) {
          final doneCount    = tasks.where((t) => t.status == TaskStatus.done).length;
          final overdueCount = tasks.where((t) => t.isOverdue).length;
          final pendCount    = tasks
              .where((t) => t.status == TaskStatus.pending && !t.isOverdue)
              .length;

          // group by room with search applied
          final roomMap = <String, List<CleaningTask>>{};
          for (final t in tasks) {
            if (search.isEmpty ||
                t.name.toLowerCase().contains(search.toLowerCase()) ||
                t.room.toLowerCase().contains(search.toLowerCase())) {
              roomMap.putIfAbsent(t.room, () => []).add(t);
            }
          }

          // apply room-level filter
          final rooms = roomMap.entries.where((e) {
            switch (filter) {
              case RoomFilter.hasOverdue:
                return e.value.any((t) => t.isOverdue);
              case RoomFilter.allDone:
                return e.value.every((t) => t.status == TaskStatus.done);
              case RoomFilter.pending:
                return e.value.any((t) => t.status == TaskStatus.pending);
              case RoomFilter.allRooms:
                return true;
            }
          }).toList()
            ..sort((a, b) {
              final aO = a.value.any((t) => t.isOverdue) ? 0 : 1;
              final bO = b.value.any((t) => t.isOverdue) ? 0 : 1;
              return aO.compareTo(bO);
            });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CleanHeader(
                  done: doneCount,
                  pending: pendCount,
                  overdue: overdueCount),
              _ProgressBar(done: doneCount, total: tasks.length),
              // search row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.border),
                      ),
                      child: TextField(
                        style: TextStyle(color: c.title, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search rooms or tasks...',
                          hintStyle: TextStyle(color: c.muted, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 16, color: c.muted),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (v) =>
                            ref.read(cleaningSearchProvider.notifier).state = v,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.border),
                    ),
                    child: Icon(Icons.tune_rounded,
                        size: 18, color: c.muted),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              // filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: RoomFilter.values.map((f) {
                    final sel = filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(roomFilterProvider.notifier).state = f,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? _green.withValues(alpha: 0.12)
                                : c.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? _green.withValues(alpha: 0.50)
                                  : c.border,
                            ),
                          ),
                          child: Text(
                            _label(f),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel ? _green : c.muted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // room grid
              Expanded(
                child: rooms.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.cleaning_services_rounded,
                              color: c.muted, size: 48),
                          const SizedBox(height: 12),
                          Text('No rooms found',
                              style: TextStyle(color: c.muted, fontSize: 14)),
                        ]))
                    : LayoutBuilder(builder: (_, box) {
                        final wide = box.maxWidth >= 600;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                          child: _RoomGrid(rooms: rooms, wide: wide),
                        );
                      }),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(context, ref, null,
            service: ref.read(firebaseServiceProvider)!),
        icon: const Icon(Icons.add),
        label: const Text('Add Task',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
    );
  }

  static String _label(RoomFilter f) {
    switch (f) {
      case RoomFilter.allRooms:   return 'All rooms';
      case RoomFilter.hasOverdue: return 'Has overdue';
      case RoomFilter.allDone:    return 'All done';
      case RoomFilter.pending:    return 'Pending';
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────
class _CleanHeader extends StatelessWidget {
  final int done, pending, overdue;
  const _CleanHeader(
      {required this.done,
      required this.pending,
      required this.overdue});

  @override
  Widget build(BuildContext context) {
    final c = _Cl.of(context);
    return Container(
      color: context.appColors.base,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Home',
                    style: TextStyle(fontSize: 11, color: c.muted)),
                Text(' · ',
                    style: TextStyle(fontSize: 11, color: c.muted)),
                Text('Cleaning',
                    style: TextStyle(fontSize: 11, color: c.muted)),
              ]),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text('Cleaning',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: c.title,
                          letterSpacing: -0.5,
                        )),
                  ),
                  _StatChip(
                      value: done,
                      label: 'done',
                      color: _green,
                      highlight: false),
                  const SizedBox(width: 8),
                  _StatChip(
                      value: pending,
                      label: 'pending',
                      color: c.title,
                      highlight: false),
                  const SizedBox(width: 8),
                  _StatChip(
                      value: overdue,
                      label: 'overdue',
                      color: _rose,
                      highlight: overdue > 0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final bool highlight;
  const _StatChip(
      {required this.value,
      required this.label,
      required this.color,
      required this.highlight});

  @override
  Widget build(BuildContext context) {
    final c = _Cl.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.14)
            : c.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? color.withValues(alpha: 0.40) : c.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: highlight
                      ? color.withValues(alpha: 0.80)
                      : c.muted)),
        ],
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int done, total;
  const _ProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = _Cl.of(context);
    final progress = total > 0 ? done / total : 0.0;
    return Container(
      color: context.appColors.base,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's progress",
                  style: TextStyle(fontSize: 11, color: c.muted)),
              Text('$done of $total tasks done',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _green)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: c.card,
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Room grid ────────────────────────────────────────────────────
class _RoomGrid extends StatelessWidget {
  final List<MapEntry<String, List<CleaningTask>>> rooms;
  final bool wide;
  const _RoomGrid({required this.rooms, required this.wide});

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: rooms
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoomCard(room: e.key, tasks: e.value),
                ))
            .toList(),
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < rooms.length; i += 2) {
      final left  = rooms[i];
      final right = i + 1 < rooms.length ? rooms[i + 1] : null;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: _RoomCard(room: left.key, tasks: left.value)),
              const SizedBox(width: 12),
              Expanded(
                  child: right != null
                      ? _RoomCard(room: right.key, tasks: right.value)
                      : const SizedBox()),
            ],
          ),
        ),
      ));
    }
    return Column(children: rows);
  }
}

// ─── Room card ────────────────────────────────────────────────────
class _RoomCard extends ConsumerWidget {
  final String room;
  final List<CleaningTask> tasks;
  const _RoomCard({required this.room, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneCount    = tasks.where((t) => t.status == TaskStatus.done).length;
    final overdueCount = tasks.where((t) => t.isOverdue).length;
    final hasOverdue   = overdueCount > 0;
    final allDone      = tasks.isNotEmpty && doneCount == tasks.length;
    final progress     = tasks.isEmpty ? 0.0 : doneCount / tasks.length;

    final String badgeLabel;
    final Color  badgeColor;
    if (allDone) {
      badgeLabel = 'All done';
      badgeColor = _green;
    } else if (hasOverdue) {
      badgeLabel = '$overdueCount overdue';
      badgeColor = _rose;
    } else {
      badgeLabel = 'Pending';
      badgeColor = _amber;
    }

    final String sub;
    if (allDone) {
      sub = '${tasks.length} task${tasks.length > 1 ? "s" : ""} · all done';
    } else if (hasOverdue) {
      sub = '${tasks.length} task${tasks.length > 1 ? "s" : ""} · $overdueCount overdue';
    } else {
      sub = '${tasks.length} task${tasks.length > 1 ? "s" : ""}';
    }

    final c = _Cl.of(context);
    final iconColor = allDone ? _green : hasOverdue ? _rose : c.muted;
    final iconBg    = allDone
        ? _green.withValues(alpha: 0.12)
        : hasOverdue
            ? _rose.withValues(alpha: 0.10)
            : c.card;
    final iconBorder = allDone
        ? _green.withValues(alpha: 0.28)
        : hasOverdue
            ? _rose.withValues(alpha: 0.22)
            : c.border;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.roomBorder(tasks)),
        boxShadow: hasOverdue
            ? [
                BoxShadow(
                  color: _rose.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconBorder),
              ),
              child: Icon(_roomIcon(room), size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.title)),
                  Text(sub,
                      style: TextStyle(fontSize: 11, color: c.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badgeLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeColor)),
            ),
          ]),
          const SizedBox(height: 10),
          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: c.card,
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone
                    ? _green
                    : hasOverdue
                        ? _rose.withValues(alpha: 0.55)
                        : _amber,
              ),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 10),
          // task rows
          ...tasks.map((t) => _TaskRow(task: t)),
        ],
      ),
    );
  }
}

// ─── Task row ─────────────────────────────────────────────────────
class _TaskRow extends ConsumerWidget {
  final CleaningTask task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c         = _Cl.of(context);
    final service   = ref.read(firebaseServiceProvider)!;
    final isDone    = task.status == TaskStatus.done;
    final isOverdue = task.isOverdue;

    final String statusText;
    final Color  statusColor;
    if (isDone) {
      statusText  = 'Done today';
      statusColor = c.muted;
    } else if (isOverdue) {
      statusText  = '${task.daysOverdue}d overdue';
      statusColor = _rose;
    } else if (task.isDueToday) {
      statusText  = 'Due today';
      statusColor = _amber;
    } else {
      statusText  = 'In ${task.daysUntilDue}d';
      statusColor = c.muted;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        // checkbox
        GestureDetector(
          onTap: isDone ? null : () => service.markCleaningTaskDone(task.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDone ? _green.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isDone
                    ? _green
                    : isOverdue
                        ? _rose
                        : c.muted.withValues(alpha: 0.50),
                width: 1.5,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, size: 12, color: _green)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        // name + meta
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDone ? c.muted : c.title,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: c.muted,
                ),
              ),
              Text(
                '${task.frequency.shortLabel.toLowerCase()} · ${task.room}',
                style: TextStyle(fontSize: 10, color: c.muted),
              ),
            ],
          ),
        ),
        // status + overflow menu
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(statusText,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: statusColor)),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 14, color: c.muted),
            color: c.card,
            onSelected: (v) {
              if (v == 'edit') {
                _showAddEditModal(context, ref, task, service: service);
              } else if (v == 'delete') {
                service.deleteCleaningTask(task.id);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit',
                      style: TextStyle(color: c.title, fontSize: 13))),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: _rose, fontSize: 13))),
            ],
          ),
        ]),
      ]),
    );
  }
}

// ─── Add / Edit modal ─────────────────────────────────────────────
Future<void> _showAddEditModal(
    BuildContext context, WidgetRef ref, CleaningTask? task,
    {dynamic service}) async {
  final svc = service ?? ref.read(firebaseServiceProvider)!;
  await showGlassSheet(
    context: context,
    title: task == null ? 'Add Cleaning Task' : 'Edit Cleaning Task',
    content: _CleaningTaskForm(task: task, service: svc),
  );
}

class _CleaningTaskForm extends StatefulWidget {
  final CleaningTask? task;
  final dynamic service;
  const _CleaningTaskForm({this.task, required this.service});

  @override
  State<_CleaningTaskForm> createState() => _CleaningTaskFormState();
}

class _CleaningTaskFormState extends State<_CleaningTaskForm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _roomCtrl;
  late TaskFrequency _frequency;
  late TaskStatus _status;
  late DateTime _lastDone;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.task?.name ?? '');
    _roomCtrl  = TextEditingController(text: widget.task?.room ?? '');
    _frequency = widget.task?.frequency ?? TaskFrequency.weekly;
    _status    = widget.task?.status ?? TaskStatus.pending;
    _lastDone  = widget.task?.lastDoneDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
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
          decoration: const InputDecoration(labelText: 'Task Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _roomCtrl,
          decoration: const InputDecoration(labelText: 'Room'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<TaskFrequency>(
          initialValue: _frequency,
          decoration: const InputDecoration(labelText: 'Frequency'),
          dropdownColor: Theme.of(context).cardColor,
          items: TaskFrequency.values
              .map((f) =>
                  DropdownMenuItem(value: f, child: Text(f.label)))
              .toList(),
          onChanged: (v) => setState(() => _frequency = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<TaskStatus>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status'),
          dropdownColor: Theme.of(context).cardColor,
          items: TaskStatus.values
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                      s.name[0].toUpperCase() + s.name.substring(1))))
              .toList(),
          onChanged: (v) => setState(() => _status = v!),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_nameCtrl.text.isEmpty || _roomCtrl.text.isEmpty) return;
              final newTask = CleaningTask(
                id: widget.task?.id ?? '',
                name: _nameCtrl.text.trim(),
                room: _roomCtrl.text.trim(),
                frequency: _frequency,
                lastDoneDate: _lastDone,
                status: _status,
                color: '#38BDF8',
              );
              if (widget.task == null) {
                await widget.service.addCleaningTask(newTask);
              } else {
                await widget.service.updateCleaningTask(newTask);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
                widget.task == null ? 'Add Task' : 'Update Task'),
          ),
        ),
      ],
    );
  }
}
