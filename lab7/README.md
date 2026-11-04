# Lab 7 · Run it on a cluster

GitHub user: ankitamandlik5-web · Fallback image used: yes

## 1 · Deploy

- 🔮 Before my first `apply`: how many Pods, and what their names start with? I predicted **3 Pods** and their names would start with **`api-` followed by the ReplicaSet hash** because **the Deployment spec has `replicas: 3`, and Kubernetes automatically appends the ReplicaSet hash and a random suffix to Pod names**. What happened: **It matched my prediction perfectly. 3 Pods were created.**

```text
$ kubectl -n course get deploy,rs,pods
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api   3/3     3            3           45s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/api-5b9d8f7c4    3         3         3       45s

NAME                           READY   STATUS    RESTARTS   AGE
pod/api-5b9d8f7c4-4x2kq        1/1     Running   0          45s
pod/api-5b9d8f7c4-9wmzp        1/1     Running   0          45s
pod/api-5b9d8f7c4-x7n5v        1/1     Running   0          45s

$ curl -s localhost:8080/
{"name":"course-api","version":"0.1.0"}
```
## 2 · Heal and scale

$ kubectl -n course get pods        (after the delete)
NAME                           READY   STATUS    RESTARTS   AGE
pod/api-5b9d8f7c4-4x2kq        1/1     Running   0          5m
pod/api-5b9d8f7c4-9wmzp        1/1     Running   0          5m
pod/api-5b9d8f7c4-v6t9r        1/1     Running   0          3s  <-- NEW POD

$ kubectl -n course get pods        (with replicas: 5)
NAME                           READY   STATUS    RESTARTS   AGE
pod/api-5b9d8f7c4-4x2kq        1/1     Running   0          6m
pod/api-5b9d8f7c4-9wmzp        1/1     Running   0          6m
pod/api-5b9d8f7c4-v6t9r        1/1     Running   0          3m
pod/api-5b9d8f7c4-k2m4x        1/1     Running   0          3s
pod/api-5b9d8f7c4-p8n2v        1/1     Running   0          3s

## 3 · Roll and roll back

$ kubectl -n course rollout status deployment/api
deployment "api" successfully rolled out

$ kubectl -n course get pods        (during the stall)
NAME                   READY   STATUS             RESTARTS   AGE
api-79f6f549cf-hm86d   1/1     Running            0          30m
api-79f6f549cf-hz6d8   1/1     Running            0          30m
api-79f6f549cf-xzpq2   1/1     Running            0          30m
api-85fbbc455c-smjjl   0/1     ImagePullBackOff   0          2m

$ kubectl -n course rollout undo deployment/api
deployment.apps/api rolled back

## 4 · What broke and how I found it

- 🔮 Before applying the teammate's branch, I expected this to go wrong first: ____

| # | What I saw | The command, and the line of output that showed it | My fix (commit) |
|--:|------------|-----------------------------------------------------|-----------------|
| 1 | One Pod stuck in ImagePullBackOff while the 3 old Pods stayed running. | kubectl -n course describe pod <pod-name> showed: Failed to pull image "ghcr.io/martinsturiba/turiba-devops-labs/api:0.2.O": not found | fix(k8s): correct image tag typo from 0.2.O to 0.2.0 |
| 2 | Port-forward hung, and curl failed. The Service couldn't find the pods. | kubectl -n course get endpointslices -l kubernetes.io/service-name=api returned <none>. The Service selector was app.kubernetes.io/name: api, but Pods were app: api. | fix(k8s): correct service selector to match pod labels |
| 3 | curl returned Empty reply from server and connection refused. | The port-forward output showed connection refused. The targetPort in the service was 8080, but the API listens on 5000. | fix(k8s): correct targetPort to 5000 |
