import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class AssessmentState {
  List<Map<String, dynamic>> questions;
  int currentQuestionIndex;
  Map<int, String> answers;
  Set<int> flaggedQuestions;
  int remainingSeconds;
  int durationMinutes;
  String title;
  bool isSubmitted;
  Map<String, dynamic>? submissionResult;

  AssessmentState({
    required this.questions,
    this.currentQuestionIndex = 0,
    Map<int, String>? answers,
    Set<int>? flaggedQuestions,
    this.remainingSeconds = 0,
    this.durationMinutes = 45,
    this.title = '',
    this.isSubmitted = false,
    this.submissionResult,
  })  : answers = answers ?? {},
        flaggedQuestions = flaggedQuestions ?? {};
}

class ExamProvider extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  String? _error;

  // All available assessments
  List<Map<String, dynamic>> _availableAssessments = [];
  // Per-assessment saved state
  final Map<String, AssessmentState> _assessmentStates = {};
  // Currently active assessment
  String? _selectedAssessmentId;

  // Active exam state (points into _assessmentStates for the selected assessment)
  String _examTitle = '';
  int _durationMinutes = 45;
  int _totalQuestions = 0;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  Map<int, String> _answers = {};
  Set<int> _flaggedQuestions = {};
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isSubmitted = false;

  List<Map<String, dynamic>> _incidents = [];

  ExamProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedAssessmentId => _selectedAssessmentId;
  List<Map<String, dynamic>> get availableAssessments => _availableAssessments;
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
  bool get isSubmitted => _isSubmitted;

  Map<String, dynamic>? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentQuestionIndex] : null;

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

  bool get allAssessmentsSubmitted {
    if (_availableAssessments.isEmpty) return false;
    return _availableAssessments.every((a) {
      final state = _assessmentStates[a['id']];
      return state?.isSubmitted ?? false;
    });
  }

  int get submittedCount {
    return _assessmentStates.values.where((s) => s.isSubmitted).length;
  }

  AssessmentState? getAssessmentState(String id) => _assessmentStates[id];

  void setAvailableAssessments(List<Map<String, dynamic>> assessments) {
    _availableAssessments = assessments;
    notifyListeners();
  }

  void selectAssessment(String assessmentId) {
    _saveCurrentState();
    _selectedAssessmentId = assessmentId;
    _restoreState(assessmentId);
    notifyListeners();
  }

  void _saveCurrentState() {
    if (_selectedAssessmentId == null || _questions.isEmpty) return;
    _assessmentStates[_selectedAssessmentId!] = AssessmentState(
      questions: _questions,
      currentQuestionIndex: _currentQuestionIndex,
      answers: Map.from(_answers),
      flaggedQuestions: Set.from(_flaggedQuestions),
      remainingSeconds: _remainingSeconds,
      durationMinutes: _durationMinutes,
      title: _examTitle,
      isSubmitted: _isSubmitted,
      submissionResult: _assessmentStates[_selectedAssessmentId!]?.submissionResult,
    );
  }

  void _restoreState(String assessmentId) {
    final state = _assessmentStates[assessmentId];
    if (state != null) {
      _questions = state.questions;
      _currentQuestionIndex = state.currentQuestionIndex;
      _answers = Map.from(state.answers);
      _flaggedQuestions = Set.from(state.flaggedQuestions);
      _remainingSeconds = state.remainingSeconds;
      _durationMinutes = state.durationMinutes;
      _examTitle = state.title;
      _totalQuestions = state.questions.length;
      _isSubmitted = state.isSubmitted;
      if (!_isSubmitted && _remainingSeconds > 0) {
        _startTimer();
      }
    }
  }

  Future<void> loadExam(String token) async {
    _isLoading = true;
    _error = null;
    _isSubmitted = false;
    notifyListeners();

    try {
      final existing = _assessmentStates[_selectedAssessmentId];
      if (existing != null && existing.questions.isNotEmpty) {
        _restoreState(_selectedAssessmentId!);
        _isLoading = false;
        notifyListeners();
        return;
      }

      final infoFuture = _apiService.getExamInfo(token, assessmentId: _selectedAssessmentId);
      final questionsFuture = _apiService.getExamQuestions(token, assessmentId: _selectedAssessmentId);

      final results = await Future.wait([infoFuture, questionsFuture]);

      final info = results[0] as Map<String, dynamic>;
      _examTitle = info['title'] ?? 'Assessment';
      _durationMinutes = info['duration_minutes'] ?? 45;
      _totalQuestions = info['total_questions'] ?? 40;

      final questionsData = results[1] as List<dynamic>;
      _questions = questionsData.cast<Map<String, dynamic>>();
      _totalQuestions = _questions.length;

      _currentQuestionIndex = 0;
      _answers = {};
      _flaggedQuestions = {};
      _remainingSeconds = _durationMinutes * 60;
      _startTimer();
      _saveCurrentState();

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
    _saveCurrentState();
    notifyListeners();
  }

  void setEssayAnswer(String text) {
    if (text.trim().isEmpty) {
      _answers.remove(_currentQuestionIndex);
    } else {
      _answers[_currentQuestionIndex] = text;
    }
    _saveCurrentState();
    notifyListeners();
  }

  void toggleFlag() {
    if (_flaggedQuestions.contains(_currentQuestionIndex)) {
      _flaggedQuestions.remove(_currentQuestionIndex);
    } else {
      _flaggedQuestions.add(_currentQuestionIndex);
    }
    _saveCurrentState();
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

      _isSubmitted = true;
      final result = {
        ...response,
        'duration_taken_seconds': durationTaken,
        'answered_count': _answers.length,
        'total_questions': _totalQuestions,
        'assessment_title': _examTitle,
      };

      if (_selectedAssessmentId != null) {
        _assessmentStates[_selectedAssessmentId!] = AssessmentState(
          questions: _questions,
          currentQuestionIndex: _currentQuestionIndex,
          answers: Map.from(_answers),
          flaggedQuestions: Set.from(_flaggedQuestions),
          remainingSeconds: _remainingSeconds,
          durationMinutes: _durationMinutes,
          title: _examTitle,
          isSubmitted: true,
          submissionResult: result,
        );
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Failed to submit exam. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> submitAllAssessments(String token) async {
    _isLoading = true;
    notifyListeners();

    final results = <Map<String, dynamic>>[];

    for (final assessment in _availableAssessments) {
      final id = assessment['id'] as String;
      final state = _assessmentStates[id];
      if (state == null || state.isSubmitted) {
        if (state?.submissionResult != null) {
          results.add(state!.submissionResult!);
        }
        continue;
      }

      final answersList = state.answers.entries.map((entry) {
        final question = state.questions[entry.key];
        final isEssay = question['type'] == 'essay';
        return {
          'questionId': question['id'],
          if (isEssay) 'essayAnswer': entry.value,
          if (!isEssay) 'selectedOption': entry.value,
        };
      }).toList();

      final durationTaken = (state.durationMinutes * 60) - state.remainingSeconds;

      try {
        final response = await _apiService.submitExam(answersList, durationTaken, token);
        final result = {
          ...response,
          'duration_taken_seconds': durationTaken,
          'answered_count': state.answers.length,
          'total_questions': state.questions.length,
          'assessment_title': state.title,
        };
        results.add(result);

        _assessmentStates[id] = AssessmentState(
          questions: state.questions,
          currentQuestionIndex: state.currentQuestionIndex,
          answers: state.answers,
          flaggedQuestions: state.flaggedQuestions,
          remainingSeconds: state.remainingSeconds,
          durationMinutes: state.durationMinutes,
          title: state.title,
          isSubmitted: true,
          submissionResult: result,
        );
      } catch (_) {}
    }

    if (_selectedAssessmentId != null) {
      final currentState = _assessmentStates[_selectedAssessmentId!];
      if (currentState != null) {
        _isSubmitted = currentState.isSubmitted;
      }
    }

    _isLoading = false;
    notifyListeners();
    return results;
  }

  void switchToAssessment(String assessmentId) {
    _saveCurrentState();
    _timer?.cancel();
    _selectedAssessmentId = assessmentId;
    _restoreState(assessmentId);
    notifyListeners();
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
    _isSubmitted = false;
    _assessmentStates.clear();
    _availableAssessments = [];
    _selectedAssessmentId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
