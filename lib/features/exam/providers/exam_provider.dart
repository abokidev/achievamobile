import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class ExamProvider extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  String? _error;

  // Assessment selection
  String? _selectedAssessmentId;

  // Exam info
  String _examTitle = '';
  int _durationMinutes = 45;
  int _totalQuestions = 0;

  // Questions
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  // Answers: for MCQ stores option id, for essay stores text
  Map<int, String> _answers = {};
  Set<int> _flaggedQuestions = {};

  // Timer
  int _remainingSeconds = 0;
  Timer? _timer;

  // Proctoring
  List<Map<String, dynamic>> _incidents = [];

  ExamProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedAssessmentId => _selectedAssessmentId;
  String get examTitle => _examTitle;
  int get durationMinutes => _durationMinutes;
  int get totalQuestions => _totalQuestions;
  List<Map<String, dynamic>> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, String> get answers => _answers;
  Set<int> get flaggedQuestions => _flaggedQuestions;
  int get remainingSeconds => _remainingSeconds;
  int get answeredCount => _answers.length;
  List<Map<String, dynamic>> get incidents => _incidents;
  bool get isOnLastQuestion => _currentQuestionIndex == _questions.length - 1;
  bool get isOnFirstQuestion => _currentQuestionIndex == 0;

  Map<String, dynamic>? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentQuestionIndex] : null;

  void selectAssessment(String assessmentId) {
    _selectedAssessmentId = assessmentId;
    notifyListeners();
  }

  bool get isCurrentQuestionEssay {
    final q = currentQuestion;
    if (q == null) return false;
    return q['type'] == 'essay';
  }

  String get formattedTime {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  bool get isTimeCritical => _remainingSeconds < 300;
  bool get isTimeWarning => _remainingSeconds < 600;

  Future<void> loadExam(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final infoFuture = _apiService.getExamInfo(token, assessmentId: _selectedAssessmentId);
      final questionsFuture = _apiService.getExamQuestions(token, assessmentId: _selectedAssessmentId);

      final results = await Future.wait([infoFuture, questionsFuture]);

      final info = results[0] as Map<String, dynamic>;
      _examTitle = info['title'] ?? 'General Assessment';
      _durationMinutes = info['duration_minutes'] ?? 45;
      _totalQuestions = info['total_questions'] ?? 40;

      final questionsData = results[1] as List<dynamic>;
      _questions = questionsData.cast<Map<String, dynamic>>();
      _totalQuestions = _questions.length;

      _remainingSeconds = _durationMinutes * 60;
      _startTimer();

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load exam. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        notifyListeners();
      }
    });
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void selectAnswer(String optionId) {
    _answers[_currentQuestionIndex] = optionId;
    notifyListeners();
  }

  void setEssayAnswer(String text) {
    if (text.trim().isEmpty) {
      _answers.remove(_currentQuestionIndex);
    } else {
      _answers[_currentQuestionIndex] = text;
    }
    notifyListeners();
  }

  void toggleFlag() {
    if (_flaggedQuestions.contains(_currentQuestionIndex)) {
      _flaggedQuestions.remove(_currentQuestionIndex);
    } else {
      _flaggedQuestions.add(_currentQuestionIndex);
    }
    notifyListeners();
  }

  void addIncident(String type) {
    _incidents.add({
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  Future<Map<String, dynamic>?> submitExam(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _timer?.cancel();

      final answersList = _answers.entries.map((entry) {
        final question = _questions[entry.key];
        final isEssay = question['type'] == 'essay';
        return {
          'questionId': question['id'],
          if (isEssay) 'essayAnswer': entry.value,
          if (!isEssay) 'selectedOption': entry.value,
        };
      }).toList();

      final durationTaken = (_durationMinutes * 60) - _remainingSeconds;

      final response = await _apiService.submitExam(
        answersList,
        durationTaken,
        token,
      );

      _isLoading = false;
      notifyListeners();
      return {
        ...response,
        'duration_taken_seconds': durationTaken,
        'answered_count': _answers.length,
        'total_questions': _totalQuestions,
      };
    } catch (e) {
      _error = 'Failed to submit exam. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _timer?.cancel();
    _questions = [];
    _currentQuestionIndex = 0;
    _answers = {};
    _flaggedQuestions = {};
    _remainingSeconds = 0;
    _incidents = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
