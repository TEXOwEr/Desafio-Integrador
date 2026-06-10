import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/gate_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/control_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/report_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GateProvider()),
      ],
      child: const SmartGateApp(),
    ),
  );
}

class SmartGateApp extends StatelessWidget {
  const SmartGateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portão IoT',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/cadastro': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/control': (context) => const ControlScreen(),
        '/logs': (context) => const LogsScreen(),
        '/report': (context) => const ReportScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}