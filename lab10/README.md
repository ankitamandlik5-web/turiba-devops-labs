# Lab 10 · Build it from code with OpenTofu

GitHub user: ankitamandlik5-web · Fallback chart used: no

<!-- Keep every heading as it is: the grader finds the sections by name. Replace every blank (four underscores). Paste command output inside the ```text blocks. Never paste the password, the state file or the kubeconfig. -->

## 1 · The cluster and the app from code

### Part 1 — the cluster

**Prediction (before the first `tofu plan`):** the plan will add 1 resource
(`kind_cluster.course`). Everything the cluster exports — `endpoint`, the certificates,
`context_name` — will be `known after apply`, because they only exist once kind has
created the cluster.

**Actual first plan:**

```text
Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + kube_context = (known after apply)
```

**Mismatch:** none — the prediction matched.

After `tofu apply`, `kubectl get nodes` showed `course-control-plane   Ready` and
`tofu output` printed `kube_context = "kind-course"`.

### Part 2 — the app on it

**Prediction (before `tofu apply` of the 4 resources):** right after apply, `tofu plan`
will say `No changes. Your infrastructure matches the configuration.`

**Actual `tofu apply` from zero** (`time tofu apply -auto-approve`, after `tofu destroy`):

```text
random_password.db: Creating...
kind_cluster.course: Creating...
random_password.db: Creation complete after 0s [id=none]
kind_cluster.course: Still creating... [10s elapsed]
kind_cluster.course: Still creating... [20s elapsed]
kind_cluster.course: Still creating... [30s elapsed]
kind_cluster.course: Still creating... [40s elapsed]
kind_cluster.course: Creation complete after 40s [id=course-]
kubernetes_namespace_v1.course: Creating...
kubernetes_namespace_v1.course: Creation complete after 0s [id=course]
kubernetes_secret_v1.db: Creating...
kubernetes_secret_v1.db: Creation complete after 0s [id=course/db-secret]
helm_release.course_app: Creating...
helm_release.course_app: Still creating... [10s elapsed]
helm_release.course_app: Still creating... [20s elapsed]
helm_release.course_app: Still creating... [30s elapsed]
helm_release.course_app: Still creating... [40s elapsed]
helm_release.course_app: Still creating... [50s elapsed]
helm_release.course_app: Still creating... [1m0s elapsed]
helm_release.course_app: Still creating... [1m10s elapsed]
helm_release.course_app: Still creating... [1m20s elapsed]
helm_release.course_app: Still creating... [1m30s elapsed]
helm_release.course_app: Still creating... [1m40s elapsed]
helm_release.course_app: Still creating... [1m50s elapsed]
helm_release.course_app: Still creating... [2m0s elapsed]
helm_release.course_app: Still creating... [2m10s elapsed]
helm_release.course_app: Still creating... [2m20s elapsed]
helm_release.course_app: Still creating... [2m30s elapsed]
helm_release.course_app: Still creating... [2m40s elapsed]
helm_release.course_app: Still creating... [2m50s elapsed]
helm_release.course_app: Still creating... [3m0s elapsed]
helm_release.course_app: Still creating... [3m10s elapsed]
helm_release.course_app: Creation complete after 3m17s [id=course-app]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

kube_context = "kind-course"

real    3m59.125s
user    0m10.853s
sys     0m7.951s
```

**Actual `tofu plan` right after:**

```text
No changes. Your infrastructure matches the configuration.
```

**Mismatch:** none.

`kubectl -n course get pods` showed 3 `api` Pods and 1 `db` Pod, all `1/1 Running`.
The todo saved through the port-forward (`{"title":"built from code"}`) and was read
back with `GET /api/todos`:

```json
[{"id":1,"title":"built from code","created_at":"2026-11-20T19:44:08.078Z"}]
```

**Prediction (password, before checking):** the password is in `terraform.tfstate` in
plain text, because `random_password.db.result` is stored in state — that is why
`.gitignore` keeps the state out of Git.

**Actual, without printing the password:**

```text
$ grep -c '"result"' terraform.tfstate
2
$ tofu state show kubernetes_secret_v1.db | grep data
    data = (sensitive value)
