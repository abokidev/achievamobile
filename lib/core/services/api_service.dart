import 'dart:math';

class ApiService {
  ApiService({String? baseUrl});

  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'token': 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
      'userId': 'usr_001',
      'name': email.split('@').first,
      'isVerified': false,
    };
  }

  Future<Map<String, dynamic>> verifyNin(
      String nin, String dob, String token) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'name': 'Demo Candidate',
      'photo_url': '',
      'nin_verified': true,
    };
  }

  Future<Map<String, dynamic>> verifyFace(
      String imageBase64, String nin, String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'match': true,
      'confidence': 0.97,
      'verified': true,
    };
  }

  Future<List<Map<String, dynamic>>> getAvailableAssessments(String token) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {
        'id': 'mcq_assessment',
        'title': 'Aptitude Assessment (MCQ)',
        'duration_minutes': 30,
        'type': 'mcq',
      },
      {
        'id': 'essay_assessment',
        'title': 'Written Assessment (Essay)',
        'duration_minutes': 45,
        'type': 'essay',
      },
    ];
  }

  Future<Map<String, dynamic>> getExamInfo(String token, {String? assessmentId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (assessmentId == 'essay_assessment') {
      return {
        'title': 'Written Assessment (Essay)',
        'duration_minutes': 45,
        'total_questions': 5,
      };
    }
    return {
      'title': 'Aptitude Assessment (MCQ)',
      'duration_minutes': 30,
      'total_questions': 40,
    };
  }

  Future<List<dynamic>> getExamQuestions(String token, {String? assessmentId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (assessmentId == 'essay_assessment') {
      return _mockEssayQuestions;
    }
    return _mockMcqQuestions;
  }

  Future<Map<String, dynamic>> submitExam(
      List<Map<String, dynamic>> answers, int durationSeconds, String token) async {
    await Future.delayed(const Duration(seconds: 1));
    final ref = 'ACH-2026-${Random().nextInt(99999).toString().padLeft(5, '0')}';
    return {
      'submitted': true,
      'timestamp': DateTime.now().toIso8601String(),
      'reference': ref,
      'answers_received': answers.length,
      'duration_taken_seconds': durationSeconds,
    };
  }

  Future<Map<String, dynamic>> sendProctorSnapshot(
      String imageBase64, String eventType, String token) async {
    return {'logged': true};
  }

  Future<Map<String, dynamic>> sendProctorEvent(
      String type, String timestamp, String token) async {
    return {'logged': true};
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}


final List<Map<String, dynamic>> _mockMcqQuestions = [
  {"id": "q_001", "text": "Choose the word that best completes the sentence: The politician's _____ remarks alienated even his most loyal supporters.", "options": [{"id": "q_001_a", "text": "Diplomatic"}, {"id": "q_001_b", "text": "Incendiary"}, {"id": "q_001_c", "text": "Mundane"}, {"id": "q_001_d", "text": "Benevolent"}], "subject": "Verbal Reasoning"},
  {"id": "q_002", "text": "ELATED is to DESPONDENT as TRANSPARENT is to:", "options": [{"id": "q_002_a", "text": "Clear"}, {"id": "q_002_b", "text": "Visible"}, {"id": "q_002_c", "text": "Opaque"}, {"id": "q_002_d", "text": "Obvious"}], "subject": "Verbal Reasoning"},
  {"id": "q_003", "text": "Which word is most nearly opposite in meaning to EPHEMERAL?", "options": [{"id": "q_003_a", "text": "Temporary"}, {"id": "q_003_b", "text": "Permanent"}, {"id": "q_003_c", "text": "Fleeting"}, {"id": "q_003_d", "text": "Brief"}], "subject": "Verbal Reasoning"},
  {"id": "q_004", "text": "Read the statement: 'All managers attended the meeting. Some managers are engineers.' Which conclusion is valid?", "options": [{"id": "q_004_a", "text": "All engineers attended the meeting"}, {"id": "q_004_b", "text": "Some engineers attended the meeting"}, {"id": "q_004_c", "text": "No engineers attended the meeting"}, {"id": "q_004_d", "text": "All attendees were engineers"}], "subject": "Verbal Reasoning"},
  {"id": "q_005", "text": "Choose the pair that best expresses a relationship similar to ARCHITECT : BLUEPRINT", "options": [{"id": "q_005_a", "text": "Teacher : Student"}, {"id": "q_005_b", "text": "Composer : Symphony"}, {"id": "q_005_c", "text": "Doctor : Hospital"}, {"id": "q_005_d", "text": "Lawyer : Courtroom"}], "subject": "Verbal Reasoning"},
  {"id": "q_006", "text": "Select the word that does NOT belong with the others:", "options": [{"id": "q_006_a", "text": "Meticulous"}, {"id": "q_006_b", "text": "Thorough"}, {"id": "q_006_c", "text": "Careless"}, {"id": "q_006_d", "text": "Painstaking"}], "subject": "Verbal Reasoning"},
  {"id": "q_007", "text": "The report was so _____ that even experts found it difficult to understand the key findings.", "options": [{"id": "q_007_a", "text": "Lucid"}, {"id": "q_007_b", "text": "Concise"}, {"id": "q_007_c", "text": "Convoluted"}, {"id": "q_007_d", "text": "Straightforward"}], "subject": "Verbal Reasoning"},
  {"id": "q_008", "text": "PROLIFIC is to SCARCE as ELABORATE is to:", "options": [{"id": "q_008_a", "text": "Complex"}, {"id": "q_008_b", "text": "Simple"}, {"id": "q_008_c", "text": "Detailed"}, {"id": "q_008_d", "text": "Ornate"}], "subject": "Verbal Reasoning"},
  {"id": "q_009", "text": "If 'no politicians are honest' and 'all honest people are trustworthy,' which must be true?", "options": [{"id": "q_009_a", "text": "No politicians are trustworthy"}, {"id": "q_009_b", "text": "Some politicians are trustworthy"}, {"id": "q_009_c", "text": "All trustworthy people are politicians"}, {"id": "q_009_d", "text": "None of the above can be determined"}], "subject": "Verbal Reasoning"},
  {"id": "q_010", "text": "Which sentence uses the word 'discrete' correctly?", "options": [{"id": "q_010_a", "text": "She was very discrete about the surprise party"}, {"id": "q_010_b", "text": "The data was divided into discrete categories"}, {"id": "q_010_c", "text": "He made a discrete attempt to leave early"}, {"id": "q_010_d", "text": "Please be discrete with this information"}], "subject": "Verbal Reasoning"},
  {"id": "q_011", "text": "A company's revenue increased from 2.4 million to 3.0 million. What is the percentage increase?", "options": [{"id": "q_011_a", "text": "20%"}, {"id": "q_011_b", "text": "25%"}, {"id": "q_011_c", "text": "30%"}, {"id": "q_011_d", "text": "80%"}], "subject": "Numerical Reasoning"},
  {"id": "q_012", "text": "If 3 workers can complete a project in 12 days, how many days would 4 workers need?", "options": [{"id": "q_012_a", "text": "8 days"}, {"id": "q_012_b", "text": "9 days"}, {"id": "q_012_c", "text": "10 days"}, {"id": "q_012_d", "text": "16 days"}], "subject": "Numerical Reasoning"},
  {"id": "q_013", "text": "What is the next number in the series: 2, 6, 18, 54, ...?", "options": [{"id": "q_013_a", "text": "108"}, {"id": "q_013_b", "text": "162"}, {"id": "q_013_c", "text": "148"}, {"id": "q_013_d", "text": "216"}], "subject": "Numerical Reasoning"},
  {"id": "q_014", "text": "A product costs 5,000 after a 20% discount. What was the original price?", "options": [{"id": "q_014_a", "text": "6,000"}, {"id": "q_014_b", "text": "6,250"}, {"id": "q_014_c", "text": "6,500"}, {"id": "q_014_d", "text": "7,000"}], "subject": "Numerical Reasoning"},
  {"id": "q_015", "text": "The ratio of boys to girls in a class is 3:5. If there are 40 students, how many boys are there?", "options": [{"id": "q_015_a", "text": "12"}, {"id": "q_015_b", "text": "15"}, {"id": "q_015_c", "text": "18"}, {"id": "q_015_d", "text": "24"}], "subject": "Numerical Reasoning"},
  {"id": "q_016", "text": "An investment of 100,000 earns 8% simple interest per year. What is the total value after 3 years?", "options": [{"id": "q_016_a", "text": "108,000"}, {"id": "q_016_b", "text": "116,000"}, {"id": "q_016_c", "text": "124,000"}, {"id": "q_016_d", "text": "125,971"}], "subject": "Numerical Reasoning"},
  {"id": "q_017", "text": "A train travels 240 km in 3 hours. If it increases speed by 20 km/h, how long will it take to travel 360 km?", "options": [{"id": "q_017_a", "text": "3 hours"}, {"id": "q_017_b", "text": "3.5 hours"}, {"id": "q_017_c", "text": "3.6 hours"}, {"id": "q_017_d", "text": "4 hours"}], "subject": "Numerical Reasoning"},
  {"id": "q_018", "text": "In a survey, 60% of 500 respondents preferred Product A. If the margin of error is 4%, what is the minimum number who preferred it?", "options": [{"id": "q_018_a", "text": "260"}, {"id": "q_018_b", "text": "280"}, {"id": "q_018_c", "text": "300"}, {"id": "q_018_d", "text": "320"}], "subject": "Numerical Reasoning"},
  {"id": "q_019", "text": "What is the next number in the series: 1, 1, 2, 3, 5, 8, 13, ...?", "options": [{"id": "q_019_a", "text": "18"}, {"id": "q_019_b", "text": "20"}, {"id": "q_019_c", "text": "21"}, {"id": "q_019_d", "text": "26"}], "subject": "Numerical Reasoning"},
  {"id": "q_020", "text": "A company's expenses: Salaries 45%, Rent 20%, Utilities 15%, Supplies 10%, Other 10%. If total is 2,000,000, how much on Rent and Utilities combined?", "options": [{"id": "q_020_a", "text": "600,000"}, {"id": "q_020_b", "text": "700,000"}, {"id": "q_020_c", "text": "800,000"}, {"id": "q_020_d", "text": "900,000"}], "subject": "Numerical Reasoning"},
  {"id": "q_021", "text": "Which shape completes the pattern? In each row, a circle gains one additional line segment. Row 3 has shapes with 0, 1, and ?.", "options": [{"id": "q_021_a", "text": "A circle with 2 line segments"}, {"id": "q_021_b", "text": "A circle with 3 line segments"}, {"id": "q_021_c", "text": "A square with 2 line segments"}, {"id": "q_021_d", "text": "A triangle with 1 line segment"}], "subject": "Abstract Reasoning"},
  {"id": "q_022", "text": "In a sequence, each figure rotates 45 degrees clockwise and alternates filled/hollow. What is the 5th figure if the 1st is a filled square at 0 degrees?", "options": [{"id": "q_022_a", "text": "Filled square at 180 degrees"}, {"id": "q_022_b", "text": "Hollow square at 180 degrees"}, {"id": "q_022_c", "text": "Filled square at 135 degrees"}, {"id": "q_022_d", "text": "Hollow square at 135 degrees"}], "subject": "Abstract Reasoning"},
  {"id": "q_023", "text": "Find the odd one out: All shapes are symmetrical along at least one axis except one.", "options": [{"id": "q_023_a", "text": "Equilateral triangle"}, {"id": "q_023_b", "text": "Regular pentagon"}, {"id": "q_023_c", "text": "Scalene triangle"}, {"id": "q_023_d", "text": "Square"}], "subject": "Abstract Reasoning"},
  {"id": "q_024", "text": "A pattern shows: 1 dot, 3 dots, 6 dots, 10 dots. How many dots come next?", "options": [{"id": "q_024_a", "text": "13"}, {"id": "q_024_b", "text": "14"}, {"id": "q_024_c", "text": "15"}, {"id": "q_024_d", "text": "16"}], "subject": "Abstract Reasoning"},
  {"id": "q_025", "text": "In a grid, each row has one circle, triangle, and square. Each column has one filled, striped, and hollow. Which fills row 3, column 2?", "options": [{"id": "q_025_a", "text": "Striped circle"}, {"id": "q_025_b", "text": "Hollow triangle"}, {"id": "q_025_c", "text": "Filled square"}, {"id": "q_025_d", "text": "Striped triangle"}], "subject": "Abstract Reasoning"},
  {"id": "q_026", "text": "If A to B means 'A is smaller than B', and the sequence shows: small circle to medium circle to ? to large square. What fills the gap?", "options": [{"id": "q_026_a", "text": "Large circle"}, {"id": "q_026_b", "text": "Medium square"}, {"id": "q_026_c", "text": "Small square"}, {"id": "q_026_d", "text": "Large triangle"}], "subject": "Abstract Reasoning"},
  {"id": "q_027", "text": "A cube is painted red on all sides, then cut into 27 equal smaller cubes. How many small cubes have exactly two painted faces?", "options": [{"id": "q_027_a", "text": "8"}, {"id": "q_027_b", "text": "12"}, {"id": "q_027_c", "text": "6"}, {"id": "q_027_d", "text": "4"}], "subject": "Abstract Reasoning"},
  {"id": "q_028", "text": "Looking at a mirror image: if the original shows an arrow pointing to the upper-right, the mirror image shows the arrow pointing to the:", "options": [{"id": "q_028_a", "text": "Upper-left"}, {"id": "q_028_b", "text": "Lower-right"}, {"id": "q_028_c", "text": "Lower-left"}, {"id": "q_028_d", "text": "Upper-right"}], "subject": "Abstract Reasoning"},
  {"id": "q_029", "text": "A sequence alternates between adding sides and rotating. Starting with a triangle facing up: Triangle up, Square right, Pentagon up, ?", "options": [{"id": "q_029_a", "text": "Hexagon right"}, {"id": "q_029_b", "text": "Hexagon up"}, {"id": "q_029_c", "text": "Pentagon right"}, {"id": "q_029_d", "text": "Heptagon right"}], "subject": "Abstract Reasoning"},
  {"id": "q_030", "text": "If you fold a piece of paper twice and punch a hole through all layers, how many holes appear when unfolded?", "options": [{"id": "q_030_a", "text": "2"}, {"id": "q_030_b", "text": "3"}, {"id": "q_030_c", "text": "4"}, {"id": "q_030_d", "text": "6"}], "subject": "Abstract Reasoning"},
  {"id": "q_031", "text": "You notice a colleague consistently taking credit for work done by the team. What is the most appropriate action?", "options": [{"id": "q_031_a", "text": "Publicly confront them in the next team meeting"}, {"id": "q_031_b", "text": "Start taking credit for their work in return"}, {"id": "q_031_c", "text": "Speak to them privately about giving proper credit"}, {"id": "q_031_d", "text": "Report them immediately to senior management"}], "subject": "Situational Judgement"},
  {"id": "q_032", "text": "A client sends an urgent request outside your expertise. Your supervisor is unavailable. What should you do?", "options": [{"id": "q_032_a", "text": "Attempt to handle it yourself to show initiative"}, {"id": "q_032_b", "text": "Ignore the email until your supervisor returns"}, {"id": "q_032_c", "text": "Acknowledge receipt and connect them with a qualified colleague"}, {"id": "q_032_d", "text": "Forward the email to all departments"}], "subject": "Situational Judgement"},
  {"id": "q_033", "text": "You discover a minor error in a submitted report. It's unlikely to affect conclusions. What do you do?", "options": [{"id": "q_033_a", "text": "Ignore it since it doesn't affect the conclusions"}, {"id": "q_033_b", "text": "Inform your supervisor and send a correction"}, {"id": "q_033_c", "text": "Wait to see if the client notices"}, {"id": "q_033_d", "text": "Blame the error on a colleague"}], "subject": "Situational Judgement"},
  {"id": "q_034", "text": "Two team members disagree about a project approach. As team lead, what is the best course of action?", "options": [{"id": "q_034_a", "text": "Side with the more senior team member"}, {"id": "q_034_b", "text": "Let them work it out themselves"}, {"id": "q_034_c", "text": "Listen to both, facilitate discussion, guide toward project goals"}, {"id": "q_034_d", "text": "Assign the project to someone else"}], "subject": "Situational Judgement"},
  {"id": "q_035", "text": "You are asked to work late to meet a deadline, but you have a personal commitment. What is the most professional response?", "options": [{"id": "q_035_a", "text": "Refuse outright and leave on time"}, {"id": "q_035_b", "text": "Cancel your personal commitment without question"}, {"id": "q_035_c", "text": "Explain your situation and offer an alternative solution"}, {"id": "q_035_d", "text": "Agree to stay but do minimal work"}], "subject": "Situational Judgement"},
  {"id": "q_036", "text": "You overhear a colleague sharing confidential information with an external party. What should you do?", "options": [{"id": "q_036_a", "text": "Pretend you didn't hear anything"}, {"id": "q_036_b", "text": "Confront the colleague loudly"}, {"id": "q_036_c", "text": "Report the incident to your supervisor or compliance"}, {"id": "q_036_d", "text": "Share the story with other colleagues"}], "subject": "Situational Judgement"},
  {"id": "q_037", "text": "A new employee is struggling to learn systems. Your workload is heavy. What is the best approach?", "options": [{"id": "q_037_a", "text": "Tell them to figure it out on their own"}, {"id": "q_037_b", "text": "Offer help during a break or set up brief daily check-ins"}, {"id": "q_037_c", "text": "Report them to HR for poor performance"}, {"id": "q_037_d", "text": "Do their work for them to avoid delays"}], "subject": "Situational Judgement"},
  {"id": "q_038", "text": "Your manager asks you to implement a change you believe will hurt the project. What do you do?", "options": [{"id": "q_038_a", "text": "Implement it without question"}, {"id": "q_038_b", "text": "Refuse to do it"}, {"id": "q_038_c", "text": "Present your concerns with evidence, then follow the final decision"}, {"id": "q_038_d", "text": "Implement it poorly so it fails"}], "subject": "Situational Judgement"},
  {"id": "q_039", "text": "During a team presentation, you realize you made an error in your slides. What is the best action?", "options": [{"id": "q_039_a", "text": "Continue and hope no one notices"}, {"id": "q_039_b", "text": "Stop the presentation to fix the slides"}, {"id": "q_039_c", "text": "Acknowledge the error briefly, correct verbally, and continue"}, {"id": "q_039_d", "text": "Blame it on technical difficulties"}], "subject": "Situational Judgement"},
  {"id": "q_040", "text": "You receive feedback that your team's service has been declining. You believe it's unfair. How do you respond?", "options": [{"id": "q_040_a", "text": "Argue with the client and defend performance"}, {"id": "q_040_b", "text": "Thank them, investigate concerns, and develop an action plan"}, {"id": "q_040_c", "text": "Ignore the feedback"}, {"id": "q_040_d", "text": "Forward the complaint to pressure your team"}], "subject": "Situational Judgement"},
];

final List<Map<String, dynamic>> _mockEssayQuestions = [
  {"id": "e_001", "text": "Describe a situation where you had to work under pressure to meet a tight deadline. What steps did you take and what was the outcome?", "type": "essay", "subject": "Professional Experience"},
  {"id": "e_002", "text": "In your opinion, what are the three most important qualities of an effective leader? Explain each quality with a real-world example.", "type": "essay", "subject": "Leadership"},
  {"id": "e_003", "text": "Discuss the impact of artificial intelligence on the modern workplace. What opportunities and challenges does it present for professionals?", "type": "essay", "subject": "Critical Thinking"},
  {"id": "e_004", "text": "A company is experiencing declining employee morale. As a newly appointed HR manager, outline a comprehensive plan to address this issue.", "type": "essay", "subject": "Problem Solving"},
  {"id": "e_005", "text": "Explain the importance of ethical decision-making in business. Provide an example of an ethical dilemma and how it should be resolved.", "type": "essay", "subject": "Ethics"},
];
