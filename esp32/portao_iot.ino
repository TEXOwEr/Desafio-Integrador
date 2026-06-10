#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
// Bibliotecas do Sinric Pro
#include <SinricPro.h>
#include <SinricProSwitch.h>

// ==========================================
// 1. CONFIGURAÇÕES DE REDE WI-FI
// ==========================================
const char* ssid = "VIVOFIBRA-6B61";
const char* password = "wnDiu5fxdE";

// ==========================================
// 2. CONFIGURAÇÕES DO HIVEMQ CLOUD (APP FLUTTER)
// ==========================================
const char* mqtt_server = "ec331e9044814f3688741a2d5efeda1f.s1.eu.hivemq.cloud";
const int mqtt_port = 8883; 
const char* mqtt_user = "Portao";
const char* mqtt_pass = "Portao@123";

const char* topico_comando = "fabricio/desafio/portao/comando";
const char* topico_status = "fabricio/desafio/portao/status";

// ==========================================
// 3. CONFIGURAÇÕES DO SINRIC PRO (ALEXA)
// ==========================================
// ATENÇÃO: Cole aqui as chaves geradas no site do Sinric Pro
#define APP_KEY           "662e4109-d3da-4dc8-abd7-55c8a6704696"
#define APP_SECRET        "6344ddca-50e0-41e3-9a8f-dae3c06c33be-9878f5f7-c0e0-4e4c-84a8-994396afa8d2"
#define SWITCH_ID         "6a289e48977a0619a757371f"

// ==========================================
// 4. MAPEAMENTO DE PINOS FÍSICOS
// ==========================================
const int RELAY_PIN = 23;      
const int SENSOR_FECHADO = 32; 
const int SENSOR_ABERTO = 33;  

WiFiClientSecure espClient;
PubSubClient client(espClient);

String estadoAtual = "Desconhecido";
unsigned long ultimoTempoSensores = 0;

// ==========================================
// FUNÇÃO DE CALLBACK DA ALEXA (SINRIC PRO)
// ==========================================
// Esta função é disparada sempre que você disser "Alexa, ligar portão"
bool onPowerState(const String &deviceId, bool &state) {
  Serial.printf("\n[ALEXA] Comando de voz recebido! Estado solicitado: %s\n", state ? "LIGAR" : "DESLIGAR");
  
  // Independentemente de ser "ligar" ou "desligar", o motor do portão 
  // só precisa de um pulso do relé para atracar.
  if (state) {
    acionarPortao();
  }
  return true; // Confirma para a Alexa que o comando foi executado
}

void setup() {
  Serial.begin(115200);
  
  // Configuração do Relé 
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); 
  
  // Configuração dos Sensores 
  pinMode(SENSOR_FECHADO, INPUT_PULLUP);
  pinMode(SENSOR_ABERTO, INPUT_PULLUP);

  setup_wifi();
  
  // --- INICIALIZAÇÃO DO HIVEMQ (FLUTTER) ---
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback_mqtt);
  client.setKeepAlive(60); 

  // --- INICIALIZAÇÃO DO SINRIC PRO (ALEXA) ---
  SinricProSwitch& meuPortaoAlexa = SinricPro[SWITCH_ID];
  meuPortaoAlexa.onPowerState(onPowerState);
  SinricPro.begin(APP_KEY, APP_SECRET);
}

void loop() {
  // 1. Processa a comunicação com o Flutter (HiveMQ)
  if (!client.connected()) {
    reconnect();
  }
  client.loop(); 
  
  // 2. Processa a comunicação com a Alexa em tempo real (Sinric Pro)
  SinricPro.handle(); 
  
  // 3. Lê os sensores físicos
  if (millis() - ultimoTempoSensores > 200) {
    monitorarSensores();
    ultimoTempoSensores = millis();
  }
}

// ==========================================
// FUNÇÕES DE REDE E MENSAGERIA (HIVEMQ)
// ==========================================

void setup_wifi() {
  delay(10);
  Serial.println("\nIniciando conexão Wi-Fi...");
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWi-Fi Conectado com sucesso!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

void callback_mqtt(char* topic, byte* payload, unsigned int length) {
  String mensagem = "";
  for (int i = 0; i < length; i++) {
    mensagem += (char)payload[i];
  }
  
  Serial.print("\n[FLUTTER] Mensagem recebida: " + mensagem);

  if (mensagem == "ACIONAR") {
    acionarPortao();
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("\nTentando conectar ao HiveMQ...");
    
    String clientId = "ESP32_Portao_";
    clientId += String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
      Serial.println(" Conectado ao HiveMQ!");
      client.subscribe(topico_comando);
      client.publish(topico_status, estadoAtual.c_str());
    } else {
      Serial.print(" Falhou. Erro = ");
      Serial.print(client.state());
      Serial.println(" Nova tentativa em 5 segundos...");
      delay(5000);
    }
  }
}

// ==========================================
// FUNÇÕES DE HARDWARE FÍSICO
// ==========================================

void acionarPortao() {
  Serial.println("\n-> Acionando o relé da placa do motor...");
  
  digitalWrite(RELAY_PIN, HIGH);
  delay(500); // Dá um pulso de meio segundo simulando o controle
  digitalWrite(RELAY_PIN, LOW);
  
  // Avisa o aplicativo Flutter que o portão foi acionado
  client.publish(topico_status, "Comando executado");
}

void monitorarSensores() {
  bool portaoFechado = (digitalRead(SENSOR_FECHADO) == LOW);
  bool portaoAberto = (digitalRead(SENSOR_ABERTO) == LOW);

  String novoEstado = estadoAtual;

  if (portaoFechado && !portaoAberto) {
    novoEstado = "Fechado";
  } else if (portaoAberto && !portaoFechado) {
    novoEstado = "Aberto";
  } else if (!portaoAberto && !portaoFechado) {
    novoEstado = "Em movimento";
  }

  // Só avisa a rede se o status realmente mudar
  if (novoEstado != estadoAtual) {
    estadoAtual = novoEstado;
    Serial.println("\nStatus atualizado: " + estadoAtual);
    
    // Envia o status para o aplicativo Flutter
    client.publish(topico_status, estadoAtual.c_str());
  }
}