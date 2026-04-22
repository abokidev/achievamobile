import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/exam_provider.dart';
import 'option_tile.dart';

class QuestionCard extends StatefulWidget {
  const QuestionCard({super.key});

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  final TextEditingController _essayController = TextEditingController();
  int _lastQuestionIndex = -1;

  @override
  void dispose() {
    _essayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, exam, _) {
        final question = exam.currentQuestion;
        if (question == null) return const SizedBox.shrink();

        final isEssay = question['type'] == 'essay';
        final isFlagged = exam.flaggedQuestions.contains(exam.currentQuestionIndex);

        // Sync essay controller when switching questions
        if (_lastQuestionIndex != exam.currentQuestionIndex) {
          _lastQuestionIndex = exam.currentQuestionIndex;
          if (isEssay) {
            _essayController.text = exam.answers[exam.currentQuestionIndex] ?? '';
          }
        }

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
                // Subject tag, type badge, and flag
                Row(
                  children: [
                    if (question['subject'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEssay
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.border.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isEssay ? 'Essay' : 'MCQ',
                        style: TextStyle(
                          color: isEssay ? AppColors.primary : AppColors.textMuted,
                          fontSize: 11,
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
                // MCQ options or Essay text area
                if (isEssay)
                  _buildEssayField(exam)
                else
                  _buildMcqOptions(exam, question),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMcqOptions(ExamProvider exam, Map<String, dynamic> question) {
    final options = (question['options'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final selectedOption = exam.answers[exam.currentQuestionIndex];

    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final letter = String.fromCharCode(65 + index);
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
    );
  }

  Widget _buildEssayField(ExamProvider exam) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _essayController,
        maxLines: 10,
        minLines: 6,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6),
        decoration: InputDecoration(
          hintText: 'Type your answer here...',
          hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterStyle: const TextStyle(color: AppColors.textMuted),
        ),
        onChanged: (text) => exam.setEssayAnswer(text),
      ),
    );
  }
}
