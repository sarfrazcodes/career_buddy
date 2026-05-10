import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database_providers.dart';
import '../../services/gemini_service.dart';
import '../../widgets/cartoon_avatars.dart'; // <-- added for avatar
import '../reminders/reminders_screen.dart';
import '../timer/timer_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';
import '../goals/goals_screen.dart';

// ─── Global Provider ─────────────────────────────────────────────────────────
// Tells AnalyticsScreen which sub-tab to open: 0 = Today, 1 = Weekly
final analyticsSubTabProvider = StateProvider<int>((ref) => 0);

// ─── Dashboard Screen ────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    // Lazy switch avoids keeping all heavy screens alive at once
    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = _DashboardContent(
          onGoToAnalytics: () => _switchTab(2),
          onGoToProfile: () => _switchTab(4),
        );
        break;
      case 1:  currentScreen = const TimerScreen();     break;
      case 2:  currentScreen = const AnalyticsScreen(); break;
      case 3:  currentScreen = const RemindersScreen(); break;
      case 4:  currentScreen = const ProfileScreen();   break;
      default: currentScreen = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      extendBody: true,
      body: currentScreen,
      bottomNavigationBar: _GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: _switchTab,
      ),
    );
  }
}

// ─── Glass Bottom Navigation Bar ────────────────────────────────────────────

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.dashboard_rounded,     Icons.dashboard_outlined,     'Home'),
    (Icons.timer_rounded,         Icons.timer_outlined,         'Timer'),
    (Icons.analytics_rounded,     Icons.analytics_outlined,     'Stats'),
    (Icons.notifications_rounded, Icons.notifications_outlined, 'Alerts'),
    (Icons.person_rounded,        Icons.person_outline,         'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1E).withAlpha(200),
            border: const Border(
                top: BorderSide(color: Color(0xFF2A2A4A), width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final isSelected = currentIndex == i;
                final item = _items[i];
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: isSelected
                        ? BoxDecoration(
                      color: AppTheme.primaryAccent.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                    )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.$1 : item.$2,
                          color: isSelected
                              ? AppTheme.secondaryAccent
                              : const Color(0xFF5A5A7A),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.secondaryAccent
                                : const Color(0xFF5A5A7A),
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Content ───────────────────────────────────────────────────────

class _DashboardContent extends ConsumerWidget {
  final VoidCallback onGoToAnalytics;
  final VoidCallback onGoToProfile;

  const _DashboardContent({
    super.key,
    required this.onGoToAnalytics,
    required this.onGoToProfile,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  // ── Dialog 1: Streak Activity Calendar ──────────────────────────────────
  void _showStreakCalendar(
      BuildContext context, List<QueryDocumentSnapshot>? sessions) {
    final activeDays = <String>{};
    if (sessions != null) {
      for (var doc in sessions) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['timestamp'] != null) {
          final date = (data['timestamp'] as Timestamp).toDate();
          activeDays.add(
            "${date.year}-"
                "${date.month.toString().padLeft(2, '0')}-"
                "${date.day.toString().padLeft(2, '0')}",
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final now = DateTime.now();
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
        final firstDay =
            DateTime(now.year, now.month, 1).weekday; // 1 = Mon, 7 = Sun

        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: const Color(0xFFFF6B35).withAlpha(60), width: 1),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFF6B35).withAlpha(70)),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFFF6B35), size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Activity Calendar',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Weekday headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((d) => SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              color: Color(0xFF5A5A7A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: daysInMonth + firstDay - 1,
                  itemBuilder: (context, index) {
                    if (index < firstDay - 1) return const SizedBox();
                    final day = index - (firstDay - 2);
                    final dateStr =
                        "${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                    final isActive = activeDays.contains(dateStr);
                    final isToday = day == now.day;

                    return Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFFF6B35).withAlpha(200)
                            : Colors.white.withAlpha(8),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(
                            color: AppTheme.secondaryAccent, width: 2)
                            : null,
                        boxShadow: isActive
                            ? [BoxShadow(
                            color: const Color(0xFFFF6B35).withAlpha(80),
                            blurRadius: 6)]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF5A5A7A),
                          fontSize: 11,
                          fontWeight: (isActive || isToday)
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(
                        color: const Color(0xFFFF6B35),
                        label: 'Active day'),
                    const SizedBox(width: 16),
                    _LegendDot(
                        color: AppTheme.secondaryAccent,
                        label: 'Today',
                        isBorder: true),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: TextStyle(
                      color: AppTheme.secondaryAccent.withAlpha(200),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // ── Dialog 2: Skills Breakdown ───────────────────────────────────────────
  void _showCategoriesDialog(
      BuildContext context, Map<String, double> categoryHours) {
    final sorted = categoryHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const accentColors = [
      Color(0xFFBB86FC),
      Color(0xFF00D4FF),
      Color(0xFF00E676),
      Color(0xFFFF6B35),
      Color(0xFFFFD60A),
    ];

    showDialog(
      context: context,
      builder: (context) {
        final totalHours = sorted.fold(0.0, (sum, e) => sum + e.value);

        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: const Color(0xFFBB86FC).withAlpha(60), width: 1),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBB86FC).withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFBB86FC).withAlpha(70)),
                ),
                child: const Icon(Icons.category_rounded,
                    color: Color(0xFFBB86FC), size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Skills Breakdown',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: sorted.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No sessions yet.\nStart tracking to see your skills!',
                textAlign: TextAlign.center,
                style:
                TextStyle(color: Color(0xFF8888AA), height: 1.6),
              ),
            )
                : ListView.separated(
              shrinkWrap: true,
              itemCount: sorted.length,
              separatorBuilder: (_, __) => Divider(
                  color: Colors.white.withAlpha(10), height: 1),
              itemBuilder: (context, index) {
                final cat = sorted[index];
                final accent =
                accentColors[index % accentColors.length];
                final pct = totalHours > 0
                    ? (cat.value / totalHours * 100).toInt()
                    : 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: accent.withAlpha(22),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color: accent.withAlpha(70)),
                            ),
                            child: Icon(Icons.category_rounded,
                                color: accent, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(cat.key,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                          Text(
                            '${cat.value.toStringAsFixed(1)}h',
                            style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 15),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$pct%',
                                style: TextStyle(
                                    color: accent.withAlpha(180),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalHours > 0
                              ? cat.value / totalHours
                              : 0,
                          minHeight: 4,
                          backgroundColor: Colors.white.withAlpha(10),
                          valueColor:
                          AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: TextStyle(
                      color: AppTheme.secondaryAccent.withAlpha(200),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync     = ref.watch(userProfileProvider);
    final sessionsAsync        = ref.watch(sessionsProvider);
    final geminiQuoteAsync     = ref.watch(dailyQuoteProvider);
    final geminiKnowledgeAsync = ref.watch(dailyQuestionProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppTheme.secondaryAccent,
        backgroundColor: const Color(0xFF12122A),
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(dailyQuoteProvider);
          ref.invalidate(dailyQuestionProvider);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: userProfileAsync.when(
          data: (profileData) {
            final String name     = profileData?['name'] ?? 'User';
            final double rawToday =
                (profileData?['todayHours'] as num?)?.toDouble() ?? 0.0;
            final String avatarType = profileData?['avatar'] ?? 'neutral';

            // Compute weekly total & category map from sessions
            double weeklyTotal = 0.0;
            String topCategory = 'None';
            Map<String, double> cats = {};

            if (sessionsAsync.hasValue) {
              for (var doc in sessionsAsync.value!) {
                final d = doc.data() as Map<String, dynamic>;
                final h = (d['durationSeconds'] ?? 0) / 3600.0;
                final c = d['category'] ?? 'General';
                cats[c] = (cats[c] ?? 0.0) + h;
                weeklyTotal += h;
              }
              if (cats.isNotEmpty) {
                topCategory = cats.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key;
              }
            }

            return Stack(
              children: [
                // ── Ambient background blobs ──────────────────────────
                Positioned(
                  top: -80, right: -60,
                  child: Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.primaryAccent.withAlpha(35),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  top: 300, left: -80,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.secondaryAccent.withAlpha(20),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),

                // ── Main scrollable content ───────────────────────────
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF00E676),
                                      boxShadow: [BoxShadow(
                                        color: const Color(0xFF00E676)
                                            .withAlpha(120),
                                        blurRadius: 6,
                                      )],
                                    ),
                                  ),
                                  Text(_getGreeting(),
                                      style: const TextStyle(
                                          color: Color(0xFF8888AA),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.3)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5)),
                            ],
                          ),
                          // ── Profile avatar (now shows selected cartoon or icon) ──
                          GestureDetector(
                            onTap: onGoToProfile,
                            child: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  AppTheme.primaryAccent.withAlpha(80),
                                  AppTheme.secondaryAccent.withAlpha(80),
                                ], begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                border: Border.all(
                                    color: AppTheme.secondaryAccent
                                        .withAlpha(80),
                                    width: 1.5),
                              ),
                              child: ClipOval(
                                child: (avatarType == 'male' || avatarType == 'female')
                                    ? CartoonAvatar(
                                        type: avatarType,
                                        size: 48,  // same size as container
                                      )
                                    : const Icon(Icons.person_outline,
                                        color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Quote Card ───────────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1E0A3C),
                                    AppTheme.primaryAccent.withAlpha(180),
                                    AppTheme.secondaryAccent.withAlpha(140),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                            Positioned(top: -30, right: -20,
                                child: Container(width: 110, height: 110,
                                    decoration: BoxDecoration(shape: BoxShape.circle,
                                        color: Colors.white.withAlpha(15)))),
                            Positioned(bottom: -25, left: 30,
                                child: Container(width: 80, height: 80,
                                    decoration: BoxDecoration(shape: BoxShape.circle,
                                        color: Colors.white.withAlpha(10)))),
                            Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(25),
                                        borderRadius:
                                        BorderRadius.circular(20)),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_awesome_rounded,
                                            color: Colors.white, size: 12),
                                        SizedBox(width: 5),
                                        Text('DAILY MOTIVATION',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.2)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  geminiQuoteAsync.when(
                                    data: (q) => Text(q,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                            height: 1.55,
                                            letterSpacing: 0.1)),
                                    loading: () => Column(children: [
                                      LinearProgressIndicator(
                                          backgroundColor:
                                          Colors.white.withAlpha(30),
                                          color: Colors.white.withAlpha(100),
                                          borderRadius:
                                          BorderRadius.circular(4)),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                          value: 0.6,
                                          backgroundColor:
                                          Colors.white.withAlpha(30),
                                          color: Colors.white.withAlpha(80),
                                          borderRadius:
                                          BorderRadius.circular(4)),
                                    ]),
                                    error: (_, __) => const Text(
                                        "Focus on your vision.",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Knowledge Booster ────────────────────────────
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(colors: [
                            const Color(0xFF12122A),
                            AppTheme.primaryAccent.withAlpha(15),
                          ], begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          border: Border.all(
                              color: AppTheme.secondaryAccent.withAlpha(50),
                              width: 1),
                        ),
                        child: Stack(
                          children: [
                            Positioned(top: 0, left: 40, right: 40,
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.transparent,
                                    AppTheme.secondaryAccent.withAlpha(150),
                                    Colors.transparent,
                                  ]),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryAccent
                                            .withAlpha(25),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppTheme.secondaryAccent
                                                .withAlpha(60)),
                                      ),
                                      child: Icon(Icons.bolt_rounded,
                                          color: AppTheme.secondaryAccent,
                                          size: 14),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('KNOWLEDGE BOOSTER',
                                        style: TextStyle(
                                            color: Color(0xFFCCCCFF),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            letterSpacing: 1.5)),
                                  ]),
                                  const SizedBox(height: 14),
                                  geminiKnowledgeAsync.when(
                                    data: (k) => Text(k,
                                        style: const TextStyle(
                                            color: Color(0xFFD0D0F0),
                                            fontSize: 15,
                                            height: 1.6,
                                            letterSpacing: 0.1)),
                                    loading: () => const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFCCCCFF)),
                                        )),
                                    error: (_, __) => const Text(
                                        'Ready to boost your knowledge today?',
                                        style: TextStyle(
                                            color: Color(0xFFD0D0F0))),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Overview Header ──────────────────────────────
                      Row(
                        children: [
                          const Text('Overview',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3)),
                          const Spacer(),
                          GestureDetector(
                            // "See All" always lands on Today sub-tab
                            onTap: () {
                              ref
                                  .read(analyticsSubTabProvider.notifier)
                                  .state = 0;
                              onGoToAnalytics();
                            },
                            child: Row(children: [
                              Text('See All',
                                  style: TextStyle(
                                      color: AppTheme.secondaryAccent
                                          .withAlpha(200),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  color: AppTheme.secondaryAccent
                                      .withAlpha(200),
                                  size: 12),
                            ]),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Stats Grid — distinct tap per card ───────────
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.88,
                        children: [
                          // Today → Analytics "Today" sub-tab (index 0)
                          _StatCard(
                            title: 'Today',
                            value: '${rawToday.toStringAsFixed(2)}h',
                            icon: Icons.timer_outlined,
                            accent: const Color(0xFF00D4FF),
                            onTap: () {
                              ref
                                  .read(analyticsSubTabProvider.notifier)
                                  .state = 0;
                              onGoToAnalytics();
                            },
                          ),
                          // Streak → opens calendar dialog
                          _StatCard(
                            title: 'Current Streak',
                            value:
                            '${profileData?['streak'] ?? 0} Days',
                            icon: Icons.local_fire_department_rounded,
                            accent: const Color(0xFFFF6B35),
                            onTap: () => _showStreakCalendar(
                                context, sessionsAsync.value),
                          ),
                          // Weekly → Analytics "Weekly" sub-tab (index 1)
                          _StatCard(
                            title: 'Weekly',
                            value:
                            '${weeklyTotal.toStringAsFixed(1)}h',
                            icon: Icons.bar_chart_rounded,
                            accent: const Color(0xFF00E676),
                            onTap: () {
                              ref
                                  .read(analyticsSubTabProvider.notifier)
                                  .state = 1;
                              onGoToAnalytics();
                            },
                          ),
                          // Top Skill → opens categories dialog
                          _StatCard(
                            title: 'Top Skill',
                            value: topCategory,
                            icon: Icons.category_rounded,
                            accent: const Color(0xFFBB86FC),
                            onTap: () =>
                                _showCategoriesDialog(context, cats),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Active Goals Header ──────────────────────────
                      Row(
                        children: [
                          const Text('Active Goals',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const GoalsScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppTheme.primaryAccent
                                        .withAlpha(60),
                                    width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune_rounded,
                                      color: AppTheme.secondaryAccent
                                          .withAlpha(200),
                                      size: 13),
                                  const SizedBox(width: 5),
                                  Text('Manage',
                                      style: TextStyle(
                                          color: AppTheme.secondaryAccent
                                              .withAlpha(200),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Goals List ───────────────────────────────────
                      Consumer(
                        builder: (context, ref, _) {
                          final goalsAsync = ref.watch(goalsProvider);
                          return goalsAsync.when(
                            data: (goals) {
                              if (goals.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 28, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0F22),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFF2A2A4A),
                                        width: 1),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.flag_outlined,
                                          color: Color(0xFF5A5A7A),
                                          size: 32),
                                      SizedBox(height: 10),
                                      Text('No goals yet',
                                          style: TextStyle(
                                              color: Color(0xFF8888AA),
                                              fontSize: 14,
                                              fontWeight:
                                              FontWeight.w600)),
                                      SizedBox(height: 4),
                                      Text(
                                          'Tap Manage to add your first goal',
                                          style: TextStyle(
                                              color: Color(0xFF5A5A7A),
                                              fontSize: 12)),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children:
                                goals.take(2).map<Widget>((doc) {
                                  final data =
                                  doc.data() as Map<String, dynamic>;
                                  final double target =
                                  (data['targetHours'] as num)
                                      .toDouble();
                                  final double current =
                                  (data['currentHours'] as num)
                                      .toDouble();
                                  final double progress = target > 0
                                      ? (current / target)
                                      .clamp(0.0, 1.0)
                                      : 0.0;
                                  final int pct =
                                  (progress * 100).toInt();

                                  final Color barAccent = pct >= 80
                                      ? const Color(0xFF00E676)
                                      : pct >= 40
                                      ? const Color(0xFF00D4FF)
                                      : const Color(0xFFBB86FC);

                                  return GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                                    child: Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 12),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F0F22),
                                      borderRadius:
                                      BorderRadius.circular(22),
                                      border: Border.all(
                                          color: barAccent.withAlpha(45),
                                          width: 1),
                                      boxShadow: [BoxShadow(
                                        color: barAccent.withAlpha(18),
                                        blurRadius: 20,
                                        spreadRadius: -4,
                                        offset: const Offset(0, 6),
                                      )],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Container(
                                            width: 36, height: 36,
                                            decoration: BoxDecoration(
                                              color: barAccent
                                                  .withAlpha(22),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  11),
                                              border: Border.all(
                                                  color: barAccent
                                                      .withAlpha(70),
                                                  width: 1),
                                            ),
                                            child: Icon(
                                                Icons.flag_rounded,
                                                color: barAccent,
                                                size: 17),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                                data['title'] ?? 'Goal',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                    FontWeight.w700,
                                                    fontSize: 15,
                                                    letterSpacing: -0.2),
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow.ellipsis),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                            decoration: BoxDecoration(
                                              color: barAccent
                                                  .withAlpha(22),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                              border: Border.all(
                                                  color: barAccent
                                                      .withAlpha(70),
                                                  width: 1),
                                            ),
                                            child: Text('$pct%',
                                                style: TextStyle(
                                                    color: barAccent,
                                                    fontSize: 12,
                                                    fontWeight:
                                                    FontWeight.w800)),
                                          ),
                                        ]),
                                        const SizedBox(height: 14),
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 6,
                                            backgroundColor: Colors.white
                                                .withAlpha(12),
                                            valueColor:
                                            AlwaysStoppedAnimation<
                                                Color>(barAccent),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            Text(
                                                '${current.toStringAsFixed(1)}h done',
                                                style: const TextStyle(
                                                    color:
                                                    Color(0xFF8888AA),
                                                    fontSize: 11,
                                                    fontWeight:
                                                    FontWeight.w500)),
                                            Text(
                                                '${target.toStringAsFixed(1)}h target',
                                                style: const TextStyle(
                                                    color:
                                                    Color(0xFF5A5A7A),
                                                    fontSize: 11,
                                                    fontWeight:
                                                    FontWeight.w500)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ));
                                }).toList(),
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding:
                                EdgeInsets.symmetric(vertical: 24),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFCCCCFF)),
                              ),
                            ),
                            error: (_, __) => const Center(
                              child: Text('Could not load goals',
                                  style: TextStyle(
                                      color: Color(0xFF8888AA),
                                      fontSize: 13)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppTheme.secondaryAccent, strokeWidth: 2),
          ),
          error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: Color(0xFF8888AA))),
          ),
        ),
      ),
    );
  }
}

// ─── Legend Dot (Calendar dialog helper) ────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isBorder;

  const _LegendDot(
      {required this.color, required this.label, this.isBorder = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBorder ? Colors.transparent : color,
            border: isBorder ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8888AA), fontSize: 11)),
      ],
    );
  }
}

// ─── Stat Card Widget ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F22),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withAlpha(55), width: 1),
          boxShadow: [BoxShadow(
            color: accent.withAlpha(28),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          )],
        ),
        child: Stack(
          children: [
            Positioned(top: -18, right: -18,
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    accent.withAlpha(50), Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(bottom: 0, left: 16, right: 16,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(colors: [
                    accent.withAlpha(180), accent.withAlpha(0),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: accent.withAlpha(22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: accent.withAlpha(70), width: 1),
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const Spacer(),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(title.toUpperCase(),
                      style: TextStyle(
                          color: accent.withAlpha(160),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}