import json
import os
import sys
from urllib.parse import urlparse

import requests

TIMEOUT_SECONDS = 10
DEFAULT_SERVER_URL = "http://localhost:8000"


def main():
    base_url = os.environ.get("SERVER_URL", DEFAULT_SERVER_URL).rstrip("/")

    parsed = urlparse(base_url)
    if parsed.scheme not in ("http", "https"):
        print(
            f"Error: SERVER_URL must use http:// or https://, got '{parsed.scheme}://'",
            file=sys.stderr,
        )
        sys.exit(1)

    url = f"{base_url}/hello"

    try:
        response = requests.get(url, timeout=TIMEOUT_SECONDS)
        response.raise_for_status()
        try:
            data = response.json()
        except ValueError:
            print(
                f"Error: Server returned non-JSON response (HTTP {response.status_code})",
                file=sys.stderr,
            )
            sys.exit(1)
        print(json.dumps(data))
    except requests.exceptions.ConnectionError:
        print(f"Connection error: Could not reach {url}", file=sys.stderr)
        sys.exit(1)
    except requests.exceptions.Timeout:
        print(
            f"Timeout: Server at {url} did not respond within {TIMEOUT_SECONDS}s",
            file=sys.stderr,
        )
        sys.exit(1)
    except requests.exceptions.HTTPError as exc:
        code = exc.response.status_code if exc.response is not None else "unknown"
        print(f"Error: Server returned HTTP {code}", file=sys.stderr)
        sys.exit(1)
    except Exception as exc:
        print(f"Unexpected error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
