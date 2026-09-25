import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase başlatılamadı: $error');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'firebase initialization',
      ),
    );
  }

  if (Firebase.apps.isNotEmpty) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
    } catch (error) {
      debugPrint('Firebase App Check başlatılamadı: $error');
    }
  }

  runApp(const SifirAtikApp());
}

class SifirAtikApp extends StatelessWidget {
  const SifirAtikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sıfır Atık',
      theme: AppTheme.light,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.25,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}

typedef MyApp = SifirAtikApp;
