import os
import time

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = FastAPI(title="Booking Service", version="1.0.0")
PORT = int(os.getenv("PORT", "8000"))
DATABASE_URL = os.getenv("DATABASE_URL", "")  # Read for future DB integration; unused in this demo.

BOOKING_REQUESTS = Counter(
    "booking_requests_total",
    "Booking endpoint requests classified against the success-under-one-second SLI.",
    ["outcome"],
)
BOOKING_DURATION = Histogram(
    "booking_request_duration_seconds",
    "Application-side duration of booking endpoint requests.",
    buckets=(0.05, 0.1, 0.2, 0.3, 0.5, 0.75, 1.0, 1.5, 2.0, 5.0, float("inf")),
)


@app.middleware("http")
async def observe_booking_requests(request: Request, call_next):
    is_booking_request = request.url.path == "/bookings"
    started = time.perf_counter()
    try:
        response = await call_next(request)
    except Exception:
        if is_booking_request:
            elapsed = time.perf_counter() - started
            BOOKING_DURATION.observe(elapsed)
            BOOKING_REQUESTS.labels(outcome="failure").inc()
        raise
    if is_booking_request:
        elapsed = time.perf_counter() - started
        BOOKING_DURATION.observe(elapsed)
        if response.status_code >= 400:
            outcome = "failure"
        elif elapsed < 1.0:
            outcome = "success_under_1s"
        else:
            outcome = "success_over_1s"
        BOOKING_REQUESTS.labels(outcome=outcome).inc()
    return response


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def readiness():
    # Add a real dependency check when database access is implemented.
    return {"status": "ready"}


@app.get("/bookings")
def get_bookings():
    return {"bookings": [
        {"id": 1, "status": "confirmed"},
        {"id": 2, "status": "pending"},
    ]}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    # Keep internal exception details out of client responses.
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})
