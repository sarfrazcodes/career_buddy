import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/cartoon_avatars.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentData;

  const EditProfileScreen({super.key, required this.currentData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  String _selectedAvatar = 'neutral';
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.currentData['name'] ?? '');
    _selectedAvatar = widget.currentData['avatar'] ?? 'neutral';

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': _nameController.text.trim(),
          'avatar': _selectedAvatar,
        }, SetOptions(merge: true));

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: 0.4, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: Colors.white),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -60,
            child: _glowCircle(260, AppTheme.primaryAccent, 35),
          ),
          Positioned(
            bottom: 80, left: -80,
            child: _glowCircle(220, AppTheme.secondaryAccent, 25),
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: MediaQuery.of(context).padding.top + 80,
                  bottom: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Choose Your Avatar'),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAvatarOption('male', 'Male'),
                        const SizedBox(width: 40),
                        _buildAvatarOption('female', 'Female'),
                      ],
                    ),
                    const SizedBox(height: 44),
                    _sectionLabel('Personal Info'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 48),
                    GestureDetector(
                      onTap: _isLoading ? null : _saveProfile,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: _isLoading
                              ? LinearGradient(colors: [
                            AppTheme.primaryAccent.withAlpha(120),
                            AppTheme.secondaryAccent.withAlpha(120),
                          ])
                              : const LinearGradient(
                            colors: [
                              AppTheme.primaryAccent,
                              AppTheme.secondaryAccent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: _isLoading
                              ? []
                              : [
                            BoxShadow(
                              color: AppTheme.primaryAccent.withAlpha(100),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color, int alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withAlpha(alpha), Colors.transparent],
      ),
    ),
  );

  Widget _sectionLabel(String text) => Row(
    children: [
      Container(
        width: 3,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3)),
    ],
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.primaryAccent.withAlpha(40)),
        ),
        child: TextField(
          controller: controller,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
            TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            filled: false,
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            prefixIcon:
            Icon(icon, color: AppTheme.primaryAccent, size: 20),
          ),
        ),
      );

  Widget _buildAvatarOption(String type, String label) {
    final isSelected = _selectedAvatar == type;
    final double containerSize = isSelected ? 100.0 : 88.0;
    final double borderWidth = isSelected ? 2.5 : 1.5;

    return GestureDetector(
      onTap: () => setState(() => _selectedAvatar = type),
      child: Column(
        children: [
          // ── Avatar circle (no padding, image fills container) ───
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,   // no overshoot → no overflow
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? LinearGradient(
                colors: [
                  AppTheme.primaryAccent.withAlpha(80),
                  AppTheme.secondaryAccent.withAlpha(60),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isSelected ? null : AppTheme.surfaceDark,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryAccent
                    : Colors.white.withAlpha(20),
                width: borderWidth,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppTheme.primaryAccent.withAlpha(100),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
                  : [],
            ),
            clipBehavior: Clip.antiAlias,   // ensures circular clip
            // No padding, image fills right up to the border
            child: CartoonAvatar(
              type: type,
              size: containerSize,   // the image will be clipped to the circle
            ),
          ),
          const SizedBox(height: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: isSelected ? 15 : 13,
              letterSpacing: 0.3,
            ),
            child: Text(label),
          ),
          if (isSelected) ...[
            const SizedBox(height: 6),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}