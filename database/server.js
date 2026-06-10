const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const port = 3000;
const JWT_SECRET = 'portao_iot_secret_2026';

app.use(cors());
app.use(express.json());

// ==========================================
// BANCO DE DADOS
// ==========================================
const db = new sqlite3.Database('./database.db', (err) => {
  if (err) return console.error('Erro ao conectar:', err.message);
  console.log('Banco de dados SQLite conectado.');

  db.run(`CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    senha TEXT NOT NULL,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS eventos_portao (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id INTEGER,
    acao TEXT NOT NULL,
    origem TEXT NOT NULL,
    data_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
  )`);
});

// ==========================================
// MIDDLEWARE DE AUTENTICAÇÃO JWT
// ==========================================
function autenticar(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ erro: 'Token não fornecido' });

  jwt.verify(token, JWT_SECRET, (err, usuario) => {
    if (err) return res.status(403).json({ erro: 'Token inválido' });
    req.usuario = usuario;
    next();
  });
}

// ==========================================
// ROTAS DE AUTENTICAÇÃO
// ==========================================
app.post('/api/cadastro', async (req, res) => {
  const { nome, email, senha } = req.body;
  if (!nome || !email || !senha)
    return res.status(400).json({ erro: 'Nome, email e senha são obrigatórios' });

  const hash = await bcrypt.hash(senha, 10);
  db.run(`INSERT INTO usuarios (nome, email, senha) VALUES (?, ?, ?)`,
    [nome, email, hash],
    function (err) {
      if (err) return res.status(409).json({ erro: 'Email já cadastrado' });
      res.status(201).json({ mensagem: 'Usuário criado com sucesso', id: this.lastID });
    });
});

app.post('/api/login', (req, res) => {
  const { email, senha } = req.body;
  if (!email || !senha)
    return res.status(400).json({ erro: 'Email e senha são obrigatórios' });

  db.get(`SELECT * FROM usuarios WHERE email = ?`, [email], async (err, usuario) => {
    if (err || !usuario)
      return res.status(401).json({ erro: 'Credenciais inválidas' });

    const senhaCorreta = await bcrypt.compare(senha, usuario.senha);
    if (!senhaCorreta)
      return res.status(401).json({ erro: 'Credenciais inválidas' });

    const token = jwt.sign(
      { id: usuario.id, nome: usuario.nome, email: usuario.email },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(200).json({ mensagem: 'Login realizado', token, nome: usuario.nome });
  });
});

// ==========================================
// ROTAS DE EVENTOS (PROTEGIDAS)
// ==========================================
app.post('/api/logs', autenticar, (req, res) => {
  const { acao, origem } = req.body;
  if (!acao || !origem)
    return res.status(400).json({ erro: 'Ação e origem são obrigatórios' });

  db.run(`INSERT INTO eventos_portao (usuario_id, acao, origem) VALUES (?, ?, ?)`,
    [req.usuario.id, acao, origem],
    function (err) {
      if (err) return res.status(500).json({ erro: err.message });
      res.status(201).json({ mensagem: 'Evento registrado', id: this.lastID });
    });
});

app.get('/api/historico', autenticar, (req, res) => {
  db.all(`
    SELECT e.id, u.nome, e.acao, e.origem, e.data_hora
    FROM eventos_portao e
    LEFT JOIN usuarios u ON e.usuario_id = u.id
    ORDER BY e.data_hora DESC
  `, [], (err, rows) => {
    if (err) return res.status(500).json({ erro: err.message });
    res.status(200).json(rows);
  });
});

app.get('/api/relatorio', autenticar, (req, res) => {
  db.get(`
    SELECT
      COUNT(*) as total_acionamentos,
      SUM(CASE WHEN origem = 'App' THEN 1 ELSE 0 END) as via_app,
      SUM(CASE WHEN origem = 'Alexa' THEN 1 ELSE 0 END) as via_alexa,
      SUM(CASE WHEN origem = 'ESP32' THEN 1 ELSE 0 END) as via_sensor
    FROM eventos_portao
  `, [], (err, row) => {
    if (err) return res.status(500).json({ erro: err.message });
    res.status(200).json(row);
  });
});

// ==========================================
// ROTA RAIZ
// ==========================================
app.get('/', (req, res) => {
  res.send('<h1>API Portão IoT — Ativa</h1>');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`API rodando em http://localhost:${port}`);
});