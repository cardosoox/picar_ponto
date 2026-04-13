import 'package:flutter/material.dart';
import 'package:picar_ponto/pages/home_page.dart';
import 'package:picar_ponto/pages/admin_page.dart';
import 'package:picar_ponto/pages/picar_page.dart';
import 'package:picar_ponto/models/funcionario_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Ponto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: HomePage.id,
      routes: {
        HomePage.id: (context) => const HomePage(),
        AdminPage.id: (context) => const AdminPage(),
        
        PicarPage.id: (context) => PicarPage(
        
          funcionarioLogado: ModalRoute.of(context)!.settings.arguments as Funcionario,
        ),
      },
    );
  }
}