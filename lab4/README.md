# Lab 4 · Multi-service app with Compose

GitHub user: <you> · Reference files used (Lab 2 fallback): no

<!-- Keep every heading as it is: the grader finds the sections by name. Fill in every blank (four underscores) and your GitHub user name: check.sh writeup flags anything left. -->

## 1 · Architecture

```mermaid
flowchart LR
    B["Browser on your laptop"]
    subgraph front["network: front"]
        W["web: nginx :80"]
    end
    A["api :5000 · networks: front, back"]
    subgraph back["network: back"]
        D[("db :5432")]
    end
    V[("volume: pgdata")]
    B -->|"HTTP localhost:8080"| W
    W -->|"HTTP api:5000"| A
    A -->|"PostgreSQL db:5432"| D
    D --- V

Which arrow crosses from your laptop into Docker: __B → W (the published 8080:80 port mapping)__

## 2 · Predictions and what happened

Part 1: fill in "I predicted" (the letter and a one-line reason) before you write any YAML. Part 3: fill in the rest. A wrong prediction that you explain earns full marks.

| # | I predicted | What I saw (command → the deciding output line) | Match? | If not: why |
|---|-------------|--------------------------------------------------|--------|-------------|
| P1 | 172.20.0.2 api api — name resolved | a(yes) | ____ | |
| P2 | Connection refused on 5432 | b(yes) | ____ | |
| P3 | Todos still there after down + up | a(yes) | ____ | |
| P4 | relation "todos" does not exist | c(yes) | ____ | |
| P5 | HTTP/1.1 500 while db stopped; 200 after db up | a(yes) | ____ | |
| P6 | 	Browser can't resolve api (only web sees it internally) | b(yes) | ____ | |

## 3 · Backup and restore

Why the restore must run before api starts: The API's ensureSchema() creates the todos table on startup. If api starts first, it creates an empty table. When the dump tries to restore CREATE TABLE todos, it fails because the table already exists. Restoring before api starts means the dump creates the table, and api sees it already there.

## 4 · Compose clinic

### c1 (worked example)
- Error line (copied): `connect ECONNREFUSED 127.0.0.1:5432`
- Checkpoint: port, inside `api`
- Fix: `DB_HOST: db`
- Why this fix, and not the tempting one: inside `api`, `localhost` is `api` itself, and nothing listens on 5432 there. Docker's DNS answers `db` with the database container's address. Publishing `db`'s port would "work" by opening a door into the database.
- Hints used: 0

### c2
- Error line (copied): The stack started but `curl localhost:8102` answered nothing. `docker compose ps` showed `0.0.0.0:3000->8102/tcp` — the port mapping was inverted.
- Checkpoint: port, on `web`
- Fix: `ports: - "8102:3000"` in `compose.yaml`
- Why this fix, and not the tempting one: nginx in `c2` listens on 3000 (see `nginx.conf`). The starter had `3000:8102`, which maps host 3000 → container 8102. Nothing is listening on container 8102, so the browser sees an empty reply. The temptation is to `docker compose down && up` without changing the port, but that won't fix it: the mapping direction is the bug.
- Hints used: 0

### c3
- Error line (copied): `nginx: [emerg] host not found in upstream "api" in /etc/nginx/conf.d/default.conf:6`
- Checkpoint: name, from `web`
- Fix: `networks: [front, back]` on `api` (was `[back]` only)
- Why this fix, and not the tempting one: `web` is on `front`, `api` only on `back`. Docker's DNS answers names only between containers on a shared network. Removing the `proxy_pass http://api:5000;` line would make nginx start, but the app would return 404 for every `/api/` call — you'd have removed the feature to fix the bug.
- Hints used: 0

## 5 · Run in one command

```bash
git clone https://github.com/<you>/turiba-devops-labs.git && cd turiba-devops-labs
____
____
```


## 6 · Answers

### A1
In c1 the API logged `ECONNREFUSED 127.0.0.1:5432`. Which container was `127.0.0.1`, and why does `db` work instead?

____

### A2
Trace `POST /api/todos` from your browser to PostgreSQL: each hop, with the name and port used. Why does `db` have no `ports:`?

____

### A3
`docker compose down` kept your todos, and `docker compose down -v` deleted them. Where were they stored, and what exactly does `-v` remove?

____

### A4
With `db` stopped, `docker compose ps` showed `api` as healthy, but `/api/todos` answered 500. Explain both. What does `service_healthy` protect against, and what not?

____
