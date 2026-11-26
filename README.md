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

The repo grows meeting by meeting. It starts with a pipeline (`.github/workflows/ci.yml`) and adds one topic per meeting. Find your meeting below to see what it covers. Nothing here is homework.

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

### Meeting 5: Docker Compose and publishing images

A `compose.yaml` describes several services and starts them with one command. Each service name is a host name on the network Compose creates. A `build_images` job builds both images on every run, and a job can publish an image to a registry (`ghcr.io`) with the token the run has.

In a Codespace, traffic between containers on a Compose network is dropped by default. Run `sudo iptables-legacy -P FORWARD ACCEPT` once; it applies to this Codespace only.

If you missed this meeting: copy `compose.yaml` and `.github/workflows/ci.yml` from this repo into your own, each as a whole file (`ci.yml` also has the `build_images` and `publish_images` jobs). There is no setting to change. None of this is homework.

Docs: [Compose file reference](https://docs.docker.com/reference/compose-file/), [Services: healthcheck and depends_on](https://docs.docker.com/reference/compose-file/services/), [docker compose up](https://docs.docker.com/reference/cli/docker/compose/up/), [Interpolation and the .env file](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/), [Working with the Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

Tasks:

1. A `build_images` job in `.github/workflows/ci.yml`: a matrix over `tasks-api` and `title-normalizer`, `docker build` for each one from its folder. It only builds. Push to `main`.
2. A `compose.yaml` in the repo root: both services, each built from its folder, the ports 5000 and 5001 published. `docker compose up --build` runs both.
3. `tasks-api` reaches `title-normalizer` by its service name. `POST /tasks` with the title `  buy   MILK ` returns `"title":"Buy MILK"` and `"normalized":true`. A wrong result is silent: the task is created and `normalized` is `false`.
4. A `publish_images` job in `ci.yml`: it runs only on a push, not on a pull request, after `build_images`. For both services it pushes the image to `ghcr.io/<owner>/<service>`, tagged with the commit. Push to `main` and find the package. The docs page Working with the Container registry shows how to log in, build and push an image.
5. A healthcheck on `title-normalizer`, and `tasks-api` starts only when it is healthy. `docker compose ps` shows `healthy`.
6. A `smoke_test` job in `ci.yml`: start both services with Compose, post a task, fail the job when `normalized` is not `true`, shut the services down.
7. Move the two published ports and the `NORMALIZER_URL` value out of `compose.yaml` into a `.env` file. `docker compose config` shows the same result as before.

### Meeting 6: protecting main and scanning images

A ruleset on `main` can require pull requests, approvals and named checks, and it can have a bypass list. A scan job checks an image against a database of known flaws and can fail the run; publishing can wait for it. An action can be pinned by commit.

If you missed this meeting: copy `.github/workflows/ci.yml` from this repo into your own as a whole file, and `services/tasks-api/Dockerfile`, `services/tasks-api/.dockerignore`, `services/title-normalizer/Dockerfile` and `services/title-normalizer/.dockerignore` if you have none. The ruleset is a setting, not a file (Settings > Rules > Rulesets, a new branch ruleset): any name, Enforcement status Active, target the default branch, bypass list Repository admin with Always allow, require a pull request with 1 approval, require status checks `run_tests (tasks-api, 3.12)`, `run_tests (title-normalizer, 3.12)`, `build_images (tasks-api)` and `build_images (title-normalizer)`. After the first green scan add `scan_images (tasks-api)` and `scan_images (title-normalizer)`. To switch the ruleset off, set Enforcement status to Disabled. A ruleset needs a public repository on a free account. None of this is homework.

Docs: [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets), [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [Trivy Action README](https://github.com/aquasecurity/trivy-action#readme), [Trivy: container image](https://trivy.dev/docs/latest/guide/target/container_image/), [Trivy: filtering](https://trivy.dev/docs/latest/guide/configuration/filtering/), [Working with the Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

Tasks:

1. Read your `publish_images` job and find the package it pushed: the image name and the tag.
2. A ruleset on `main` with the settings above. Open a pull request and read its merge box.
3. A `scan_images` job after `build_images` (a matrix over both services, a Trivy scan of each image that fails on `CRITICAL` and `HIGH` findings that have a fix), with the Trivy action pinned by the commit SHA of a release you looked up. `publish_images` runs only after `scan_images`. Do it on a pull request, add the two `scan_images` checks to your ruleset, then merge.
4. A job `checks_passed` that needs `run_tests`, `build_images` and `scan_images` and fails unless all three succeeded. Require that one name in your ruleset.
5. Pin the other actions in `ci.yml` by the full commit SHA, with the version in a comment.
6. Read your whole `ci.yml` and say aloud what each job does.

### Meeting 7: keeping dependencies and the repo in order

Dependabot opens pull requests that update dependencies when newer versions exist. Pinning a base image by digest freezes it; Dependabot proposes a newer digest a few days after the tag has moved. A `CODEOWNERS` file names who is asked to review a change, a pull request template is the starting text for a description, and two ruleset settings keep the branch history linear and limit the available merge methods.

If you missed this meeting: copy `services/tasks-api/Dockerfile` and `services/title-normalizer/Dockerfile` (they carry a pinned digest), `.github/pull_request_template.md`, `scripts/scratch-repo.sh` and `.github/dependabot.yml` from this repo as whole files, and `.github/workflows/ci.yml` if you have no `scan_images` job. Write `.github/CODEOWNERS` as one line: `* @<your-username>`. The ruleset changes are settings: in your ruleset tick Require linear history and allow only squash and rebase; also add `scan_images (tasks-api)` and `scan_images (title-normalizer)` to the required status checks. None of this is homework.

Docs: [Dependabot options reference](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference), [About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners), [Creating a pull request template](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets), [Keeping your actions up to date with Dependabot](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot), [Pin base image versions](https://docs.docker.com/build/building/best-practices/#pin-base-image-versions).

Tasks:

1. Open the pull request with the files you copied, read the log of the `scan_images` job, name the library and the vulnerability ids it reports, and merge the pull request with your admin bypass.
2. Create `.github/dependabot.yml` with entries for github-actions and pip: a weekly schedule, a limit of three open pull requests, and one group for all actions.
3. Add a docker entry for both Dockerfile folders with an `ignore` rule for the `python` image and a group for the base image.
4. Create `.github/CODEOWNERS` with one line that names you as owner of every file, copy `.github/pull_request_template.md`, open one pull request and merge it.
5. In your ruleset require linear history and allow only the squash and rebase merge methods.
6. In a Codespace run `bash scripts/scratch-repo.sh` and read the graph it prints.
7. Open the Dependabot pull request for your Dockerfiles, read what it changes and what the checks say, and write your decision and one reason in a comment. If you approve, merge it without the bypass. Add the two `scan_images` check names to your ruleset.
8. Write `.github/CODEOWNERS` rules per folder, each owned by you, and read who is asked to review a pull request that changes files in two of those folders.
9. Turn on the ruleset rule that requires review from Code Owners, open a pull request that changes an owned file, read the merge box, and turn the rule off again.

### Meeting 8: git history

A history is a graph of commits. A merge adds a commit that joins two lines, a rebase replays commits on top of another branch and gives them new ids, a squash turns many commits into one, and a ruleset can require that the history stays linear. Cherry-pick copies one commit to another branch. A conflict is two changes to the same lines: Git stops and asks you to choose. Rewriting commits is safe only for commits nobody else has.

If you missed this meeting: nothing changes in this repo. The practice happens in a separate new repository: create it with a README, open a Codespace on it and follow the two lines in the README of kubino148/git-scenarios. None of this is homework.

Docs: [Git Branching - Rebasing](https://git-scm.com/book/en/v2/Git-Branching-Rebasing), [git cherry-pick](https://git-scm.com/docs/git-cherry-pick), [Basic merge conflicts](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging), [git reflog](https://git-scm.com/docs/git-reflog), [About merge methods on GitHub](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github), [Resolving a merge conflict on GitHub](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/resolving-a-merge-conflict-on-github).

Tasks:

1. Create a new repository with a README, open a Codespace on it and run the scenario script.
2. Predict, then merge three pull requests with the three merge buttons, and read the graph each leaves.
3. Rebase a branch that is behind and push it with --force-with-lease.
4. Resolve a conflict in a merge.
5. Resolve a conflict in a rebase.
6. Cherry-pick two commits from hotfix-main onto hotfix-release.
7. Run git pull on a diverged branch, read what git says, and put your commit on top of the remote.
8. Revert a bad commit that is already pushed; bring lost commits back with git reflog.
9. Cherry-pick a commit that conflicts (add the scenario with the script) and resolve the conflict.
10. Squash-merge a pull request that another pull request is built on (add the scenario with the script), then repair the second branch.
11. Push a rebase with --force-with-lease after a teammate pushed first (add the scenario with the script).

### Meeting 9: monitoring

Prometheus reads the numbers every service offers on a schedule: the app lists them at `/metrics`, and Prometheus asks for them again and again. A counter only goes up, a histogram counts values into buckets, and a label is how you ask a question of the numbers. Grafana draws what Prometheus stores. An alert rule is a query that must stay true for a while.

If you missed this meeting: copy these as whole files: `services/tasks-api/app/metrics.py`, `services/tasks-api/app/__init__.py`, `services/tasks-api/requirements.txt`, `services/tasks-api/tests/test_metrics.py`; add the two services (`prometheus`, `grafana`) to your own `compose.yaml` (or copy `compose.yaml` if you have none); copy `prometheus/prometheus.yml` and `prometheus/alerts.yml` together; then in Grafana add the data source (URL `http://prometheus:9090`) and build the panels. Run the firewall command once per Codespace session. None of this is homework.

Docs: [Prometheus overview](https://prometheus.io/docs/introduction/overview/), [Prometheus configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/), [Alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/), [Querying basics](https://prometheus.io/docs/prometheus/latest/querying/basics/), [Prometheus Python client](https://prometheus.github.io/client_python/), [Grafana: Prometheus data source](https://grafana.com/docs/grafana/latest/datasources/prometheus/configure/), [Compose services](https://docs.docker.com/reference/compose-file/services/), [Compose volumes](https://docs.docker.com/reference/compose-file/volumes/), [Forwarding ports in your codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace).

Tasks:

1. Copy the four instrumentation files and see the `http_requests_total` series on `/metrics`.
2. Add `prometheus` and `grafana` to `compose.yaml` and open both pages.
3. Write `prometheus/prometheus.yml` so the target `tasks-api` is UP.
4. In Grafana add the data source and build a panel that answers a question.
5. Push, open a pull request and merge it.
6. Write an alert rule for errors on `/tasks`.
7. Build a second panel.

### Meeting 10: infrastructure as code

A file can declare what should exist, and a tool makes it so. `plan` shows the difference between the file and what exists before anything changes, the state records what was made, and `for_each` turns one definition into several environments.

#### Install Terraform

```bash
curl -fsSL -o /tmp/install-terraform.sh https://raw.githubusercontent.com/kubino148/tasks-app-reference/main/scripts/install-terraform.sh
cat /tmp/install-terraform.sh
bash /tmp/install-terraform.sh
```

Read the script before you run it.

If you missed this meeting: run the three lines above, then copy these as whole files: `terraform/.gitignore` and `terraform/main.tf`. Build the two images as in meetings 4 and 5 (`title-normalizer:local` and `tasks-api:local`), run the firewall command from the Firewall commands section once per Codespace, then run `terraform init` in `terraform/`. The containers are gone with the Codespace. None of this is homework.

Docs: [Terraform: resource blocks](https://developer.hashicorp.com/terraform/language/block/resource), [for_each](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each), [Local values](https://developer.hashicorp.com/terraform/language/values/locals), [Output values](https://developer.hashicorp.com/terraform/language/values/outputs), [References to values](https://developer.hashicorp.com/terraform/language/expressions/references), [Strings and templates](https://developer.hashicorp.com/terraform/language/expressions/strings), [depends_on](https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on), [terraform init](https://developer.hashicorp.com/terraform/cli/commands/init), [terraform plan](https://developer.hashicorp.com/terraform/cli/commands/plan), [terraform apply](https://developer.hashicorp.com/terraform/cli/commands/apply), [terraform destroy](https://developer.hashicorp.com/terraform/cli/commands/destroy), [terraform state list](https://developer.hashicorp.com/terraform/cli/commands/state/list), [terraform output](https://developer.hashicorp.com/terraform/cli/commands/output), [terraform validate](https://developer.hashicorp.com/terraform/cli/commands/validate), [Dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock), [Docker provider: docker_container](https://registry.terraform.io/providers/kreuzwerker/docker/4.7.0/docs/resources/container), [Docker provider: docker_network](https://registry.terraform.io/providers/kreuzwerker/docker/4.7.0/docs/resources/network)

Tasks:

1. Run the install script and start one container from a file.
2. Describe the app environment in `terraform/main.tf`.
3. Make `dev` and `staging` from one definition with `for_each`.
4. Push a branch, open a pull request and merge it.
5. Fix a change made by hand.
6. Predict which edit replaces a container.

### Meeting 11: Kubernetes, the environment

A Kubernetes cluster runs your containers on one or more machines and is told what to run by files. kind runs a Kubernetes cluster inside Docker; ours has one node, so every Codespace can have its own. A Pod is the smallest thing Kubernetes runs; `kubectl` reads and changes the cluster.

#### Install kind

```bash
curl -fsSL -o /tmp/install-kind.sh https://raw.githubusercontent.com/kubino148/tasks-app-reference/main/scripts/install-kind.sh
cat /tmp/install-kind.sh
bash /tmp/install-kind.sh
```

Read the script before you run it.

If you missed this meeting: run the three lines above, then copy these as whole files: `kubernetes/kind-config.yaml` and `kubernetes/tasks-api-pod.yaml` (no file you already have changes). Build `tasks-api:local` as in Meeting 4, then put it into the cluster node with `docker image save --platform linux/amd64 --output /tmp/tasks-api.tar tasks-api:local` and `kind load image-archive /tmp/tasks-api.tar`. The cluster is gone with the Codespace. None of this is homework.

Docs: [kind quick start](https://kind.sigs.k8s.io/docs/user/quick-start/), [Kubernetes: Pods](https://kubernetes.io/docs/concepts/workloads/pods/), [kubectl port-forward](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_port-forward/), [Forwarding ports in your codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace), [GitHub: Codespaces billing](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces)

Tasks:

1. Run the install script and create a cluster from `kubernetes/kind-config.yaml`.
2. Start a Pod from a file and read it with `get`, `describe` and `logs`.
3. Put your `tasks-api` image into the node and describe it in `kubernetes/tasks-api-pod.yaml`.
4. Open the Pod in a browser tab through `kubectl port-forward`.
5. Delete the cluster and make it again from the file.
6. Push the two files on a branch.
