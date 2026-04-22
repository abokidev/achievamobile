import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../shared/widgets/achieva_button.dart';
import '../../../shared/widgets/achieva_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class NinVerificationScreen extends StatefulWidget {
  const NinVerificationScreen({super.key});

  @override
  State<NinVerificationScreen> createState() => _NinVerificationScreenState();
}

class _NinVerificationScreenState extends State<NinVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ninController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
  }

  Future<void> _enableScreenSecurity() async {
    try {
      await ScreenProtector.protectDataLeakageWithColor(Colors.black);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ninController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 5, 20),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final dob = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final success = await context.read<OnboardingProvider>().verifyNin(
          _ninController.text.trim(),
          dob,
          token,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamed(context, '/face-verification');
    } else {
      final error = context.read<OnboardingProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? AppStrings.ninNotFound),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        return LoadingOverlay(
          isLoading: provider.isLoading,
          message: AppStrings.verifyingNimc,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.ninStepTitle),
              automaticallyImplyLeading: false,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          AppStrings.ninStepIndicator,
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // NIN Field
                      AchievaTextField(
                        label: AppStrings.ninLabel,
                        controller: _ninController,
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your NIN';
                          }
                          if (value.length != 11) {
                            return AppStrings.ninInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // DOB Field
                      AchievaTextField(
                        label: AppStrings.dobLabel,
                        controller: _dobController,
                        readOnly: true,
                        onTap: _selectDate,
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: AppColors.textSecondary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your date of birth';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Explainer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppStrings.ninExplainer,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      AchievaButton(
                        label: AppStrings.verifyIdentity,
                        onPressed: _handleVerify,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
