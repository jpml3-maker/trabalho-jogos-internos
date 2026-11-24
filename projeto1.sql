

CREATE DATABASE IF NOT EXISTS jogos_internos
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE jogos_internos;


DROP TABLE IF EXISTS PARTIDA;
DROP TABLE IF EXISTS INSCRICAO;
DROP TABLE IF EXISTS EQUIPE;
DROP TABLE IF EXISTS ATLETA;
DROP TABLE IF EXISTS MODALIDADE;
DROP TABLE IF EXISTS TURMA;
DROP TABLE IF EXISTS USUARIO;


CREATE TABLE USUARIO (
    id_usuario    INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    senha         VARCHAR(255) NOT NULL,
    perfil        VARCHAR(20) NOT NULL,
    CONSTRAINT chk_perfil CHECK (perfil IN ('COORDENADOR', 'ARBITRO'))
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
CREATE TABLE TURMA (
    id_turma      INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(20) NOT NULL,    -- ex: '912A', '922A'
    serie         VARCHAR(30) NOT NULL,
    turno         VARCHAR(20) NOT NULL,
    ano_letivo    YEAR NOT NULL
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
CREATE TABLE MODALIDADE (
    id_modalidade             INT AUTO_INCREMENT PRIMARY KEY,
    nome                      VARCHAR(80) NOT NULL UNIQUE,
    descricao                 TEXT,
    min_atletas               INT NOT NULL,
    max_atletas               INT NOT NULL,
    limite_modalidades_atleta INT NOT NULL,
    id_usuario                INT NOT NULL,
    CONSTRAINT chk_min_atletas      CHECK (min_atletas > 0),
    CONSTRAINT chk_max_min_atletas  CHECK (max_atletas >= min_atletas),
    CONSTRAINT fk_modalidade_usuario FOREIGN KEY (id_usuario)
        REFERENCES USUARIO (id_usuario)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
CREATE TABLE ATLETA (
    id_atleta        INT AUTO_INCREMENT PRIMARY KEY,
    nome             VARCHAR(100) NOT NULL,
    matricula        VARCHAR(30) NOT NULL UNIQUE,
    data_nascimento  DATE NOT NULL,
    ativo            BOOLEAN NOT NULL DEFAULT 1,
    id_turma         INT NOT NULL,
    CONSTRAINT fk_atleta_turma FOREIGN KEY (id_turma)
        REFERENCES TURMA (id_turma)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
CREATE TABLE EQUIPE (
    id_equipe      INT AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(100) NOT NULL,
    cor_uniforme   VARCHAR(50) NOT NULL,
    confirmada     BOOLEAN NOT NULL DEFAULT 0,
    id_modalidade  INT NOT NULL,
    id_turma       INT NOT NULL,
    CONSTRAINT uk_equipe_modalidade_turma UNIQUE (id_modalidade, id_turma),
    CONSTRAINT fk_equipe_modalidade FOREIGN KEY (id_modalidade)
        REFERENCES MODALIDADE (id_modalidade),
    CONSTRAINT fk_equipe_turma FOREIGN KEY (id_turma)
        REFERENCES TURMA (id_turma)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
CREATE TABLE INSCRICAO (
    id_atleta       INT NOT NULL,
    id_equipe       INT NOT NULL,
    data_inscricao  DATE NOT NULL,
    numero_camisa   INT NOT NULL,
    capitao         BOOLEAN NOT NULL DEFAULT 0,
    PRIMARY KEY (id_atleta, id_equipe),
    CONSTRAINT fk_inscricao_atleta FOREIGN KEY (id_atleta)
        REFERENCES ATLETA (id_atleta),
    CONSTRAINT fk_inscricao_equipe FOREIGN KEY (id_equipe)
        REFERENCES EQUIPE (id_equipe)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
CREATE TABLE PARTIDA (
    id_partida            INT AUTO_INCREMENT PRIMARY KEY,
    fase                  VARCHAR(50) NOT NULL,
    data_partida          DATE NOT NULL,
    hora_inicio           TIME NOT NULL,
    hora_fim              TIME NOT NULL,
    local_quadra          VARCHAR(80) NOT NULL,
    placar_mandante       INT,
    placar_visitante      INT,
    status_partida        VARCHAR(20) NOT NULL,
    id_equipe_mandante    INT NOT NULL,
    id_equipe_visitante   INT NOT NULL,
    id_usuario            INT NOT NULL,
    CONSTRAINT chk_hora_fim              CHECK (hora_fim > hora_inicio),
    CONSTRAINT chk_placar_mandante       CHECK (placar_mandante >= 0),
    CONSTRAINT chk_placar_visitante      CHECK (placar_visitante >= 0),
    CONSTRAINT chk_status_partida        CHECK (status_partida IN ('AGENDADA', 'EM_ANDAMENTO', 'FINALIZADA')),
    CONSTRAINT chk_equipes_diferentes    CHECK (id_equipe_mandante <> id_equipe_visitante),
    CONSTRAINT fk_partida_mandante FOREIGN KEY (id_equipe_mandante)
        REFERENCES EQUIPE (id_equipe),
    CONSTRAINT fk_partida_visitante FOREIGN KEY (id_equipe_visitante)
        REFERENCES EQUIPE (id_equipe),
    CONSTRAINT fk_partida_usuario FOREIGN KEY (id_usuario)
        REFERENCES USUARIO (id_usuario)
) ENGINE=InnoDB;


-- USUARIO
INSERT INTO USUARIO (nome, email, senha, perfil) VALUES
('João Coordenador',  'joao.coordenador@ifal.edu.br', 'senha123', 'COORDENADOR'),
('Maria Arbitragem',  'maria.arbitro@ifal.edu.br',    'senha123', 'ARBITRO'),
('Ana Paula Souza',   'ana.paula@ifal.edu.br',         'senha123', 'COORDENADOR'),
('Carlos Pereira',    'carlos.pereira@ifal.edu.br',    'senha123', 'ARBITRO'),
('Beatriz Lima',      'beatriz.lima@ifal.edu.br',      'senha123', 'COORDENADOR'),
('Daniel Oliveira',   'daniel.oliveira@ifal.edu.br',   'senha123', 'ARBITRO'),
('Fernanda Costa',    'fernanda.costa@ifal.edu.br',    'senha123', 'COORDENADOR'),
('Gustavo Santos',    'gustavo.santos@ifal.edu.br',    'senha123', 'ARBITRO'),
('Helena Almeida',    'helena.almeida@ifal.edu.br',    'senha123', 'COORDENADOR'),
('Igor Ribeiro',      'igor.ribeiro@ifal.edu.br',      'senha123', 'ARBITRO');

-- TURMA
INSERT INTO TURMA (nome, serie, turno, ano_letivo) VALUES
('912A',  '9º Ano',  'Manhã', 2026),
('922A',  '9º Ano',  'Tarde', 2026),
('811B',  '8º Ano',  'Manhã', 2026),
('822B',  '8º Ano',  'Tarde', 2026),
('713A',  '7º Ano',  'Manhã', 2026),
('723A',  '7º Ano',  'Tarde', 2026),
('1EM-A', '1ª Série EM', 'Manhã', 2026),
('1EM-B', '1ª Série EM', 'Tarde', 2026),
('2EM-A', '2ª Série EM', 'Manhã', 2026),
('2EM-B', '2ª Série EM', 'Tarde', 2026);

-- MODALIDADE
INSERT INTO MODALIDADE (nome, descricao, min_atletas, max_atletas, limite_modalidades_atleta, id_usuario) VALUES
('Futsal',           'Futsal de salão (5 jogadores de linha + goleiro)', 5, 12, 2, 1),
('Basquete',         'Basquete 5x5',                                     5, 10, 2, 1),
('Vôlei',            'Vôlei 6x6',                                        6, 12, 2, 2),
('Handebol',         'Handebol 7x7',                                     7, 14, 1, 2),
('Futsal Feminino',  'Futsal feminino',                                  5, 12, 2, 3),
('Xadrez',           'Xadrez individual',                                1,  2, 3, 3),
('Tênis de Mesa',    'Tênis de mesa',                                    1,  4, 3, 4),
('Atletismo',        'Provas de corrida e salto',                        1,  8, 3, 4),
('Badminton',        'Badminton de duplas',                              2,  4, 2, 5),
('Queimada',         'Queimada escolar',                                 6, 15, 2, 5);

-- ATLETA
INSERT INTO ATLETA (nome, matricula, data_nascimento, ativo, id_turma) VALUES
('Lucas Almeida',   '2026001', '2008-03-15', 1, 1),
('Mariana Souza',   '2026002', '2008-07-22', 1, 1),
('Pedro Santos',    '2026003', '2007-11-05', 1, 2),
('Juliana Pereira', '2026004', '2008-01-30', 1, 2),
('Gabriel Costa',   '2026005', '2007-05-18', 0, 3),
('Beatriz Lima',    '2026006', '2008-09-12', 1, 3),
('Felipe Oliveira', '2026007', '2007-12-03', 1, 4),
('Camila Rocha',    '2026008', '2008-04-25', 1, 4),
('Ricardo Alves',   '2026009', '2007-08-14', 1, 5),
('Tatiane Dias',    '2026010', '2008-06-19', 1, 5);

-- EQUIPE
INSERT INTO EQUIPE (nome, cor_uniforme, confirmada, id_modalidade, id_turma) VALUES
('Águias',  'Azul',   1, 1, 1),
('Tigres',  'Vermelho', 1, 1, 2),
('Leões',   'Amarelo', 0, 2, 1),
('Tubarões','Verde',   1, 3, 2),
('Falcons', 'Preto',   1, 2, 3),
('Raptors', 'Branco',  1, 4, 3),
('Bulls',   'Roxo',    0, 5, 4),
('Wolves',  'Laranja', 1, 3, 4),
('Sharks',  'Cinza',   1, 6, 5),
('Eagles',  'Dourado', 1, 1, 5);

-- INSCRICAO (relacionamento N:N com atributos)
INSERT INTO INSCRICAO (id_atleta, id_equipe, data_inscricao, numero_camisa, capitao) VALUES
(1, 1, '2026-03-10', 10, 1),
(2, 1, '2026-03-10', 11, 0),
(3, 2, '2026-03-10',  7, 1),
(4, 2, '2026-03-10',  8, 0),
(7, 3, '2026-03-11',  4, 1),
(6, 4, '2026-03-11',  1, 1),
(8, 4, '2026-03-11',  2, 0),
(1, 6, '2026-03-12',  5, 0),
(9, 9, '2026-03-12',  1, 1),
(10,10, '2026-03-12',  9, 0);

-- PARTIDA
INSERT INTO PARTIDA (fase, data_partida, hora_inicio, hora_fim, local_quadra,
                     placar_mandante, placar_visitante, status_partida,
                     id_equipe_mandante, id_equipe_visitante, id_usuario) VALUES
('1ª Fase', '2026-04-01', '08:00:00', '09:00:00', 'Quadra A',  NULL,  NULL, 'AGENDADA',   1, 2, 6),
('1ª Fase', '2026-04-01', '09:30:00', '10:30:00', 'Quadra B',  NULL,  NULL, 'AGENDADA',   3, 4, 6),
('1ª Fase', '2026-04-02', '08:00:00', '09:00:00', 'Quadra A',    2,    1, 'FINALIZADA', 5, 6, 7),
('1ª Fase', '2026-04-02', '09:30:00', '10:30:00', 'Quadra B',  NULL,  NULL, 'AGENDADA',   7, 8, 7),
('Semifinal','2026-04-05', '14:00:00', '15:00:00', 'Quadra A',  NULL,  NULL, 'AGENDADA',   1, 4, 8),
('Semifinal','2026-04-05', '15:30:00', '16:30:00', 'Quadra B',  NULL,  NULL, 'AGENDADA',   3,10, 8),
('Final',   '2026-04-10', '16:00:00', '17:00:00', 'Quadra A',  NULL,  NULL, 'AGENDADA',   2, 3, 2),
('1ª Fase', '2026-04-03', '10:00:00', '11:00:00', 'Quadra A',    0,    0, 'FINALIZADA', 6, 7, 9),
('1ª Fase', '2026-04-03', '11:30:00', '12:30:00', 'Quadra B',  NULL,  NULL, 'AGENDADA',   8, 9, 9),
('Semifinal','2026-04-06', '14:00:00', '15:00:00', 'Quadra A',  NULL,  NULL, 'AGENDADA',   4, 5, 10);


SELECT p.id_partida,
       p.fase,
       p.data_partida,
       p.hora_inicio,
       p.hora_fim,
       p.local_quadra,
       em.nome AS equipe_mandante,
       ev.nome AS equipe_visitante,
       p.placar_mandante,
       p.placar_visitante,
       p.status_partida,
       m.nome AS modalidade,
       u.nome AS arbitro
FROM PARTIDA p
INNER JOIN EQUIPE em ON p.id_equipe_mandante = em.id_equipe
INNER JOIN EQUIPE ev ON p.id_equipe_visitante = ev.id_equipe
INNER JOIN MODALIDADE m ON em.id_modalidade = m.id_modalidade
INNER JOIN USUARIO u ON p.id_usuario = u.id_usuario
ORDER BY p.data_partida, p.hora_inicio;

SELECT a.id_atleta,
       a.nome,
       a.matricula,
       a.data_nascimento,
       a.ativo,
       t.nome AS turma,
       t.serie,
       t.turno,
       t.ano_letivo
FROM ATLETA a
INNER JOIN TURMA t ON a.id_turma = t.id_turma
ORDER BY t.nome, a.nome;


SELECT i.id_atleta,
       at.nome AS atleta,
       i.id_equipe,
       eq.nome AS equipe,
       i.numero_camisa,
       i.capitao,
       i.data_inscricao
FROM INSCRICAO i
INNER JOIN ATLETA at ON i.id_atleta = at.id_atleta
INNER JOIN EQUIPE eq ON i.id_equipe = eq.id_equipe
ORDER BY eq.nome, i.numero_camisa;


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
ORDER BY pontos DESC, vitorias DESC, (gols_pro - gols_contra) DESC, gols_pro DESC;


SELECT m.nome AS modalidade,
       COUNT(eq.id_equipe) AS total_equipes,
       SUM(CASE WHEN eq.confirmada = 1 THEN 1 ELSE 0 END) AS confirmadas
FROM MODALIDADE m
LEFT JOIN EQUIPE eq ON eq.id_modalidade = m.id_modalidade
GROUP BY m.id_modalidade, m.nome
ORDER BY total_equipes DESC;


SELECT t.nome AS turma,
       t.serie,
       t.turno,
       COUNT(a.id_atleta) AS total_atletas,
       SUM(CASE WHEN a.ativo = 1 THEN 1 ELSE 0 END) AS ativos
FROM TURMA t
LEFT JOIN ATLETA a ON a.id_turma = t.id_turma
GROUP BY t.id_turma, t.nome, t.serie, t.turno
ORDER BY total_atletas DESC;


SELECT u.id_usuario,
       u.nome AS arbitro,
       u.perfil,
       COUNT(p.id_partida) AS total_partidas,
       SUM(CASE WHEN p.status_partida = 'FINALIZADA' THEN 1 ELSE 0 END) AS finalizadas
FROM USUARIO u
LEFT JOIN PARTIDA p ON p.id_usuario = u.id_usuario
GROUP BY u.id_usuario, u.nome, u.perfil
ORDER BY total_partidas DESC;


SELECT eq.id_equipe,
       eq.nome AS equipe,
       m.nome AS modalidade,
       COUNT(i.id_atleta) AS atletas_inscritos,
       SUM(CASE WHEN i.capitao = 1 THEN 1 ELSE 0 END) AS capitães
FROM EQUIPE eq
INNER JOIN MODALIDADE m ON eq.id_modalidade = m.id_modalidade
LEFT JOIN INSCRICAO i ON i.id_equipe = eq.id_equipe
GROUP BY eq.id_equipe, eq.nome, m.nome
ORDER BY eq.nome;

