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
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: AppTheme.backgroundDark,
                title: const Text('New 2026 Goal', style: TextStyle(color: Colors.white)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Goal Title (e.g., KrishiSetu AI / Web Dev)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Target Hours (e.g., 300)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        dropdownColor: AppTheme.surfaceDark,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Link to Category', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                        initialValue: _selectedCategory,
                        items: userCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedCategory = val),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_selectedDeadline == null ? 'Select Deadline' : DateFormat('MMM dd, yyyy').format(_selectedDeadline!), style: const TextStyle(color: AppTheme.primaryAccent)),
                        trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryAccent),
                        onTap: () async {
                          DateTime? date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                          if (date != null) setDialogState(() => _selectedDeadline = date);
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () async {
                      if (_titleController.text.isNotEmpty && _hoursController.text.isNotEmpty && _selectedCategory != null && _selectedDeadline != null) {
                        final user = ref.read(authServiceProvider).currentUser;
                        if (user != null) {
                          await ref.read(databaseServiceProvider).addGoal(user.uid, _titleController.text, _selectedCategory!, double.parse(_hoursController.text), _selectedDeadline!);
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
            }
        );
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Yearly Goals'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(categories),
        backgroundColor: AppTheme.primaryAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) return const Center(child: Text("No goals set yet. Time to aim high!", style: TextStyle(color: AppTheme.textSecondary)));

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final data = goals[index].data() as Map<String, dynamic>;
              final double target = (data['targetHours'] as num).toDouble();
              final double current = (data['currentHours'] as num).toDouble();
              final double progress = (current / target).clamp(0.0, 1.0);
              final deadline = DateTime.parse(data['deadline']);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primaryAccent.withAlpha(50))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(data['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                        Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Category: ${data['category']}  •  Deadline: ${DateFormat('MMM yyyy').format(deadline)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${current.toStringAsFixed(1)} hrs', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        Text('${target.toInt()} hrs', style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black26, color: AppTheme.primaryAccent, minHeight: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}