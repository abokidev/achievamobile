import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/exam_provider.dart';
import 'option_tile.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, exam, _) {
        final question = exam.currentQuestion;
        if (question == null) return const SizedBox.shrink();

        final options = (question['options'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final selectedOption = exam.answers[exam.currentQuestionIndex];
        final isFlagged = exam.flaggedQuestions.contains(exam.currentQuestionIndex);

        return Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject tag and flag
                Row(
                  children: [
                    if (question['subject'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          question['subject'],
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isFlagged ? Icons.bookmark : Icons.bookmark_border,
                        color: isFlagged ? AppColors.warning : AppColors.textMuted,
                      ),
                      onPressed: () => exam.toggleFlag(),
                      tooltip: 'Flag question',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Question text
                SelectionContainer.disabled(
                  child: Text(
                    question['text'] ?? '',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Options
                ...List.generate(options.length, (index) {
                  final option = options[index];
                  final letter = String.fromCharCode(65 + index); // A, B, C, D
                  final isSelected = selectedOption == option['id'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OptionTile(
                      letter: letter,
                      text: option['text'] ?? '',
                      isSelected: isSelected,
                      onTap: () => exam.selectAnswer(option['id']),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
