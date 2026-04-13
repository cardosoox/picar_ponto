import 'package:flutter/material.dart';
import 'package:picar_ponto/database/api_connection_table.dart';
import 'package:picar_ponto/pages/home_page.dart';
import 'package:picar_ponto/models/registo_model.dart';

class AdminPage extends StatefulWidget {
  static const String id = 'admin_page';

  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool mostrarHistorico = false;

  void encerrarDia() async {
    final registosDeHoje = await ApiConnectionDatabase.instance.lerRegistosDeHoje();
    if (registosDeHoje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não há registos pendentes para encerrar hoje."),
        ),
      );
      return;
    }

    await ApiConnectionDatabase.instance.encerrarDiaNoSQLite();

    setState(() {
      mostrarHistorico = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Dia encerrado e movido para o histórico SQL!"),
        ),
      );
    }
  }

  void cancelarRegistoFuncionario(int idDoRegisto) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Apagar Registo"),
        content: const Text(
          "Tens a certeza que queres eliminar este registo? O funcionário terá de picar de novo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Apagar"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await ApiConnectionDatabase.instance.apagarRegistoUnico(idDoRegisto);

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🗑️ Registo eliminado com sucesso!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          mostrarHistorico ? "Histórico de Dias" : "Registos de Hoje",
        ),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(mostrarHistorico ? Icons.today : Icons.history),
            onPressed: () => setState(() => mostrarHistorico = !mostrarHistorico),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, HomePage.id),
          ),
        ],
      ),
      body: mostrarHistorico ? _buildHistorico() : _buildHoje(),

      floatingActionButton: !mostrarHistorico
          ? FloatingActionButton.extended(
              onPressed: encerrarDia,
              label: const Text("Encerrar Dia"),
              icon: const Icon(Icons.lock_clock),
              backgroundColor: Colors.redAccent,
            )
          : null,
    );
  }

  Widget _buildHoje() {
    return FutureBuilder<List<RegistoPonto>>(
      future: ApiConnectionDatabase.instance.lerRegistosDeHoje(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Sem registos na Base de Dados."));
        }

        final registosDoDisco = snapshot.data!;

        return ListView.builder(
          itemCount: registosDoDisco.length,
          itemBuilder: (context, index) {
            final r = registosDoDisco[index];
            return ListTile(
              title: Text(r.nomeFuncionario),
              subtitle: Text(
                "Entrada: ${r.entrada.hour.toString().padLeft(2, '0')}:${r.entrada.minute.toString().padLeft(2, '0')}",
              ),
              
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                tooltip: 'Eliminar Registo',
                onPressed: () {
                  if (r.id != null) {
                    cancelarRegistoFuncionario(r.id!);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistorico() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiConnectionDatabase.instance.lerHistoricoCompleto(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("O histórico está vazio."));
        }

        final historico = snapshot.data!;

        return ListView.builder(
          itemCount: historico.length,
          itemBuilder: (context, index) {
            final dia = historico[index];
            final data = dia['data'] as DateTime;
            final registos = dia['registos'] as List<RegistoPonto>;

            return ExpansionTile(
              title: Text(
                "Dia ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("${registos.length} registos neste dia"),

              children: registos.map((r) {
                // Segurança
                if (r.saida == null) {
                  return ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(
                      r.nomeFuncionario,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Esqueceu-se de picar a saída!"),
                  );
                }

                final tempoTrabalhado = r.saida!.difference(r.entrada);
                final horas = tempoTrabalhado.inHours;
                final minutos = tempoTrabalhado.inMinutes % 60;

                final horaEnt = "${r.entrada.hour.toString().padLeft(2, '0')}:${r.entrada.minute.toString().padLeft(2, '0')}";
                final horaSai = "${r.saida!.hour.toString().padLeft(2, '0')}:${r.saida!.minute.toString().padLeft(2, '0')}";

                return ListTile(
                  leading: const Icon(Icons.person, color: Colors.grey),
                  title: Text(
                    r.nomeFuncionario,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Das $horaEnt às $horaSai"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${horas}h ${minutos}m",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}