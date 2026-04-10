import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cleaning_task.dart';
import '../models/expense.dart';
import '../models/food_entry.dart';
import '../models/shopping_item.dart';
import '../models/budget_category.dart';
import '../models/health_habit.dart';
import '../models/wish_item.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  FirebaseService(this.userId);

  CollectionReference get _cleaningRef =>
      _db.collection('users').doc(userId).collection('cleaning_tasks');

  CollectionReference get _shoppingRef =>
      _db.collection('users').doc(userId).collection('shopping_items');

  CollectionReference get _budgetRef =>
      _db.collection('users').doc(userId).collection('budget_categories');

  CollectionReference get _healthRef =>
      _db.collection('users').doc(userId).collection('health_habits');

  CollectionReference get _expenseRef =>
      _db.collection('users').doc(userId).collection('expenses');

  CollectionReference get _wishRef =>
      _db.collection('users').doc(userId).collection('wish_list');

  CollectionReference get _foodRef =>
      _db.collection('users').doc(userId).collection('food_entries');

  // ─── Cleaning Tasks ───────────────────────────────────────────────

  Stream<List<CleaningTask>> cleaningTasksStream() {
    return _cleaningRef
        .snapshots()
        .map((snap) {
          final tasks =
              snap.docs.map<CleaningTask>(CleaningTask.fromFirestore).toList();
          tasks.sort((a, b) {
            // Done tasks always go last
            final aDone = a.status == TaskStatus.done;
            final bDone = b.status == TaskStatus.done;
            if (aDone != bDone) return aDone ? 1 : -1;
            // Among active tasks: earliest nextDueDate first
            // (overdue → due today → upcoming)
            return a.nextDueDate.compareTo(b.nextDueDate);
          });
          return tasks;
        });
  }

  Future<void> addCleaningTask(CleaningTask task) async {
    await _cleaningRef.add(task.toFirestore());
  }

  Future<void> updateCleaningTask(CleaningTask task) async {
    await _cleaningRef.doc(task.id).update(task.toFirestore());
  }

  Future<void> deleteCleaningTask(String id) async {
    await _cleaningRef.doc(id).delete();
  }

  Future<void> markCleaningTaskDone(String id) async {
    await _cleaningRef.doc(id).update({
      'lastDoneDate': Timestamp.fromDate(DateTime.now()),
      'status': TaskStatus.done.name,
    });
  }

  // ─── Shopping Items ───────────────────────────────────────────────

  Stream<List<ShoppingItem>> shoppingItemsStream() {
    return _shoppingRef
        .snapshots()
        .map((snap) {
          final items =
              snap.docs.map<ShoppingItem>(ShoppingItem.fromFirestore).toList();
          items.sort((a, b) {
            // Bought items go last
            if (a.bought != b.bought) return a.bought ? 1 : -1;
            // Sort by priority: essential(0) → high(1) → medium(2) → basic(3)
            return a.priority.index.compareTo(b.priority.index);
          });
          return items;
        });
  }

  Future<void> addShoppingItem(ShoppingItem item) async {
    await _shoppingRef.add(item.toFirestore());
  }

  Future<void> updateShoppingItem(ShoppingItem item) async {
    await _shoppingRef.doc(item.id).update(item.toFirestore());
  }

  Future<void> deleteShoppingItem(String id) async {
    await _shoppingRef.doc(id).delete();
  }

  Future<void> toggleItemBought(String id, bool bought) async {
    await _shoppingRef.doc(id).update({'bought': bought});
  }

  // ─── Budget Categories ────────────────────────────────────────────

  Stream<List<BudgetCategory>> budgetStream() {
    return _budgetRef
        .orderBy('category')
        .snapshots()
        .map((snap) => snap.docs.map<BudgetCategory>(BudgetCategory.fromFirestore).toList());
  }

  Future<void> addBudgetCategory(BudgetCategory cat) async {
    await _budgetRef.add(cat.toFirestore());
  }

  Future<void> updateBudgetCategory(BudgetCategory cat) async {
    await _budgetRef.doc(cat.id).update(cat.toFirestore());
  }

  Future<void> deleteBudgetCategory(String id) async {
    await _budgetRef.doc(id).delete();
  }

  // ─── Health Habits ────────────────────────────────────────────────

  Stream<List<HealthHabit>> healthStream() {
    return _healthRef
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map<HealthHabit>(HealthHabit.fromFirestore).toList());
  }

  Future<void> addHealthHabit(HealthHabit habit) async {
    await _healthRef.add(habit.toFirestore());
  }

  Future<void> updateHealthHabit(HealthHabit habit) async {
    await _healthRef.doc(habit.id).update(habit.toFirestore());
  }

  Future<void> deleteHealthHabit(String id) async {
    await _healthRef.doc(id).delete();
  }

  Future<void> logHabitValue(String id, double value) async {
    final doc = await _healthRef.doc(id).get();
    final habit = HealthHabit.fromFirestore(doc);
    final newValue = (habit.todayValue + value).clamp(0.0, habit.goal * 2);
    await _healthRef.doc(id).update({'todayValue': newValue});
  }

  Future<void> resetHabitValue(String id) async {
    await _healthRef.doc(id).update({'todayValue': 0.0});
  }

  // ─── Default Seed ────────────────────────────────────────────────

  Future<void> seedDefaultCleaningTasks() async {
    final existing = await _cleaningRef.limit(1).get();
    if (existing.docs.isNotEmpty) return; // already seeded

    final now = DateTime.now();
    final batch = _db.batch();

    final tasks = [
      // Restrooms (×2) — weekly
      _task('Restroom Wash', 'Bathroom 1', 'weekly', now, '#00BFA5'),
      _task('Restroom Wash', 'Bathroom 2', 'weekly', now, '#00BFA5'),
      // Doors (×4) — monthly
      _task('Door Cleaning', 'All Doors (×4)', 'monthly', now, '#2196F3'),
      // Windows (×5) — monthly
      _task('Window Cleaning', 'All Windows (×5)', 'monthly', now, '#2196F3'),
      // Sinks (×3) — weekly
      _task('Sink Wash', 'Kitchen Sink', 'weekly', now, '#FF6D00'),
      _task('Sink Wash', 'Bathroom Sink 1', 'weekly', now, '#FF6D00'),
      _task('Sink Wash', 'Bathroom Sink 2', 'weekly', now, '#FF6D00'),
      // Gas stove — every 2 weeks
      _task('Gas Stove Clean', 'Kitchen', 'biweekly', now, '#F44336'),
      // Floor — every 3 days
      _task('Floor Cleaning', 'All Rooms', 'every3Days', now, '#9C27B0'),
      // Fan — every 2 months
      _task('Fan Cleaning', 'All Rooms', 'every2Months', now, '#607D8B'),
      // Lights — every 3 months
      _task('Light Cleaning', 'All Rooms', 'every3Months', now, '#FFC107'),
      // AC — every 4 months
      _task('AC Service', 'All Rooms', 'every4Months', now, '#03A9F4'),
      // TV — every 5 months
      _task('TV Cleaning', 'Living Room', 'every5Months', now, '#4CAF50'),
    ];

    for (final t in tasks) {
      batch.set(_cleaningRef.doc(), t);
    }
    await batch.commit();
  }

  Future<void> seedDefaultShoppingItems() async {
    final existing = await _shoppingRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    final items = [
      // ── Essential ──────────────────────────────────────────────
      _item('Gas Cylinder', 'Fuel', 'essential', 900, 1),
      _item('Washing Machine Cleaner', 'Cleaning', 'essential', 200, 1),
      _item('Door Lock', 'Security', 'essential', 500, 2),
      // ── High ───────────────────────────────────────────────────
      _item('Bathroom Brush', 'Bathroom', 'high', 80, 2),
      _item('Sink Brush', 'Bathroom', 'high', 60, 2),
      _item('Slipper Rack', 'Entryway', 'high', 350, 1),
      _item('Shoe Rack', 'Entryway', 'high', 800, 1),
      _item('Shelf Liner', 'Storage', 'high', 150, 1),
      _item('Fridge & Washing Machine Cloth', 'Appliances', 'high', 100, 1),
      _item('Fridge Container Box', 'Kitchen', 'high', 300, 1),
      _item('Iron Box', 'Laundry', 'high', 700, 1),
      _item('Iron Box Stand', 'Laundry', 'high', 400, 1),
      _item('Cloth Hanger', 'Laundry', 'high', 200, 1),
      _item('Bed Cover & Pillow Cover', 'Bedroom', 'high', 600, 1),
      _item('Rack for Spices', 'Kitchen', 'high', 350, 1),
      _item('Vessel Rack', 'Kitchen', 'high', 450, 1),
      _item('Pillow', 'Bedroom', 'high', 500, 1),
      _item('Key Holder', 'Entryway', 'high', 150, 1),
      // ── Medium ─────────────────────────────────────────────────
      _item('Door Curtain', 'Decor', 'medium', 400, 2),
      _item('Window Curtain', 'Decor', 'medium', 350, 3),
      _item('OTG Oven', 'Appliances', 'medium', 2500, 1),
      _item('Ceramic Cookware', 'Kitchen', 'medium', 1200, 1),
      _item('Room Spray', 'Home Fragrance', 'medium', 200, 1),
      _item('Carpet', 'Decor', 'medium', 800, 1),
      _item('Chair', 'Furniture', 'medium', 1500, 1),
      // ── Basic ──────────────────────────────────────────────────
      _item('Sofa', 'Furniture', 'basic', 15000, 1),
      _item('Buddha Statue', 'Decor', 'basic', 500, 1),
      _item('Cot', 'Bedroom', 'basic', 8000, 1),
      _item('Photo Frame', 'Decor', 'basic', 300, 1),
      _item('Plants', 'Decor', 'basic', 200, 1),
      _item('Dress Trolley', 'Bedroom', 'basic', 1200, 1),
      _item('Cupboard', 'Furniture', 'basic', 12000, 1),
      _item('Decorative Lights', 'Decor', 'basic', 600, 1),
      _item('Humidifier', 'Home Fragrance', 'basic', 1800, 1),
      _item('Air Scent Diffuser', 'Home Fragrance', 'basic', 500, 1),
      _item('Balcony Decor', 'Decor', 'basic', 800, 1),
      _item('Balcony Artificial Grass', 'Decor', 'basic', 1200, 1),
      _item('Dining Table', 'Furniture', 'basic', 10000, 1),
    ];

    for (final item in items) {
      batch.set(_shoppingRef.doc(), item);
    }
    await batch.commit();
  }

  Map<String, dynamic> _item(String name, String category, String priority,
      double cost, int quantity) {
    return {
      'name': name,
      'category': category,
      'priority': priority,
      'cost': cost,
      'bought': false,
      'quantity': quantity,
    };
  }

  Map<String, dynamic> _task(String name, String room, String frequency,
      DateTime lastDone, String color) {
    return {
      'name': name,
      'room': room,
      'frequency': frequency,
      'lastDoneDate': Timestamp.fromDate(lastDone),
      'status': 'pending',
      'color': color,
    };
  }

  // ─── Expenses ─────────────────────────────────────────────────────

  Stream<List<Expense>> expensesStream() {
    return _expenseRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map<Expense>(Expense.fromFirestore).toList());
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseRef.add(expense.toFirestore());
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseRef.doc(expense.id).update(expense.toFirestore());
  }

  Future<void> deleteExpense(String id) async {
    await _expenseRef.doc(id).delete();
  }

  // ─── Wish List ────────────────────────────────────────────────────

  Stream<List<WishItem>> wishListStream() {
    return _wishRef
        .orderBy('addedDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map<WishItem>(WishItem.fromFirestore).toList());
  }

  Future<void> addWishItem(WishItem item) async {
    await _wishRef.add(item.toFirestore());
  }

  Future<void> updateWishItem(WishItem item) async {
    await _wishRef.doc(item.id).update(item.toFirestore());
  }

  Future<void> deleteWishItem(String id) async {
    await _wishRef.doc(id).delete();
  }

  Future<void> markWishAchieved(String id) async {
    await _wishRef.doc(id).update({'status': WishStatus.achieved.name});
  }

  Future<void> seedDefaultWishItems() async {
    final existing = await _wishRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final now = DateTime.now();
    final batch = _db.batch();

    final items = [
      // ── Clothing ───────────────────────────────────────────────
      _wish('Pattu Saree', 'buy', 15000, 4, 'Traditional silk sarees', now),
      _wish('Saree', 'buy', 3000, 5, 'Regular sarees', now),
      _wish('Chudi', 'buy', 800, 5, 'Churidar sets', now),
      _wish('Tops', 'buy', 500, 5, '', now),
      _wish('Night Wear', 'buy', 600, 5, '', now),
      _wish('Baby Doll', 'beauty', 700, 5, '', now),
      _wish('Shimmy & Jatti', 'beauty', 300, 5, 'Innerwear', now),
      _wish('Vibrator', 'beauty', 1500, 1, 'Personal care', now),
      // ── Accessories ────────────────────────────────────────────
      _wish('Necklace Set', 'beauty', 2500, 2, '', now),
      _wish('Makeup Kit', 'beauty', 3000, 1, 'Foundation, lipstick, kajal, etc.', now),
      _wish('Shoes', 'buy', 1500, 1, '', now),
      _wish('Slipper', 'buy', 500, 1, '', now),
      _wish('Hair Color', 'beauty', 400, 1, '', now),
    ];

    for (final item in items) {
      batch.set(_wishRef.doc(), item);
    }
    await batch.commit();
  }

  Map<String, dynamic> _wish(String title, String category, double cost,
      int qty, String description, DateTime now) {
    return {
      'title': title,
      'description': description,
      'category': category,
      'estimatedCost': cost,
      'quantity': qty,
      'status': 'pending',
      'addedDate': Timestamp.fromDate(now),
      'note': '',
    };
  }

  // ─── Food Entries ─────────────────────────────────────────────────

  Stream<List<FoodEntry>> foodEntriesStream(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _foodRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
          final entries =
              snap.docs.map<FoodEntry>(FoodEntry.fromFirestore).toList();
          entries.sort((a, b) => a.date.compareTo(b.date));
          return entries;
        });
  }

  Future<void> addFoodEntry(FoodEntry entry) async {
    await _foodRef.add(entry.toFirestore());
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    await _foodRef.doc(entry.id).update(entry.toFirestore());
  }

  Future<void> deleteFoodEntry(String id) async {
    await _foodRef.doc(id).delete();
  }

  // ─── Calorie Goal ─────────────────────────────────────────────────

  Stream<int> calorieGoalStream() {
    return _userDoc.snapshots().map((doc) {
      if (!doc.exists) return 2000;
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['calorieGoal'] as int?) ?? 2000;
    });
  }

  Future<void> setCalorieGoal(int goal) async {
    await _userDoc.set({'calorieGoal': goal}, SetOptions(merge: true));
  }

  // ─── User Profile / Role ──────────────────────────────────────────

  DocumentReference get _userDoc => _db.collection('users').doc(userId);

  Stream<bool> userRoleStream() {
    return _userDoc.snapshots().map((doc) {
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['isAdmin'] as bool?) ?? false;
    });
  }

  Future<void> saveUserProfile(String email) async {
    final doc = await _userDoc.get();
    if (doc.exists) return; // profile already saved

    await _userDoc.set({
      'email': email,
      'isAdmin': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
