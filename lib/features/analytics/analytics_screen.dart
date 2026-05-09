import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database_providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isWeeklyMode = true;
  String? _selectedGoalId;

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final sessionsAsync    = ref.watch(sessionsProvider);
    final goalsAsync       = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      body: Stack(
        children: [
          // ── Ambient blobs ─────────────────────────────────────────────
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primaryAccent.withAlpha(30),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            top: 420, left: -80,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.secondaryAccent.withAlpha(18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: userProfileAsync.when(
              data: (profileData) {
                final double rawHours =
                    (profileData?['totalHours'] as num?)?.toDouble() ?? 0.0;
                final String formattedHours = rawHours.toStringAsFixed(2);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header ────────────────────────────────────────
                      const Text(
                        'Analytics',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Track your focus and progress',
                        style: TextStyle(
                            color: Color(0xFF8888AA),
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 28),

                      // ── Total Hours Hero Card ─────────────────────────
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
                            Positioned(
                              top: -30, right: -20,
                              child: Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withAlpha(12),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -20, left: 20,
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withAlpha(8),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(28),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(22),
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bar_chart_rounded,
                                                color: Colors.white, size: 12),
                                            SizedBox(width: 5),
                                            Text('TOTAL TRACKED',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.2)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formattedHours,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 52,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -2,
                                              height: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Padding(
                                            padding:
                                            EdgeInsets.only(bottom: 8),
                                            child: Text('hrs',
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 18,
                                                    fontWeight:
                                                    FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('hours of focused work logged',
                                          style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12)),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withAlpha(20),
                                      border: Border.all(
                                          color: Colors.white.withAlpha(40),
                                          width: 1),
                                    ),
                                    child: const Icon(
                                        Icons.trending_up_rounded,
                                        color: Colors.white,
                                        size: 26),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Time Progress Header + Toggle ─────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Time Progress',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFF2A2A4A), width: 1),
                            ),
                            child: Row(
                              children: [
                                _buildToggleBtn('Today', !_isWeeklyMode,
                                        () => setState(() => _isWeeklyMode = false)),
                                _buildToggleBtn('Weekly', _isWeeklyMode,
                                        () => setState(() => _isWeeklyMode = true)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Bar Chart ─────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F22),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: const Color(0xFF2A2A4A), width: 1),
                        ),
                        child: sessionsAsync.when(
                          data: (sessions) {
                            if (sessions.isEmpty) {
                              return const SizedBox(
                                height: 200,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bar_chart_outlined,
                                          color: Color(0xFF2A2A4A), size: 40),
                                      SizedBox(height: 10),
                                      Text('No sessions recorded.',
                                          style: TextStyle(
                                              color: Color(0xFF5A5A7A))),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final now = DateTime.now();
                            List<double> chartData = [];
                            List<String> labels = [];

                            if (_isWeeklyMode) {
                              chartData = List.filled(7, 0.0);
                              for (var doc in sessions) {
                                final data =
                                doc.data() as Map<String, dynamic>;
                                if (data['timestamp'] == null) continue;
                                final DateTime date =
                                (data['timestamp'] as Timestamp).toDate();
                                final double hours =
                                    (data['durationSeconds'] ?? 0) / 3600.0;
                                final int daysAgo = DateTime(now.year,
                                    now.month, now.day)
                                    .difference(DateTime(
                                    date.year, date.month, date.day))
                                    .inDays;
                                if (daysAgo < 7 && daysAgo >= 0) {
                                  chartData[6 - daysAgo] += hours;
                                }
                              }
                              labels = List.generate(
                                  7,
                                      (i) => DateFormat('EEE').format(
                                      now.subtract(Duration(days: 6 - i))));
                            } else {
                              Map<String, double> todayCategories = {};
                              for (var doc in sessions) {
                                final data =
                                doc.data() as Map<String, dynamic>;
                                if (data['timestamp'] == null) continue;
                                final DateTime date =
                                (data['timestamp'] as Timestamp).toDate();
                                if (date.day == now.day &&
                                    date.month == now.month &&
                                    date.year == now.year) {
                                  final double hours =
                                      (data['durationSeconds'] ?? 0) / 3600.0;
                                  final String cat =
                                      data['category'] ?? 'Other';
                                  todayCategories[cat] =
                                      (todayCategories[cat] ?? 0) + hours;
                                }
                              }
                              if (todayCategories.isEmpty) {
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.today_outlined,
                                            color: Color(0xFF2A2A4A),
                                            size: 40),
                                        SizedBox(height: 10),
                                        Text('No tracking done today.',
                                            style: TextStyle(
                                                color: Color(0xFF5A5A7A))),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              labels = todayCategories.keys.toList();
                              chartData = todayCategories.values.toList();
                            }

                            double maxHours = chartData.isNotEmpty
                                ? chartData.reduce((a, b) => a > b ? a : b)
                                : 0;
                            if (maxHours <= 0) maxHours = 1;

                            // ── FittedBox chart (replaces horizontal ScrollView) ──
                            return SizedBox(
                              height: 200,
                              child: FittedBox(
                                alignment: Alignment.bottomCenter,
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  children: List.generate(
                                    chartData.length,
                                        (index) {
                                      final double heightRatio =
                                      (chartData[index] / maxHours)
                                          .clamp(0.0, 1.0);
                                      final bool isMax =
                                          chartData[index] == maxHours &&
                                              maxHours > 0;
                                      final Color barAccent = isMax
                                          ? AppTheme.secondaryAccent
                                          : AppTheme.primaryAccent;

                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: _isWeeklyMode
                                                ? 10.0
                                                : 18.0),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.end,
                                          children: [
                                            if (chartData[index] > 0)
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 6,
                                                    vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: barAccent
                                                      .withAlpha(25),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      6),
                                                ),
                                                child: Text(
                                                  '${chartData[index].toStringAsFixed(2)}h',
                                                  style: TextStyle(
                                                      color: barAccent,
                                                      fontSize: 9,
                                                      fontWeight:
                                                      FontWeight.w700),
                                                ),
                                              )
                                            else
                                              const SizedBox(height: 20),
                                            const SizedBox(height: 6),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 600),
                                              curve: Curves.easeOutCubic,
                                              width: _isWeeklyMode
                                                  ? 28
                                                  : 44,
                                              height: 140 * heightRatio,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    barAccent
                                                        .withAlpha(220),
                                                    barAccent.withAlpha(80),
                                                  ],
                                                  begin:
                                                  Alignment.topCenter,
                                                  end: Alignment
                                                      .bottomCenter,
                                                ),
                                                boxShadow: isMax
                                                    ? [
                                                  BoxShadow(
                                                    color: barAccent
                                                        .withAlpha(80),
                                                    blurRadius: 12,
                                                    offset: const Offset(
                                                        0, 4),
                                                  )
                                                ]
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              labels[index],
                                              style: TextStyle(
                                                color: isMax
                                                    ? Colors.white
                                                    : const Color(
                                                    0xFF5A5A7A),
                                                fontSize: 10,
                                                fontWeight: isMax
                                                    ? FontWeight.w800
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.secondaryAccent),
                            ),
                          ),
                          error: (e, _) => SizedBox(
                              height: 200,
                              child: Center(child: Text('Error: $e'))),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Goal Flow vs Barriers Header ──────────────────
                      Row(
                        children: [
                          Container(
                            width: 3, height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFEF4444),
                                  AppTheme.primaryAccent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Goal Flow vs Barriers',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3),
                              ),
                              Text(
                                'Watch your flow approach the goal limits.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8888AA)),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Goal Flow Graph ───────────────────────────────
                      goalsAsync.when(
                        data: (goals) {
                          if (goals.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 36, horizontal: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F22),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: const Color(0xFF2A2A4A),
                                    width: 1),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.flag_outlined,
                                      color: Color(0xFF2A2A4A), size: 36),
                                  SizedBox(height: 10),
                                  Text('No active goals to track.',
                                      style: TextStyle(
                                          color: Color(0xFF5A5A7A),
                                          fontSize: 14)),
                                ],
                              ),
                            );
                          }

                          final activeGoalDoc = _selectedGoalId != null &&
                              goals.any((g) => g.id == _selectedGoalId)
                              ? goals.firstWhere(
                                  (g) => g.id == _selectedGoalId)
                              : goals.first;

                          final data =
                          activeGoalDoc.data() as Map<String, dynamic>;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F22),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.primaryAccent
                                        .withAlpha(60),
                                    width: 1,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: activeGoalDoc.id,
                                    dropdownColor: const Color(0xFF0F0F22),
                                    isExpanded: true,
                                    icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppTheme.primaryAccent),
                                    items: goals.map((g) {
                                      final gData =
                                      g.data() as Map<String, dynamic>;
                                      return DropdownMenuItem<String>(
                                        value: g.id,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8, height: 8,
                                              margin: const EdgeInsets.only(
                                                  right: 10),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                AppTheme.primaryAccent,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                gData['title'] ?? 'Goal',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                    fontSize: 14),
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(
                                                () => _selectedGoalId = val);
                                      }
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              _FlowToBarrierGraph(
                                title: data['title'] ?? 'Goal',
                                category:
                                data['category'] ?? 'Category',
                                currentHours:
                                (data['currentHours'] as num?)
                                    ?.toDouble() ??
                                    0.0,
                                targetHours:
                                (data['targetHours'] as num?)
                                    ?.toDouble() ??
                                    1.0,
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.secondaryAccent),
                        ),
                        error: (e, _) =>
                            Center(child: Text('Error: $e')),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.secondaryAccent),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
      String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: [
            AppTheme.primaryAccent,
            AppTheme.secondaryAccent,
          ])
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: AppTheme.primaryAccent.withAlpha(60),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF5A5A7A),
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─── Flow to Barrier Graph ────────────────────────────────────────────────────

