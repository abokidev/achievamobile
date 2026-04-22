import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/achieva_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exam_provider.dart';

class AssessmentHubScreen extends StatefulWidget {
  const AssessmentHubScreen({super.key});

  @override
  State<AssessmentHubScreen> createState() => _AssessmentHubScreenState();
}

class _AssessmentHubScreenState extends State<AssessmentHubScreen> {
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

  void _openAssessment(String assessmentId) {
    final exam = context.read<ExamProvider>();
    exam.switchToAssessment(assessmentId);
    Navigator.pushReplacementNamed(context, '/exam');
  }

  void _showSubmitAllConfirmation() {
    final exam = context.read<ExamProvider>();
    final unsubmitted = exam.availableAssessments.where((a) {
      final state = exam.getAssessmentState(a['id'] as String);
      return state == null || !state.isSubmitted;
    }).length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Submit All Assessments?',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            '$unsubmitted assessment${unsubmitted == 1 ? '' : 's'} will be submitted. This action cannot be undone.',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitAll();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Submit All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAll() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final results = await context.read<ExamProvider>().submitAllAssessments(token);

    if (!mounted) return;

    if (results.isNotEmpty && context.read<ExamProvider>().allAssessmentsSubmitted) {
      Navigator.pushReplacementNamed(context, '/submission', arguments: {
        'duration_taken_seconds': results.fold<int>(0, (sum, r) => sum + ((r['duration_taken_seconds'] ?? 0) as int)),
        'answered_count': results.fold<int>(0, (sum, r) => sum + ((r['answered_count'] ?? 0) as int)),
        'total_questions': results.fold<int>(0, (sum, r) => sum + ((r['total_questions'] ?? 0) as int)),
        'reference': results.map((r) => r['reference']).join(', '),
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, exam, _) {
        final allSubmitted = exam.allAssessmentsSubmitted;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Assessments'),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Your Assessments',
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${exam.submittedCount} of ${exam.availableAssessments.length} submitted',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: exam.availableAssessments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final assessment = exam.availableAssessments[index];
                        final id = assessment['id'] as String;
                        final title = assessment['title'] as String;
                        final type = assessment['type'] as String;
                        final duration = assessment['duration_minutes'] as int;
                        final state = exam.getAssessmentState(id);
                        final isSubmitted = state?.isSubmitted ?? false;
                        final answered = state?.answers.length ?? 0;
                        final total = state?.questions.length ?? 0;
                        final hasStarted = state != null && state.questions.isNotEmpty;

                        return GestureDetector(
                          onTap: isSubmitted ? null : () => _openAssessment(id),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSubmitted
                                    ? AppColors.success.withOpacity(0.4)
                                    : exam.selectedAssessmentId == id
                                        ? AppColors.primary.withOpacity(0.5)
                                        : AppColors.border,
                                width: isSubmitted || exam.selectedAssessmentId == id ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _statusBadge(isSubmitted, hasStarted),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _infoChip(Icons.category_outlined,
                                        type == 'essay' ? 'Essay' : 'MCQ'),
                                    const SizedBox(width: 12),
                                    _infoChip(Icons.timer_outlined, '$duration min'),
                                    if (hasStarted) ...[
                                      const SizedBox(width: 12),
                                      _infoChip(Icons.quiz_outlined, '$answered / $total'),
                                    ],
                                  ],
                                ),
                                if (!isSubmitted) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _openAssessment(id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hasStarted
                                            ? AppColors.surface2
                                            : AppColors.primary,
                                        foregroundColor: AppColors.textPrimary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(hasStarted ? 'Continue' : 'Start'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (allSubmitted)
                    AchievaButton(
                      label: 'Exit',
                      backgroundColor: AppColors.primary,
                      onPressed: () async {
                        context.read<ExamProvider>().reset();
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false,
                        );
                      },
                    )
                  else
                    AchievaButton(
                      label: 'Submit All Assessments',
                      backgroundColor: AppColors.primary,
                      onPressed: _showSubmitAllConfirmation,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(bool isSubmitted, bool hasStarted) {
    if (isSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 14),
            SizedBox(width: 4),
            Text('Submitted',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (hasStarted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('In Progress',
            style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('Not Started',
          style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}
