# Tasks app: two small services

A to-do API that calls a tiny stateless function to clean up task titles.

| Service | Folder | Port | What it does |
|---|---|---|---|
| tasks-api | `services/tasks-api` | 5000 | CRUD for tasks. Calls `title-normalizer` when a task is created. |
| title-normalizer | `services/title-normalizer` | 5001 | One function: `POST /invoke` trims a title, collapses spaces, capitalizes the first letter. |

If `title-normalizer` is down, `tasks-api` still creates the task with the raw title and `"normalized": false`.

## Endpoints

tasks-api:

- `GET /health`
- `GET /tasks`
- `POST /tasks` with `{"title": "..."}`: 201, or 400 for an empty title or a non-JSON body
- `GET /tasks/<id>`: 200 or 404
- `DELETE /tasks/<id>`: 204 or 404

title-normalizer:

- `GET /health`
- `POST /invoke` with `{"title": "  buy   milk "}` returns `{"title": "Buy milk"}`; 400 if `title` is not a string

## Run (two terminals)

Each service has its own `requirements.txt`.

```bash
# terminal 1
cd services/title-normalizer
pip install -r requirements.txt
flask --app app:create_app run --port 5001

# terminal 2
cd services/tasks-api
pip install -r requirements.txt
NORMALIZER_URL=http://localhost:5001 flask --app app:create_app run --port 5000
```

Firewall commands
```bash
sudo iptables-legacy -P FORWARD ACCEPT
sudo iptables-legacy -S FORWARD | head -1
```

Try it:

```bash
curl -X POST localhost:5000/tasks -H 'Content-Type: application/json' -d '{"title": "  buy   milk "}'
curl localhost:5000/tasks
```

Stop terminal 1 and create another task: it still works, with `"normalized": false`.

## Test

Run in each service folder:

```bash
pytest
```

## What each meeting covers

The repo grows meeting by meeting. First a pipeline (`.github/workflows/ci.yml`), later containers, infrastructure and monitoring. Find your meeting below to see what it covers. Nothing here is homework, and later topics are planned: order and details may change.

### Meeting 1: first CI

A workflow that runs on every push: check out the code, set up Python, install the requirements, run `pytest`.

Tasks: break a test on a branch and read the red run. Find which step failed and why.

### Meeting 2: CI in depth

The same workflow for both services and several Python versions (a matrix). The test output is saved as an artifact. A Bandit security scan writes an HTML report, also saved as an artifact. `continue-on-error` lets the job go on when Bandit finds something.

Tasks: read the matrix and `upload-artifact` parts of the [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax). Download an artifact from a run page and open it.

### Meeting 3: CD with GitHub Pages

A `deploy` job that waits for `run_tests` (`needs`), downloads the two Bandit reports, builds an `index.html` and publishes everything with GitHub Pages. A `generate_api_docs` job makes API docs for both services with pdoc, and the index page links to them. The deploy runs only when a pull request is merged: the `pull_request` trigger has the activity types `opened`, `synchronize` and `closed`, and `deploy` checks the `merged` field. Pages needs a public repo on a free account, and what you publish is public.

Two settings are not in the file. Set them in your own repo:

- Settings > Pages > Source: GitHub Actions (the repo must be public).
- Settings > Environments > github-pages > Deployment branches and tags: add the rule `refs/pull/*/merge`. Without it the `deploy` job of a merged pull request is refused with: Branch "refs/pull/N/merge" is not allowed to deploy to github-pages due to environment protection rules.

If you missed this meeting: replace `.github/workflows/ci.yml` with the one in this repo, delete `.github/workflows/ci_livecode.yml` if you have it, and set the two settings above. None of this is homework.

Docs: [Using custom workflows with GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages), [events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows).

Tasks:

1. Auto-generated API docs: add any tool that documents Flask code, run a command that creates the HTML, upload it, publish it on your site and link it from the index page. Do not change `services/`. [pdoc](https://pdoc.dev/) is one easy option.
2. Deploy only when a pull request is merged (look at the `pull_request` activity types and the `merged` field).
3. Read your whole `ci.yml` and explain each job to yourself.

### Meeting 4: Docker images and containers

A Dockerfile describes an image: a base image plus the steps that add your service to it. You build the image, run it as a container, and reach it on a port.

If you missed this meeting: copy these four files from this repo into your own, each as a whole file: `services/tasks-api/Dockerfile`, `services/tasks-api/.dockerignore`, `services/title-normalizer/Dockerfile`, `services/title-normalizer/.dockerignore`. There is no setting to change and `ci.yml` does not change. None of this is homework.

Docs: [Dockerfile reference](https://docs.docker.com/reference/dockerfile/), [Building best practices](https://docs.docker.com/build/building/best-practices/), [Forwarding ports in your codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace).

Tasks:

1. A Dockerfile for `tasks-api`: build the image, run it, then `curl` `/health` and `POST /tasks`. Do not change `services/`.
2. The same for `title-normalizer`.
3. A `.dockerignore` for each service.
4. Run a container as a user that is not root.

### Coming later (planned)

- Docker Compose and containers that talk to each other: running both services together from one file, a `build_images` CI job that builds both images, publishing an image to a registry. Docs: [Docker Compose](https://docs.docker.com/compose/).
- Quality and security: image scanning, Dependabot, lint gates. Docs: [Securing your software supply chain](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain).
- Infrastructure as code with Terraform and the Docker provider (no cloud account). Docs: [kreuzwerker/docker provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs).
- Monitoring: metrics from the app, Prometheus, Grafana. Docs: [Prometheus overview](https://prometheus.io/docs/introduction/overview/).

