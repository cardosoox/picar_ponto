import 'package:flutter/material.dart';
import 'package:picar_ponto/database/api_connection_table.dart';
import 'package:picar_ponto/models/funcionario_model.dart'; 
import 'package:picar_ponto/pages/home_page.dart';
import 'package:picar_ponto/models/registo_model.dart';

class PicarPage extends StatefulWidget {
  static const String id = 'picar_page';
  
  final Funcionario funcionarioLogado;

  const PicarPage({
    super.key,
    required this.funcionarioLogado,
  });

  @override
  State<PicarPage> createState() => _PicarPageState();
}

class _PicarPageState extends State<PicarPage> {
  bool jaEntrou = false;
  bool jaSaiu = false;
  

  int? registoIdAtual;

  String horaEntradaTexto = "--:--";
  String horaSaidaTexto = "--:--";

  DateTime? momentoEntrada;
  DateTime? momentoSaida;

  @override
  void initState() {
    super.initState();
    verificarEstadoInicial();
  }

  void verificarEstadoInicial() async {
    final registo = await ApiConnectionDatabase.instance.buscarRegistoAberto(widget.funcionarioLogado.nome);

    if (registo != null) {
      setState(() {
        jaEntrou = true;
        momentoEntrada = registo.entrada;
        registoIdAtual = registo.id; 
        
        final h = registo.entrada.hour.toString().padLeft(2, '0');
        final m = registo.entrada.minute.toString().padLeft(2, '0');
        horaEntradaTexto = "$h:$m";

        if (registo.saida != null) {
          jaSaiu = true;
          momentoSaida = registo.saida;
          final sh = registo.saida!.hour.toString().padLeft(2, '0');
          final sm = registo.saida!.minute.toString().padLeft(2, '0');
          horaSaidaTexto = "$sh:$sm";
        }
      });
    }
  }

  void registarEntrada() async {
    setState(() {
      jaEntrou = true;
      momentoEntrada = DateTime.now();
      
      final hora = momentoEntrada!.hour.toString().padLeft(2, '0');
      final minuto = momentoEntrada!.minute.toString().padLeft(2, '0');
      horaEntradaTexto = "$hora:$minuto";
    });

    final novoRegisto = RegistoPonto(
      nomeFuncionario: widget.funcionarioLogado.nome,
      entrada: momentoEntrada!,
    );

    try {
      final registoGravado = await ApiConnectionDatabase.instance.inserirRegisto(novoRegisto);
      registoIdAtual = registoGravado.id;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Ponto de Entrada picado!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao gravar Entrada!"), backgroundColor: Colors.red),
      );
    }
  }

  void registarSaida() async {
    setState(() {
      jaSaiu = true;
      momentoSaida = DateTime.now();
      
      final hora = momentoSaida!.hour.toString().padLeft(2, '0');
      final minuto = momentoSaida!.minute.toString().padLeft(2, '0');
      horaSaidaTexto = "$hora:$minuto";
    });

    final registoAtualizado = RegistoPonto(
      id: registoIdAtual, 
      nomeFuncionario: widget.funcionarioLogado.nome,
      entrada: momentoEntrada!,
      saida: momentoSaida, 
    );

    try {
      await ApiConnectionDatabase.instance.atualizarSaida(registoAtualizado);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Ponto de Saída picado! Bom descanso!"), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao gravar Saída!"), backgroundColor: Colors.red),
      );
    }
  }

  void terminarSessao() {
    Navigator.pushReplacementNamed(context, HomePage.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Olá, ${widget.funcionarioLogado.nome}!"), 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Terminar Sessão',
            onPressed: terminarSessao,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Entrada: $horaEntradaTexto", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: jaEntrou ? null : registarEntrada,
              child: const Text("Picar Entrada"),
            ),
            
            const SizedBox(height: 40),
            
            Text("Saída: $horaSaidaTexto", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: (jaEntrou && !jaSaiu) ? registarSaida : null,
              child: const Text("Picar Saída"),
            ),
            
            if (jaSaiu) 
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  "✅ Dia concluído! Podes terminar sessão.", 
                  style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
          ],
        ),
      ),
    );
  }
}