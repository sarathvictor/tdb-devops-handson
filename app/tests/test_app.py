from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_returns_200():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_returns_200():
    assert client.get("/ready").status_code == 200


def test_bookings_returns_sample_json():
    response = client.get("/bookings")
    assert response.status_code == 200
    assert response.json()["bookings"][0]["status"] == "confirmed"


def test_metrics_endpoint_exposes_booking_counter():
    client.get("/bookings")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "booking_requests_total" in response.text
