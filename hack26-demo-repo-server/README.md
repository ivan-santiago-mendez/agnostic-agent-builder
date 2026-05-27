# hack26-demo-repo-server

Minimal FastAPI Hello World server built for the Hack26 demo. Exposes a single `GET /hello`
endpoint that returns a JSON greeting.

## Prerequisites

- Python 3.9+

## Setup

1. Create and activate a virtual environment:

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate   # Windows: .venv\Scripts\activate
   ```

2. Install dependencies:

   For production:

   ```bash
   pip install -r requirements.txt
   ```

   For development and testing:

   ```bash
   pip install -r requirements-dev.txt
   ```

## Run

From inside the `hack26-demo-repo-server/` directory:

```bash
uvicorn main:app --reload
```

The server starts on `http://127.0.0.1:8000`.

## Test

### Manual — curl

```bash
curl http://localhost:8000/hello
# Expected response: {"message":"Hello, World!"}
```

### Automated — pytest

```bash
python -m pytest test_main.py -v
```

Expected output:

```
test_main.py::test_hello_returns_200 PASSED
test_main.py::test_hello_returns_message PASSED
test_main.py::test_root_returns_404 PASSED
test_main.py::test_post_hello_returns_405 PASSED
```

## Endpoints

| Method | Path     | Status | Response body                      |
|--------|----------|--------|------------------------------------|
| GET    | `/hello` | 200    | `{"message": "Hello, World!"}`     |
| GET    | `/`      | 404    | Not defined — returns 404 by default |
| POST   | `/hello` | 405    | Method not allowed                 |
