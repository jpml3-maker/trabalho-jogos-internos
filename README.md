# Arena IFAL — Jogos Internos

Sistema web para organizar os jogos internos de uma escola: modalidades, turmas, equipes, atletas, inscrições, partidas, placares e classificação.
Projeto Integrado (Banco de Dados + POO + Programação Web) — IFAL Campus Maceió.

Stack: Node.js, Express, EJS, MySQL 8 (mysql2), bcryptjs, cookie-parser.


## API simples + front-end estático (projeto2.js + projeto.html)


- `projeto1.sql` — banco de dados (7 tabelas, 70 registros e 8 consultas com JOIN/GROUP BY).
- `projeto2.js` — back-end Express com API JSON em `/api/*`, pool de conexões, CORS e serve do `projeto.html`.
- `projeto.html` — front-end de página única (vanilla HTML/JS) que consome a API.



> `projeto2.js` lê as credenciais do `.env` (via `dotenv`). Não commite o `.env` — ele já está no `.gitignore`.

## Usuários de teste

| Perfil | E-mail | Senha |
|---|---|---|
| Administrador | admin@ifal.edu.br | admin123 |
| Organizador | organizador@ifal.edu.br | organiza123 |

O administrador acessa tudo. O organizador não acessa Modalidades, Turmas, Locais e Configuração.

## Estrutura

```
database/        DDL, povoamento e consultas do sistema
docs/            DER, modelo lógico e diagramas de classes (PNG e PDF)
scripts/         resetarBanco.js
src/
  config/        ambiente, pool de conexões e transação, menu
  models/        classes de modelo (encapsuladas) e hierarquia de usuários
  dao/           acesso ao banco (um DAO por entidade) e consultas de relatório
  services/      regras de negócio e transações
  controllers/   fluxo das telas (BaseController + um controller por cadastro)
  routes/        mapa de rotas
  middlewares/   sessão por cookies, avisos, tratamento de erros
  erros/         hierarquia de exceções e tradução dos erros do MySQL
  views/         telas EJS
  public/        CSS, JS e logotipo
```

Fluxo: rota → controller → service (regras e transação) → DAO → MySQL. Nenhuma rota ou tela contém SQL.

## Requisitos do enunciado

**Banco de dados**
- DER e modelo lógico em `docs/` (PNG e PDF).
- 9 tabelas: usuario, configuracao, turma, modalidade, local_jogo, atleta, equipe, inscricao, partida.
- 1:N (turma → atleta, turma → equipe, modalidade → equipe, local → partida) e N:N (atleta ↔ equipe pela tabela `inscricao`, com PK composta e atributos data, camisa e função). Partida tem duas FKs para equipe.
- PK, FK, NOT NULL, UNIQUE e CHECK em `database/01_criacao.sql`.
- Povoamento em `database/02_povoamento.sql`: 100 atletas, 16 equipes, 96 inscrições, 20 partidas, 10 turmas. As datas das partidas são relativas ao dia em que o script roda, então sempre há jogos hoje.
- Consultas com JOIN e GROUP BY usadas pelo sistema em `database/03_consultas_do_sistema.sql` (junções implícitas, no estilo das aulas).

**POO**
- Uma classe de modelo por entidade, com campos privados (`#`), getters e setters.
- Herança: `Usuario` (abstrata) → `Organizador` → `Administrador`, com comportamento diferente (`recursosPermitidos()`), criados por `UsuarioFabrica`. Também há herança em `Entidade` (modelos), `BaseDAO` e `BaseController`.
- Separação de responsabilidades em DAOs, services e controllers.
- Exceções: `ErroDeValidacao`, `ErroDeNegocio`, `ErroDeBanco`, `ErroDeAcesso`, `ErroNaoEncontrado`. Erros do MySQL (duplicidade, FK, CHECK) viram mensagens claras em `src/erros/traducaoBanco.js`.
- Diagramas de classes em `docs/`. Atualize se o código mudar.

**Web**
- Login com cookies assinados (usuário, perfil e situação de login); Sair apaga os cookies.
- Menu com e-mail do usuário e Sair.
- Listagens com Atualizar, Remover (com confirmação, rota `/excluirNomeCadastro/:id`) e Novo.
- Mesmo formulário para Novo e Atualizar. Equipe, Atleta e Partida têm 5 ou mais campos, campo de seleção, checkbox, validação no front-end e no back-end, botão Voltar e retorno ao formulário com dados preenchidos e a mensagem exata do erro.

