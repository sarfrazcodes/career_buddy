import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database_providers.dart';
import '../../services/gemini_service.dart';
import '../../widgets/cartoon_avatars.dart';
import 'support_screen.dart';
import 'edit_profile_screen.dart';

final _aiInsightsTriggerProvider = StateProvider<bool>((ref) => false);

final _manualAiInsightsProvider = FutureProvider.autoDispose<String>((ref) async {
  final shouldFetch = ref.watch(_aiInsightsTriggerProvider);
  if (!shouldFetch) return '';
  return ref.watch(productivityAnalysisProvider.future);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final aiInsightsAsync = ref.watch(_manualAiInsightsProvider);
    final hasFetchedAI = ref.watch(_aiInsightsTriggerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          profileAsync.when(
            data: (data) => IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryAccent),
              onPressed: () async {
                if (data != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditProfileScreen(currentData: data)),
                  );
                  // Refresh the profile after returning
                  ref.invalidate(userProfileProvider);
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (data) {
          final String name = data?['name'] ?? 'User';
          final String email = data?['email'] ??
              FirebaseAuth.instance.currentUser?.email ??
              'No email provided';
          final String avatarType = data?['avatar'] ?? 'neutral';

          final int streak = data?['streak'] ?? 0;
          final double totalHours =
              (data?['totalHours'] as num?)?.toDouble() ?? 0.0;
          final double todayHours =
              (data?['todayHours'] as num?)?.toDouble() ?? 0.0;

          final bool hasStreak5 = streak >= 5;
          final bool hasNightOwl =
              aiInsightsAsync.value?.contains('Night Owl') ?? false;
          final bool hasEarlyBird =
              aiInsightsAsync.value?.contains('Early Bird') ?? false;
          final bool hasHeavyHitter = totalHours >= 50;

          final earnedBadges = <Map<String, dynamic>>[
            if (hasStreak5)
              {'label': '5-Day Streak', 'icon': Icons.local_fire_department},
            if (hasNightOwl)
              {'label': 'Night Owl', 'icon': Icons.nights_stay_rounded},
            if (hasEarlyBird)
              {'label': 'Early Bird', 'icon': Icons.wb_sunny_rounded},
            if (hasHeavyHitter)
              {'label': 'Heavy Hitter', 'icon': Icons.fitness_center},
          ];

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
              ref.read(_aiInsightsTriggerProvider.notifier).state = false;
            },
            color: AppTheme.primaryAccent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // ── Avatar — fills the circle with zero gap ───────────
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryAccent.withAlpha(60),
                          AppTheme.secondaryAccent.withAlpha(40),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryAccent.withAlpha(60),
                          blurRadius: 28,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: (avatarType == 'male' || avatarType == 'female')
                          ? CartoonAvatar(
                        type: avatarType,
                        size: 120, // exactly fills the container
                      )
                          : const Icon(Icons.person_rounded,
                          size: 60, color: AppTheme.primaryAccent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryAccent.withAlpha(40)),
                    ),
                    child: Text(
                      "LPU Student • AI & ML",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Stats card ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primaryAccent.withAlpha(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem("Total Hours", "${totalHours.toStringAsFixed(1)}h"),
                        _buildDivider(),
                        _buildStatItem("Today", "${todayHours.toStringAsFixed(1)}h"),
                        _buildDivider(),
                        _buildStatItem("Streak", "$streak Days"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── AI Analysis card ─────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primaryAccent.withAlpha(40)),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.surfaceDark,
                          AppTheme.primaryAccent.withAlpha(12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: AppTheme.secondaryAccent, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'AI PERFORMANCE INSIGHTS',
                                style: TextStyle(
                                  color: AppTheme.secondaryAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            if (!hasFetchedAI)
                              GestureDetector(
                                onTap: () => ref
                                    .read(_aiInsightsTriggerProvider.notifier)
                                    .state = true,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.primaryAccent,
                                        AppTheme.secondaryAccent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryAccent.withAlpha(80),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Analyse',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!hasFetchedAI)
                          Text(
                            'Tap Analyse to get your personalised AI performance report.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          )
                        else
                          aiInsightsAsync.when(
                            data: (insight) => Text(
                              insight.isEmpty
                                  ? 'Track more sessions to unlock AI analysis.'
                                  : insight,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            loading: () => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const LinearProgressIndicator(minHeight: 2),
                                const SizedBox(height: 8),
                                Text(
                                  'Analysing your study patterns…',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            error: (_, __) => const Text(
                              'Track more sessions to unlock AI analysis.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Badges (only earned) ─────────────────────────────
                  if (earnedBadges.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Earned Badges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: earnedBadges.map((badge) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: _buildBadge(
                              badge['label'] as String,
                              badge['icon'] as IconData,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Menu ─────────────────────────────────────────────
                  _buildMenuTile(Icons.help_center_outlined, "Help & Support",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SupportScreen()),
                        );
                      }),
                  _buildMenuTile(Icons.logout_rounded, "Log Out", () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  }, isDestructive: true),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDivider() => Container(
    height: 40,
    width: 1,
    color: Colors.white.withAlpha(20),
  );

  Widget _buildStatItem(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryAccent,
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ],
  );

  Widget _buildBadge(String label, IconData icon) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryAccent.withAlpha(60),
              AppTheme.secondaryAccent.withAlpha(40),
            ],
          ),
          border: Border.all(color: AppTheme.primaryAccent),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryAccent.withAlpha(50), blurRadius: 12)
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryAccent, size: 28),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
    ],
  );

  Widget _buildMenuTile(
      IconData icon,
      String title,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? Colors.redAccent.withAlpha(40)
                : Colors.white.withAlpha(10),
          ),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isDestructive ? Colors.redAccent : AppTheme.primaryAccent,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isDestructive ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.chevron_right,
              color: AppTheme.textSecondary, size: 20),
          onTap: onTap,
        ),
      );
}