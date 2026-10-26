.PHONY: test lint docker-build prom-check

test:
	pytest -q

lint:
	ruff check app

docker-build:
	docker build -t booking-service:local .

prom-check:
	docker run --rm -v "$(CURDIR)/monitoring:/etc/prometheus:ro" prom/prometheus:v2.55.1 promtool check rules /etc/prometheus/alerts.yml
