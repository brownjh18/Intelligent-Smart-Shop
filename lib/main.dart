import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:provider/provider.dart';
import 'package:ismart_shop/firebase_options.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/providers/language_provider.dart';
import 'package:ismart_shop/providers/theme_provider.dart';
import 'package:ismart_shop/screens/splash_screen.dart';
import 'package:ismart_shop/utils/theme.dart';
import 'package:ismart_shop/services/openai_parser_service.dart';

bool _firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Set a shorter timeout for Firebase initialization
    final firebaseFuture = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Wait for Firebase with a timeout
    await firebaseFuture.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        throw Exception('Firebase initialization timeout');
      },
    );

    // Enable Firestore offline persistence for faster data loading
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    _firebaseInitialized = true;
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e - running in demo mode');
    _firebaseInitialized = false;
  }

  // Initialize OpenAI parser service
  try {
    await OpenAIParserService.initialize();
    debugPrint('OpenAI parser service initialized');
  } catch (e) {
    debugPrint('OpenAI parser service initialization failed: $e');
  }

  // Store the Firebase initialization state in a global variable
  // that can be checked by AuthProvider
  try {
    var delegate = await LocalizationDelegate.create(
      fallbackLocale: 'en',
      supportedLocales: ['en', 'lg'],
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(firebaseInitialized: _firebaseInitialized),
          ),
          ChangeNotifierProvider(
              create: (_) => TransactionProvider()..initialize()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: LocalizedApp(delegate, const MyApp()),
      ),
    );
  } catch (e) {
    debugPrint(
        'Localization initialization failed: $e - running without translations');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(firebaseInitialized: _firebaseInitialized),
          ),
          ChangeNotifierProvider(
              create: (_) => TransactionProvider()..initialize()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'iSmart Shop',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
