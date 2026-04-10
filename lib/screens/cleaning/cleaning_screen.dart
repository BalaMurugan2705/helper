import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
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

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, ref, filter),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = _filterTasks(tasks, filter, search);
                if (filtered.isEmpty) {
                  return _emptyState(context, filter);
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
              loading: () => _loadingList(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(context, ref, null, service: ref.read(firebaseServiceProvider)!),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, CleaningFilter filter) {
    final search = ref.watch(cleaningSearchProvider);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cleaning Tracker',
              style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) =>
                ref.read(cleaningSearchProvider.notifier).state = v,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CleaningFilter.values.map((f) {
                final selected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(cleaningFilterProvider.notifier).state = f,
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

  Widget _emptyState(BuildContext context, CleaningFilter filter) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cleaning_services_rounded,
              size: 64, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            filter == CleaningFilter.all
                ? 'No cleaning tasks yet'
                : 'No ${filter.name} tasks',
            style: GoogleFonts.inter(
                fontSize: 16,
                color: cs.onSurface.withOpacity(0.5)),
          ),
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
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
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

  Color get _borderColor {
    if (widget.task.status == TaskStatus.done) return Colors.green;
    if (widget.task.daysOverdue > 7) return Colors.red;
    if (widget.task.isOverdue) return Colors.orange;
    if (widget.task.isDueToday) return Colors.yellow;
    return AppTheme.accentTeal;
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
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Reminder set for ${date.day}/${date.month} at $h:$m $period'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _cancelReminder(BuildContext context) async {
    await NotificationService.instance.cancelTaskReminder(widget.task.id);
    if (mounted) setState(() => _reminderTime = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reminder cancelled'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(firebaseServiceProvider)!;
    final cs = Theme.of(context).colorScheme;
    final hasReminder = _reminderTime != null;

    return Card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.task.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: cs.onSurface,
                              decoration: widget.task.status == TaskStatus.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        _StatusBadge(task: widget.task),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              color: cs.onSurface.withOpacity(0.5), size: 18),
                          onSelected: (v) {
                            if (v == 'edit') {
                              _showAddEditModal(
                                  context, ref, widget.task, service: service);
                            } else if (v == 'delete') {
                              service.deleteCleaningTask(widget.task.id);
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.room_rounded,
                            size: 13,
                            color: cs.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(widget.task.room,
                            style: GoogleFonts.inter(
                                color: cs.onSurface.withOpacity(0.6),
                                fontSize: 12)),
                        const SizedBox(width: 12),
                        _FrequencyBadge(frequency: widget.task.frequency),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _DueDateInfo(task: widget.task),
                    if (_reminderLoaded && hasReminder) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _cancelReminder(context),
                        child: Row(
                          children: [
                            Icon(Icons.alarm_rounded,
                                size: 12,
                                color: AppTheme.primaryPurple.withOpacity(0.8)),
                            const SizedBox(width: 4),
                            Text(
                              _fmtReminder(_reminderTime!),
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.primaryPurple,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.close_rounded,
                                size: 11,
                                color: AppTheme.primaryPurple.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.task.status != TaskStatus.done)
                    IconButton(
                      icon: Icon(
                        hasReminder
                            ? Icons.alarm_on_rounded
                            : Icons.alarm_add_rounded,
                        color: hasReminder
                            ? AppTheme.primaryPurple
                            : cs.onSurface.withOpacity(0.35),
                        size: 20,
                      ),
                      onPressed: () => _pickReminder(context),
                      tooltip: hasReminder ? 'Edit reminder' : 'Set reminder',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  if (widget.task.status != TaskStatus.done)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          color: AppTheme.accentTeal),
                      onPressed: () =>
                          service.markCleaningTaskDone(widget.task.id),
                      tooltip: 'Mark Done',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.check_circle_rounded,
                          color: Colors.green.withOpacity(0.6)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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

class _StatusBadge extends StatelessWidget {
  final CleaningTask task;
  const _StatusBadge({required this.task});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    if (task.status == TaskStatus.done) {
      color = Colors.green;
      label = 'DONE';
    } else if (task.daysOverdue > 7) {
      color = Colors.red;
      label = 'CRITICAL';
    } else if (task.isOverdue) {
      color = Colors.orange;
      label = 'OVERDUE';
    } else if (task.isDueToday) {
      color = Colors.yellow.shade700;
      label = 'TODAY';
    } else {
      color = AppTheme.accentTeal;
      label = 'OK';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  final TaskFrequency frequency;
  const _FrequencyBadge({required this.frequency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        frequency.shortLabel,
        style: GoogleFonts.inter(
            color: AppTheme.primaryPurple,
            fontSize: 9,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DueDateInfo extends StatelessWidget {
  final CleaningTask task;
  const _DueDateInfo({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (task.status == TaskStatus.done) {
      return Text(
        'Completed today',
        style: GoogleFonts.inter(color: Colors.green, fontSize: 11),
      );
    }
    if (task.isOverdue) {
      return Text(
        '${task.daysOverdue} day${task.daysOverdue > 1 ? "s" : ""} overdue',
        style: GoogleFonts.inter(color: Colors.orange, fontSize: 11),
      );
    }
    if (task.isDueToday) {
      return Text(
        'Due today',
        style: GoogleFonts.inter(
            color: Colors.yellow.shade700, fontSize: 11),
      );
    }
    return Text(
      'Due in ${task.daysUntilDue} day${task.daysUntilDue > 1 ? "s" : ""}',
      style: GoogleFonts.inter(
          color: cs.onSurface.withOpacity(0.5), fontSize: 11),
    );
  }
}

Future<void> _showAddEditModal(BuildContext context, WidgetRef ref, CleaningTask? task,
    {dynamic service}) async {
  final svc = service ?? ref.read(firebaseServiceProvider)!;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _CleaningTaskModal(task: task, service: svc),
  );
}

class _CleaningTaskModal extends StatefulWidget {
  final CleaningTask? task;
  final dynamic service;
  const _CleaningTaskModal({this.task, required this.service});

  @override
  State<_CleaningTaskModal> createState() => _CleaningTaskModalState();
}

class _CleaningTaskModalState extends State<_CleaningTaskModal> {
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
            widget.task == null ? 'Add Cleaning Task' : 'Edit Cleaning Task',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 16),
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
            value: _frequency,
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
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            dropdownColor: Theme.of(context).cardColor,
            items: TaskStatus.values
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
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
                if (_nameCtrl.text.isEmpty || _roomCtrl.text.isEmpty) return;
                final newTask = CleaningTask(
                  id: widget.task?.id ?? '',
                  name: _nameCtrl.text.trim(),
                  room: _roomCtrl.text.trim(),
                  frequency: _frequency,
                  lastDoneDate: _lastDone,
                  status: _status,
                  color: '#7C4DFF',
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
      ),
    );
  }
}
