import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/api_service.dart';

class GateProvider with ChangeNotifier {
  String _status = 'Aguardando conexão...';
  bool _isLoading = false;
  final MqttService _mqttService = MqttService();

  String get status => _status;
  bool get isLoading => _isLoading;

  GateProvider() {
    _initMqtt();
  }

  Future<void> _initMqtt() async {
    _mqttService.onStatusUpdate = (String novoStatus) {
      _status = novoStatus;
      _isLoading = false;
      notifyListeners();
    };
    await _mqttService.connect();
  }

  void triggerGate() async {
    _isLoading = true;
    notifyListeners();

    _mqttService.sendCommand('ACIONAR');

    // Registra o acionamento no banco via API REST
    await ApiService.registrarEvento('Portão acionado', 'App');

    Future.delayed(const Duration(seconds: 4), () {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }
}