require('dotenv').config();
const path = require('path');
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
const PORT = Number(process.env.PORT) || 3000;

app.use(cors());
app.use(express.json());

let pool;

async function initDb() {
  pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'jogos_internos',
    waitForConnections: true,
    connectionLimit: 10,
  });
  const conn = await pool.getConnection();
  conn.release();
  console.log('Conectado ao MySQL: jogos_internos');
}

initDb().catch(err => {
  console.error('Erro ao conectar ao MySQL:', err.message);
  process.exit(1);
});

async function query(sql, params = []) {
  const [rows] = await pool.query(sql, params);
  return rows;
}


app.get('/api/turmas', async (req, res) => {
  try {
    const rows = await query('SELECT id_turma, nome, serie, turno FROM TURMA ORDER BY nome');
    res.json(rows);
  } catch (err) { res.status(500).json({ erro: err.message }); }
});

app.get('/api/modalidades', async (req, res) => {
  try {
    const rows = await query('SELECT id_modalidade, nome FROM MODALIDADE ORDER BY nome');
    res.json(rows);
  } catch (err) { res.status(500).json({ erro: err.message }); }
});

app.get('/api/usuarios', async (req, res) => {
  try {
    const rows = await query("SELECT id_usuario, nome, perfil FROM USUARIO ORDER BY nome");
    res.json(rows);
  } catch (err) { res.status(500).json({ erro: err.message }); }
});


app.get('/api/atletas', async (req, res) => {
  try {
    const rows = await query(`
      SELECT a.id_atleta, a.nome, a.matricula, a.data_nascimento, a.ativo,
             t.id_turma, t.nome AS turma, t.serie, t.turno
      FROM ATLETA a
      INNER JOIN TURMA t ON a.id_turma = t.id_turma
      ORDER BY t.nome, a.nome
    `);
    res.json(rows);
  } catch (err) { res.status(500).json({ erro: err.message }); }
});

app.post('/api/atletas', async (req, res) => {
  try {
    const { nome, matricula, data_nascimento, ativo, id_turma } = req.body;
    if (!nome || !matricula || !data_nascimento || !id_turma) {
      return res.status(400).json({ erro: 'Preencha todos os campos obrigatórios.' });
    }
    const [result] = await pool.query(
      'INSERT INTO ATLETA (nome, matricula, data_nascimento, ativo, id_turma) VALUES (?, ?, ?, ?, ?)',
      [nome, matricula, data_nascimento, ativo !== undefined ? ativo : 1, id_turma]
    );
    res.status(201).json({ id_atleta: result.insertId, mensagem: 'Atleta cadastrado com sucesso.' });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ erro: 'Matrícula já cadastrada.' });
    res.status(500).json({ erro: err.message });
  }
});

app.delete('/excluirAtleta/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const inscricoes = await query('SELECT COUNT(*) AS total FROM INSCRICAO WHERE id_atleta = ?', [id]);
    if (inscricoes[0].total > 0) {
      return res.status(409).json({ erro: 'Não é possível excluir: atleta possui inscrições em equipes.' });
    }
    const [result] = await pool.query('DELETE FROM ATLETA WHERE id_atleta = ?', [id]);
    if (result.affectedRows === 0) return res.status(404).json({ erro: 'Atleta não encontrado.' });
    res.json({ mensagem: 'Atleta excluído com sucesso.' });
  } catch (err) { res.status(500).json({ erro: err.message }); }
});


app.get('/api/equipes', async (req, res) => {
  try {
    const rows = await query(`
      SELECT e.id_equipe, e.nome, e.cor_uniforme, e.confirmada,
             m.id_modalidade, m.nome AS modalidade,
             t.id_turma, t.nome AS turma
      FROM EQUIPE e
      INNER JOIN MODALIDADE m ON e.id_modalidade = m.id_modalidade
      INNER JOIN TURMA t ON e.id_turma = t.id_turma
      ORDER BY e.nome
    `);
    res.json(rows);
  } catch (err) { res.status(500).json({ erro: err.message }); }
});

