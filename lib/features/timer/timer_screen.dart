import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database_providers.dart';
import '../../services/notification_service.dart';
import 'timer_provider.dart';

// ─── TimerScreen (converted to ConsumerStatefulWidget) ───────────────────────
// Was ConsumerWidget — recreated categoryController every build tick. Fixed.

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  final TextEditingController _categoryController = TextEditingController();

  // Track last known running state so we only fire notifications on *change*
  bool _wasRunning = false;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _registerNotificationListeners();

    // Show idle notification when screen first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.showIdleNotification();
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _requestNotificationPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  void _registerNotificationListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationService.onActionReceivedMethod,
    );

    // Listen for notification action button taps (e.g. "Stop & Save")
    NotificationService.actionStream.stream.listen((action) {
      if (!mounted) return;
      final key = action.buttonKeyPressed;
      final timerNotifier = ref.read(timerProvider.notifier);

      if (key == 'STOP_TIMER') {
        timerNotifier.stopAndSave(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Session Saved!',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
            backgroundColor: const Color(0xFF00E676).withAlpha(220),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          ),
        );
        // Show idle notification after stopping
        NotificationService.showIdleNotification();
      } else if (key.startsWith('START_')) {
        final category = key.replaceFirst('START_', '');
        timerNotifier.setCategory(category);
        timerNotifier.start();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final int seconds = totalSeconds % 60;
    final int minutes = (totalSeconds / 60).truncate() % 60;
    final int hours = (totalSeconds / 3600).truncate();

    final String hoursStr = hours.toString().padLeft(2, '0');
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');

    return hours > 0
        ? '$hoursStr:$minutesStr:$secondsStr'
        : '$minutesStr:$secondsStr';
  }

  void _showAddCategoryDialog() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.primaryAccent.withAlpha(60), width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withAlpha(22),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: AppTheme.primaryAccent.withAlpha(70)),
              ),
              child: Icon(Icons.add_rounded,
                  color: AppTheme.primaryAccent, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('New Category',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF07070F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A2A4A), width: 1),
          ),
          child: TextField(
            controller: _categoryController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g., Data Structures, Math',
              hintStyle: const TextStyle(color: Color(0xFF5A5A7A)),
              prefixIcon: const Icon(Icons.category_outlined,
                  color: Color(0xFF5A5A7A), size: 18),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: AppTheme.primaryAccent.withAlpha(180), width: 1.5),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8888AA))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newCat = _categoryController.text.trim();
              if (newCat.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await ref
                      .read(databaseServiceProvider)
                      .addCategory(user.uid, newCat);
                  ref.read(timerProvider.notifier).setCategory(newCat);
                }
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primaryAccent,
                  AppTheme.secondaryAccent,
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('Add',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);
    final userProfile = ref.watch(userProfileProvider);

    List<String> categories = ['Deep Work', 'Reading', 'Coding'];
    if (userProfile.value != null &&
        userProfile.value!['categories'] != null) {
      categories = List<String>.from(userProfile.value!['categories']);
    }

    final bool isRunning = timerState.isRunning;
    final bool hasElapsed = timerState.elapsedSeconds > 0;
    final Color ringAccent =
    isRunning ? AppTheme.secondaryAccent : AppTheme.primaryAccent;

    // ── Fire notifications on state change (not every rebuild) ──────────────
    // Using addPostFrameCallback avoids calling async during build
    if (isRunning != _wasRunning) {
      _wasRunning = isRunning;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (isRunning) {
          await NotificationService.showActiveNotification(
            timerState.category,
            _formatTime(timerState.elapsedSeconds),
          );
        } else {
          await NotificationService.showIdleNotification();
        }
      });
    }

    // ── Update active notification body every 30 seconds while running ───────
    // We use the elapsed seconds mod 30 as a cheap throttle
    if (isRunning && timerState.elapsedSeconds % 30 == 0 && timerState.elapsedSeconds > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !timerState.isRunning) return;
        await NotificationService.showActiveNotification(
          timerState.category,
          _formatTime(timerState.elapsedSeconds),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      body: Stack(
        children: [
          // ── Ambient blobs ─────────────────────────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
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
            bottom: 60,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.secondaryAccent.withAlpha(20),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Focus Timer',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                          ),
                          Text(
                            isRunning
                                ? 'Session in progress...'
                                : 'Ready to focus?',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8888AA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning
                              ? const Color(0xFF00E676)
                              : const Color(0xFF2A2A4A),
                          boxShadow: isRunning
                              ? [
                            BoxShadow(
                                color: const Color(0xFF00E676)
                                    .withAlpha(160),
                                blurRadius: 10)
                          ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRunning ? 'LIVE' : 'IDLE',
                        style: TextStyle(
                          color: isRunning
                              ? const Color(0xFF00E676)
                              : const Color(0xFF5A5A7A),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Category selector ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRunning
                                  ? const Color(0xFF2A2A4A)
                                  : AppTheme.primaryAccent.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: categories.contains(timerState.category)
                                  ? timerState.category
                                  : categories.first,
                              dropdownColor: const Color(0xFF0F0F22),
                              isExpanded: true,
                              onChanged: isRunning
                                  ? null
                                  : (val) {
                                if (val != null) {
                                  timerNotifier.setCategory(val);
                                }
                              },
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isRunning
                                    ? const Color(0xFF2A2A4A)
                                    : AppTheme.primaryAccent,
                              ),
                              items: categories
                                  .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(
                                          right: 10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.primaryAccent,
                                      ),
                                    ),
                                    Text(cat),
                                  ],
                                ),
                              ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: isRunning ? null : _showAddCategoryDialog,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isRunning
                                ? const Color(0xFF0F0F22)
                                : AppTheme.primaryAccent.withAlpha(22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isRunning
                                  ? const Color(0xFF2A2A4A)
                                  : AppTheme.primaryAccent.withAlpha(70),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: isRunning
                                ? const Color(0xFF2A2A4A)
                                : AppTheme.primaryAccent,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Timer ring ────────────────────────────────────────────
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                              ringAccent.withAlpha(isRunning ? 55 : 30),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: isRunning ? null : 0.0,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          color: ringAccent,
                          backgroundColor: Colors.white.withAlpha(8),
                        ),
                      ),
                      Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F0F22).withAlpha(220),
                          border: Border.all(
                              color: Colors.white.withAlpha(8), width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(timerState.elapsedSeconds),
                              style: TextStyle(
                                fontSize:
                                timerState.elapsedSeconds >= 3600 ? 42 : 52,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isRunning
                                  ? timerState.category.toUpperCase()
                                  : 'PAUSED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: ringAccent.withAlpha(180),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Stat chips ────────────────────────────────────────────
                if (hasElapsed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(
                          label: 'Elapsed',
                          value: _formatTime(timerState.elapsedSeconds),
                          icon: Icons.timer_outlined,
                          color: const Color(0xFF00D4FF),
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Category',
                          value: timerState.category,
                          icon: Icons.category_outlined,
                          color: const Color(0xFFBB86FC),
                        ),
                      ],
                    ),
                  ),

                // ── Controls ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasElapsed) ...[
                        _ControlButton(
                          onTap: () async {
                            timerNotifier.stopAndSave(ref);
                            // Cancel the ongoing notification and show idle
                            await AwesomeNotifications()
                                .cancel(10); // id 10 = timer notification
                            await NotificationService.showIdleNotification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 10),
                                      Text('Session Saved!',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ],
                                  ),
                                  backgroundColor:
                                  const Color(0xFF00E676).withAlpha(220),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  margin: const EdgeInsets.fromLTRB(
                                      24, 0, 24, 16),
                                ),
                              );
                            }
                          },
                          size: 64,
                          color: const Color(0xFF0F0F22),
                          borderColor: AppTheme.error.withAlpha(80),
                          child: Icon(Icons.stop_rounded,
                              color: AppTheme.error, size: 28),
                        ),
                        const SizedBox(width: 24),
                      ],
                      _ControlButton(
                        onTap: isRunning
                            ? timerNotifier.pause
                            : timerNotifier.start,
                        size: 80,
                        isGradient: true,
                        child: Icon(
                          isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ],
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

// ─── Control Button ───────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final bool isGradient;
  final Color? color;
  final Color? borderColor;
  final Widget child;

  const _ControlButton({
    required this.onTap,
    required this.size,
    required this.child,
    this.isGradient = false,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isGradient
              ? LinearGradient(
            colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isGradient ? null : color,
          border: Border.all(
            color: borderColor ?? Colors.white.withAlpha(15),
            width: 1.5,
          ),
          boxShadow: isGradient
              ? [
            BoxShadow(
              color: AppTheme.primaryAccent.withAlpha(80),
              blurRadius: 24,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            )
          ]
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50), width: 1),
        boxShadow: [
          BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      color: color.withAlpha(160),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}