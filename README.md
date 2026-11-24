# Arena IFAL — Jogos Internos

Sistema web para organizar os jogos internos de uma escola: modalidades, turmas, equipes, atletas, inscrições, partidas, placares e classificação.
Projeto Integrado (Banco de Dados + POO + Programação Web) — IFAL Campus Maceió.

Stack: Node.js, Express, EJS, MySQL 8 (mysql2), bcryptjs, cookie-parser.

## Como executar

### No GitHub Codespaces (recomendado)

1. Suba o projeto para o GitHub e abra em um Codespace (Code → Codespaces → Create).
2. O `.devcontainer` sobe o Node e o MySQL e já roda `npm install` e `npm run db:reset` sozinho.
3. No terminal do Codespace: `npm start`
4. Abra a porta 3000 (o Codespaces avisa e abre o navegador).

Se o banco precisar ser recriado a qualquer momento: `npm run db:reset`

### Na sua máquina

1. Tenha o MySQL 8 rodando (ou `docker compose up -d` na raiz do projeto).
2. `cp .env.example .env` e ajuste usuário e senha do MySQL.
3. `npm install`
4. `npm run db:reset`
5. `npm start` e acesse http://localhost:3000

## API simples + front-end estático (projeto2.js + projeto.html)

Além da aplicação completa (EJS + sessões + relatórios), o repositório inclui uma implementação leve e autossuficiente dos três cadastros exigidos pelo enunciado (Atleta, Equipe e Partida com placar/classificação):

- `projeto1.sql` — banco de dados (7 tabelas, 70 registros e 8 consultas com JOIN/GROUP BY).
- `projeto2.js` — back-end Express com API JSON em `/api/*`, pool de conexões, CORS e serve do `projeto.html`.
- `projeto.html` — front-end de página única (vanilla HTML/JS) que consome a API.

### Como executar apenas a API simples

1. Tenha o MySQL 8 rodando (ou `docker compose up -d` na raiz).
2. `cp .env.example .env` e ajuste usuário e senha do MySQL.
3. `npm install`
4. Importe o banco: `mysql -u root -p jogos_internos < projeto1.sql`
5. `npm run api` → sobe a API e o front-end em http://localhost:3000
6. Abra http://localhost:3000 no navegador.

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

**Funcionalidades do tema**
1. Modalidades com mínimo e máximo de atletas.
2. Equipes por turma e modalidade, inscrição de atletas (tela Atletas na listagem de Equipes).
3. Partidas com data, horário, local e registro de placar (botão Placar).
4. Classificação por modalidade calculada por consulta SQL (pontos, J, V, E, D, pró, contra e saldo).
5. Relatórios: agenda do dia e vitórias por turma.

**Regras de negócio** (service + transação com bloqueio de linhas)
- Máximo de modalidades por atleta, configurável em Configuração.
- Equipe só joga com o número mínimo de atletas; o máximo da modalidade também é respeitado.
- Uma equipe não tem duas partidas sobrepostas; um local não recebe duas partidas ao mesmo tempo.
- As duas equipes de uma partida precisam ser da mesma modalidade e estar ativas.
- O atleta só defende equipes da própria turma.
- Vitória vale 3 pontos e empate vale 1.

## Roteiro rápido para a apresentação

1. Login com admin → Início (avisos de equipes incompletas e agenda de hoje).
2. Equipes → Atletas de uma equipe → inscrever atleta (mostrar erro de camisa repetida e de outra turma).
3. Partidas → Novo → tentar horário sobreposto (mensagem exata) → salvar uma válida.
4. Placar de uma partida → Classificação mudando → Vitórias por turma.
5. Remover uma turma com atletas (mensagem de vínculo) e tentar o formulário de atleta com e-mail inválido.
6. Sair e mostrar que as telas exigem login; entrar como organizador e mostrar o acesso restrito.

## Git

```
git add .
git commit -m "Descreve o que foi feito"
git pull
git push
```
Sempre `pull` antes do `push`. Se houver conflito de merge, abra os arquivos marcados, escolha o trecho correto, remova os marcadores `<<<<<<<`, `=======`, `>>>>>>>`, depois `git add` e `git commit`.