app.post('/api/equipes', async (req, res) => {
  try {
    const { nome, cor_uniforme, confirmada, id_modalidade, id_turma } = req.body;
    if (!nome || !cor_uniforme || !id_modalidade || !id_turma) {
      return res.status(400).json({ erro: 'Preencha todos os campos obrigatórios.' });
    }
    const [result] = await pool.query(
      'INSERT INTO EQUIPE (nome, cor_uniforme, confirmada, id_modalidade, id_turma) VALUES (?, ?, ?, ?, ?)',
      [nome, cor_uniforme, confirmada ? 1 : 0, id_modalidade, id_turma]
    );
    res.status(201).json({ id_equipe: result.insertId, mensagem: 'Equipe cadastrada com sucesso.' });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ erro: 'Já existe equipe para esta modalidade/turma.' });
    res.status(500).json({ erro: err.message });
  }
});

app.delete('/excluirEquipe/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const inscricoes = await query('SELECT COUNT(*) AS total FROM INSCRICAO WHERE id_equipe = ?', [id]);
    if (inscricoes[0].total > 0) {
      return res.status(409).json({ erro: 'Não é possível excluir: equipe possui atletas inscritos.' });
    }
    const partidas = await query("SELECT COUNT(*) AS total FROM PARTIDA WHERE id_equipe_mandante = ? OR id_equipe_visitante = ?", [id, id]);
    if (partidas[0].total > 0) {
      return res.status(409).json({ erro: 'Não é possível excluir: equipe participa de partidas.' });
    }
    const [result] = await pool.query('DELETE FROM EQUIPE WHERE id_equipe = ?', [id]);
    if (result.affectedRows === 0) return res.status(404).json({ erro: 'Equipe não encontrada.' });
    res.json({ mensagem: 'Equipe excluída com sucesso.' });
  } catch (err) { res.status(500).json({ erro: err.message }); }
});


app.get('/api/partidas', async (req, res) => {
  try {
    const rows = await query(`
      SELECT p.id_partida, p.fase, p.data_partida, p.hora_inicio, p.hora_fim,
             p.local_quadra, p.placar_mandante, p.placar_visitante, p.status_partida,
             em.id_equipe AS id_equipe_mandante, em.nome AS equipe_mandante,
             ev.id_equipe AS id_equipe_visitante, ev.nome AS equipe_visitante,
             u.id_usuario, u.nome AS usuario
      FROM PARTIDA p
      INNER JOIN EQUIPE em ON p.id_equipe_mandante = em.id_equipe
      INNER JOIN EQUIPE ev ON p.id_equipe_visitante = ev.id_equipe
      INNER JOIN USUARIO u ON p.id_usuario = u.id_usuario
      ORDER BY p.data_partida, p.hora_inicio
    `);
    res.json(rows);
  } catch (err) { res.status(500).json({ erro: err.message }); }
});

