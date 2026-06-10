# Portão IoT — Sistema de Controle Inteligente

Projeto desenvolvido como Desafio Integrador do curso de Engenharia de Software.
Sistema completo de automação residencial para controle de portão elétrico via
aplicativo mobile, comando de voz (Alexa) e monitoramento em tempo real.

---

## Visão Geral da Arquitetura
[Alexa] ──── Sinric Pro ────┐
├──── ESP32 ──── Relé ──── Motor do Portão
[App Flutter] ── HiveMQ ────┘        │
│                              └──── Reed Switches (sensores)
│
[API REST Node.js] ──── SQLite (banco de dados)

---

## Estrutura Física do Hardware

### Componentes utilizados

| Componente | Função |
|---|---|
| ESP32 | Microcontrolador principal com Wi-Fi integrado |
| Módulo Relé 5V | Simula o pressionamento da botoeira do motor |
| Reed Switch 1 | Detecta quando o portão está completamente fechado |
| Reed Switch 2 | Detecta quando o portão está completamente aberto |
| Carregador de celular (5V) | Alimentação do ESP32 via pino VIN |
| Jumpers | Conexão do relé à entrada de botoeira da placa do motor |

### Mapeamento de pinos do ESP32

| Pino | Componente | Descrição |
|---|---|---|
| D23 | Relé (IN) | Sinal de acionamento do relé |
| D32 | Reed Switch 1 | Sensor de portão fechado |
| D33 | Reed Switch 2 | Sensor de portão aberto |
| GND | Reed Switches | Terra compartilhado dos sensores |
| VIN | Carregador 5V | Alimentação externa |

### Diagrama de ligação
Carregador 5V ──── VIN (ESP32)
└── GND (ESP32)
ESP32 D23 ──── IN (Módulo Relé)
Relé COM  ──── GND da placa do motor
Relé NO   ──── BOT (botoeira) da placa do motor
ESP32 D32 ──── Terminal 1 (Reed Switch — Fechado)
ESP32 D33 ──── Terminal 1 (Reed Switch — Aberto)
ESP32 GND ──── Terminal 2 (ambos os Reed Switches)

### Observações importantes

- O ESP32 é alimentado por um carregador de celular comum (5V/1A mínimo)
  conectado diretamente ao pino VIN. Nunca utilize a saída de 12V da placa
  do motor para alimentar o ESP32, pois ultrapassa o limite suportado.
- Os reed switches utilizam o resistor interno de pull-up do ESP32
  (INPUT_PULLUP), dispensando resistores externos.
- A lógica do relé funciona como contato seco: ao atracar por 500ms,
  simula exatamente o clique do controle remoto original do portão.
- Os jumpers do relé são inseridos nos bornes GND e BOT da placa do motor,
  sem nenhuma modificação no circuito original.

---

## Configuração do Hardware (ESP32)

### Pré-requisitos

