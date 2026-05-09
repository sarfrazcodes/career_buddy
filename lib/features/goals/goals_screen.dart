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

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _titleController = TextEditingController();
  final _hoursController = TextEditingController();
  String? _selectedCategory;
  DateTime? _selectedDeadline;

  void _showAddGoalDialog(List<String> userCategories) {
    _selectedCategory = userCategories.isNotEmpty ? userCategories.first : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.backgroundDark,
            title: const Text('New 2026 Goal',
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Goal Title (e.g., KrishiSetu AI / Web Dev)',
                        labelStyle: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Target Hours (e.g., 300)',
                        labelStyle: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Link to Category',
                        labelStyle: TextStyle(color: AppTheme.textSecondary)),
                    initialValue: _selectedCategory,
                    items: userCategories
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        _selectedDeadline == null
                            ? 'Select Deadline'
                            : DateFormat('MMM dd, yyyy')
                                .format(_selectedDeadline!),
                        style: const TextStyle(color: AppTheme.primaryAccent)),
                    trailing: const Icon(Icons.calendar_today,
                        color: AppTheme.primaryAccent),
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030));
                      if (date != null)
                        setDialogState(() => _selectedDeadline = date);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isNotEmpty &&
                      _hoursController.text.isNotEmpty &&
                      _selectedCategory != null &&
                      _selectedDeadline != null) {
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user != null) {
                      await ref.read(databaseServiceProvider).addGoal(
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
                child: const Text('Save Goal'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final userProfile = ref.watch(userProfileProvider);

    List<String> categories = ['Deep Work'];
    if (userProfile.value != null && userProfile.value!['categories'] != null) {
      categories = List<String>.from(userProfile.value!['categories']);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Yearly Goals'),
        actions: [
          IconButton(
              icon: const Icon(Icons.rocket_launch_rounded),
              onPressed: () => _showAddGoalDialog(categories)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(categories),
        backgroundColor: AppTheme.primaryAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: goalsAsync.when(
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.flag_outlined,
                        size: 64, color: AppTheme.primaryAccent),
                    SizedBox(height: 24),
                    Text('No goals set yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16)),
                    SizedBox(height: 12),
                    Text(
                        'Add one now and craft a bigger, smarter goal for the next months or year.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF22C55E)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Build bigger habit goals',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text(
                        'Goals work best when they stretch over months or a full year, not just a few days. Track progress, then level up to a longer-term ambition.',
                        style: TextStyle(color: Colors.white70, height: 1.5)),
                  ],
                ),
              ),
              if (activeGoals.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Active Goals',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                ...activeGoals.map((goal) {
                  final data = goal.data() as Map<String, dynamic>;
                  final double target = (data['targetHours'] as num).toDouble();
                  final double current =
                      (data['currentHours'] as num).toDouble();
                  final double progress = (current / target).clamp(0.0, 1.0);
                  final deadline = DateTime.parse(data['deadline']);
                  final percentage = (progress * 100).toStringAsFixed(0);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppTheme.secondaryAccent.withOpacity(0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Text(data['title'] ?? 'Untitled Goal',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryAccent.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text('$percentage%',
                                  style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(data['category'] ?? 'General',
                                  style: const TextStyle(color: Colors.white)),
                              backgroundColor:
                                  AppTheme.primaryAccent.withOpacity(0.16),
                            ),
                            Chip(
                              label: Text(
                                  'Deadline ${DateFormat('MMM yyyy').format(deadline)}',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              backgroundColor: Colors.white10,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${current.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} hrs',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)),
                            Text(
                                '${(target - current).clamp(0.0, target).toStringAsFixed(1)} hrs left',
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white10,
                              color: AppTheme.secondaryAccent,
                              minHeight: 12),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(24)),
                  child: const Text(
                      'No active goals right now. Add a strong 3–12 month plan to stay focused.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, height: 1.5)),
                ),
              ],
              if (completedGoals.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 12),
                  child: Text('Completed Goals',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                ...completedGoals.map((goal) {
                  final data = goal.data() as Map<String, dynamic>;
                  final double target = (data['targetHours'] as num).toDouble();
                  final deadline = DateTime.parse(data['deadline']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.secondaryAccent.withOpacity(0.24)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppTheme.secondaryAccent, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? 'Completed Goal',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(
                                  'Finished ${target.toStringAsFixed(1)} hrs • ${DateFormat('MMM yyyy').format(deadline)}',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                              const SizedBox(height: 10),
                              const Text(
                                  'Nice work! This goal has reached completion. Consider stretching your next milestone across months or an entire year.',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppTheme.textSecondary))),
      ),
    );
  }
}