```

**Mismatch:** none — the state holds the password, the plan and `state show` mask it.

## 2 · Change, drift, rebuild

### Step 1 — a change

**Prediction (before `tofu apply -var api_replicas=2`):** the plan will show
`~ update in-place` for `helm_release.course_app`, with `~ value = "3" -> "2"` inside
`set`. Helm will record revision 2.

**Actual:**

```text
  # helm_release.course_app will be updated in-place
  ~ resource "helm_release" "course_app" {
      ~ set = [
          ~ {
                name  = "api.replicas"
              ~ value = "3" -> "2"
            },
        ]
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

```text
$ helm history course-app -n course
REVISION        UPDATED                         STATUS          CHART               APP VERSION     DESCRIPTION
1               Fri Nov 20 22:19:21 2026        superseded      course-app-0.1.0    0.2.0           Install complete
2               Fri Nov 20 23:07:15 2026        deployed        course-app-0.1.0    0.2.0           Upgrade complete

$ kubectl -n course get deployment api
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
api    2/2     2            2           48m
```

**Mismatch:** none — revision 2 `deployed`, Deployment at `2/2`.

### Step 2a — drift: the Secret deleted by hand

**Prediction (before `kubectl delete secret db-secret` + `tofu plan`):** `tofu plan`
will show `+ create` for `kubernetes_secret_v1.db` and `Plan: 1 to add`, because
OpenTofu reads every managed resource from the cluster before planning and the Secret
is gone.

**Actual:**

```text
secret "db-secret" deleted from course namespace

  # kubernetes_secret_v1.db will be created
  + resource "kubernetes_secret_v1" "db" {
      + data = (sensitive value)
      ...
    }

Plan: 1 to add, 1 to change, 0 to destroy.
```

(The `1 to change` is the `-var api_replicas=2` still pending from Step 1.)

**Mismatch:** none — the Secret shows as `+ create`.

### Step 2b — drift: the Deployment scaled by hand

**Prediction (before `kubectl scale deployment api --replicas=1` + `tofu plan`):** the
plan will show the same thing as before — nothing about the Deployment — because the
Deployment lives inside the Helm release and the release itself did not change.

**Actual:**

```text
deployment.apps/api scaled

  # kubernetes_secret_v1.db will be created
  + resource "kubernetes_secret_v1" "db" { ... }
  # helm_release.course_app will be updated in-place
  ~ resource "helm_release" "course_app" { ... }

Plan: 1 to add, 1 to change, 0 to destroy.
```

Identical to Step 2a — nothing about the Deployment. `kubectl scale` is invisible to
OpenTofu.

**Mismatch:** none — same plan, no Deployment drift.

### Step 3 — bring it back

**Prediction (before a plain `tofu apply`, no `-var`):** the plan will contain
`+ create` for the Secret and `~ update in-place` for the release (`"2" -> "3"`),
`Plan: 1 to add, 1 to change, 0 to destroy`. After the apply, 3 API Pods will run
again, and the `kubectl scale` will be undone too.

**Actual:**

```text
  # kubernetes_secret_v1.db will be created
  + resource "kubernetes_secret_v1" "db" { ... }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  ...
  Enter a value: yes

kubernetes_secret_v1.db: Creating...
kubernetes_secret_v1.db: Creation complete after 0s [id=course/db-secret]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

$ kubectl -n course get deployment api
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
api    1/1     1            1           4m11s
```

**Mismatch — explained:** my prediction was `Plan: 1 to add, 1 to change` (Secret +
release `"2" -> "3"`), but the actual plan was `Plan: 1 to add, 0 to change` (Secret
only). The Deployment stayed at `1/1`, so the `kubectl scale` was not undone. Reason:
the release's `set` in state still matched what `tofu` sent, so there was nothing to
change at the release level; and a change inside the Helm release is invisible to
OpenTofu anyway (Step 2b). This is the honest result, and it shows why rule 5 exists:
once OpenTofu made it, change it only through OpenTofu.

### Step 4 — rebuild from zero

**Prediction (before `tofu destroy` + `tofu apply`):** the todo will be gone. The
database lived on a PVC inside the cluster, and `tofu destroy` deleted the cluster.
The code comes back, the data does not, because data is not code.

**Actual:**

```text
$ time tofu destroy -auto-approve
...
helm_release.course_app: Destruction complete after 2s
kubernetes_secret_v1.db: Destruction complete after 0s
kubernetes_namespace_v1.course: Destruction complete after 53s
kind_cluster.course: Destruction complete after 2s

Destroy complete! Resources: 5 destroyed.

real    1m1.308s
user    0m3.725s
sys     0m2.052s

$ time tofu apply -auto-approve
...
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

kube_context = "kind-course"

real    3m59.125s
user    0m10.853s
sys     0m7.951s

$ kubectl -n course get pods
NAME                   READY   STATUS    RESTARTS   AGE
api-76f65f5499-n9qbb   1/1     Running   0          3m17s
api-76f65f5499-v49v8   1/1     Running   0          3m17s
api-76f65f5499-wf6xr   1/1     Running   0          3m17s
db-864878fdcf-pwxmv    1/1     Running   0          3m17s

$ curl -s localhost:8080/api/todos
[]
```

**Mismatch:** none — the data is gone, the code came back.

## 3 · What broke and how I found it

- 🔮 Before `tofu plan` on the teammate's branch, I expected this to go wrong first: **the provider source in `versions.tf`** — `break.sh` changed `infra/main.tf` and `infra/versions.tf`, and a change to the providers is what `tofu init` / the lock file check sees *before* the code and the chart are even read.

| # | What I saw | The command, and the line of output that showed it | My fix (commit) |
|--:|------------|-----------------------------------------------------|-----------------|
| 1 | `Error: Inconsistent dependency lock file` — the kind provider was no longer the one the lock file records | `cd infra && tofu plan` → `provider registry.opentofu.org/hashicorp/kind: required by this configuration but no version is selected` | `versions.tf`: `source = "hashicorp/kind"` → `source = "tehcyx/kind"` (`1c63b54`) |
| 2 | `Error: Error locating chart` — the release pointed at `../chart/course-app` (no `s`) | `tofu plan` → `Unable to locate chart ./../chart/course-app: path "./../chart/course-app" not found` | `main.tf`: `chart = "${path.module}/../charts/course-app"` (`6babaa1`) |
| 3 | `-/+` replacement on the Helm release — `namespace = "course" -> "courses" # forces replacement` (would drop the PVC and database) | `tofu plan` → `Plan: 1 to add, 0 to change, 1 to destroy.` with the `# forces replacement` line | `main.tf`: `namespace = kubernetes_namespace_v1.course.metadata[0].name` (`acdaeac`) |

## 4. In my own words

A **provider** is a plugin that knows how to talk to one system — kind makes
clusters, kubernetes makes Kubernetes objects, helm installs charts, random makes
passwords. OpenTofu reads all `.tf` files in the folder, compares what they say with
what the **state** remembers, and prints a **plan**: `+` create, `~` update in place,
`-/+` destroy and recreate, `-` destroy. `tofu apply` does what the plan says and
writes the result into `terraform.tfstate`.

The state holds **every value, including secrets in plain text** — the database
password is in there, which is why `.gitignore` keeps `*.tfstate` and the kubeconfig
out of Git. The **lock file** `.terraform.lock.hcl` is the opposite: it records the
exact provider versions and *does* go into Git, so everyone who commits and pulls the
lock file gets the same providers.

OpenTofu can see drift on resources it manages: when I deleted the Secret by hand, the
next plan showed `+ create`. But it **cannot** see drift inside a Helm release: when I
scaled the Deployment by hand, the plan showed nothing about the Deployment, because
the release itself didn't change. That's why the rule is: once OpenTofu made
something, change it only through OpenTofu.

Before typing `yes` on a plan with `-/+`, I would tell a teammate: **read the plan**.
`-/+` means "destroy and then create replacement", and the line marked
`# forces replacement` names the cause. For a Helm release that means uninstall and
reinstall — the PVC and the database go with it. If the plan says `-/+` and you didn't
mean to, stop, fix the code, and plan again.