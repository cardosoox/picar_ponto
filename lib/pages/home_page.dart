import 'package:flutter/material.dart';
import 'picar_page.dart'; 
import 'admin_page.dart'; 
import 'package:picar_ponto/database/api_connection_table.dart';

class HomePage extends StatefulWidget {
  static const String id = 'home_page';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String mensagemErro = "";

  void fazerLogin() async {
    final usernameInserido = _usernameController.text;
    final passwordInserida = _passwordController.text;
    final utilizadorEncontrado = await ApiConnectionDatabase.instance.verificarLogin(
      usernameInserido, 
      passwordInserida
    );

    if (utilizadorEncontrado != null) {
      
      setState(() => mensagemErro = "");

      if (utilizadorEncontrado.isAdmin) {
        Navigator.pushReplacementNamed(context, AdminPage.id);
      } else {
        Navigator.pushReplacementNamed(
          context, 
          PicarPage.id,
          arguments: utilizadorEncontrado, 
        );
      }
      
    } else {
      setState(() => mensagemErro = "Credenciais inválidas!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 32, 165),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Login da Empresa", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Utilizador (ex: joao)"),
              ),
              const SizedBox(height: 10),
              
              TextField(
                controller: _passwordController,
                obscureText: true, 
                decoration: const InputDecoration(labelText: "Palavra-passe"),
              ),
              const SizedBox(height: 20),
              
              if (mensagemErro.isNotEmpty)
                Text(mensagemErro, style: const TextStyle(color: Colors.red)),
              
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: fazerLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 81, 32, 165),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Entrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}