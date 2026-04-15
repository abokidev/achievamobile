import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/achieva_button.dart';
import '../../auth/providers/auth_provider.dart';

class ExamDetailsScreen extends StatefulWidget {
  const ExamDetailsScreen({super.key});

  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
  Map<String, dynamic>? _examInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
    _loadExamInfo();
  }

  Future<void> _enableScreenSecurity() async {
    try {
      await ScreenProtector.protectDataLeakageWithColor(Colors.black);
    } catch (_) {}
  }

  Future<void> _loadExamInfo() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final info = await ApiService().getExamInfo(token);
      if (mounted) {
        setState(() {
          _examInfo = info;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.userName ?? 'Candidate';
    final email = 'test@achieva.ng';
    final candidateId = 'ACH-CND-001';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Details'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exam title
                    Center(
                      child: Text(
                        _examInfo?['title'] ?? 'General Assessment',
                        style: GoogleFonts.cinzel(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Candidate info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Candidate Information',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoRow(Icons.person_outline, 'Name', userName),
                          const SizedBox(height: 12),
                          _infoRow(Icons.badge_outlined, 'Candidate ID', candidateId),
                          const SizedBox(height: 12),
                          _infoRow(Icons.email_outlined, 'Email', email),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Exam info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exam Information',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoRow(Icons.timer_outlined, 'Duration',
                              '${_examInfo?['duration_minutes'] ?? 45} minutes'),
                          const SizedBox(height: 12),
                          _infoRow(Icons.quiz_outlined, 'Total Questions',
                              '${_examInfo?['total_questions'] ?? 40} questions'),
                          const SizedBox(height: 12),
                          _infoRow(Icons.category_outlined, 'Question Types',
                              'MCQ & Essay'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Rules card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Important Rules',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ruleItem('Do not leave the app during the exam'),
                          _ruleItem('Screenshots are disabled'),
                          _ruleItem('Copy/paste is disabled'),
                          _ruleItem('Your session is being monitored'),
                          _ruleItem('Submit before the timer runs out'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    AchievaButton(
                      label: 'Proceed to Test Setup',
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/test-setup');
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _ruleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
