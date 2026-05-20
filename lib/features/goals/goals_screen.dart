import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_providers.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _hoursController = TextEditingController();
  String? _selectedCategory;
  DateTime? _selectedDeadline;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 18),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
    );
  }

  void _showAddGoalDialog(List<String> userCategories) {
    _selectedCategory = userCategories.isNotEmpty ? userCategories.first : null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1B2E),
                    const Color(0xFF16213E),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.18),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.rocket_launch_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New Goal',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3)),
                              Text('Set a powerful long-term target',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded,
                              color: Colors.white.withOpacity(0.4), size: 20),
                        ),
                      ],
                    ),
                  ),

                  // Dialog Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _fieldDecoration(
                                'Goal Title (e.g., KrishiSetu AI / Web Dev)',
                                Icons.flag_rounded),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _hoursController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _fieldDecoration(
                                'Target Hours (e.g., 300)', Icons.timer_rounded),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            dropdownColor: const Color(0xFF1E2235),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _fieldDecoration(
                                'Link to Category', Icons.category_rounded),
                            value: _selectedCategory,
                            items: userCategories
                                .map((cat) => DropdownMenuItem(
                                value: cat, child: Text(cat)))
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => _selectedCategory = val),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () async {
                              DateTime? date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                                builder: (context, child) => Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF6366F1),
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (date != null)
                                setDialogState(() => _selectedDeadline = date);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.10)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded,
                                      color: Color(0xFF6366F1), size: 18),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDeadline == null
                                        ? 'Select Deadline'
                                        : DateFormat('MMM dd, yyyy')
                                        .format(_selectedDeadline!),
                                    style: TextStyle(
                                      color: _selectedDeadline == null
                                          ? Colors.white.withOpacity(0.45)
                                          : Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_selectedDeadline != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Set',
                                          style: TextStyle(
                                              color: Color(0xFF6366F1),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dialog Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                            ),
                            child: Text('Cancel',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              if (_titleController.text.isNotEmpty &&
                                  _hoursController.text.isNotEmpty &&
                                  _selectedCategory != null &&
                                  _selectedDeadline != null) {
                                final user =
                                    ref.read(authServiceProvider).currentUser;
                                if (user != null) {
                                  await ref
                                      .read(databaseServiceProvider)
                                      .addGoal(
                                      user.uid,
                                      _titleController.text,
                                      _selectedCategory!,
                                      double.parse(_hoursController.text),
                                      _selectedDeadline!);
                                }
                                if (mounted) Navigator.pop(context);
                                _titleController.clear();
                                _hoursController.clear();
                                _selectedDeadline = null;
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rocket_launch_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text('Save Goal',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final userProfile = ref.watch(userProfileProvider);

    List<String> categories = [];
    if (userProfile.value != null && userProfile.value!['categories'] != null) {
      categories = List<String>.from(userProfile.value!['categories']);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E1A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Yearly Goals',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showAddGoalDialog(categories),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('New',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22C55E).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main body
          goalsAsync.when(
            data: (goals) {
              final activeGoals = goals.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final target = (data['targetHours'] as num).toDouble();
                final current = (data['currentHours'] as num).toDouble();
                return current < target;
              }).toList();
              final completedGoals = goals.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final target = (data['targetHours'] as num).toDouble();
                final current = (data['currentHours'] as num).toDouble();
                return current >= target;
              }).toList();

              if (goals.isEmpty) {
                return _buildEmptyState();
              }

              return FadeTransition(
                opacity: _fadeController,
                child: ListView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                    left: 20,
                    right: 20,
                    bottom: 100,
                  ),
                  children: [
                    _buildMotivationBanner(),
                    const SizedBox(height: 28),

                    if (activeGoals.isNotEmpty) ...[
                      _buildSectionHeader('Active Goals', activeGoals.length,
                          const Color(0xFF6366F1)),
                      const SizedBox(height: 14),
                      ...activeGoals.asMap().entries.map((entry) {
                        return _buildActiveGoalCard(
                            entry.value, entry.key);
                      }),
                    ] else ...[
                      _buildEmptyGoalCard(),
                    ],

                    if (completedGoals.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _buildSectionHeader('Completed', completedGoals.length,
                          const Color(0xFF22C55E)),
                      const SizedBox(height: 14),
                      ...completedGoals.map(_buildCompletedGoalCard),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
                strokeWidth: 2,
              ),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: TextStyle(color: Colors.white.withOpacity(0.4))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('💡 Pro Tip',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              const Text('Build bigger habit goals',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(
                'Goals work best when they stretch over months or a full year. Track progress, then level up to a longer-term ambition.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    height: 1.5,
                    fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildActiveGoalCard(dynamic goal, int index) {
    final data = goal.data() as Map<String, dynamic>;
    final double target = (data['targetHours'] as num).toDouble();
    final double current = (data['currentHours'] as num).toDouble();
    final double progress = (current / target).clamp(0.0, 1.0);
    final deadline = DateTime.parse(data['deadline']);
    final percentage = (progress * 100).toStringAsFixed(0);
    final daysLeft = deadline.difference(DateTime.now()).inDays;

    final List<List<Color>> gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFF0EA5E9), const Color(0xFF6366F1)],
      [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
    ];
    final gradient = gradients[index % gradients.length];

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + index * 80),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF13141F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color indicator dot
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 5, right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: gradient),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    data['title'] ?? 'Untitled Goal',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3),
                  ),
                ),
                const SizedBox(width: 10),
                // Percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradient[0].withOpacity(0.25),
                        gradient[1].withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: gradient[0].withOpacity(0.3), width: 1),
                  ),
                  child: Text('$percentage%',
                      style: TextStyle(
                          color: gradient[0],
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Tags row — uses Wrap to prevent horizontal overflow
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildTag(data['category'] ?? 'General',
                    Icons.folder_rounded, gradient[0]),
                _buildTag(
                    daysLeft > 0 ? '$daysLeft days left' : 'Overdue',
                    Icons.schedule_rounded,
                    daysLeft > 30
                        ? const Color(0xFF22C55E)
                        : daysLeft > 7
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444)),
                _buildTag(DateFormat('MMM yy').format(deadline),
                    Icons.calendar_today_rounded,
                    Colors.white.withOpacity(0.35)),
              ],
            ),

            const SizedBox(height: 18),

            // Progress section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${current.toStringAsFixed(1)} hrs done',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 12),
                          ),
                          Text(
                            '${(target - current).clamp(0.0, target).toStringAsFixed(1)} hrs left',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient:
                                LinearGradient(colors: gradient),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradient[0].withOpacity(0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Target info
            Row(
              children: [
                Icon(Icons.my_location_rounded,
                    size: 13, color: Colors.white.withOpacity(0.3)),
                const SizedBox(width: 5),
                Text(
                  'Target: ${target.toStringAsFixed(0)} hrs',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color.withOpacity(0.8)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCompletedGoalCard(dynamic goal) {
    final data = goal.data() as Map<String, dynamic>;
    final double target = (data['targetHours'] as num).toDouble();
    final deadline = DateTime.parse(data['deadline']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF13141F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF22C55E).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF22C55E).withOpacity(0.3)),
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF22C55E), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Completed Goal',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2),
                ),
                const SizedBox(height: 4),
                Text(
                  '${target.toStringAsFixed(0)} hrs · ${DateFormat('MMM yyyy').format(deadline)}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stretch your next milestone across months or an entire year.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      height: 1.4),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('100%',
                style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13141F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Text(
        'No active goals right now. Add a strong 3–12 month plan to stay focused.',
        style: TextStyle(
            color: Colors.white.withOpacity(0.4), height: 1.5, fontSize: 13),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.flag_rounded,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('No goals yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4)),
            const SizedBox(height: 10),
            Text(
              'Add a goal and craft a bigger, smarter target for the next months or year.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  height: 1.6,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}