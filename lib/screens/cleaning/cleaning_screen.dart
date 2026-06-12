import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_tile.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../models/cleaning_task.dart';
import '../../providers/providers.dart';
import '../../services/notification_service.dart';

enum CleaningFilter { all, overdue, pending, done }

final cleaningFilterProvider = StateProvider<CleaningFilter>((ref) => CleaningFilter.all);
final cleaningSearchProvider = StateProvider<String>((ref) => '');

class CleaningScreen extends ConsumerWidget {
  const CleaningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(cleaningTasksProvider);
    final filter = ref.watch(cleaningFilterProvider);
    final search = ref.watch(cleaningSearchProvider);

    final taskCount = tasksAsync.when(
      data: (t) => t.length, loading: () => 0, error: (_, __) => 0);
    final overdueCount = tasksAsync.when(
      data: (t) => t.where((x) => x.isOverdue).length,
      loading: () => 0, error: (_, __) => 0);

    final subtitle = taskCount > 0
        ? '$taskCount tasks · $overdueCount overdue'
        : 'No tasks yet';

    return Scaffold(
      body: Column(
        children: [
          // ── Aurora Hero header ───────────────────────────────
          AuroraHero(
            accent: AppColors.accentCleaning,
            eyebrow: 'HOME · CLEANING',
            title: 'Cleaning',
            subtitle: subtitle,
            trailing: overdueCount > 0
                ? GlassCard(
                    accent: AppColors.accentCleaning,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OVERDUE', style: AppTextStyles.labelLarge),
                        Text(
                          '$overdueCount',
                          style: AppTextStyles.statDisplay
                              .copyWith(color: AppColors.accentCleaning),
                        ),
                        Text('tasks', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                : null,
          ),
          // ── Search ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search tasks or rooms…',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
              ),
              onChanged: (v) =>
                  ref.read(cleaningSearchProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 12),
          // ── Filter pill bar ──────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: CleaningFilter.values.map((f) {
                final selected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(cleaningFilterProvider.notifier).state = f,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accentCleaning.withValues(alpha: 0.18)
                            : AppColors.glassCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.accentCleaning
                                  .withValues(alpha: 0.50)
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        _filterLabel(f),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: selected
                              ? AppColors.accentCleaning
                              : AppColors.textMuted,
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
          // ── List ────────────────────────────────────────────
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = _filterTasks(tasks, filter, search);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cleaning_services_rounded,
                            color: AppColors.textSubtle, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          filter == CleaningFilter.all
                              ? 'No tasks yet'
                              : 'No ${filter.name} tasks',
                          style: AppTextStyles.bodyMedium,
                        ),
                        if (filter == CleaningFilter.all)
                          Text(
                            'Tap + to add your first cleaning task',
                            style: AppTextStyles.bodySmall,
                          ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CleaningTaskCard(task: filtered[i]),
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
        label: Text('Add Task',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.accentCleaning,
        foregroundColor: Colors.white,
      ),
    );
  }

  String _filterLabel(CleaningFilter f) {
    switch (f) {
      case CleaningFilter.all:     return 'All';
      case CleaningFilter.overdue: return 'Overdue';
      case CleaningFilter.pending: return 'Pending';
      case CleaningFilter.done:    return 'Done';
    }
  }

  List<CleaningTask> _filterTasks(
      List<CleaningTask> tasks, CleaningFilter filter, String search) {
    var result = tasks;
    if (search.isNotEmpty) {
      result = result
          .where((t) =>
              t.name.toLowerCase().contains(search.toLowerCase()) ||
              t.room.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    switch (filter) {
      case CleaningFilter.overdue:
        return result.where((t) => t.isOverdue).toList();
      case CleaningFilter.pending:
        return result.where((t) => t.status == TaskStatus.pending && !t.isOverdue).toList();
      case CleaningFilter.done:
        return result.where((t) => t.status == TaskStatus.done).toList();
      case CleaningFilter.all:
        return result;
    }
  }
}

class CleaningTaskCard extends ConsumerStatefulWidget {
  final CleaningTask task;
  const CleaningTaskCard({super.key, required this.task});

  @override
  ConsumerState<CleaningTaskCard> createState() => _CleaningTaskCardState();
}

class _CleaningTaskCardState extends ConsumerState<CleaningTaskCard> {
  DateTime? _reminderTime;
  bool _reminderLoaded = false;

  Color get _statusColor {
    if (widget.task.status == TaskStatus.done)   return AppColors.statusDone;
    if (widget.task.daysOverdue > 7)             return AppColors.statusOverdue;
    if (widget.task.isOverdue)                   return AppColors.statusPending;
    if (widget.task.isDueToday)                  return AppColors.accentCleaning;
    return AppColors.accentCleaning;
  }

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final dt = await NotificationService.instance
        .getTaskReminderTime(widget.task.id);
    if (mounted) setState(() { _reminderTime = dt; _reminderLoaded = true; });
  }

  Future<void> _pickReminder(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: _reminderTime != null
          ? TimeOfDay.fromDateTime(_reminderTime!)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    final scheduled = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    await NotificationService.instance.scheduleTaskReminder(
      taskId: widget.task.id,
      taskName: widget.task.name,
      room: widget.task.room,
      when: scheduled,
    );
    if (mounted) setState(() => _reminderTime = scheduled);

    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    messenger.showSnackBar(SnackBar(
      content: Text(
          'Reminder set for ${date.day}/${date.month} at $h:$m $period'),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _cancelReminder(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await NotificationService.instance.cancelTaskReminder(widget.task.id);
    if (mounted) setState(() => _reminderTime = null);
    messenger.showSnackBar(const SnackBar(
      content: Text('Reminder cancelled'),
      duration: Duration(seconds: 2),
    ));
  }

  String _dueDateLabel() {
    if (widget.task.status == TaskStatus.done) return 'Completed today';
    if (widget.task.isOverdue) {
      return '${widget.task.daysOverdue} day${widget.task.daysOverdue > 1 ? "s" : ""} overdue';
    }
    if (widget.task.isDueToday) return 'Due today';
    return 'Due in ${widget.task.daysUntilDue} day${widget.task.daysUntilDue > 1 ? "s" : ""}';
  }

  Widget _taskStatusChip(CleaningTask task) {
    if (task.status == TaskStatus.done) {
      return const StatusChip.done();
    }
    if (task.daysOverdue > 7) {
      return StatusChip.custom(label: 'Critical', accent: AppColors.statusOverdue);
    }
    if (task.isOverdue) {
      return const StatusChip.overdue();
    }
    return const StatusChip.pending();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(firebaseServiceProvider)!;
    final hasReminder = _reminderTime != null;

    return GlassTile(
      dotColor: _statusColor,
      title: widget.task.name,
      subtitle: '${widget.task.frequency.shortLabel} · ${widget.task.room} · ${_dueDateLabel()}'
          '${_reminderLoaded && hasReminder ? ' · ⏰ ${_fmtReminder(_reminderTime!)}' : ''}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _taskStatusChip(widget.task),
          const SizedBox(width: 4),
          if (widget.task.status != TaskStatus.done)
            GestureDetector(
              onTap: () => _pickReminder(context),
              child: Icon(
                hasReminder
                    ? Icons.alarm_on_rounded
                    : Icons.alarm_add_rounded,
                color: hasReminder
                    ? AppColors.accentCleaning
                    : AppColors.textSubtle,
                size: 18,
              ),
            ),
          if (widget.task.status != TaskStatus.done) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => service.markCleaningTaskDone(widget.task.id),
              child: Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.statusDone, size: 18),
            ),
          ] else ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle_rounded,
                color: AppColors.statusDone.withValues(alpha: 0.7), size: 18),
          ],
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: AppColors.textSubtle, size: 18),
            onSelected: (v) {
              if (v == 'edit') {
                _showAddEditModal(context, ref, widget.task, service: service);
              } else if (v == 'delete') {
                service.deleteCleaningTask(widget.task.id);
              } else if (v == 'cancel_reminder') {
                _cancelReminder(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit',   child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
              if (_reminderLoaded && hasReminder)
                const PopupMenuItem(
                    value: 'cancel_reminder',
                    child: Text('Cancel Reminder')),
            ],
          ),
        ],
      ),
      onTap: () => _showAddEditModal(context, ref, widget.task, service: service),
    );
  }

  String _fmtReminder(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final timeStr = '$h:$m $period';
    if (isToday) return 'Today $timeStr';
    if (isTomorrow) return 'Tomorrow $timeStr';
    return '${dt.day}/${dt.month} $timeStr';
  }
}

Future<void> _showAddEditModal(BuildContext context, WidgetRef ref, CleaningTask? task,
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
    _nameCtrl = TextEditingController(text: widget.task?.name ?? '');
    _roomCtrl = TextEditingController(text: widget.task?.room ?? '');
    _frequency = widget.task?.frequency ?? TaskFrequency.weekly;
    _status = widget.task?.status ?? TaskStatus.pending;
    _lastDone = widget.task?.lastDoneDate ?? DateTime.now();
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
              .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.label),
                  ))
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
                        s.name[0].toUpperCase() + s.name.substring(1)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _status = v!),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCleaning,
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
            child: Text(widget.task == null ? 'Add Task' : 'Update Task'),
          ),
        ),
      ],
    );
  }
}
