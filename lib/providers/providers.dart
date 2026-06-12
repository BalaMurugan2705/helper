import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cleaning_task.dart';
import '../models/expense.dart';
import '../models/food_entry.dart';
import '../models/shopping_item.dart';
import '../models/budget_category.dart';
import '../models/health_habit.dart';
import '../models/wish_item.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

// ─── Auth Providers ───────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ─── Service Provider ─────────────────────────────────────────────

final firebaseServiceProvider = Provider<FirebaseService?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return FirebaseService(user.uid);
});

// ─── Theme Provider ───────────────────────────────────────────────

final themeModeProvider = StateProvider<bool>((ref) => true); // true = dark

// ─── Cleaning Tasks Stream ────────────────────────────────────────

final cleaningTasksProvider = StreamProvider<List<CleaningTask>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  if (service == null) return const Stream.empty();
  return service.cleaningTasksStream();
});

// ─── Shopping Items Stream ────────────────────────────────────────

final shoppingItemsProvider = StreamProvider<List<ShoppingItem>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  if (service == null) return const Stream.empty();
  return service.shoppingItemsStream();
});

// ─── Budget Stream ────────────────────────────────────────────────

final budgetProvider = StreamProvider<List<BudgetCategory>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  if (service == null) return const Stream.empty();
  return service.budgetStream();
});

// Budget categories with spentAmount auto-calculated from this month's expenses.
final budgetWithSpentProvider = Provider<AsyncValue<List<BudgetCategory>>>((ref) {
  final byCategory = ref.watch(expenseByCategoryProvider);
  return ref.watch(budgetProvider).whenData(
    (cats) => cats
        .map((c) => c.copyWith(spentAmount: byCategory[c.category] ?? 0.0))
        .toList(),
  );
});

// Category names from current-month budget (for expense category picker).
final budgetCategoryNamesProvider = Provider<List<String>>((ref) {
  return ref.watch(budgetProvider).when(
    data: (cats) => cats.map((c) => c.category).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Health Stream ────────────────────────────────────────────────

final healthProvider = StreamProvider<List<HealthHabit>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  if (service == null) return const Stream.empty();
  return service.healthStream();
});

// ─── Expenses Stream ──────────────────────────────────────────────

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  if (service == null) return const Stream.empty();
  return service.expensesStream();
});

final thisMonthExpensesProvider = Provider<List<Expense>>((ref) {
  final now = DateTime.now();
  return ref.watch(expensesProvider).when(
        data: (expenses) => expenses
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .toList(),
        loading: () => [],
        error: (_, __) => [],
      );
});

final totalThisMonthProvider = Provider<double>((ref) {
  return ref.watch(thisMonthExpensesProvider).fold(0.0, (s, e) => s + e.amount);
});

final expenseByCategoryProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(thisMonthExpensesProvider);
  final map = <String, double>{};
  for (final e in expenses) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
});

// ─── Wish List Stream ─────────────────────────────────────────────

final wishListProvider = StreamProvider<List<WishItem>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  if (service == null) return const Stream.empty();
  return service.wishListStream();
});

// ─── Dashboard Month Filter ───────────────────────────────────────

final dashboardMonthProvider = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));

final selectedMonthExpensesProvider = Provider<List<Expense>>((ref) {
  final month = ref.watch(dashboardMonthProvider);
  return ref.watch(expensesProvider).when(
        data: (expenses) => expenses
            .where((e) =>
                e.date.year == month.year && e.date.month == month.month)
            .toList(),
        loading: () => [],
        error: (_, __) => [],
      );
});

final selectedMonthTotalProvider = Provider<double>((ref) {
  return ref
      .watch(selectedMonthExpensesProvider)
      .fold(0.0, (s, e) => s + e.amount);
});

final selectedMonthByCategoryProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(selectedMonthExpensesProvider);
  final map = <String, double>{};
  for (final e in expenses) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
});

final prevMonthTotalProvider = Provider<double>((ref) {
  final month = ref.watch(dashboardMonthProvider);
  final prev = DateTime(month.year, month.month - 1);
  return ref.watch(expensesProvider).when(
        data: (expenses) => expenses
            .where((e) =>
                e.date.year == prev.year && e.date.month == prev.month)
            .fold(0.0, (s, e) => s + e.amount),
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
});

// ─── Food Tracker ─────────────────────────────────────────────────

final foodDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final foodEntriesProvider =
    StreamProvider.family<List<FoodEntry>, DateTime>((ref, date) {
  final service = ref.watch(firebaseServiceProvider);
  if (service == null) return const Stream.empty();
  return service.foodEntriesStream(date);
});

final calorieGoalProvider = StreamProvider<int>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  if (service == null) return Stream.value(2000);
  return service.calorieGoalStream();
});

// ─── User Role / Admin ────────────────────────────────────────────

final userRoleProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  if (service == null) return Stream.value(false);
  return service.userRoleStream();
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider).when(
        data: (isAdmin) => isAdmin,
        loading: () => false,
        error: (_, __) => false,
      );
});

// ─── Derived Providers ────────────────────────────────────────────

final overduTasksCountProvider = Provider<int>((ref) {
  return ref.watch(cleaningTasksProvider).when(
        data: (tasks) => tasks.where((t) => t.isOverdue).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});

final itemsToBuyCountProvider = Provider<int>((ref) {
  return ref.watch(shoppingItemsProvider).when(
        data: (items) => items.where((i) => !i.bought).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});

final totalBudgetUsedProvider = Provider<double>((ref) {
  return ref.watch(budgetWithSpentProvider).when(
        data: (cats) {
          final totalBudget =
              cats.fold(0.0, (sum, c) => sum + c.budgetAmount);
          final totalSpent = cats.fold(0.0, (sum, c) => sum + c.spentAmount);
          return totalBudget > 0 ? totalSpent / totalBudget : 0.0;
        },
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
});

final healthScoreProvider = Provider<double>((ref) {
  return ref.watch(healthProvider).when(
        data: (habits) {
          if (habits.isEmpty) return 0.0;
          final total = habits.fold(0.0, (sum, h) => sum + h.progressPercent);
          return (total / habits.length * 100).clamp(0.0, 100.0);
        },
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
});

final pendingShoppingCostProvider = Provider<double>((ref) {
  return ref.watch(shoppingItemsProvider).when(
        data: (items) => items
            .where((i) => !i.bought)
            .fold(0.0, (sum, i) => sum + i.cost * i.quantity),
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
});

final overBudgetCategoriesProvider = Provider<List<BudgetCategory>>((ref) {
  return ref.watch(budgetWithSpentProvider).when(
        data: (cats) => cats.where((c) => c.isOverBudget).toList(),
        loading: () => [],
        error: (_, __) => [],
      );
});
