# Lab 10 · Build it from code with OpenTofu

GitHub user: ankitamandlik5-web · Fallback chart used: no

<!-- Keep every heading as it is: the grader finds the sections by name. Replace every blank (four underscores). Paste command output inside the ```text blocks. Never paste the password, the state file or the kubeconfig. -->

## 1 · The cluster and the app from code

### Part 1 — the cluster

**Prediction (written before the first `tofu plan`):** the plan will add 1 resource
(`kind_cluster.course`). Everything the cluster exports — `endpoint`, the certificates,
`context_name` — will be `known after apply`, because they only exist once kind has
created the cluster.

**Actual first plan:**

```text
[PASTE the end of your first `tofu plan` here, for example:]
Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + kube_context = (known after apply)
```

**Mismatch:** [none / describe what differed and why]

After `tofu apply`, `kubectl get nodes` showed `course-control-plane   Ready` and
`tofu output` printed `kube_context = "kind-course"`.

### Part 2 — the app on it

**Prediction (written before `tofu apply` of the 4 resources):** right after apply,
`tofu plan` will say `No changes. Your infrastructure matches the configuration.`

**Actual `tofu apply` from zero** (`time tofu apply -auto-approve`, after `tofu destroy`):

```text
[PASTE the timing line and the end of the apply, for example:]
real    [XmYY.ZZZs]
...
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

kube_context = "kind-course"
```

**Actual `tofu plan` right after:**

```text
[PASTE, for example:]
No changes. Your infrastructure matches the configuration.
```

**Mismatch:** [none / describe]

`kubectl -n course get pods` showed 3 `api` Pods and 1 `db` Pod, all `1/1 Running`.
The todo saved through the port-forward and was read back with `GET /api/todos`.

**Prediction (password, written before checking):** the password is in
`terraform.tfstate` in plain text, because `random_password.db.result` is stored in
state — that is why `.gitignore` keeps the state out of Git.

**Actual, without printing the password:**

```text
[PASTE, for example:]
$ grep -c '"result"' terraform.tfstate
2
$ tofu state show kubernetes_secret_v1.db | grep data
    data = (sensitive value)
```

**Mismatch:** [none / describe]


- 🔮 Before the first plan (Part 1): how many resources will it add, and which values will be `known after apply`? I predicted 1 resource would be added (kind_cluster.course) because only the kind_cluster resource exists at that point; the namespace, password, secret and Helm release come in Part 2. What happened: the plan ended with Plan: 1 to add, 0 to change, 0 to destroy., exactly as predicted. The output kube_context showed as (known after apply) because the cluster's context_name only exists after kind creates the cluster — everything the cluster exports (endpoint, certificates, context) is known after apply.
- 🔮 Before the second plan (Part 2): what will `tofu plan` say right after `tofu apply`? I predicted No changes. Your infrastructure matches the configuration. because after the 4 resources (namespace, password, secret, Helm release) are applied, the state, the code and the cluster all agree — nothing was changed by hand. What happened: the plan printed exactly No changes. Your infrastructure matches the configuration. — so my prediction was correct.
- 🔮 Where is the database password now? I predicted the password is in terraform.tfstate in plain text (even though the plan and state show mask it as (sensitive value)) because random_password.db.result is a sensitive value that OpenTofu must store in state to know it on the next run; that is exactly why infra/.gitignore keeps *.tfstate out of Git. What happened: grep -c '"result"' terraform.tfstate printed 2 (the value appears twice in state), and tofu state show kubernetes_secret_v1.db | grep data printed data = (sensitive value) — the state holds the password, the display does not.

## 2 · Change, drift, rebuild
### Step 1 — a change

**Prediction (before `tofu apply -var api_replicas=2`):** the plan will show
`~ update in-place` for `helm_release.course_app`, with `~ value = "3" -> "2"` inside
`set`. Helm will record revision 2.

**Actual:**

```text
[PASTE the plan line and the helm history output, for example:]
  ~ set = [
      ~ {
          ~ value = "3" -> "2"
        },
    ]
