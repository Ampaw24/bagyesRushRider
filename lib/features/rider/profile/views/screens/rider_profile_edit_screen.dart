import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_document_completion_providers.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';
import 'package:hugeicons/hugeicons.dart';

class RiderProfileEditScreen extends ConsumerStatefulWidget {
  const RiderProfileEditScreen({super.key});

  @override
  ConsumerState<RiderProfileEditScreen> createState() =>
      _RiderProfileEditScreenState();
}

class _RiderProfileEditScreenState
    extends ConsumerState<RiderProfileEditScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  File? _pickedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populate());
  }

  void _populate() {
    final session = sl<UserSessionManager>();
    final profile = ref.read(riderMeProfileProvider).profile;
    _firstNameCtrl.text = profile?.firstName ?? session.firstName ?? '';
    _lastNameCtrl.text = profile?.lastName ?? session.lastName ?? '';
    _plateCtrl.text = profile?.plateNumber ?? '';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(riderMeProfileProvider);
    final isLoading =
        profileState.actionStatus == RiderMeActionStatus.inProgress ||
            _isUploading;

    ref.listen(riderMeProfileProvider, (_, next) {
      if (next.actionStatus == RiderMeActionStatus.error &&
          next.actionMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar section ──────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (profileState.profile?.photoUrl != null &&
                                  profileState.profile!.photoUrl!.isNotEmpty
                              ? NetworkImage(profileState.profile!.photoUrl!)
                              : null),
                      child: (_pickedImage == null &&
                              (profileState.profile?.photoUrl == null ||
                                  profileState.profile!.photoUrl!.isEmpty))
                          ? Icon(HugeIcons.strokeRoundedUser,
                              size: 48, color: Colors.grey.shade400)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFCA445D)],
                          ),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(HugeIcons.strokeRoundedCamera01,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Form fields ─────────────────────────────────────────────────
            _buildField(
              controller: _firstNameCtrl,
              label: 'First Name',
              hint: 'Enter your first name',
              icon: HugeIcons.strokeRoundedUser,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _lastNameCtrl,
              label: 'Last Name',
              hint: 'Enter your last name',
              icon: HugeIcons.strokeRoundedUser,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _plateCtrl,
              label: 'Number Plate',
              hint: 'e.g. GR-1234-21',
              icon: HugeIcons.strokeRoundedCar01,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 36),
            AppGradientButton(
              label: 'Save Changes',
              isLoading: isLoading,
              onPressed: isLoading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
              prefixIcon:
                  Icon(icon, color: Colors.grey.shade500, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null && mounted) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(riderMeProfileProvider.notifier);

    // 1. Upload selfie if a new one was picked
    if (_pickedImage != null) {
      setState(() => _isUploading = true);
      final uploaded = await notifier.uploadPhoto(_pickedImage!.path);
      setState(() => _isUploading = false);
      if (!uploaded && mounted) return; // error shown via listener
      ref.read(riderDocumentCompletionProvider.notifier).refresh();
    }

    // 2. Update text fields
    final ok = await notifier.updateProfile({
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'plate_number': _plateCtrl.text.trim(),
    });

    if (ok) {
      await sl<UserSessionManager>().updateUser({
        'profile': {
          ...?sl<UserSessionManager>().currentUser?['profile'] as Map?,
          'first_name': _firstNameCtrl.text.trim(),
          'last_name': _lastNameCtrl.text.trim(),
        },
      });
    }

    if (ok && mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }
}
