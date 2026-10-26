# Runbook: Booking success/latency SLI alert

## Meaning
The alert means the proportion of `/bookings` requests that return successfully in under one second is below the configured threshold. The business objective is 99.9% of booking requests succeeding in less than one second over a month. This demo metric is application-side latency, not end-to-end client latency.

## First response
1. Acknowledge the alert and confirm it is still firing.
2. Check traffic volume; low request rates can make ratios noisy.
3. Inspect service logs and Kubernetes events around the alert start time.
4. Compare request outcomes and latency before/after the alert began.

## Prometheus checks
- `sum(rate(booking_requests_total{outcome="failure"}[5m]))`
- `sum(rate(booking_requests_total{outcome="success_over_1s"}[5m]))`
- `sum(rate(booking_requests_total{outcome="success_under_1s"}[5m]))`
- `histogram_quantile(0.95, sum by (le) (rate(booking_request_duration_seconds_bucket[5m])))`

## Kubernetes checks
```bash
kubectl get pods -n booking
kubectl get events -n booking --sort-by=.lastTimestamp
kubectl logs -n booking deploy/booking-service --since=30m
kubectl top pods -n booking
kubectl rollout status deployment/booking-service -n booking
```

## Mitigation
- If a release correlates with the issue, follow the approved rollback procedure: `helm rollback booking-service REVISION -n booking`.
- For restarts/readiness failures, inspect events and logs before changing probes.
- For saturation, check HPA and node capacity; scale only within approved limits.
- If database integration is added, inspect DB latency, connection counts and failover events.
- Do not disable alerts just to clear the page. Record the incident and evidence.

## Recovery
Confirm the SLI recovers and stays stable for at least 30 minutes. Record the timeline, impact, root cause and follow-up actions.
