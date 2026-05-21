import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_form_data.dart';
import 'package:delivery_boy/features/rider/kyc/viewmodels/kyc_viewmodel.dart';
import 'package:hugeicons/hugeicons.dart';

class KycStep5ReviewView extends ConsumerWidget {
  const KycStep5ReviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycProvider);
    final isLoading = state.submitStatus == KycSubmitStatus.loading;

    ref.listen<KycState>(kycProvider, (_, next) {
      if (next.submitStatus == KycSubmitStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(kycProvider.notifier).clearError();
      }
      if (next.submitStatus == KycSubmitStatus.success) {
        _showSuccessDialog(context);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(HugeIcons.strokeRoundedClipboard,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Review Your Information',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Please review your details before submitting',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Identity section
          _ReviewCard(
            title: 'Identity',
            icon: HugeIcons.strokeRoundedIdentityCard,
            onEdit: () => ref.read(kycProvider.notifier).goToStep(0),
            children: [
              _ReviewRow(
                  label: 'National ID', value: state.identity.nationalId),
              _ReviewRow(
                  label: 'Date of Birth',
                  value: state.identity.dateOfBirth != null
                      ? DateFormat('dd MMM yyyy')
                          .format(state.identity.dateOfBirth!)
                      : '—'),
              _ReviewRow(label: 'Address', value: state.identity.address),
              _DocStatusRow(
                label: 'ID Front',
                uploaded: state.uploadStates[KycDocKey.idFront]?.isDone ??
                    false,
              ),
              _DocStatusRow(
                label: 'ID Back',
                uploaded: state.uploadStates[KycDocKey.idBack]?.isDone ??
                    false,
              ),
              _DocStatusRow(
                label: 'Selfie',
                uploaded: state.uploadStates[KycDocKey.selfie]?.isDone ??
                    false,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Licence section
          _ReviewCard(
            title: 'Driver Licence',
            icon: HugeIcons.strokeRoundedCar01,
            onEdit: () => ref.read(kycProvider.notifier).goToStep(1),
            children: [
              _ReviewRow(
                  label: 'Licence No.',
                  value: state.license.licenseNumber),
              _ReviewRow(
                  label: 'Expiry Date',
                  value: state.license.expiryDate != null
                      ? DateFormat('dd MMM yyyy')
                          .format(state.license.expiryDate!)
                      : '—'),
              _DocStatusRow(
                label: 'Licence Photo',
                uploaded:
                    state.uploadStates[KycDocKey.licensePhoto]?.isDone ??
                        false,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Vehicle section
          _ReviewCard(
            title: 'Vehicle',
            icon: HugeIcons.strokeRoundedMotorbike01,
            onEdit: () => ref.read(kycProvider.notifier).goToStep(2),
            children: [
              _ReviewRow(
                  label: 'Type', value: state.vehicle.vehicleType),
              _ReviewRow(
                  label: 'Brand & Model',
                  value:
                      '${state.vehicle.brand} ${state.vehicle.model}'),
              _ReviewRow(
                  label: 'Plate', value: state.vehicle.plateNumber),
              _ReviewRow(
                  label: 'Color', value: state.vehicle.color),
              _DocStatusRow(
                label: 'Registration',
                uploaded:
                    state.uploadStates[KycDocKey.vehicleRegDoc]?.isDone ??
                        false,
              ),
              _DocStatusRow(
                label: 'Insurance',
                uploaded:
                    state.uploadStates[KycDocKey.vehicleInsurance]?.isDone ??
                        false,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Declaration note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(HugeIcons.strokeRoundedInformationCircle,
                    size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'By submitting, you confirm that all information provided is accurate and your documents are genuine.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => ref.read(kycProvider.notifier).goToStep(3),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppGradientButton(
                  label: 'Submit for Verification',
                  isLoading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () =>
                          ref.read(kycProvider.notifier).submit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(HugeIcons.strokeRoundedCheckmarkCircle01,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Submitted!',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your documents are under review. We\'ll notify you once verified.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.dashboard);
              },
              child: const Text(
                'Back to Dashboard',
                style: TextStyle(
                    fontFamily: 'Roboto', fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review card components ─────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<Widget> children;

  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocStatusRow extends StatelessWidget {
  final String label;
  final bool uploaded;

  const _DocStatusRow({required this.label, required this.uploaded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Icon(
            uploaded
                ? HugeIcons.strokeRoundedCheckmarkCircle01
                : HugeIcons.strokeRoundedCircle,
            size: 16,
            color: uploaded ? AppColors.success : Colors.orange.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            uploaded ? 'Uploaded' : 'Pending',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  uploaded ? AppColors.success : Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
