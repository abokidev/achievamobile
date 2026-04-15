class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Achieva';
  static const String tagline = 'Your Excellence, Verified.';

  // API Base URL
  // For Android emulator use: http://10.0.2.2:3000
  // For physical device use your machine's IP: http://192.168.x.x:3000
  // For deployed backend use: https://api.achieva.ng
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Login
  static const String signIn = 'Sign In';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String loginError = 'Invalid email or password. Please try again.';
  static const String networkError = 'Network error. Please check your connection and try again.';

  // NIN Verification
  static const String ninStepTitle = 'Identity Verification';
  static const String ninStepIndicator = 'Step 1 of 2';
  static const String ninLabel = 'National Identification Number (NIN)';
  static const String dobLabel = 'Date of Birth';
  static const String ninExplainer =
      'We\'ll verify your identity using the National Identity Management Commission database.';
  static const String verifyIdentity = 'Verify Identity';
  static const String verifyingNimc = 'Verifying with NIMC...';
  static const String ninNotFound = 'We couldn\'t find this NIN. Please check and try again.';
  static const String dobMismatch = 'Date of birth does not match our records.';
  static const String ninInvalid = 'NIN must be exactly 11 digits.';

  // Facial Verification
  static const String faceStepTitle = 'Face Verification';
  static const String faceStepIndicator = 'Step 2 of 2';
  static const String faceInstruction = 'Position your face within the oval and hold steady';
  static const String identityConfirmed = 'Identity confirmed';
  static const String proceedToExam = 'Proceed to Exam';
  static const String retryVerification = 'Retry Verification';
  static const String faceVerificationFailed = 'Face verification failed. Please try again.';

  // Exam
  static const String submitExam = 'Submit Exam';
  static const String previousQuestion = 'Previous';
  static const String nextQuestion = 'Next';
  static const String flagQuestion = 'Flag';
  static const String questionGrid = 'Question Grid';
  static const String examLeftWarning =
      'You left the exam. This incident has been recorded.';
  static const String submitConfirmTitle = 'Submit Exam?';

  static String submitConfirmMessage(int answered, int total, String timeRemaining) =>
      'You have answered $answered of $total questions. Submit your test?\n\nTime remaining: $timeRemaining';

  // Submission
  static const String testSubmitted = 'Test Submitted Successfully';
  static const String submissionSubtext =
      'Your responses have been recorded. Results will be communicated to you in due course.';
  static const String timeTaken = 'Time Taken';
  static const String questionsAnswered = 'Questions Answered';
  static const String exit = 'Exit';
}
