import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/ai_processing_screen.dart';
import 'screens/ai_match_summary.dart';
import 'screens/ai_video_upload.dart';
import 'screens/match_highlights_list.dart';
import 'screens/ai_predictions_screen.dart';
import 'screens/expanded_highlight_view.dart';
import 'models/match_highlight.dart';

import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const FootyAIApp());
}

class FootyAIApp extends StatelessWidget {
  const FootyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Footy AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Lexend',
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/expanded') {
          final highlight = settings.arguments as MatchHighlight;
          return MaterialPageRoute(
            builder: (context) => ExpandedHighlightView(highlight: highlight),
          );
        }
        // Handle other routes normally or fallback
        return null;
      },
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => MainNavigationScreen(),
        '/processing': (context) => AIProcessingScreen(),
        '/summary': (context) => AIMatchSummary(),
        '/upload': (context) => AIVideoUpload(),
        '/highlights': (context) => MatchHighlightsList(),
        '/predictions': (context) => AIPredictionsScreen(),
      },
    );
  }
}
