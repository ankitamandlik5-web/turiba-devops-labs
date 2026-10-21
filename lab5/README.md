# Lab 5 · Your first CI pipeline

GitHub user: ankitamandlik5-web · Reference files used (Lab 2 fallback): no

![ci](https://github.com/ankitamandlik5-web/turiba-devops-labs/actions/workflows/ci.yml/badge.svg?branch=main)

<!-- Keep every heading as it is: the grader finds the sections by name. Replace every blank (four underscores), and your user name placeholder in the first line and in the badge URL: write your GitHub user name exactly as GitHub shows it. -->

## 1 · Graph predictions

Part 1, step 1.2: fill in this section **before** you run `lab05 graph`. A wrong prediction that you explain earns full marks.

My drawing of the `lab05 graph` jobs, before the first run (boxes and arrows in text are fine):

ankitamandlik5-web


| # | Question | I predicted, and why | What the run showed |
|---|----------|----------------------|---------------------|
| P1 | Which jobs start together? | `graph-lint` and `graph-build` | `graph-lint` and `graph-build` started together. |
| P2 | Will `graph-package` find `build.txt`? | No | No, jobs don't share files. `build.txt: not here` was in the log. |
| P3 | With `break = build`: which jobs run, which fail, which are skipped? | `graph-build` fails. `graph-test` and `graph-package` skipped. `graph-report` runs. | Exactly as predicted. `graph-report` ran and succeeded. |

## 2 · Pipeline

- B5, before I filled it in: `localhost` or `db`? I predicted `localhost` because the tests run directly on the runner machine, not in a separate container.
- My first red run in Part 2 (the job, the first red step, the error line copied from the log): `unit` job, `npm test` step, `Unknown command: "npm"`.
- What I changed to make it green: Fixed the `ci.yml` file to use `npm run lint` and `npm test` properly without duplicating `npm`.
- My lint findings, and how I fixed them (fixed, not silenced): File `api/server.js`, line 81, rule `no-unused-vars`. Fix: Removed `const server =` from the `app.listen` call.
- Part 2 pull request (URL): https://github.com/ankitamandlik5-web/turiba-devops-labs/pull/3
- Part 3: will the PR run push an image? I predicted No. What happened: It built the image but did not push because the login and push steps only run on the `main` branch.
- My image on GHCR, from the `main` run: `ghcr.io/ankitamandlik5-web/turiba-devops-labs/api:5e1bab7` (use your actual 40-character SHA from the main run if this is different).

## 3 · Red PR

- Red PR (URL): https://github.com/ankitamandlik5-web/turiba-devops-labs/pull/4 (use your actual PR number)
- The test that failed, with Expected and Received (copied): `Expected: 404`, `Received: 500`
- The cause line from "On failure: the API log" (copied): `invalid input syntax for type integer: "abc"`
- The merge box while it was red (the text, copied): `Some checks were not successful` / `Merging is blocked`
- Which commit did the red check test: your branch alone, or your branch merged with `main`? How do you know? My branch alone. GitHub Actions runs on the HEAD of the PR branch (`fix/delete-bad-id`), not the merge commit, as shown in the run summary.

## 4 · Answers

**A1.** In the `break = build` run, `graph-build` failed. `graph-test` and `graph-package` were skipped because they depend on `graph-build`. However, `graph-report` succeeded. It still ran because its `needs:` list or default `if` condition allows it to report the failure even if a previous job fails.

**A2.** `graph-test` found `build.txt` because it ran the command to create it in its own job. `graph-package` didn't find it because GitHub Actions jobs run on completely separate virtual machines and do not share a file system. To make `graph-package` find it, you would need to add a step to upload `build.txt` as an artifact in `graph-test`, and a step to download it in `graph-package`.

**A3.** Both are right because of the network context. In the CI job, the tests run directly on the GitHub runner machine, and the PostgreSQL database runs in a service container exposed on `localhost:5432`. In Lab 4, the API runs inside its own Docker container, so it must use the Compose service name `db` to reach the database. If the CI job ran inside a container (`container: node:24-alpine`), the database would no longer be on `localhost`, and we would have to use `db` instead.

**A4.** The `integration` required check failed. That run tested the commit on my branch alone (not merged with main). The merge was blocked because the ruleset requires all four checks to pass, and the merge box said "Some checks were not successful". The `image` job ran on the PR but did not push because the `if` condition on the login and push steps checks if the branch is `main`, and my PR was on a different branch.
