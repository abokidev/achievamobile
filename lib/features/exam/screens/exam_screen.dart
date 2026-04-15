import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/proctor_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../widgets/question_card.dart';
import '../widgets/timer_widget.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
  late ProctorService _proctorService;
  bool _showLeftWarning = false;

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
    WidgetsBinding.instance.addObserver(this);
    _proctorService = ProctorService(apiService: ApiService());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExam();
    });
  }

  Future<void> _enableScreenSecurity() async {
    try {
      await ScreenProtector.protectDataLeakageWithColor(Colors.black);
    } catch (_) {}
  }

  Future<void> _loadExam() async {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      await context.read<ExamProvider>().loadExam(token);
      _proctorService.startMonitoring();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final examProvider = context.read<ExamProvider>();
    final token = context.read<AuthProvider>().token;

    if (state == AppLifecycleState.paused) {
      examProvider.addIncident('app_backgrounded');
      if (token != null) {
        _proctorService.logEvent('app_backgrounded');
      }
    } else if (state == AppLifecycleState.resumed) {
      if (token != null) {
        _proctorService.logEvent('focus_regained');
        _proctorService.captureAndSend('app_resume');
      }
      if (examProvider.incidents.isNotEmpty) {
        setState(() => _showLeftWarning = true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showLeftWarning = false);
        });
      }
    }
  }

  void _showQuestionGrid() {
    final examProvider = context.read<ExamProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.questionGrid,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(AppColors.primary, 'Answered'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.surface2, 'Unanswered'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.warning, 'Flagged'),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8, mainAxisSpacing: 8, crossAxisSpacing: 8,
                  ),
                  itemCount: examProvider.totalQuestions,
                  itemBuilder: (context, index) {
                    final isAnswered = examProvider.answers.containsKey(index);
                    final isFlagged = examProvider.flaggedQuestions.contains(index);
                    final isCurrent = index == examProvider.currentQuestionIndex;

                    return GestureDetector(
                      onTap: () {
                        examProvider.goToQuestion(index);
                        Navigator.pop(context);
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isAnswered ? AppColors.primary : AppColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                              border: isCurrent
                                  ? Border.all(color: AppColors.textPrimary, width: 2)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isAnswered ? AppColors.textPrimary : AppColors.textSecondary,
                                fontSize: 12, fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isFlagged)
                            Positioned(
                              top: 2, right: 2,
                              child: Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.warning, shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  void _showSubmitConfirmation() {
    final examProvider = context.read<ExamProvider>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(AppStrings.submitConfirmTitle, style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            AppStrings.submitConfirmMessage(
              examProvider.answeredCount, examProvider.totalQuestions, examProvider.formattedTime,
            ),
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
                _submitExam();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(AppStrings.submitExam),
            ),
          ],
        );
      },
    );
  }

  void _showFabMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted, borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Submit Exam', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${context.read<ExamProvider>().answeredCount} of ${context.read<ExamProvider>().totalQuestions} answered',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showSubmitConfirmation();
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: AppColors.accent),
                  ),
                  title: const Text('Reload Page', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Refresh current question', style: TextStyle(color: AppColors.textMuted)),
                  onTap: () {
                    Navigator.pop(context);
                    final exam = context.read<ExamProvider>();
                    exam.goToQuestion(exam.currentQuestionIndex);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitExam() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    _proctorService.stopMonitoring();
    final result = await context.read<ExamProvider>().submitExam(token);

    if (!mounted) return;

    if (result != null) {
      Navigator.pushReplacementNamed(context, '/submission', arguments: result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit exam. Please try again.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _proctorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, exam, _) {
        return LoadingOverlay(
          isLoading: exam.isLoading,
          message: 'Loading exam...',
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(exam.examTitle, style: const TextStyle(fontSize: 16)),
              leading: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Center(child: TimerWidget()),
              ),
              leadingWidth: 140,
              actions: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      'Q ${exam.currentQuestionIndex + 1} / ${exam.totalQuestions}',
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        child: const QuestionCard(),
                      ),
                    ),
                    // Bottom navigation bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            // Previous
                            TextButton.icon(
                              onPressed: exam.isOnFirstQuestion ? null : () => exam.previousQuestion(),
                              icon: const Icon(Icons.chevron_left, size: 20),
                              label: const Text(AppStrings.previousQuestion),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                disabledForegroundColor: AppColors.textMuted.withOpacity(0.3),
                              ),
                            ),
                            const Spacer(),
                            // Question grid
                            IconButton(
                              onPressed: _showQuestionGrid,
                              icon: const Icon(Icons.grid_view_rounded, color: AppColors.textSecondary),
                              tooltip: AppStrings.questionGrid,
                            ),
                            const Spacer(),
                            // Next or Submit (on last question)
                            if (exam.isOnLastQuestion)
                              ElevatedButton.icon(
                                onPressed: _showSubmitConfirmation,
                                icon: const Icon(Icons.send_rounded, size: 18),
                                label: const Text('Submit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => exam.nextQuestion(),
                                icon: const Text(AppStrings.nextQuestion),
                                label: const Icon(Icons.chevron_right, size: 20),
                                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Left exam warning overlay
                if (_showLeftWarning)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _showLeftWarning = false),
                      child: Container(
                        color: Colors.black.withOpacity(0.8),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 60),
                                SizedBox(height: 16),
                                Text(
                                  AppStrings.examLeftWarning,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // FAB with menu (submit + reload)
            floatingActionButton: FloatingActionButton(
              onPressed: _showFabMenu,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            ),
          ),
        );
      },
    );
  }
}
