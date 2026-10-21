# Lab 4 · Multi-service app with Compose

GitHub user: ikaran34 · Reference files used (Lab 2 fallback): no

## Architecture

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
Which arrow crosses from your laptop into Docker: B → W (the published 8080:80 port mapping)

## Predictions
#	I predicted	What I saw	Match?	If not: why
P1	172.20.0.2 api api — name resolved	a(yes)	—	
P2	Connection refused on 5432	b(yes)	—	
P3	Todos still there after down + up	a(yes)	—	
P4	relation "todos" does not exist	c(yes)	—	
P5	HTTP/1.1 500 while db stopped; 200 after db up	a(yes)	—	
P6	Browser can't resolve api (only web sees it internally)	b(yes)	—	
## Backup and restore
(Paste the terminal output of the backup block here, from mkdir -p backup to the last curl)

Why the restore must run before api starts: The API's ensureSchema() creates the todos table on startup. If api starts first, it creates an empty table. When the dump tries to restore CREATE TABLE todos, it fails because the table already exists. Restoring before api starts means the dump creates the table, and api sees it already there.

## Compose clinic
c2
Error line: The stack started but curl localhost:8102 answered nothing. docker compose ps showed 0.0.0.0:3000->8102/tcp — the port mapping was inverted.

Checkpoint: port, on web

Fix: ports: - "8102:3000" in compose.yaml

Why this fix: nginx in c2 listens on 3000. The starter had 3000:8102, mapping host 3000 → container 8102. Nothing listens on 8102, so the browser gets an empty reply.

Hints used: 0

c3
Error line: nginx: [emerg] host not found in upstream "api" in /etc/nginx/conf.d/default.conf:6

Checkpoint: name, from web

Fix: networks: [front, back] on api (was [back] only)

Why this fix: web is on front, api only on back. Docker's DNS answers names only between containers on a shared network.

Hints used: 0

c4
Error line: browser console shows GET http://api:5000/api/todos net::ERR_NAME_NOT_RESOLVED

Checkpoint: path, from the browser

Fix: public/app.js line 2 changed to const API = '/api/todos';

Why this fix: the browser runs on the laptop, which can't resolve api. Using /api/todos goes through nginx on port 8104, which is on the same network as api.

Hints used: 0

c5
Error line: no error message — the stack runs fine, but the todo disappears after down and up.

Checkpoint: data, on db

Fix: volumes: - pgdata:/var/lib/postgresql/data added to the db service.

Why this fix: without a named volume mounted at /var/lib/postgresql/data, PostgreSQL writes to the container's writable layer, which is deleted on down.

Hints used: 0

## Run in one command
bash
git clone https://github.com/ikaran34/turiba-devops-labs.git && cd turiba-devops-labs
cp .env.example .env
docker compose up -d --wait
Open http://localhost:8080

## Answers
What does docker compose up do differently than docker run?
docker compose up reads the YAML file and starts all services (web, api, db) in the right order, creates the networks and volumes, and handles the port mappings. docker run only starts one container and you have to manually wire everything.

What is the purpose of the front and back networks?
They isolate the services. The web frontend only needs to talk to the api, so it's on front. The api talks to both web and db, so it's on front and back. The db only talks to api, so it's only on back. This prevents web from talking directly to db.

Why must the restore run before api starts?
The API's ensureSchema() creates the todos table on startup. If api starts first, it creates an empty table. When the dump tries to restore CREATE TABLE todos, it fails because the table already exists. Restoring before api starts means the dump creates the table, and api sees it already there.

What happens if you run docker compose down -v?
The -v flag deletes the named volumes. Since pgdata is a named volume, all data in the database is permanently deleted. Running down without -v keeps the volume and the data.
