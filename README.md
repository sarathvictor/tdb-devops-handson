# Booking Service — DevOps Hands-on (Grade I)

Reference implementation for the five assessment problems: Docker, GitHub Actions/GHCR, Helm, Terraform/AWS, and Prometheus alerting.

**Safety:** Do not run `terraform apply`. The AWS infrastructure is for validation only. The app returns sample bookings and does not yet connect to PostgreSQL. Do not commit credentials, `.env` files, Terraform state, or real secret values.

## Local setup
Requirements: Docker, Git, Python 3.12+, Helm 3, Terraform, TFLint, Trivy, kubeconform. Docker is also used to run `promtool`.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements-dev.txt
ruff check app
pytest -q
uvicorn app.main:app --host 127.0.0.1 --port 8000
```
In another terminal:
```bash
curl -i http://127.0.0.1:8000/health
curl -i http://127.0.0.1:8000/bookings
curl -s http://127.0.0.1:8000/metrics
```

## P1 — Docker
```bash
docker build -t booking-service:local .
docker run --rm -p 8000:8000 booking-service:local
# In another terminal: curl -i http://127.0.0.1:8000/health
docker image inspect booking-service:local --format='Image size: {{.Size}} bytes'
docker run --rm booking-service:local id
```
Record the actual image size in the PR; do not guess. The image uses a slim Python base and runs as UID 10001.

## P2 — GitHub Actions and GHCR
Create a **public** repository named `tdb-devops-handson`; keep the owner/repository path lowercase for GHCR. Push the initial setup to `main`. The workflow tests/lints, builds and scans on PRs. A critical Trivy finding fails the scan job and blocks publishing. A merge to `main` publishes an image tagged with the full commit SHA and `latest`. Make the package public if anonymous image pulls are required. The workflow uses `GITHUB_TOKEN`, with `packages: write` only in the publish job.

## P3 — Helm
```bash
helm lint helm/booking-service -f helm/booking-service/values-dev.yaml
helm lint helm/booking-service -f helm/booking-service/values-prod.yaml
for env in dev prod; do
  helm template booking-service helm/booking-service -f helm/booking-service/values-$env.yaml > /tmp/booking-$env.yaml
  kubeconform -strict -summary /tmp/booking-$env.yaml
done
```
Replace `ghcr.io/OWNER/tdb-devops-handson` in values files with your lowercase GitHub owner. Production has 3 replicas minimum, HPA, PDB, rolling updates, probes and topology spreading. HPA requires the metrics API. The chart only references an existing Kubernetes Secret; it never creates secret values.

## P4 — Terraform (validation only)
Run in both `terraform/environments/dev` and `terraform/environments/prod`:
```bash
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
tflint --init
tflint
trivy config ../../..
```
**Do not run `terraform apply`.** The Terraform configuration describes a VPC with public/private subnets, NAT gateways and a private PostgreSQL RDS instance. Production RDS is Multi-AZ. NAT gateways and RDS would incur costs if deployed.

For a real team, create the remote state bucket via an approved bootstrap process, enable S3 versioning and encryption, restrict IAM access, and configure separate dev/prod state keys with S3 native locking (`use_lockfile = true`). This repo deliberately has no live backend because the assessment uses no AWS account. Never commit state files. Inject `db_password` securely; do not put it in committed tfvars.

## P5 — Prometheus
```bash
docker run --rm -v "$PWD/monitoring:/etc/prometheus:ro" prom/prometheus:v2.55.1 promtool check rules /etc/prometheus/alerts.yml
```
The `/bookings` endpoint increments `booking_requests_total` with outcomes `success_under_1s`, `success_over_1s`, and `failure`. The ratio of successful-under-one-second requests to all booking requests approximates the business SLI. Alerts are illustrative and need tuning against real traffic and a true monthly SLI calculation.

## PR discipline
Use five branches in order: `feature/p1-container-image`, `feature/p2-ci-pipeline`, `feature/p3-helm-chart`, `feature/p4-terraform-aws`, `feature/p5-prometheus-alerts`. Each PR needs assumptions, trade-offs and verification commands. Review the full diff, leave a specific review comment, address it or explain why not, merge, then update local `main`. Do not commit directly to `main` after initial setup.

## Known demo limitations
- Static sample bookings; no database client/migrations are implemented.
- `DATABASE_URL` is read from environment only; the app does not use it yet.
- Metrics measure application-side request duration, not end-to-end client latency.
- Scanner rules/tool versions change over time; review findings instead of blindly suppressing them.
