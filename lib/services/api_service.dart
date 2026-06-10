import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 10.0.2.2 é o endereço do localhost visto pelo emulador Android
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // ==========================================
  // AUTENTICAÇÃO
  // ==========================================
  static Future<Map<String, dynamic>> cadastrar(
      String nome, String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cadastro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'erro': 'Sem conexão com o servidor'};
    }
  }

  static Future<Map<String, dynamic>> login(
      String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': senha}),
      );
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nome', data['nome']);
      }
      return data;
    } catch (e) {
      return {'erro': 'Sem conexão com o servidor'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nome');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getNome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nome');
  }

  // ==========================================
  // EVENTOS
  // ==========================================
  static Future<void> registrarEvento(String acao, String origem) async {
    try {
      final token = await getToken();
      await http.post(
        Uri.parse('$baseUrl/logs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'acao': acao, 'origem': origem}),
      );
    } catch (e) {
      print('Erro ao registrar evento: $e');
    }
  }

  // ==========================================
  // HISTÓRICO
  // ==========================================
  static Future<List<dynamic>> getHistorico() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/historico'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // RELATÓRIO
  // ==========================================
  static Future<Map<String, dynamic>> getRelatorio() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/relatorio'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'erro': 'Sem conexão com o servidor'};
    }
  }
}