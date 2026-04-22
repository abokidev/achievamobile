import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/exam_provider.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, exam, _) {
        Color timerColor = AppColors.textPrimary;
        if (exam.isTimeCritical) {
          timerColor = AppColors.error;
        } else if (exam.isTimeWarning) {
          timerColor = AppColors.warning;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: timerColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: timerColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                color: timerColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              _PulsingText(
                text: exam.formattedTime,
                color: timerColor,
                shouldPulse: exam.isTimeCritical,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PulsingText extends StatefulWidget {
  final String text;
  final Color color;
  final bool shouldPulse;

  const _PulsingText({
    required this.text,
    required this.color,
    required this.shouldPulse,
  });

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_PulsingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.shouldPulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: widget.shouldPulse ? 0.5 + (_controller.value * 0.5) : 1.0,
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
    );
  }
}
