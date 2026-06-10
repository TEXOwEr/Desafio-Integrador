import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_drawer.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Map<String, dynamic> _dados = {};
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final dados = await ApiService.getRelatorio();

    setState(() {
      _carregando = false;
      if (dados.containsKey('erro')) {
        _erro = dados['erro'];
      } else {
        _dados = dados;
      }
    });
  }

  Widget _card(String titulo, String valor, IconData icone, Color cor) {
  return Card(
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 32, color: cor),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarRelatorio,
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
                      const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_erro!,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarRelatorio,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _card(
                          'Total de Acionamentos',
                          '${_dados['total_acionamentos'] ?? 0}',
                          Icons.bolt,
                          Colors.blue),
                      _card(
                          'Via Aplicativo',
                          '${_dados['via_app'] ?? 0}',
                          Icons.smartphone,
                          Colors.green),
                      _card(
                          'Via Alexa',
                          '${_dados['via_alexa'] ?? 0}',
                          Icons.record_voice_over,
                          Colors.purple),
                      _card(
                          'Via Sensor Físico',
                          '${_dados['via_sensor'] ?? 0}',
                          Icons.sensors,
                          Colors.orange),
                    ],
                  ),
                ),
    );
  }
}