class _FlowToBarrierGraph extends StatelessWidget {
  final String title;
  final String category;
  final double currentHours;
  final double targetHours;

  const _FlowToBarrierGraph({
    required this.title,
    required this.category,
    required this.currentHours,
    required this.targetHours,
  });

  @override
  Widget build(BuildContext context) {
    final double safeTarget = targetHours > 0 ? targetHours : 1.0;
    final double progress = (currentHours / safeTarget).clamp(0.0, 1.0);
    final int pct = (progress * 100).toInt();

    final Color progressAccent = pct >= 80
        ? const Color(0xFF00E676)
        : pct >= 40
        ? AppTheme.primaryAccent
        : AppTheme.secondaryAccent;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFEF4444).withAlpha(40), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withAlpha(15),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: progressAccent.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: progressAccent.withAlpha(70), width: 1),
                  ),
                  child: Icon(Icons.flag_rounded,
                      color: progressAccent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        category,
                        style: const TextStyle(
                            color: Color(0xFF8888AA), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withAlpha(18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withAlpha(60)),
                      ),
                      child: const Text(
                        'BARRIER',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${targetHours.toInt()}h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                const Color(0xFFEF4444).withAlpha(100),
                Colors.transparent,
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: ClipRRect(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _DangerFlowPainter(progress: progress),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: progressAccent.withAlpha(18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: progressAccent.withAlpha(60), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          color: progressAccent, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '$pct% FLOW',
                        style: TextStyle(
                          color: progressAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${currentHours.toStringAsFixed(2)}h',
                  style: const TextStyle(
                    color: Color(0xFF8888AA),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' / ${targetHours.toStringAsFixed(1)}h',
                  style: const TextStyle(
                    color: Color(0xFF5A5A7A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Danger Flow Painter ──────────────────────────────────────────────────────

class _DangerFlowPainter extends CustomPainter {
  final double progress;

  _DangerFlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paintBarrier = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final barrierPath = Path();
    double startX = 0;
    while (startX < size.width) {
      barrierPath.moveTo(startX, 0);
      barrierPath.lineTo(startX + 10, 0);
      startX += 20;
    }
    canvas.drawShadow(barrierPath, const Color(0xFFEF4444), 10, true);
    canvas.drawPath(barrierPath, paintBarrier);

    if (progress == 0) return;

    final double visualProgress = progress < 0.05 ? 0.05 : progress;
    final double flowWidth  = size.width * visualProgress;
    final double flowHeight = size.height - (size.height * visualProgress);

    final Rect shaderRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paintFlowLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = const LinearGradient(
        colors: [AppTheme.secondaryAccent, AppTheme.primaryAccent],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(shaderRect);

    final paintFlowArea = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryAccent.withAlpha(150),
          AppTheme.primaryAccent.withAlpha(0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(shaderRect);

    final flowPath = Path();
    flowPath.moveTo(0, size.height);
    flowPath.cubicTo(
      flowWidth * 0.4, size.height,
      flowWidth * 0.6, flowHeight,
      flowWidth, flowHeight,
    );

    canvas.drawShadow(flowPath, AppTheme.primaryAccent, 15, true);
    canvas.drawPath(flowPath, paintFlowLine);

    final areaPath = Path.from(flowPath);
    areaPath.lineTo(flowWidth, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();
    canvas.drawPath(areaPath, paintFlowArea);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(flowWidth, flowHeight), 6, dotPaint);

    final pulsePaint = Paint()
      ..color = AppTheme.primaryAccent.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(flowWidth, flowHeight), 12, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}