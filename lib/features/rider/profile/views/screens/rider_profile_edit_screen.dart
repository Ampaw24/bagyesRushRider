import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_profile_providers.dart';

class RiderProfileEditScreen extends ConsumerStatefulWidget {
  const RiderProfileEditScreen({super.key});

  @override
  ConsumerState<RiderProfileEditScreen> createState() =>
      _RiderProfileEditScreenState();
}

class _RiderProfileEditScreenState
    extends ConsumerState<RiderProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  File? _pickedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populate());
  }

  void _populate() {
    final user = ref.read(riderProfileProvider).user;
    if (user == null) return;
    _nameCtrl.text = user.name ?? '';
    _emailCtrl.text = user.email ?? '';
    _plateCtrl.text = user.numberPlate ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(riderProfileProvider);
    final isLoading =
        profileState.status == ProfileStatus.loading || _isUploading;

    ref.listen(riderProfileProvider, (_, next) {
      if (next.status == ProfileStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
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
                          : (profileState.user?.selfie != null &&
                                  profileState.user!.selfie!.isNotEmpty
                              ? NetworkImage(profileState.user!.selfie!)
                              : null),
                      child: (_pickedImage == null &&
                              (profileState.user?.selfie == null ||
                                  profileState.user!.selfie!.isEmpty))
                          ? Icon(Icons.person,
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
                        child: const Icon(Icons.camera_alt,
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
              controller: _nameCtrl,
              label: 'Full Name',
              hint: 'Enter your name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _emailCtrl,
              label: 'Email Address',
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _plateCtrl,
              label: 'Number Plate',
              hint: 'e.g. GR-1234-21',
              icon: Icons.directions_car_outlined,
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
    final notifier = ref.read(riderProfileProvider.notifier);
    final userId =
        ref.read(riderProfileProvider).user?.id ?? '';

    // 1. Upload selfie if a new one was picked
    if (_pickedImage != null) {
      setState(() => _isUploading = true);
      final filename = _pickedImage!.path.split('/').last;
      final formData = FormData.fromMap({
        'id': userId,
        'selfie': await MultipartFile.fromFile(
          _pickedImage!.path,
          filename: filename,
        ),
      });
      final uploaded = await notifier.uploadDoc(formData);
      setState(() => _isUploading = false);
      if (!uploaded && mounted) return; // error shown via listener
    }

    // 2. Update text fields
    final ok = await notifier.updateCourier({
      'id': userId,
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'numberPlate': _plateCtrl.text.trim(),
    });

    if (ok && mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}
