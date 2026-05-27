"""Tests for client.py — uses unittest.mock to patch requests.get."""

import json
import sys
from unittest.mock import MagicMock, patch

import pytest
import requests


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_response(status_code: int, json_data=None, raise_for_status_exc=None):
    """Build a mock requests.Response."""
    mock_resp = MagicMock()
    mock_resp.status_code = status_code

    if raise_for_status_exc is not None:
        mock_resp.raise_for_status.side_effect = raise_for_status_exc
    else:
        mock_resp.raise_for_status.return_value = None

    if json_data is not None:
        mock_resp.json.return_value = json_data
    else:
        mock_resp.json.side_effect = ValueError("No JSON")

    return mock_resp


def _run_main(monkeypatch, env=None):
    """Import and call client.main(), isolating env vars."""
    if env is not None:
        for key, value in env.items():
            monkeypatch.setenv(key, value)

    # Re-import to pick up any module-level state resets.
    import importlib
    import client as client_mod
    importlib.reload(client_mod)

    with pytest.raises(SystemExit) as exc_info:
        client_mod.main()

    return exc_info.value.code


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestHappyPath:
    def test_prints_json_and_exits_zero(self, monkeypatch, capsys):
        payload = {"message": "Hello, World!"}
        mock_resp = _make_response(200, json_data=payload)

        with patch("requests.get", return_value=mock_resp):
            exit_code = _run_main(monkeypatch)

        captured = capsys.readouterr()
        assert exit_code == 0
        assert json.loads(captured.out.strip()) == payload
        assert captured.err == ""


class TestConnectionError:
    def test_prints_error_to_stderr_and_exits_one(self, monkeypatch, capsys):
        with patch("requests.get", side_effect=requests.exceptions.ConnectionError):
            exit_code = _run_main(monkeypatch)

        captured = capsys.readouterr()
        assert exit_code == 1
        assert "Connection error" in captured.err
        assert captured.out == ""


class TestTimeout:
    def test_exits_one_on_timeout(self, monkeypatch, capsys):
        with patch("requests.get", side_effect=requests.exceptions.Timeout):
            exit_code = _run_main(monkeypatch)

        captured = capsys.readouterr()
        assert exit_code == 1
        assert "Timeout" in captured.err


class TestNon200Response:
    def test_exits_one_on_500(self, monkeypatch, capsys):
        # Build a mock HTTPError whose .response carries the status code.
        mock_resp = MagicMock()
        mock_resp.status_code = 500

        http_err = requests.exceptions.HTTPError(response=mock_resp)
        mock_resp.raise_for_status.side_effect = http_err

        with patch("requests.get", return_value=mock_resp):
            exit_code = _run_main(monkeypatch)

        captured = capsys.readouterr()
        assert exit_code == 1
        assert "500" in captured.err


class TestCustomServerURL:
    def test_uses_env_var_url(self, monkeypatch, capsys):
        custom_url = "http://custom-server:9999"
        payload = {"message": "Hello, World!"}
        mock_resp = _make_response(200, json_data=payload)

        captured_urls = []

        def fake_get(url, **kwargs):
            captured_urls.append(url)
            return mock_resp

        with patch("requests.get", side_effect=fake_get):
            exit_code = _run_main(monkeypatch, env={"SERVER_URL": custom_url})

        assert exit_code == 0
        assert len(captured_urls) == 1
        assert captured_urls[0] == f"{custom_url}/hello"


class TestURLSchemeValidation:
    def test_rejects_non_http_scheme(self, monkeypatch, capsys):
        with patch("requests.get") as mock_get:
            exit_code = _run_main(
                monkeypatch, env={"SERVER_URL": "ftp://bad-scheme.example.com"}
            )
            mock_get.assert_not_called()

        captured = capsys.readouterr()
        assert exit_code == 1
        assert "SERVER_URL must use http://" in captured.err


class TestNonJSONResponse:
    def test_exits_one_on_non_json_body(self, monkeypatch, capsys):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.raise_for_status.return_value = None
        mock_resp.json.side_effect = ValueError("not json")

        with patch("requests.get", return_value=mock_resp):
            exit_code = _run_main(monkeypatch)

        captured = capsys.readouterr()
        assert exit_code == 1
        assert "non-JSON" in captured.err
