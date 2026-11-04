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

- 3a: I rolled from the tag ____ to the tag ____.

```text
$ kubectl -n course rollout status deployment/api
____
```

- 3b: 🔮 With the tag 9.9.9, I predicted that ____ old Pods keep running, because ____. What happened: ____

```text
$ kubectl -n course get pods        (during the stall)
____

$ kubectl -n course rollout undo deployment/api
____
```

- What the `rollout undo` warning means, in my own words, and what I did so that Git and the cluster agree again: ____

## 4 · What broke and how I found it

- 🔮 Before applying the teammate's branch, I expected this to go wrong first: ____

| # | What I saw | The command, and the line of output that showed it | My fix (commit) |
|--:|------------|-----------------------------------------------------|-----------------|
| 1 | ____ | ____ | ____ |
| 2 | ____ | ____ | ____ |
| 3 | ____ | ____ | ____ |
