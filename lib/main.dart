import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/exam/providers/exam_provider.dart';
import 'features/exam/screens/exam_screen.dart';
import 'features/exam/screens/assessment_hub_screen.dart';
import 'features/exam/screens/submission_screen.dart';
import 'features/exam_setup/screens/exam_details_screen.dart';
import 'features/exam_setup/screens/test_setup_screen.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/screens/facial_verification_screen.dart';
import 'features/onboarding/screens/nin_verification_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const AchievaApp());
}

class AchievaApp extends StatelessWidget {
  const AchievaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              );
            case '/nin-verification':
              return MaterialPageRoute(
                builder: (_) => const NinVerificationScreen(),
              );
            case '/face-verification':
              return MaterialPageRoute(
                builder: (_) => const FacialVerificationScreen(),
              );
            case '/exam-details':
              return MaterialPageRoute(
                builder: (_) => const ExamDetailsScreen(),
              );
            case '/test-setup':
              return MaterialPageRoute(
                builder: (_) => const TestSetupScreen(),
              );
            case '/assessment-hub':
              return MaterialPageRoute(
                builder: (_) => const AssessmentHubScreen(),
              );
            case '/exam':
              return MaterialPageRoute(
                builder: (_) => const ExamScreen(),
              );
            case '/submission':
              final data = settings.arguments as Map<String, dynamic>? ?? {};
              return MaterialPageRoute(
                builder: (_) => SubmissionScreen(submissionData: data),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              );
          }
        },
      ),
    );
  }
}
