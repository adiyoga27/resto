import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'firebase_options.dart';
import 'services/firebase_setup.dart';
import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/restaurant_provider.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/setup_wizard.dart';
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
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
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
  bool _checking = true;
  bool _needsSetup = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.init();

    if (!mounted) return;

    if (auth.isLoggedIn && auth.restaurantId.isNotEmpty) {
      final setup = FirebaseSetup();
      final needs = await setup.needsSetup(auth.userId);
      if (!mounted) return;

      if (needs) {
        setState(() {
          _needsSetup = true;
          _checking = false;
        });
        return;
      }

      final menuProv = context.read<MenuProvider>();
      final orderProv = context.read<OrderProvider>();
      menuProv.setRestaurantId(auth.restaurantId);
      menuProv.init();
      orderProv.setRestaurantId(auth.restaurantId);
      orderProv.init();
      context.read<RestaurantProvider>().load(auth.restaurantId);
    } else if (auth.isLoggedIn) {
      setState(() {
        _needsSetup = true;
        _checking = false;
      });
      return;
    }

    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F2027),
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    if (_needsSetup) return const SetupWizard();

    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) return const HomeScreen();

    return const LoginScreen();
  }
}
