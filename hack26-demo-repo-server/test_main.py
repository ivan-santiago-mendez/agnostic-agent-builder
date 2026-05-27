import pytest
from fastapi.testclient import TestClient
from main import app

@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c

def test_hello_returns_200(client):
    response = client.get("/hello")
    assert response.status_code == 200

def test_hello_returns_message(client):
    response = client.get("/hello")
    assert response.json() == {"message": "Hello, World!"}

def test_root_returns_404(client):
    response = client.get("/")
    assert response.status_code == 404

def test_post_hello_returns_405(client):
    response = client.post("/hello")
    assert response.status_code == 405
