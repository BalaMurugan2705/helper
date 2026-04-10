import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

// ─── Message model ────────────────────────────────────────────────

enum _Role { user, model }

class _ChatMsg {
  final _Role role;
  final String text;
  const _ChatMsg(this.role, this.text);
}

// ─── Screen ───────────────────────────────────────────────────────

class AdvisorScreen extends ConsumerStatefulWidget {
  const AdvisorScreen({super.key});

  @override
  ConsumerState<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends ConsumerState<AdvisorScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];

  bool _loading = false;
  String? _apiKey;
  GenerativeModel? _model;
  ChatSession? _chat;

  static const _keyPref = 'gemini_api_key';

  static const _quickPrompts = [
    'What should I clean today?',
    'Review my calories today',
    'Analyze my budget',
    'Full home report',
    'Shopping suggestions',
    'Health tips for today',
    'What food should I eat next?',
    'Am I on track this week?',
  ];

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyPref) ?? '';
    if (key.isNotEmpty) {
      setState(() => _apiKey = key);
      _initModel(key);
    }
  }

  void _initModel(String key) {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
    _chat = _model!.startChat();
  }

  Future<void> _saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPref, key);
    setState(() => _apiKey = key);
    _initModel(key);
  }

  // ─── Context builder (injects all live app data) ──────────────

  String _buildContext() {
    final cleaning = ref.read(cleaningTasksProvider).valueOrNull ?? [];
    final shopping = ref.read(shoppingItemsProvider).valueOrNull ?? [];
    final budget = ref.read(budgetProvider).valueOrNull ?? [];
    final health = ref.read(healthProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final food = ref.read(foodEntriesProvider(todayDate)).valueOrNull ?? [];
    final calorieGoal = ref.read(calorieGoalProvider).valueOrNull ?? 2000;

    final sb = StringBuffer()
      ..writeln(
          'You are a smart home management AI for HomeSync. Be concise, friendly and actionable.')
      ..writeln('Always use ₹ for currency. Today is ${_fmtDate(now)}.\n');

    // Cleaning
    sb.writeln('## CLEANING TASKS');
    final overdue = cleaning.where((t) => t.isOverdue).toList()
      ..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
    final dueToday = cleaning.where((t) => t.isDueToday).toList();
    final done = cleaning.where((t) => t.status.name == 'done').length;
    if (overdue.isNotEmpty) {
      sb.writeln('Overdue (${overdue.length}):');
      for (final t in overdue.take(6)) {
        sb.writeln('  - ${t.name} (${t.room}): ${t.daysOverdue}d overdue');
      }
    }
    if (dueToday.isNotEmpty) {
      sb.writeln('Due today: ${dueToday.map((t) => '${t.name} (${t.room})').join(', ')}');
    }
    sb.writeln('Done: $done/${cleaning.length}');

    // Shopping
    sb.writeln('\n## SHOPPING LIST');
    final unbought = shopping.where((i) => !i.bought).toList();
    final pendingCost =
        unbought.fold(0.0, (s, i) => s + i.cost * i.quantity);
    sb.writeln(
        'Pending: ${unbought.length} items • ₹${pendingCost.toStringAsFixed(0)} total');
    final byPri = <String, List<String>>{};
    for (final i in unbought.take(12)) {
      byPri.putIfAbsent(i.priority.name, () => []).add(i.name);
    }
    for (final e in byPri.entries) {
      sb.writeln('  ${e.key}: ${e.value.join(', ')}');
    }

    // Budget
    sb.writeln('\n## BUDGET');
    final totalBudget =
        budget.fold(0.0, (s, c) => s + c.budgetAmount);
    final totalSpent =
        budget.fold(0.0, (s, c) => s + c.spentAmount);
    sb.writeln(
        'Overall: ₹${totalSpent.toStringAsFixed(0)} / ₹${totalBudget.toStringAsFixed(0)}');
    for (final c in budget) {
      final flag = c.isOverBudget
          ? '⚠️ OVER by ₹${(c.spentAmount - c.budgetAmount).toStringAsFixed(0)}'
          : '${(c.percentUsed * 100).toStringAsFixed(0)}%';
      sb.writeln('  ${c.category}: ₹${c.spentAmount.toStringAsFixed(0)}/₹${c.budgetAmount.toStringAsFixed(0)} ($flag)');
    }

    // Health
    sb.writeln('\n## HEALTH HABITS');
    for (final h in health) {
      sb.writeln(
          '  ${h.name}: ${h.todayValue}/${h.goal} ${h.unit} | streak: ${h.streak}d | ${h.isCompleted ? "✅ done" : "pending"}');
    }

    // Food / Calories
    sb.writeln('\n## TODAY\'S NUTRITION');
    final totalCals = food.fold(0.0, (s, e) => s + e.calories);
    final protein = food.fold(0.0, (s, e) => s + e.protein);
    final carbs = food.fold(0.0, (s, e) => s + e.carbs);
    final fat = food.fold(0.0, (s, e) => s + e.fat);
    final remaining = calorieGoal - totalCals;
    sb.writeln('Goal: $calorieGoal kcal');
    sb.writeln(
        'Consumed: ${totalCals.toInt()} kcal | ${remaining > 0 ? "${remaining.toInt()} remaining" : "${(-remaining).toInt()} over goal"}');
    sb.writeln(
        'Macros: Protein ${protein.toInt()}g • Carbs ${carbs.toInt()}g • Fat ${fat.toInt()}g');
    if (food.isNotEmpty) {
      final byMeal = <String, List<String>>{};
      for (final e in food) {
        byMeal
            .putIfAbsent(e.mealType.label, () => [])
            .add('${e.name} (${e.calories.toInt()} kcal)');
      }
      for (final e in byMeal.entries) {
        sb.writeln('  ${e.key}: ${e.value.join(', ')}');
      }
    } else {
      sb.writeln('No food logged yet today.');
    }

    return sb.toString();
  }

  // ─── Send message ─────────────────────────────────────────────

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading || _chat == null) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMsg(_Role.user, trimmed));
      _loading = true;
    });
    _scrollToBottom();

    try {
      // First message: inject live context before the question
      final isFirst =
          _messages.where((m) => m.role == _Role.user).length == 1;
      final payload =
          isFirst ? '${_buildContext()}\n\nQuestion: $trimmed' : trimmed;

      final response =
          await _chat!.sendMessage(Content.text(payload));
      final reply =
          response.text ?? 'Sorry, I could not generate a response.';

      setState(() {
        _messages.add(_ChatMsg(_Role.model, reply));
        _loading = false;
      });
    } on GenerativeAIException catch (e) {
      setState(() {
        _messages.add(_ChatMsg(
            _Role.model, '⚠️ API error: ${e.message}. Check your API key.'));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMsg(_Role.model,
            '⚠️ Something went wrong. Please try again.'));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  void _resetChat() {
    if (_model == null) return;
    setState(() {
      _messages.clear();
      _chat = _model!.startChat();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showKeyDialog() {
    final ctrl = TextEditingController(text: _apiKey ?? '');
    bool obscure = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Gemini API Key',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: AppTheme.primaryPurple),
                      const SizedBox(width: 6),
                      Text('How to get a free key:',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryPurple)),
                    ]),
                    const SizedBox(height: 4),
                    Text('1. Go to aistudio.google.com',
                        style: GoogleFonts.inter(fontSize: 12)),
                    Text('2. Sign in with Google account',
                        style: GoogleFonts.inter(fontSize: 12)),
                    Text('3. Click "Get API Key" → Create',
                        style: GoogleFonts.inter(fontSize: 12)),
                    Text('4. Copy & paste the key below',
                        style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'AIzaSy...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setSt(() => obscure = !obscure),
                        iconSize: 18,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Copy',
                        onPressed: () => Clipboard.setData(
                            ClipboardData(text: ctrl.text)),
                      ),
                    ],
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final key = ctrl.text.trim();
                if (key.isNotEmpty) {
                  _saveKey(key);
                  _resetChat();
                  Navigator.pop(ctx);
                }
              },
              child: Text('Save & Connect',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const days = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Advisor',
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface)),
                      Text('Gemini 1.5 Flash • Free tier',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.4))),
                    ],
                  ),
                  const Spacer(),
                  if (_messages.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'New chat',
                      onPressed: _resetChat,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  GestureDetector(
                    onTap: _showKeyDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasKey
                            ? const Color(0xFF4CAF50).withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasKey
                              ? const Color(0xFF4CAF50).withOpacity(0.4)
                              : Colors.orange.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasKey
                                ? Icons.check_circle_rounded
                                : Icons.key_rounded,
                            size: 13,
                            color: hasKey
                                ? const Color(0xFF4CAF50)
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasKey ? 'Connected' : 'Set API Key',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: hasKey
                                    ? const Color(0xFF4CAF50)
                                    : Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Quick prompts (visible when chat is empty) ───────
            if (_messages.isEmpty) ...[
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) => ActionChip(
                    label: Text(_quickPrompts[i],
                        style: GoogleFonts.inter(fontSize: 12)),
                    onPressed:
                        hasKey ? () => _send(_quickPrompts[i]) : null,
                    backgroundColor:
                        AppTheme.primaryPurple.withOpacity(0.08),
                    side: BorderSide(
                        color: AppTheme.primaryPurple.withOpacity(0.25)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Messages ─────────────────────────────────────────
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyState(hasKey: hasKey, onTap: _send)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount:
                          _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (_loading && i == _messages.length) {
                          return const _TypingIndicator();
                        }
                        return _Bubble(msg: _messages[i]);
                      },
                    ),
            ),

            // ── Input bar ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                    top: BorderSide(
                        color: cs.onSurface.withOpacity(0.08))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      enabled: hasKey && !_loading,
                      maxLines: 4,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: hasKey
                            ? 'Ask about cleaning, food, budget, health...'
                            : 'Tap "Set API Key" to start',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.35)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: FloatingActionButton(
                      backgroundColor: _loading || !hasKey
                          ? cs.onSurface.withOpacity(0.15)
                          : AppTheme.primaryPurple,
                      elevation: 0,
                      onPressed: _loading || !hasKey
                          ? null
                          : () => _send(_inputCtrl.text),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
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

// ─── Empty state ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasKey;
  final void Function(String) onTap;
  const _EmptyState({required this.hasKey, required this.onTap});

  static const _featured = [
    'Full home report',
    'Review my calories today',
    'What should I clean today?',
    'Analyze my budget',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.accentTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text('AI Home Advisor',
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              hasKey
                  ? 'Your personal AI trained on your live home data.\nAsk anything — food, cleaning, budget, health.'
                  : 'Connect Google Gemini (free) to get\npersonalized insights from your home data.',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.5),
                  height: 1.6),
              textAlign: TextAlign.center,
            ),
            if (hasKey) ...[
              const SizedBox(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _featured
                    .map((p) => ActionChip(
                          avatar: const Icon(Icons.auto_awesome_rounded,
                              size: 14, color: AppTheme.primaryPurple),
                          label: Text(p,
                              style: GoogleFonts.inter(fontSize: 13)),
                          onPressed: () => onTap(p),
                          backgroundColor:
                              AppTheme.primaryPurple.withOpacity(0.08),
                          side: BorderSide(
                              color: AppTheme.primaryPurple.withOpacity(0.25)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Chat bubble ──────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final _ChatMsg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = msg.role == _Role.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.accentTeal]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () =>
                  Clipboard.setData(ClipboardData(text: msg.text)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(colors: [
                          AppTheme.primaryPurple,
                          Color(0xFF5340D8),
                        ])
                      : null,
                  color: isUser ? null : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isUser ? Colors.white : cs.onSurface,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(reverse: true),
    );
    _anims = _ctrls.asMap().entries.map((e) {
      Future.delayed(Duration(milliseconds: e.key * 150), () {
        if (mounted) _ctrls[e.key].forward();
      });
      return Tween(begin: 0.3, end: 1.0).animate(_ctrls[e.key]);
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.accentTeal]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => FadeTransition(
                  opacity: _anims[i],
                  child: Container(
                    margin: EdgeInsets.only(left: i > 0 ? 5.0 : 0),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
