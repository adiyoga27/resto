import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  runApp(const RestoApp());
}

class RestoApp extends StatelessWidget {
  const RestoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (_, langProv, themeProv, __) {
          return MaterialApp(
            title: 'Resto POS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProv.themeMode,
            locale: langProv.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.init();
    if (auth.isLoggedIn) {
      final menuProv = context.read<MenuProvider>();
      final orderProv = context.read<OrderProvider>();
      menuProv.setUserId(auth.userId);
      menuProv.init();
      orderProv.setUserId(auth.userId);
      orderProv.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
