# Lab 6 · Test what you ship, ship a release

GitHub user: ankitamandlik5-web · Reference pipeline used (Part 0 fallback): no

## 1 · Smoke test

- The names of my smoke-test steps in the `image` job: `Build for the smoke test (amd64, kept on the runner)` and `Smoke test the image`
- What my smoke test asks, and what makes it fail: It uses `curl` to request `GET http://localhost:5000/`. It fails if the container crashes on startup or if the API doesn't return a successful HTTP response.
- 🔮 Part 1, before my first run: will my code pass the smoke test? I predicted it would pass because the code and Dockerfile were unchanged from Lab 5, and the API was working. What happened: It passed on the first run and printed the API's version JSON.
- 🔮 Part 2, before the checks finished: which checks will go red after `break.sh`? I predicted the `image` check would go red because it's the only one that tests the built Docker image. The others test the source code directly.

## 2 · What broke and how I found it

- The check and the step that went red: The `image` check went red, specifically in the `Smoke test the image` step.
- The log line that showed the cause (copied from the log):

```text
Error: Cannot find module './banner'

## 3 · Release

- Release page: https://github.com/ankitamandlik5-web/turiba-devops-labs/releases/tag/v0.2.0
- Image: `ghcr.io/ankitamandlik5-web/turiba-devops-labs/api:0.2.0`, platforms (from `docker buildx imagetools inspect`): linux/amd64, linux/arm64
- One thing in Part 3 that didn't work the first time, and how I fixed it: ____
