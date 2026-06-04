import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

// ── Palette ───────────────────────────────────────────────────────────
const _kGreen  = Color(0xFF1D9E75);
const _kBlue   = Color(0xFF185FA5);
const _kPurple = Color(0xFF534AB7);
const _kAmber  = Color(0xFFBA7517);

// ── Data models ───────────────────────────────────────────────────────
class _Dish {
  final String name;
  final Color dot;
  const _Dish(this.name, this.dot);
}

class _CardData {
  final Color badgeBg;
  final Color badgeFg;
  final String badge;
  final String title;
  final String body;
  const _CardData(this.badgeBg, this.badgeFg, this.badge, this.title, this.body);
}

// ── Screen ────────────────────────────────────────────────────────────
class PcosGuideScreen extends StatelessWidget {
  const PcosGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.accentTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PCOS Guide',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text('Meals · Gym · Avoid · Support · Routine',
                            style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('ADMIN ONLY',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
                  ),
                ],
              ),
            ),
          ),

          // Tab bar
          Container(
            color: cs.surface,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
              labelStyle: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tabs: const [
                Tab(text: 'Meals (100+)'),
                Tab(text: 'Gym Routine'),
                Tab(text: 'Foods to Avoid'),
                Tab(text: 'Support Her'),
                Tab(text: 'Daily Routine'),
              ],
            ),
          ),

          // Tab views
          const Expanded(
            child: TabBarView(
              children: [
                _MealsTab(),
                _GymTab(),
                _AvoidTab(),
                _SupportTab(),
                _DailyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 1 · MEALS ───────────────────────────────────────────────────
class _MealsTab extends StatelessWidget {
  const _MealsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Breakfast  ·  08:30 AM'),
        const _DishGrid([
          _Dish('Vegetable oats upma with flaxseed', _kGreen),
          _Dish('Ragi dosa with coconut chutney', _kGreen),
          _Dish('Moong dal chilla with mint chutney', _kGreen),
          _Dish('Boiled eggs + sautéed vegetables', _kGreen),
          _Dish('Greek yogurt with berries & seeds', _kGreen),
          _Dish('Whole wheat dosa with vegetable filling', _kGreen),
          _Dish('Paneer bhurji with roti', _kGreen),
          _Dish('Chia seed pudding with almond milk', _kGreen),
          _Dish('Oats porridge with cinnamon & walnuts', _kGreen),
          _Dish('Idli with sambar (ragi/oat — no rice)', _kGreen),
          _Dish('Ragi (Finger Millet) Idli with onion-tomato chutney', _kGreen),
          _Dish('Pesarattu (Green Gram Dosa) with moong dal & ginger', _kGreen),
          _Dish('Kuthiraivali (Barnyard Millet) Pongal with moong dal & pepper', _kGreen),
          _Dish('Varagu (Kodo Millet) Upma with beans, carrots & peas', _kGreen),
          _Dish('Adai Dosa (Multi-lentil crepe) — Chana, Toor & Moong dal', _kGreen),
          _Dish('Oats Kozhukattai (Steamed dumplings) with spicy tempering', _kGreen),
          _Dish('Sorghum (Jowar/Cholam) Puttu with kadala curry', _kGreen),
          _Dish('Samai (Little Millet) Curd Rice with Greek yogurt', _kGreen),
          _Dish('Sprouted Moong Sundal with fresh grated coconut', _kGreen),
          _Dish('Thinai (Foxtail Millet) Ven Pongal', _kGreen),
          _Dish('Masala Oats Paniyaram (cast-iron, minimal oil)', _kGreen),
          _Dish('Egg Appam (brown rice/millet base) with 2 egg whites', _kGreen),
          _Dish('Besan & Murungai Keerai (Drumstick Leaf) Adai', _kGreen),
        ]),
        const _SectionTitle('Lunch  ·  01:30 PM'),
        const _DishGrid([
          _Dish('Brown rice + dal + mixed sabzi', _kBlue),
          _Dish('Quinoa pulao with vegetables', _kBlue),
          _Dish('Rajma with jowar roti', _kBlue),
          _Dish('Palak paneer + 1 multigrain roti', _kBlue),
          _Dish('Grilled chicken + salad + lentil soup', _kBlue),
          _Dish('Methi thepla with low-fat curd', _kBlue),
          _Dish('Mung bean salad with lemon dressing', _kBlue),
          _Dish('Baingan bharta + brown rice', _kBlue),
          _Dish('Chickpea curry + quinoa', _kBlue),
          _Dish('Tuna / grilled fish + vegetables', _kBlue),
          _Dish('Soya chunks curry + millets', _kBlue),
          _Dish('Lentil soup + multigrain bread', _kBlue),
          _Dish('Thinai (Foxtail Millet) Sambar Rice with extra vegetables', _kBlue),
          _Dish('Varagu (Kodo Millet) Curd Rice + Sambar Vengayam Poriyal', _kBlue),
          _Dish('Keerai Masiyal (Mashed spinach) + Kala Chana Sundal', _kBlue),
          _Dish('Meen Kulambu (Fish Curry) — Rohu/Bangda + Cabbage Poriyal', _kBlue),
          _Dish('Kootu (Lentil veggie stew) using Chow-Chow or Lauki', _kBlue),
          _Dish('Kandanthippili Rasam + Boiled Eggs', _kBlue),
          _Dish('Vazhaithandu (Banana Stem) Poriyal — great for water retention', _kBlue),
          _Dish('Karuveppilai (Curry Leaf) Rice made with Samai Millet', _kBlue),
          _Dish('Chicken Chettinad (low oil) + Beans & Carrot Poriyal', _kBlue),
          _Dish('Murungai Keerai (Drumstick Leaf) Soup + Grilled Paneer', _kBlue),
          _Dish('Sura Puttu (Steamed fish scramble) — very high protein', _kBlue),
          _Dish('Peerkangai (Ridge Gourd) Thogayal with millet rotis', _kBlue),
          _Dish('Vendakkai (Okra) Fry (air-fried) + Moong Dal Kootu', _kBlue),
          _Dish('Pavakkai (Bitter Gourd) Pitlai (lentil-based curry)', _kBlue),
          _Dish('Kollu (Horse Gram) Rasam — known for fat burning', _kBlue),
          _Dish('Millet Bisi Bele Bath with heavy vegetables', _kBlue),
          _Dish('Sundakkai (Turkey Berry) Vatha Kulambu — great for iron', _kBlue),
        ]),
        const _SectionTitle('Dinner  ·  07:30 PM'),
        const _DishGrid([
          _Dish('Grilled chicken/fish + stir-fried veggies', _kPurple),
          _Dish('Vegetable daliya (broken wheat)', _kPurple),
          _Dish('Egg curry + 1 roti (no rice at night)', _kPurple),
          _Dish('Paneer tikka + salad', _kPurple),
          _Dish('Tofu stir-fry with quinoa', _kPurple),
          _Dish('Moong dal khichdi (light version)', _kPurple),
          _Dish('Zucchini soup + whole wheat toast', _kPurple),
          _Dish('Masoor dal + 1 jowar roti', _kPurple),
          _Dish('Baked salmon / fish with vegetables', _kPurple),
          _Dish('Mushroom stir-fry with millets', _kPurple),
          _Dish('Millet Semiya Upma with double the vegetables', _kPurple),
          _Dish('Oats Kanji (Savory — ginger & garlic)', _kPurple),
          _Dish('Grilled Nethili (Anchovies) with turmeric & pepper', _kPurple),
          _Dish('Vegetable Manchow Soup (home-made)', _kPurple),
          _Dish('Moong Dal Soup with drumstick leaves', _kPurple),
          _Dish('Paneer Salad with South Indian tempering (mustard/curry leaves)', _kPurple),
          _Dish('Stir-fried Shrimp/Prawns with pepper and onions', _kPurple),
          _Dish('Mushroom Pepper Fry (dry version, no rice)', _kPurple),
          _Dish('Cauliflower Rice Biryani (grated cauliflower base)', _kPurple),
          _Dish('Steamed Sprouts with Lemon', _kPurple),
          _Dish('Tofu Stir-fry with curry leaf pesto', _kPurple),
          _Dish('Clear Chicken Broth with cilantro', _kPurple),
          _Dish('Cinnamon Milk (warm water + cinnamon bark)', _kPurple),
        ]),
        const _SectionTitle('Snacks & Metabolism Boosters  ·  04:30 PM'),
        const _DishGrid([
          _Dish('Handful of almonds + walnuts', _kAmber),
          _Dish('Roasted makhana (fox nuts)', _kAmber),
          _Dish('Apple + peanut butter (small)', _kAmber),
          _Dish('Hummus + cucumber sticks', _kAmber),
          _Dish('Sprouts chaat (no sev)', _kAmber),
          _Dish('Boiled egg + black pepper', _kAmber),
          _Dish('Coconut water (1 glass)', _kAmber),
          _Dish('Flaxseed & pumpkin seed mix', _kAmber),
          _Dish('Low-sugar smoothie (berries + spinach)', _kAmber),
          _Dish('Curd with jeera powder', _kAmber),
          _Dish('Roasted chana (handful)', _kAmber),
          _Dish('Sliced guava or papaya', _kAmber),
          _Dish('Roasted Peanuts (small handful)', _kAmber),
          _Dish('Spearmint Tea or Ginger Lemon Tea (No Sugar)', _kAmber),
          _Dish('Cucumber & Tomato slices with chilli powder', _kAmber),
          _Dish('Neer Mor (Buttermilk) with ginger, green chilli & curry leaves', _kAmber),
          _Dish('Roasted Lotus Seeds (Makhana)', _kAmber),
          _Dish('Steamed Sweet Corn (small portion)', _kAmber),
          _Dish('Walnuts & Soaked Almonds', _kAmber),
          _Dish('Guava or Papaya slices', _kAmber),
        ]),
        const _TipBox(
            'Spices that help: cinnamon (improves insulin sensitivity), fenugreek (methi), turmeric, and ginger — add to everyday cooking.'),
        const _TipBox(
            'Eat every 3–4 hours. Never skip breakfast. Keep dinner light and early (before 8 PM).'),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── TAB 2 · GYM ─────────────────────────────────────────────────────
class _GymTab extends StatelessWidget {
  const _GymTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _CardGrid([
          _CardData(Color(0xFFEAF3DE), Color(0xFF3B6D11), 'Best',
              'Strength Training',
              'Reduces insulin resistance. 3x/week — squats, deadlifts, lunges, rows. Builds muscle = burns fat at rest.'),
          _CardData(Color(0xFFEAF3DE), Color(0xFF3B6D11), 'Best',
              'HIIT (2x/week)',
              'Short bursts: 20s on / 40s off × 10 rounds. Powerful for hormonal balance. Keep sessions under 30 min.'),
          _CardData(Color(0xFFE6F1FB), Color(0xFF185FA5), 'Good', 'Walking',
              'Brisk 30 min walk daily — especially after meals. Lowers cortisol and helps with blood sugar spikes.'),
          _CardData(Color(0xFFE6F1FB), Color(0xFF185FA5), 'Good', 'Yoga',
              '1–2x/week. Supta Baddha Konasana, Butterfly, Child\'s Pose. Reduces stress hormones (cortisol).'),
          _CardData(Color(0xFFFAEEDA), Color(0xFF854F0B), 'Moderate',
              'Cycling / Swimming',
              'Low-impact cardio. 45 min sessions. Good joint health, low stress on adrenals.'),
          _CardData(Color(0xFFFCEBEB), Color(0xFFA32D2D), 'Avoid',
              'Excessive Cardio',
              'Long daily cardio raises cortisol, worsening PCOS. No 90+ min cardio sessions.'),
        ]),
        const _SectionTitle('Weekly Plan'),
        const _RoutineBlock('Monday — Strength (Lower Body)',
            ['Squats 3×12', 'Lunges 3×10', 'Leg press', 'Glute bridges', 'Calf raises']),
        const _RoutineBlock('Tuesday — HIIT + Core', [
          '10 min HIIT circuit',
          'Plank 3×45s',
          'Dead bugs',
          'Bicycle crunches',
          '20 min brisk walk'
        ]),
        const _RoutineBlock('Wednesday — Active Recovery',
            ['30 min yoga / stretching', 'Light walk', 'Focus on breathing exercises']),
        const _RoutineBlock('Thursday — Strength (Upper Body)', [
          'Dumbbell rows',
          'Shoulder press',
          'Chest press',
          'Lat pulldowns',
          'Tricep dips'
        ]),
        const _RoutineBlock('Friday — HIIT or Cycling',
            ['20 min HIIT or 40 min cycling', 'Followed by 10 min stretching']),
        const _RoutineBlock('Saturday — Full Body Strength',
            ['Deadlifts', 'Rows', 'Squats combo', 'Core work', 'End with 20 min walk']),
        const _RoutineBlock('Sunday — Rest / Light Yoga',
            ['Restorative yoga', 'Breathing', 'Meditative walk — no gym']),
        const _TipBox(
            'Post-workout nutrition matters: protein + complex carb within 30–45 min (e.g. eggs + fruit, or whey + banana).'),
        const _TipBox(
            'Sleep before 10:30 PM — poor sleep spikes cortisol and androgens, worsening PCOS symptoms.'),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── TAB 3 · FOODS TO AVOID ───────────────────────────────────────────
class _AvoidTab extends StatelessWidget {
  const _AvoidTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Foods to Strictly Avoid'),
        const _AvoidRow('White rice, maida (refined flour), white bread',
            'spike blood sugar rapidly, worsen insulin resistance'),
        const _AvoidRow('Sugary drinks & packaged juices',
            'massive glucose spikes; use whole fruit instead'),
        const _AvoidRow('Deep fried foods',
            'trans fats worsen inflammation and hormone disruption'),
        const _AvoidRow('Processed & packaged snacks',
            'chips, biscuits, instant noodles, crackers'),
        const _AvoidRow('Excess dairy',
            'full-fat milk, paneer daily may raise IGF-1. Use in moderation.'),
        const _AvoidRow('Red meat (excess)',
            'especially processed meats. Max 1–2x/week if at all'),
        const _AvoidRow('Alcohol',
            'disrupts liver function, estrogen metabolism, and blood sugar'),
        const _AvoidRow('Excess caffeine',
            '>2 cups/day raises cortisol. Switch partially to green tea'),
        const _AvoidRow('High-sugar fruits in excess',
            'mango, banana, grapes, chikoo (eat small portions, pair with protein)'),
        const _AvoidRow('Soy in excess',
            'contains phytoestrogens; small amounts ok but not daily soya products'),
        const _AvoidRow('Hydrogenated vegetable oils',
            'vanaspati, margarine, partially hydrogenated fats'),
        const SizedBox(height: 12),
        const _SectionTitle('Limit (Not Eliminate)'),
        const _DishGrid([
          _Dish('White rice (max 1 small serving/day)', _kAmber),
          _Dish('Potato (avoid fried; boiled ok rarely)', _kAmber),
          _Dish('Sweetened curd / flavored yogurt', _kAmber),
          _Dish('Fruit juices (even "natural")', _kAmber),
          _Dish('Coconut oil (small amounts ok)', _kAmber),
          _Dish('Salt (excess worsens bloating)', _kAmber),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── TAB 4 · SUPPORT HER ─────────────────────────────────────────────
class _SupportTab extends StatelessWidget {
  const _SupportTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('What You Can Do as Her Partner'),
        const _CardGrid([
          _CardData(Color(0xFFEAF3DE), Color(0xFF3B6D11), 'Nutrition',
              'Eat the same food',
              'Don\'t eat junk at home. If she\'s avoiding white rice, you avoid it too at shared meals. It makes a huge difference.'),
          _CardData(Color(0xFFEAF3DE), Color(0xFF3B6D11), 'Gym',
              'Train together',
              'Having a gym partner = higher consistency. Spot her lifts, do HIIT together, and celebrate small wins.'),
          _CardData(Color(0xFFE6F1FB), Color(0xFF185FA5), 'Emotional',
              'Understand the symptoms',
              'Mood swings, fatigue, and irregular periods are hormonal — not personal. Be patient, not dismissive.'),
          _CardData(Color(0xFFE6F1FB), Color(0xFF185FA5), 'Emotional',
              'Never comment on weight',
              'PCOS causes weight retention even with effort. Acknowledge her hard work, not the number on the scale.'),
          _CardData(Color(0xFFFAEEDA), Color(0xFF854F0B), 'Practical',
              'Help with meal prep',
              'Sunday meal prep together — cook dals, cut veggies, portion snacks. Halves her effort during weekdays.'),
          _CardData(Color(0xFFFAEEDA), Color(0xFF854F0B), 'Practical',
              'Track with her',
              'Use apps like MyFitnessPal or Flo together. Knowing her cycle phases helps plan gym intensity.'),
          _CardData(Color(0xFFE6F1FB), Color(0xFF185FA5), 'Health',
              'Doctor appointments',
              'Go with her to gynecologist/endocrinologist visits. Shows you take it seriously and helps understand treatment plans.'),
          _CardData(Color(0xFFEAF3DE), Color(0xFF3B6D11), 'Sleep',
              'Protect her sleep',
              'Sleep is medicine for PCOS. Keep consistent sleep times. Avoid late-night screen time together.'),
        ]),
        const _TipBox(
            'PCOS is a marathon, not a sprint. Results (regular periods, reduced symptoms) take 3–6 months of consistent lifestyle change. Celebrate every small win.'),
        const _TipBox(
            'Stress is a major PCOS trigger. Help reduce her stress: share household load, plan occasional low-key outings, and be her calm when she\'s overwhelmed.'),
        const _TipBox(
            'Consider a registered dietitian (RD) who specializes in PCOS + a gynecologist/endocrinologist for medical management (metformin, inositol, etc.).'),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── TAB 5 · DAILY ROUTINE ────────────────────────────────────────────
class _DailyTab extends StatelessWidget {
  const _DailyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Ideal Daily Routine for PCOS'),
        const _RoutineBlock('6:00–6:30 AM — Wake up', [
          'Warm water with cinnamon + lemon',
          '5 min breathing / light stretching',
          'Do NOT skip breakfast'
        ]),
        const _RoutineBlock('7:00–8:00 AM — Breakfast', [
          'High protein, low GI breakfast within 1 hour of waking',
          'Take prescribed supplements if any (Inositol, Vitamin D, Iron)'
        ]),
        const _RoutineBlock('10:00–10:30 AM — Mid-morning snack',
            ['Nuts, seeds, or fruit (low sugar)', 'Green tea instead of chai']),
        const _RoutineBlock('1:00–1:30 PM — Lunch', [
          'Largest meal of the day',
          'Protein + complex carb + vegetables',
          '10 min walk post-lunch'
        ]),
        const _RoutineBlock('4:00–4:30 PM — Snack + Gym Prep',
            ['Light pre-workout snack: banana + peanut butter or boiled egg']),
        const _RoutineBlock('5:00–6:30 PM — Gym', [
          'Follow weekly plan (strength / HIIT / yoga)',
          'Post-workout: protein + carb snack within 45 min'
        ]),
        const _RoutineBlock('7:30–8:00 PM — Dinner', [
          'Light dinner — protein + vegetables, minimal carbs',
          'No screen eating — mindful meals help digestion and cortisol'
        ]),
        const _RoutineBlock('9:30–10:00 PM — Wind down', [
          'No screens 30 min before bed',
          'Warm turmeric milk (low-fat) or herbal tea',
          'Journal / light reading'
        ]),
        const _RoutineBlock('10:00–10:30 PM — Sleep', [
          '7–8 hours is non-negotiable for PCOS recovery',
          'Dark, cool room. Consistent bedtime every day.'
        ]),
        const _TipBox(
            'Cycle-syncing workouts: during menstrual phase (Day 1–5) keep workouts gentle. Follicular/Ovulatory (Day 6–14) is when she\'ll feel strongest — good time for heavy lifts. Luteal (Day 15–28) reduce intensity, add yoga.'),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _DishGrid extends StatelessWidget {
  final List<_Dish> dishes;
  const _DishGrid(this.dishes);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth > 500 ? 3 : 2;
        final itemW = (constraints.maxWidth - (cols - 1) * 8) / cols;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dishes
              .map((d) => SizedBox(
                    width: itemW,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: d.dot,
                                  shape: BoxShape.circle),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(d.name,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: cs.onSurface,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      }),
    );
  }
}

class _CardGrid extends StatelessWidget {
  final List<_CardData> cards;
  const _CardGrid(this.cards);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth > 500 ? 3 : 2;
        final itemW = (constraints.maxWidth - (cols - 1) * 8) / cols;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map((c) => SizedBox(
                    width: itemW,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.badgeBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(c.badge,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: c.badgeFg)),
                          ),
                          const SizedBox(height: 6),
                          Text(c.title,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface)),
                          const SizedBox(height: 4),
                          Text(c.body,
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color:
                                      cs.onSurface.withValues(alpha: 0.65),
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      }),
    );
  }
}

class _RoutineBlock extends StatelessWidget {
  final String title;
  final List<String> items;
  const _RoutineBlock(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border:
            Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color:
                                  cs.onSurface.withValues(alpha: 0.7),
                              height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _AvoidRow extends StatelessWidget {
  final String bold;
  final String detail;
  const _AvoidRow(this.bold, this.detail);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: const Color(0xFFF09595)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$bold  —  ',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          TextSpan(
              text: detail,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.65))),
        ]),
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String text;
  const _TipBox(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        border: const Border(left: BorderSide(color: _kGreen, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 12.5,
              color: cs.onSurface,
              height: 1.6)),
    );
  }
}
