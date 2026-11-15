# Lab 8 · Run the whole app

GitHub user: ankitamandlik5-web · Fallback image used: no · Fallback Mission 7 files used: no

<!-- Keep every heading as it is: the grader finds the sections by name. Replace every blank (four underscores). Paste command output inside the ```text blocks. Never paste your password, not even the base64 form. -->

## Part 0 · Sync, cluster

- Lab 8 sync PR merged: yes (`chore/sync-upstream` → PR merged on GitHub, merge commit `03dbcde`)
- Mission 7 starting point: my own Mission 7 files (`00-namespace.yaml`, `api-deployment.yaml`, `api-service.yaml`)
- Fallback Mission 7 files used: no
- API image: `ghcr.io/martinsturiba/turiba-devops-labs/api:0.2.0` (pinned tag, never `latest`)

Starting point:

```text
$ kubectl -n course get pods
NAME                   READY   STATUS    RESTARTS   AGE
api-7ff476cc44-4cxm2   1/1     Running   0          18m
api-7ff476cc44-gq67q   1/1     Running   0          18m
api-7ff476cc44-lnglc   1/1     Running   0          18m
```

## 1 · Database with storage

- 🔮 Before deleting the database Pod: will your todo still be there afterwards? I predicted **yes** because **PostgreSQL stores its data in the PVC `db-data` (`/var/lib/postgresql/data`), not in the container filesystem. A new Pod mounts the same claim, so the rows survive the Pod being replaced.** What happened: **the todo was still listed after the new `db` Pod came up.** The first `GET` after the replacement returned `500` once while the API reconnected; the second `GET` listed the todo.
$ kubectl -n course get pvc,pv
NAME                            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/db-data   Bound    pvc-37820898-039f-4b10-9e6c-95caf22c5a99   1Gi        RWO            standard       <unset>                 120m

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM            STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/pvc-37820898-039f-4b10-9e6c-95caf22c5a99   1Gi        RWO            Delete           Bound    course/db-data   standard       <unset>                          120m

$ curl -s -X POST -H 'Content-Type: application/json' -d '{"title":"survive a restart"}' localhost:8080/api/todos
{"id":1,"title":"survive a restart","done":false,"created_at":"2026-11-15T14:15:50.247Z"}

$ curl -s -X POST -H 'Content-Type: application/json' -d '{"title":"second survive test"}' localhost:8080/api/todos
{"id":2,"title":"second survive test","done":false,"created_at":"2026-11-15T14:36:35.977Z"}

$ kubectl -n course get pods -l app=db        (before the delete)
NAME                  READY   STATUS    RESTARTS   AGE
db-864878fdcf-85hkh   1/1     Running   0          20m

$ kubectl -n course delete pod -l app=db
pod "db-864878fdcf-85hkh" deleted from course namespace

$ kubectl -n course get pods -l app=db        (after the delete)
NAME                  READY   STATUS    RESTARTS   AGE
db-864878fdcf-nl89w   1/1     Running   0          6s

$ curl -s localhost:8080/api/todos
[{"id":1,"title":"survive a restart","done":false,"created_at":"2026-11-15T14:15:50.247Z"},{"id":2,"title":"second survive test","done":false,"created_at":"2026-11-15T14:36:35.977Z"}]


## 2 · Connect the API
```text
$ kubectl -n course logs deployment/api -c wait-for-db
Found 3 pods, using pod/api-57679498f6-skn58
db:5432 - no response
waiting for the database
db:5432 - accepting connections

$ kubectl -n course logs deployment/api -c api
Found 3 pods, using pod/api-57679498f6-skn58
course-api 0.1.0 starting (Node.js v24.22.0)
API listening on port 5000
Database ready
Database connection lost: terminating connection due to administrator command

- 🔮 Before looking: will `kubectl -n course get secret db-secret -o yaml` show your password? I predicted ____ because ____. What I saw, in words (don't paste the value): ____

## 3 · Health and resources

**What I added:**

- `api`: `readinessProbe` and `livenessProbe` on `httpGet /healthz:5000` (liveness `initialDelaySeconds: 10`); `requests` cpu/memory, `limits` cpu/memory.
- `postgres`: `readinessProbe` and `livenessProbe` using `exec pg_isready -h localhost -U todo -d todo` (liveness `initialDelaySeconds: 30`); `requests` and `limits`.

Why `-h localhost`: on its first start PostgreSQL runs a temporary server that does not listen on TCP; `-h localhost` forces `pg_isready` to check over TCP, so it only passes when the real server is ready.

### Probes as configured

```text
$ kubectl -n course describe pod -l app=api | grep -A2 -i "readiness\|liveness"
    Liveness:   http-get http://:5000/healthz delay=10s timeout=1s period=10s successThreshold=1 failureThreshold=3
    Readiness:  http-get http://:5000/healthz delay=0s timeout=1s period=5s successThreshold=1 failureThreshold=3
    Environment Variables from:
      app-config  ConfigMap  Optional: false
    ```  
$ kubectl -n course get pods -l app=api       (about a minute later)
NAME                   READY   STATUS    RESTARTS      AGE
api-84d76fb6c8-qbncp   1/1     Running   1 (29s ago)   70s
api-84d76fb6c8-xv8kk   1/1     Running   1 (22s ago)   62s
api-84d76fb6c8-zn6q9   1/1     Running   1 (18s ago)   58s
- How I made Git and the cluster agree again afterwards: ____

## 4 · What broke and how I found it

- 🔮 Before applying the teammate's branch, I expected this to go wrong first: ____

| # | What I saw | The command, and the line of output that showed it | My fix (commit) |
|--:|------------|-----------------------------------------------------|-----------------|
| 1 | ____ | ____ | ____ |
| 2 | ____ | ____ | ____ |
| 3 | ____ | ____ | ____ |