- Arduino IDE 2.x instalada
- Suporte ao ESP32 instalado via Gerenciador de Placas
  (URL: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`)

### Bibliotecas necessárias

Instale via **Sketch > Incluir Biblioteca > Gerenciar Bibliotecas**:

| Biblioteca | Autor |
|---|---|
| PubSubClient | Nick O'Leary |
| SinricPro | Boris Lovosevic |

### Variáveis a configurar no código

Abra o arquivo `.ino` e preencha as seguintes constantes:

```cpp
// Wi-Fi
const char* ssid     = "NOME_DA_SUA_REDE";
const char* password = "SENHA_DA_SUA_REDE";

// HiveMQ Cloud
const char* mqtt_server = "SEU_CLUSTER.s1.eu.hivemq.cloud";
const char* mqtt_user   = "SEU_USUARIO";
const char* mqtt_pass   = "SUA_SENHA";

// Sinric Pro
#define APP_KEY    "SUA_APP_KEY"
#define APP_SECRET "SEU_APP_SECRET"
#define SWITCH_ID  "SEU_DEVICE_ID"
```

### Upload

1. Conecte o ESP32 via cabo USB
2. Selecione a placa: **ESP32 Dev Module**
3. Selecione a porta COM correspondente
4. Clique em **Upload**
5. Abra o Serial Monitor (115200 baud) e confirme as mensagens:
   - `Wi-Fi Conectado com sucesso!`
   - `Conectado ao HiveMQ!`

---

## Configuração da API (Node.js)

### Pré-requisitos

- Node.js v18 ou superior instalado

### Instalação

```bash
# Entre na pasta da API
cd api

# Instale as dependências
npm install

# Inicie o servidor
node server.js
```

O servidor iniciará em `http://localhost:3000`.
O arquivo `database.db` será criado automaticamente na primeira execução.

### Endpoints disponíveis

| Método | Rota | Autenticação | Descrição |
|---|---|---|---|
| POST | /api/cadastro | Não | Cadastra novo usuário |
| POST | /api/login | Não | Autentica e retorna token JWT |
| POST | /api/logs | Bearer Token | Registra evento de acionamento |
| GET | /api/historico | Bearer Token | Retorna histórico completo |
| GET | /api/relatorio | Bearer Token | Retorna estatísticas agregadas |

### Estrutura do banco de dados

**Tabela: usuarios**

| Campo | Tipo | Descrição |
|---|---|---|
| id | INTEGER PK | Identificador único |
| nome | TEXT | Nome do usuário |
| email | TEXT UNIQUE | E-mail de acesso |
| senha | TEXT | Hash bcrypt da senha |
| criado_em | DATETIME | Data de cadastro |

**Tabela: eventos_portao**

| Campo | Tipo | Descrição |
|---|---|---|
| id | INTEGER PK | Identificador único |
| usuario_id | INTEGER FK | Referência ao usuário |
| acao | TEXT | Descrição da ação |
| origem | TEXT | App, Alexa ou ESP32 |
| data_hora | DATETIME | Timestamp do evento |

---

## Configuração do Aplicativo (Flutter)

### Pré-requisitos

- Flutter SDK 3.x instalado
- Android Studio ou VS Code com extensão Flutter
- Emulador Android configurado ou dispositivo físico

### Instalação

```bash
# Entre na pasta do aplicativo
cd portao_iot

# Instale as dependências
flutter pub get

# Execute o aplicativo
flutter run
```

### Configuração do endereço da API

Abra `lib/services/api_service.dart` e ajuste a URL conforme o ambiente:

```dart
// Para emulador Android
static const String baseUrl = 'http://10.0.2.2:3000/api';

// Para dispositivo físico na mesma rede
static const String baseUrl = 'http://192.168.X.X:3000/api';
```

### Telas do aplicativo

| Tela | Rota | Descrição |
|---|---|---|
| Login | / | Autenticação do usuário |
| Cadastro | /cadastro | Criação de nova conta |
| Dashboard | /dashboard | Resumo de status e últimos eventos |
| Controle | /control | Acionamento do portão em tempo real |
| Logs | /logs | Histórico completo de eventos |
| Relatórios | /report | Estatísticas agregadas por origem |

---

## Configuração da Alexa (Sinric Pro)

1. Acesse [sinric.pro](https://sinric.pro) e crie uma conta
2. Em **Devices**, adicione um novo dispositivo do tipo **Switch**
3. Nomeie como **Portão** (ou o nome que preferir falar para a Alexa)
4. Copie a **App Key**, **App Secret** e **Device ID** para o código do ESP32
5. No aplicativo da Amazon Alexa, vá em **Skills e Jogos**
6. Busque por **Sinric Pro** e ative a skill
7. Faça login com sua conta do Sinric Pro
8. Diga **"Alexa, descobrir meus dispositivos"**
9. O portão aparecerá na lista de dispositivos

**Comando de voz:** `"Alexa, ligar o portão"`

---

## Fluxo de funcionamento
Usuário abre o app
│
▼
Tela de Login ──── API REST ──── Valida credenciais no SQLite
│
▼ (token JWT salvo)
Dashboard ──── Mostra status em tempo real via MQTT
│
▼
Controle ──── Botão ACIONAR ──── HiveMQ ──── ESP32 ──── Relé ──── Motor
│
└──── API REST ──── Registra evento no SQLite
│
▼
Reed Switches detectam posição final
│
▼
ESP32 publica status ──── HiveMQ ──── App atualiza ícone em tempo real

---

## Dependências do projeto

### API (Node.js)

| Pacote | Versão | Função |
|---|---|---|
| express | ^4.x | Framework HTTP |
| sqlite3 | ^5.x | Banco de dados |
| bcryptjs | ^2.x | Hash de senhas |
| jsonwebtoken | ^9.x | Autenticação JWT |
| cors | ^2.x | Liberação de origens |

### Aplicativo (Flutter)

| Pacote | Versão | Função |
|---|---|---|
| provider | ^6.1.2 | Gerenciamento de estado |
| mqtt5_client | ^3.0.0 | Comunicação MQTT |
| http | ^1.2.0 | Consumo da API REST |
| shared_preferences | ^2.2.2 | Persistência local do token |

---