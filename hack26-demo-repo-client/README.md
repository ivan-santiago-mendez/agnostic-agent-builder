# hack26-demo-repo-client

A minimal Python HTTP client that calls the `GET /hello` endpoint of the demo server built in HACK-SERVER-001 and prints the JSON response to stdout.

---

## Requirements

- Python 3.8 or later
- HACK-SERVER-001 must be running and reachable at the target URL (default: `http://localhost:8000`)

---

## Installation

It is recommended to install dependencies inside a virtual environment.

```bash
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

---

## Usage

### Default (server on localhost:8000)

```bash
python client.py
```

### Custom server URL

```bash
SERVER_URL=http://localhost:9000 python client.py
```

Set `SERVER_URL` to the base URL of the running HACK-SERVER-001 instance. The client appends `/hello` automatically.

---

## Expected Output

On success the JSON response is printed to stdout and the process exits with code 0:

```
{"message": "Hello, World!"}
```

---

## Error Scenarios

All error messages are printed to **stderr** and the process exits with code **1**.

| Scenario | stderr message |
|---|---|
| Server is not running / unreachable | `Connection error: Could not reach <url>` |
| Server does not respond within 10 seconds | `Timeout: Server at <url> did not respond within 10s` |
| Server returns a non-2xx HTTP status | `HTTP error: Server returned status <code>` |
| Any other unexpected failure | `Unexpected error: <detail>` |
