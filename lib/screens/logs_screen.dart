import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_drawer.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<dynamic> _logs = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarLogs();
  }

  Future<void> _carregarLogs() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final dados = await ApiService.getHistorico();

    setState(() {
      _carregando = false;
      if (dados.isEmpty) {
        _erro = 'Nenhum evento registrado ainda.';
      } else {
        _logs = dados;
      }
    });
  }

  IconData _iconeOrigem(String? origem) {
    switch (origem) {
      case 'App':
        return Icons.smartphone;
      case 'Alexa':
        return Icons.record_voice_over;
      default:
        return Icons.sensors;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs do Sistema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarLogs,
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_erro!,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          _iconeOrigem(log['origem']),
                          color: Colors.blue,
                        ),
                        title: Text(log['acao'] ?? ''),
                        subtitle: Text(
                          '${log['nome'] ?? 'Sistema'} — ${log['origem'] ?? ''}\n${log['data_hora'] ?? ''}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}