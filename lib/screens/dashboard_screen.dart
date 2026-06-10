import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gate_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _relatorio = {};
  List<dynamic> _ultimosLogs = [];
  bool _carregando = true;
  String? _nomeUsuario;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final nome = await ApiService.getNome();
    final relatorio = await ApiService.getRelatorio();
    final logs = await ApiService.getHistorico();

    setState(() {
      _nomeUsuario = nome;
      _relatorio = relatorio;
      _ultimosLogs = logs.take(3).toList();
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gateProvider = Provider.of<GateProvider>(context);

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (gateProvider.status.toLowerCase().contains('aberto')) {
      statusColor = Colors.green;
      statusIcon = Icons.lock_open;
    } else if (gateProvider.status.toLowerCase().contains('fechado')) {
      statusColor = Colors.red;
      statusIcon = Icons.lock;
    } else if (gateProvider.status.toLowerCase().contains('movimento')) {
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Saudação
                  Text(
                    'Olá, ${_nomeUsuario ?? 'Usuário'}!',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Aqui está o resumo do seu sistema.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // Card de status do portão
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 48, color: statusColor),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status do Portão',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                              Text(
                                gateProvider.status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cards de estatísticas
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.bolt,
                                    size: 32, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text(
                                  '${_relatorio['total_acionamentos'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text('Total',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.smartphone,
                                    size: 32, color: Colors.green),
                                const SizedBox(height: 8),
                                Text(
                                  '${_relatorio['via_app'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text('Via App',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.record_voice_over,
                                    size: 32, color: Colors.purple),
                                const SizedBox(height: 8),
                                Text(
                                  '${_relatorio['via_alexa'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text('Alexa',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Últimos eventos
                  const Text('Últimos Eventos',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _ultimosLogs.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhum evento registrado ainda.',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : Column(
                          children: _ultimosLogs.map((log) {
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.history,
                                    color: Colors.blue),
                                title: Text(log['acao'] ?? ''),
                                subtitle: Text(
                                    '${log['origem']} — ${log['data_hora']}'),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 16),

                  // Botão de atalho
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/control'),
                      icon: const Icon(Icons.settings_remote),
                      label: const Text('Ir para Controle do Portão'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}