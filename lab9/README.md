M# Lab 9 · Package it with Helm

GitHub user: ankitamandlik5-web · Fallback image used: no · Fallback Mission 8 files used: no

<!-- Keep every heading as it is: the grader finds the sections by name. Replace every blank (four underscores). Paste command output inside the ```text blocks. Never paste your password. -->

## 1 · The chart

```text
$ helm lint charts/course-app
==> Linting charts/course-app
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

$ helm template course-app charts/course-app -n course --set api.replicas=2 | grep -E 'replicas:|image:'
  replicas: 2
          image: postgres:17-alpine
          image: "ghcr.io/ankitamandlik5-web/turiba-devops-labs/api:0.2.0"
  replicas: 1
          image: postgres:17-alpine

____
```


- 🔮 Before running `helm template … --set api.replicas=2`: which lines of the output change, and which file decides that? I predicted ____ because ____. What happened: ____
- In my own words, why the Namespace and the Secret are **not** in the chart: ____

## 2 · Install, upgrade, rollback

```text
$ helm install course-app charts/course-app -n course
NAME: course-app
LAST DEPLOYED: Wed Nov 18 21:00:00 2026
NAMESPACE: course
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete

$ helm upgrade course-app charts/course-app -n course --set api.image.tag=does-not-exist
Release "course-app" has been upgraded. Happy Helming!
NAME: course-app
LAST DEPLOYED: Wed Nov 18 21:05:00 2026
NAMESPACE: course
STATUS: deployed
REVISION: 2

$ kubectl -n course get pods -l app=api        (about 30 seconds later)
NAME                   READY   STATUS             RESTARTS   AGE
api-54b6d4c8d7-5x8f9   1/1     Running            0          15m
api-54b6d4c8d7-7q2m3   1/1     Running            0          15m
api-54b6d4c8d7-9z4k1   1/1     Running            0          15m
api-7f8b9c6d5-2j4k1    0/1     ImagePullBackOff   0          30s

$ helm history course-app -n course        (before the rollback)
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         deployed    Upgrade complete

$ helm rollback course-app 1 -n course
Rollback was a success! Happy Helming!

$ helm history course-app -n course        (after the rollback)
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         deployed    Rollback to 1
____
```

- 🔮 Before the upgrade with a tag that doesn't exist: will `helm upgrade` say it failed? Will `GET /api/todos` still answer? I predicted ____ because ____. What happened: ____
- 🔮 Before the rollback: which revision number will `helm rollback course-app 1` create? I predicted ____ because ____. What happened: ____
- 🔮 Before `helm uninstall` and a new `helm install`: will your todo still be there? I predicted ____ because ____. What happened: ____

```text
$ curl -s localhost:8080/api/todos             (after uninstall and install)
[]
____
```

## 3 · What broke and how I found it

- 🔮 Before upgrading with the teammate's branch, I expected this to go wrong first: ____

| # | What I saw | The command, and the line of output that showed it | My fix (commit) |
|--:|------------|-----------------------------------------------------|-----------------|
| 1 | Helm failed immediately with nil pointer evaluating interface {}.repository | helm upgrade course-app charts/course-app -n course
Error: UPGRADE FAILED: ... at <.Values.api.images.repository>: nil pointer evaluating interface {}.repository | The template had .Values.api.images.repository (with an 's'), but values.yaml had image. I changed it back to .Values.api.image.repository. Commit: fix(chart): correct api.image.repository value name |
| 2 | Helm failed because it refused to take over the course namespace. | helm upgrade course-app charts/course-app -n course
Error: UPGRADE FAILED: unable to continue with update: Namespace "course" ... exists and cannot be imported ... invalid ownership metadata | The teammate added a namespace.yaml file. I deleted it with git rm. Commit: fix(chart): remove namespace from templates (created outside the release) |
| 3 | Helm said "deployed", but the API deployment only had 1 Pod running instead of 3. | kubectl -n course get deployment api
api 1/1 1 1 | The template asked for .Values.api.replicas, but the teammate changed values.yaml to say replicaCount. I changed it back to replicas. Commit: fix(chart): restore api.replicas value name |
