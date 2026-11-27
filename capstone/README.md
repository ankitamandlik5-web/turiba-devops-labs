Capstone: Ship it, run it, explain it
Run it from zero
This is the exact sequence to get the app running from a fresh clone.

1. Start the application with Docker Compose:
cp .env.example .env
docker compose up -d
The app is now available at http://localhost:8080.

2. Create the Kubernetes Secret (required for the Helm chart):
kubectl create secret generic db-secret --from-literal=password='<your-secure-password>' -n course
(Note: Replace <your-secure-password> with a real password. The namespace course is created by the OpenTofu configuration).

3. Create the cluster and install the chart using OpenTofu:
cd infra
tofu init
tofu apply -auto-approve
This creates a kind cluster, creates the course namespace, and installs the Helm chart.

4. Verify it works:
kubectl get pods -n course

Architecture
The application is built using Node.js and PostgreSQL. The CI pipeline validates the code, runs tests against a temporary database, builds a Docker image, scans it for vulnerabilities, and pushes it to GHCR. OpenTofu is used to provision the kind cluster and install the Helm chart, which deploys the API and database into the cluster.

What is where
Path	What it is
api/Dockerfile	Multi-stage Dockerfile for the Node.js API (uses node:24-alpine reference file)
compose.yaml	Local development environment (db, api, web)
.github/workflows/ci.yml	CI pipeline (lint, unit, integration, image, gitleaks)
.github/workflows/release.yml	Release pipeline triggered by v* tags
.github/dependabot.yml	Dependabot configuration for npm, actions, and docker
charts/course-app/	Helm chart for the API and PostgreSQL
infra/	OpenTofu configuration to create the kind cluster and install the chart
observability/	Grafana dashboard JSON and screenshot
Level and evidence
Level claimed: Target

M1 (Containers and local dev): api/Dockerfile

M2 (Version control): All changes merged via PR. Protected main branch.

M3 (CI): CI workflow runs

M4 (Release 1.0.0): GitHub Release v1.0.0

M5 (Kubernetes with Helm): charts/course-app/values.yaml

M6 (No secrets in Git): gitleaks job is green on main.

M7 (Documentation): This file.

T1 (OpenTofu): infra/main.tf

T2 (Security gates): gitleaks and Trivy are in ci.yml. Dependabot PRs were handled.

T3 (Observability): observability/dashboard.json. See screenshot below.

Grafana Dashboard
![Grafana Dashboard](https://github.com/ankitamandlik5-web/turiba-devops-labs/blob/main/observability/dashboard.png?raw=true)

When it breaks
If the app fails on the cluster, here are the 3 most likely faults and how to check them:

The DB pod is not starting (CrashLoopBackOff):

Check the logs: kubectl logs -n course deployment/db

Check the PVC: kubectl get pvc -n course (Ensure it is Bound)

The API cannot connect to the database:

Check if the Secret exists: kubectl get secret -n course

Check the API logs: kubectl logs -n course deployment/api

The image is not pulling:

Check the pod events: kubectl describe pod -n course -l app=api

Ensure the GHCR image is public and the tag in values.yaml is correct.

Known issues
Dependabot PRs (#36 and #37) were closed with a comment because Dependabot runs in a restricted environment that cannot access the DB_PASSWORD secret required for the integration tests.

api/Dockerfile is based on the course's Lab 2 reference file.

AI use
## Extension

**Chosen: SBOM and a signed image**

I chose this extension because supply chain security is critical. Even if the CI passes and the image is public, users need to know that the image they pull was built by my specific GitHub Actions workflow and hasn't been tampered with.

This changes the release process by adding `sbom: true` to the Docker build step, which automatically generates a Software Bill of Materials (SBOM) attesting to the exact packages inside the image. It also installs Cosign and uses GitHub's OIDC identity to keylessly sign the image digest. There is no private key to manage or leak.

**Trade-offs:** The main trade-off is that the release job now takes slightly longer to run because it has to generate the SBOM and interact with Sigstore's transparency log. However, this is a small price to pay for cryptographic proof of image integrity.

**Evidence:**
The signature and SBOM can be verified using the following commands:
```bash
cosign verify ghcr.io/ankitamandlik5-web/turiba-devops-labs/api:1.0.4 \
  --certificate-identity-regexp "^https://github.com/ankitamandlik5-web/turiba-devops-labs/\.github/workflows/release\.yml@refs/tags/v.*$" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"

cosign verify-attestation ghcr.io/ankitamandlik5-web/turiba-devops-labs/api:1.0.4 \
  --type spdxjson \
  --certificate-identity-regexp "^https://github.com/ankitamandlik5-web/turiba-devops-labs/\.github/workflows/release\.yml@refs/tags/v.*$" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
I used AI tools to help debug GitHub Actions errors (specifically fixing the working-directory issue in the integration job and resolving invalid action SHAs). I also used AI to help draft this README and the OpenTofu configuration structure.
