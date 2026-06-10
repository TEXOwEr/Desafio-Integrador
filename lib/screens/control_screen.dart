import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gate_provider.dart';
import '../widgets/custom_drawer.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gateProvider = Provider.of<GateProvider>(context);
    Color statusColor = gateProvider.status.toLowerCase().contains("aberto") ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text('Controle do Portão')),
      drawer: const CustomDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power_settings_new, size: 100, color: statusColor),
            const SizedBox(height: 20),
            Text(gateProvider.status.toUpperCase(), style: TextStyle(fontSize: 24, color: statusColor)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => gateProvider.triggerGate(),
              child: const Text('ACIONAR PORTÃO', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}