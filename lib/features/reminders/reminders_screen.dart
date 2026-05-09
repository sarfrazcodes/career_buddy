import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database_providers.dart';
import '../../services/notification_service.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Schedule notifications ────────────────────────────────────────────────
  Future<void> _scheduleNotifications(
      String title,
      DateTime targetDate,
      List<int> alertOffsets,
      ) async {
    for (final hours in alertOffsets) {
      // hours == 0  →  notify at the exact deadline
      final scheduleTime =
      hours == 0 ? targetDate : targetDate.subtract(Duration(hours: hours));

      if (scheduleTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleReminder(
          id: (title.hashCode ^ hours).remainder(100000).abs(),
          title: hours == 0
              ? '⏰ Deadline: $title'
              : '🔔 Reminder: $title',
          scheduledTime: scheduleTime,
        );
      }
    }
  }

  void _showSuccessSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF0D2137)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.primaryAccent.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryAccent.withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Text('✅', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Reminder Saved! 🎯',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    SizedBox(height: 2),
                    Text("We'll ping you before the deadline ⏰",
                        style: TextStyle(
                            color: Color(0xFF8AAFD4), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Add Reminder bottom sheet (cleaner, less messy) ───────────────────────
  void _showAddReminderSheet() {
    final titleController = TextEditingController();
    final customDaysController = TextEditingController();
    DateTime? selectedDate;
    bool alert1Day = false;
    bool alert2Days = false;
    bool alert1Week = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1B2A),
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                              AppTheme.primaryAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_alarm_rounded,
                                color: AppTheme.primaryAccent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New Reminder',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text('Set a task & alerts',
                                  style: TextStyle(
                                      color: Color(0xFF5A7A9A),
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Title field ──────────────────────────────────
                      _sheetLabel('Task Title'),
                      const SizedBox(height: 8),
                      _sheetTextField(
                        controller: titleController,
                        hint: 'e.g. Submit project report',
                        icon: Icons.assignment_outlined,
                      ),

                      const SizedBox(height: 20),

                      // ── Date / time picker ───────────────────────────
                      _sheetLabel('Deadline'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                            builder: _darkPickerTheme,
                          );
                          if (date == null || !mounted) return;
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                            builder: _darkPickerTheme,
                          );
                          if (time == null) return;
                          setSheetState(() {
                            selectedDate = DateTime(date.year, date.month,
                                date.day, time.hour, time.minute);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selectedDate != null
                                ? AppTheme.primaryAccent.withOpacity(0.08)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedDate != null
                                  ? AppTheme.primaryAccent.withOpacity(0.4)
                                  : Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 18,
                                  color: selectedDate != null
                                      ? AppTheme.primaryAccent
                                      : Colors.white.withOpacity(0.3)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedDate == null
                                      ? 'Pick date & time'
                                      : DateFormat('EEE, MMM dd  •  hh:mm a')
                                      .format(selectedDate!),
                                  style: TextStyle(
                                    color: selectedDate != null
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    fontSize: 14,
                                    fontWeight: selectedDate != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: Colors.white.withOpacity(0.2),
                                  size: 18),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Notifications ────────────────────────────────
                      _sheetLabel('Notify Me'),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.07), width: 1),
                        ),
                        child: Column(
                          children: [
                            _alertTile('1 Day Before', alert1Day, (v) {
                              setSheetState(() => alert1Day = v ?? false);
                            }),
                            _thinDivider(),
                            _alertTile('2 Days Before', alert2Days, (v) {
                              setSheetState(() => alert2Days = v ?? false);
                            }),
                            _thinDivider(),
                            _alertTile('1 Week Before', alert1Week, (v) {
                              setSheetState(() => alert1Week = v ?? false);
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Custom days
                      _sheetTextField(
                        controller: customDaysController,
                        hint: 'Custom: days before deadline (e.g. 5)',
                        icon: Icons.tune_rounded,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 28),

                      // ── Save button ──────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty || selectedDate == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content:
                                  Text('⚠️ Please fill in title & date'),
                                  backgroundColor: Color(0xFF2A1A1A),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              // Build alert offsets (hours before deadline).
                              // 0 = at deadline time.
                              final List<int> offsets = [0];
                              if (alert1Day) offsets.add(24);
                              if (alert2Days) offsets.add(48);
                              if (alert1Week) offsets.add(168);
                              final custom =
                              int.tryParse(customDaysController.text);
                              if (custom != null && custom > 0) {
                                offsets.add(custom * 24);
                              }

                              await ref
                                  .read(databaseServiceProvider)
                                  .addReminder(
                                user.uid,
                                title,
                                selectedDate!,
                                offsets,
                              );

                              // Schedule notifications BEFORE closing
                              await _scheduleNotifications(
                                  title, selectedDate!, offsets);
                            }

                            // ✅ Close the sheet first, then show snackbar
                            // ✅ Close the sheet first, then show snackbar
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                            _showSuccessSnackBar();
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppTheme.primaryAccent,
                                AppTheme.secondaryAccent,
                              ]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Save Reminder',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Shared helper widgets ─────────────────────────────────────────────────

  Widget _sheetLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF5A7A9A),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );

  Widget _sheetTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
          prefixIcon:
          Icon(icon, color: const Color(0xFF3A5A7A), size: 18),
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: AppTheme.primaryAccent, width: 1.5),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _alertTile(
      String label,
      bool value,
      void Function(bool?) onChanged,
      ) =>
      CheckboxListTile(
        dense: true,
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryAccent,
        checkColor: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          label,
          style: TextStyle(
            color: value ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );

  Widget _thinDivider() => Divider(
    height: 1,
    color: Colors.white.withOpacity(0.05),
    indent: 16,
    endIndent: 16,
  );

  Widget _darkPickerTheme(BuildContext context, Widget? child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppTheme.primaryAccent,
        onPrimary: Colors.white,
        surface: Color(0xFF0D1B2A),
        onSurface: Colors.white,
      ),
    ),
    child: child!,
  );

  // ── Calendar history ──────────────────────────────────────────────────────
  void _showCalendarHistory(List<dynamic> allCompleted) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: _darkPickerTheme,
    );

    if (picked != null && mounted) {
      final dailyTasks = allCompleted.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final taskDate = DateTime.parse(data['targetDate']);
        return taskDate.year == picked.year &&
            taskDate.month == picked.month &&
            taskDate.day == picked.day;
      }).toList();
      _showDailyTasksDialog(picked, dailyTasks);
    }
  }

  void _showDailyTasksDialog(DateTime date, List<dynamic> tasks) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: AppTheme.primaryAccent.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryAccent.withOpacity(0.15),
                  blurRadius: 40)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: AppTheme.primaryAccent.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history_rounded,
                          color: AppTheme.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('MMM dd, yyyy').format(date),
                            style: const TextStyle(
                                color: AppTheme.primaryAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const Text('Daily History',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: tasks.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text('📭', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 12),
                      Text('No tasks completed on this day.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF5A7A9A), fontSize: 14)),
                    ],
                  ),
                )
                    : ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight:
                      MediaQuery.of(context).size.height * 0.4),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => Divider(
                        color: Colors.white.withOpacity(0.05),
                        height: 1),
                    itemBuilder: (context, index) {
                      final data = tasks[index].data()
                      as Map<String, dynamic>;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryAccent
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: AppTheme.secondaryAccent,
                              size: 18),
                        ),
                        title: Text(data['title'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          DateFormat('hh:mm a').format(
                              DateTime.parse(data['targetDate'])),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Close
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor:
                      AppTheme.primaryAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close',
                        style: TextStyle(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070F17),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reminders',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primaryAccent.withOpacity(0.3), width: 1),
            ),
            child: IconButton(
              onPressed: _showAddReminderSheet,
              icon: const Icon(Icons.add_rounded,
                  color: AppTheme.primaryAccent, size: 22),
              tooltip: 'Add Reminder',
              padding: const EdgeInsets.all(8),
              constraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          final activeReminders = reminders
              .where((doc) =>
          !((doc.data() as Map<String, dynamic>)['isCompleted'] ??
              false))
              .toList();

          final allCompleted = reminders
              .where((doc) =>
          (doc.data() as Map<String, dynamic>)['isCompleted'] ?? false)
              .toList()
            ..sort((a, b) {
              final dA = DateTime.parse(
                  (a.data() as Map<String, dynamic>)['targetDate']);
              final dB = DateTime.parse(
                  (b.data() as Map<String, dynamic>)['targetDate']);
              return dB.compareTo(dA);
            });

          final recentCompleted = allCompleted.take(3).toList();

          if (activeReminders.isEmpty && recentCompleted.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppTheme.primaryAccent.withOpacity(0.15)),
                    ),
                    child: const Center(
                        child: Text('🔔',
                            style: TextStyle(fontSize: 36))),
                  ),
                  const SizedBox(height: 20),
                  const Text('No reminders yet',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tap + to add your first task',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 14)),
                ],
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              16,
              120,
            ),
            children: [
              if (activeReminders.isNotEmpty) ...[
                _sectionHeader('🔔  ACTIVE', null, null, null),
                const SizedBox(height: 12),
                ...activeReminders.asMap().entries.map((e) {
                  final data = e.value.data() as Map<String, dynamic>;
                  return _reminderCard(e.value.id, data['title'],
                      DateTime.parse(data['targetDate']), false,
                      index: e.key);
                }),
                const SizedBox(height: 28),
              ],
              if (recentCompleted.isNotEmpty) ...[
                _sectionHeader(
                  '✅  COMPLETED',
                  'View All',
                  Icons.calendar_month_rounded,
                      () => _showCalendarHistory(allCompleted),
                ),
                const SizedBox(height: 12),
                ...recentCompleted.asMap().entries.map((e) {
                  final data = e.value.data() as Map<String, dynamic>;
                  return _reminderCard(e.value.id, data['title'],
                      DateTime.parse(data['targetDate']), true,
                      index: e.key);
                }),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppTheme.primaryAccent, strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _sectionHeader(
      String title,
      String? actionLabel,
      IconData? actionIcon,
      VoidCallback? onAction,
      ) =>
      Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.5)),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  if (actionIcon != null)
                    Icon(actionIcon,
                        size: 13, color: AppTheme.primaryAccent),
                  const SizedBox(width: 4),
                  Text(actionLabel,
                      style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      );

  Widget _reminderCard(
      String id,
      String title,
      DateTime date,
      bool isCompleted, {
        int index = 0,
      }) {
    final now = DateTime.now();
    final diff = date.difference(now);
    final isOverdue = !isCompleted && diff.isNegative;
    final isUrgent = !isCompleted && !isOverdue && diff.inHours < 24;

    Color accentColor = AppTheme.primaryAccent;
    if (isOverdue) accentColor = const Color(0xFFFF6B6B);
    if (isUrgent) accentColor = const Color(0xFFFFB347);
    if (isCompleted) accentColor = AppTheme.secondaryAccent;

    String urgencyLabel = '';
    if (isOverdue) urgencyLabel = 'OVERDUE';
    if (isUrgent) {
      urgencyLabel =
      diff.inHours < 1 ? 'DUE SOON' : 'IN ${diff.inHours}H';
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? Colors.white.withOpacity(0.06)
              : accentColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isCompleted
            ? []
            : [
          BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        leading: Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: isCompleted,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side:
            BorderSide(color: accentColor.withOpacity(0.5), width: 1.5),
            activeColor: accentColor,
            checkColor: Colors.white,
            onChanged: (val) =>
                ref.read(databaseServiceProvider).toggleReminder(id, val!),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isCompleted ? Colors.white.withOpacity(0.35) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
            if (urgencyLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: accentColor.withOpacity(0.3), width: 0.5),
                ),
                child: Text(urgencyLabel,
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 11, color: Colors.white.withOpacity(0.25)),
              const SizedBox(width: 4),
              Text(
                DateFormat('EEE, MMM dd  •  hh:mm a').format(date),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCompleted
                ? Icons.check_rounded
                : isOverdue
                ? Icons.warning_amber_rounded
                : Icons.notifications_active_rounded,
            color: accentColor,
            size: isCompleted ? 16 : 15,
          ),
        ),
      ),
    );
  }
}