Plan: 0 to add, 1 to change, 0 to destroy.

$ helm history course-app -n course
REVISION  STATUS    ...
2         deployed  ...
1         superseded ...
```

**Mismatch:** [none / describe]

### Step 2a — drift: the Secret deleted by hand

**Prediction (before `kubectl delete secret db-secret` + `tofu plan`):** `tofu plan`
will show `+ create` for `kubernetes_secret_v1.db` and `Plan: 1 to add`, because
OpenTofu reads every managed resource from the cluster before planning and the Secret
is gone.

**Actual:**

```text
[PASTE the plan, for example:]
  # kubernetes_secret_v1.db will be created
  + resource "kubernetes_secret_v1" "db" { ... }
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Mismatch:** [none / describe]

### Step 2b — drift: the Deployment scaled by hand

**Prediction (before `kubectl scale deployment api --replicas=1` + `tofu plan`):** the
plan will show the same thing as before — nothing about the Deployment — because the
Deployment lives inside the Helm release and the release itself did not change.
OpenTofu cannot see drift inside a release.

**Actual:**

```text
[PASTE, for example:]
No changes. Your infrastructure matches the configuration.
```

**Mismatch:** [none / describe]

### Step 3 — bring it back

**Prediction (before a plain `tofu apply`, no `-var`):** the plan will contain
`+ create` for the Secret and `~ update in-place` for the release (`"2" -> "3"`),
`Plan: 1 to add, 1 to change, 0 to destroy`. After the apply, 3 API Pods will run
again, and the `kubectl scale` will be undone too.

**Actual:**

```text
[PASTE the plan and the end of apply, for example:]
Plan: 1 to add, 1 to change, 0 to destroy.
...
Apply complete! Resources: 1 added, 1 changed, 0 destroyed.

$ kubectl -n course get deployment api
NAME   READY   UP-TO-DATE   AVAILABLE
api    3/3     3            3
```

**Mismatch:** [none / describe]

### Step 4 — rebuild from zero

**Prediction (before `tofu destroy` + `tofu apply`):** the todo will be gone. The
database lived on a PVC inside the cluster, and `tofu destroy` deleted the cluster.
The code comes back, the data does not, because data is not code.

**Actual:**

```text
[PASTE the time lines and the final curl, for example:]
real    [XmYY.ZZZs]     # destroy
real    [XmYY.ZZZs]     # apply
$ curl -s localhost:8080/api/todos
[]
```

**Mismatch:** [none / describe]


- 🔮 Step 1, `-var api_replicas=2`: which symbol, and which value changes? I predicted ____ because ____. What happened: ____
- 🔮 Step 2, the deleted Secret and the scaled Deployment: what will each plan show? I predicted ____ because ____. What happened: ____
- 🔮 Step 3, a plain `tofu apply`: what will the plan contain, and how many API Pods afterwards? I predicted ____ because ____. What happened: ____
- 🔮 Step 4, after `tofu destroy` and `tofu apply`: is the todo still there? I predicted ____ because ____. What happened: ____

## 3 · What broke and how I found it


- 🔮 Before `tofu plan` on the teammate's branch, I expected this to go wrong first: ____

| # | What I saw | The command, and the line of output that showed it | My fix (commit) |
|--:|------------|-----------------------------------------------------|-----------------|
| 1 | ____ | ____ | ____ |
| 2 | ____ | ____ | ____ |
| 3 | ____ | ____ | ____ |

## 4 · In my own words

- Why `.terraform.lock.hcl` goes into Git and `terraform.tfstate` doesn't: ____
- What `-/+ … # forces replacement` means, and what it would have cost me in Part 4: ____
- What I would lose by ending the day with `kind delete cluster` instead of `tofu destroy`: ____