app.post('/api/partidas', async (req, res) => {
  try {
    const { fase, data_partida, hora_inicio, hora_fim, local_quadra,
            placar_mandante, placar_visitante, status_partida,
            id_equipe_mandante, id_equipe_visitante, id_usuario } = req.body;
    if (!fase || !data_partida || !hora_inicio || !hora_fim || !local_quadra ||
        !status_partida || !id_equipe_mandante || !id_equipe_visitante || !id_usuario) {
      return res.status(400).json({ erro: 'Preencha todos os campos obrigatórios.' });
    }
    if (id_equipe_mandante == id_equipe_visitante) {
      return res.status(400).json({ erro: 'As equipes mandante e visitante devem ser diferentes.' });
    }
    const [result] = await pool.query(
      `INSERT INTO PARTIDA (fase, data_partida, hora_inicio, hora_fim, local_quadra,
        placar_mandante, placar_visitante, status_partida,
        id_equipe_mandante, id_equipe_visitante, id_usuario)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [fase, data_partida, hora_inicio, hora_fim, local_quadra,
       placar_mandante || null, placar_visitante || null, status_partida,
       id_equipe_mandante, id_equipe_visitante, id_usuario]
    );
    res.status(201).json({ id_partida: result.insertId, mensagem: 'Partida cadastrada com sucesso.' });
  } catch (err) { res.status(500).json({ erro: err.message }); }
});

app.put('/api/partidas/:id/placar', async (req, res) => {
  try {
    const { id } = req.params;
    const { placar_mandante, placar_visitante, status_partida } = req.body;
    if (placar_mandante == null || placar_visitante == null) {
      return res.status(400).json({ erro: 'Informe os placares de ambos os times.' });
    }
    if (placar_mandante < 0 || placar_visitante < 0) {
      return res.status(400).json({ erro: 'Placar não pode ser negativo.' });
    }
    const [result] = await pool.query(
      'UPDATE PARTIDA SET placar_mandante = ?, placar_visitante = ?, status_partida = ? WHERE id_partida = ?',
      [placar_mandante, placar_visitante, status_partida || 'FINALIZADA', id]
    );
    if (result.affectedRows === 0) return res.status(404).json({ erro: 'Partida não encontrada.' });
    res.json({ mensagem: 'Placar atualizado com sucesso.' });
  } catch (err) { res.status(500).json({ erro: err.message }); }
});

app.delete('/excluirPartida/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await pool.query('DELETE FROM PARTIDA WHERE id_partida = ?', [id]);
    if (result.affectedRows === 0) return res.status(404).json({ erro: 'Partida não encontrada.' });
    res.json({ mensagem: 'Partida excluída com sucesso.' });
  } catch (err) { res.status(500).json({ erro: err.message }); }
});



app.get('/api/classificacao', async (req, res) => {
  try {
    const rows = await query(`
      SELECT
        eq.id_equipe,
        eq.nome AS equipe,
        m.nome AS modalidade,
        COUNT(p.id_partida) AS jogos,
        SUM(CASE WHEN p.status_partida = 'FINALIZADA'
                  AND ((p.id_equipe_mandante = eq.id_equipe AND p.placar_mandante > p.placar_visitante)
                       OR (p.id_equipe_visitante = eq.id_equipe AND p.placar_visitante > p.placar_mandante))
                 THEN 1 ELSE 0 END) AS vitorias,
        SUM(CASE WHEN p.status_partida = 'FINALIZADA' AND p.placar_mandante = p.placar_visitante
                 THEN 1 ELSE 0 END) AS empates,
        SUM(CASE WHEN p.status_partida = 'FINALIZADA'
                  AND ((p.id_equipe_mandante = eq.id_equipe AND p.placar_mandante < p.placar_visitante)
                       OR (p.id_equipe_visitante = eq.id_equipe AND p.placar_visitante < p.placar_mandante))
                 THEN 1 ELSE 0 END) AS derrotas,
        SUM(CASE WHEN p.status_partida = 'FINALIZADA' THEN
          CASE
            WHEN (p.id_equipe_mandante = eq.id_equipe AND p.placar_mandante > p.placar_visitante)
              OR (p.id_equipe_visitante = eq.id_equipe AND p.placar_visitante > p.placar_mandante) THEN 3
            WHEN p.placar_mandante = p.placar_visitante THEN 1
            ELSE 0
          END
          ELSE 0 END) AS pontos,
        SUM(CASE WHEN p.id_equipe_mandante = eq.id_equipe THEN p.placar_mandante ELSE p.placar_visitante END) AS gols_pro,
        SUM(CASE WHEN p.id_equipe_mandante = eq.id_equipe THEN p.placar_visitante ELSE p.placar_mandante END) AS gols_contra
      FROM EQUIPE eq
      INNER JOIN MODALIDADE m ON eq.id_modalidade = m.id_modalidade
      LEFT JOIN PARTIDA p ON p.id_equipe_mandante = eq.id_equipe OR p.id_equipe_visitante = eq.id_equipe
      GROUP BY eq.id_equipe, eq.nome, m.nome
      ORDER BY pontos DESC, vitorias DESC, (gols_pro - gols_contra) DESC, gols_pro DESC
    `);
    res.json(rows);
  } catch (err) { res.status(500).json({ erro: err.message }); }
});

// Serve o front-end estático (projeto.html) na raiz — um único comando sobe API + UI
app.use(express.static(path.join(__dirname)));
app.get('/', (_req, res) => {
  res.sendFile(path.join(__dirname, 'projeto.html'));
});

app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
  console.log(`Abra http://localhost:${PORT} para usar o front-end`);
});

process.on('SIGINT', async () => {
  await pool.end();
  process.exit(0);
});
