import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder<String?>(
            future: ApiService.getNome(),
            builder: (context, snapshot) {
              final nome = snapshot.data ?? 'Usuário';
              return DrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.home_work, color: Colors.white, size: 48),
                    const SizedBox(height: 10),
                    const Text('Portão IoT',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    Text(nome,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_remote),
            title: const Text('Controle do Portão'),
            onTap: () => Navigator.pushReplacementNamed(context, '/control'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Logs e Histórico'),
            onTap: () => Navigator.pushReplacementNamed(context, '/logs'),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Relatórios'),
            onTap: () => Navigator.pushReplacementNamed(context, '/report'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ApiService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}