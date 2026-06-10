import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'dart:io';

class MqttService {
  final MqttServerClient client = MqttServerClient.withPort(
      'ec331e9044814f3688741a2d5efeda1f.s1.eu.hivemq.cloud', 
      'App_${DateTime.now().second}${DateTime.now().millisecond}', 
      8883);
  
  final String topicCommand = "fabricio/desafio/portao/comando";
  final String topicStatus = "fabricio/desafio/portao/status";

  final String mqttUser = "Portao";
  final String mqttPass = "Portao@123";

  Function(String)? onStatusUpdate;

  Future<void> connect() async {
    client.secure = true;
    client.keepAlivePeriod = 60;
    client.onDisconnected = onDisconnected;
    
    // Bypass universal
    client.onBadCertificate = (dynamic cert) => true;

    final SecurityContext context = SecurityContext.defaultContext;
    client.securityContext = context;
    
    // A sintaxe do Mqtt5 para conexão
    final connMess = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .authenticateAs(mqttUser, mqttPass)
        .startClean();
        
    client.connectionMessage = connMess;

    try {
      print('Flutter: Iniciando Mqtt5_client para HiveMQ Cloud...');
      await client.connect();
    } catch (e) {
      print('Flutter Erro de Conexão Mqtt5: $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Flutter: CONECTADO COM SUCESSO AO CLUSTER!');
      
      client.subscribe(topicStatus, MqttQos.atLeastOnce);
      
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String statusRecebido = MqttUtilities.bytesToStringAsString(recMess.payload.message!);
        
        print('Flutter: Novo Status Recebido -> $statusRecebido');
        if (onStatusUpdate != null) {
          onStatusUpdate!(statusRecebido);
        }
      });
    }
  }

  void sendCommand(String command) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttPayloadBuilder();
      builder.addString(command);
      client.publishMessage(topicCommand, MqttQos.atLeastOnce, builder.payload!);
      print('Flutter: Comando "$command" enviado.');
    } else {
      print('Flutter: Erro - Tentou enviar comando mas não está conectado.');
    }
  }

  void onDisconnected() {
    print('Flutter: Desconectado do broker MQTT.');
  }
}