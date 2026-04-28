import os
import pytest
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@pytest.fixture
def client():
    from main import app, reset
    app.config['TESTING'] = True
    with app.test_client() as client:
        reset()
        yield client


def test_get_root(client):
    response = client.get('/')
    assert response.status_code == 200
    assert response.json == {"message": "Hello, World!"}


def test_get_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json == {"status": "ok"}


def test_get_users_empty(client):
    response = client.get('/api/users')
    assert response.status_code == 200
    assert response.json == {"users": []}


def test_create_user_success(client):
    response = client.post('/api/users', json={"name": "Alice"})
    assert response.status_code == 201
    data = response.json
    assert data["id"] == 1
    assert data["name"] == "Alice"


def test_create_user_missing_name(client):
    response = client.post('/api/users', json={})
    assert response.status_code == 400
    assert "error" in response.json


def test_get_user_existing(client):
    client.post('/api/users', json={"name": "Bob"})
    response = client.get('/api/users/1')
    assert response.status_code == 200
    assert response.json["name"] == "Bob"


def test_get_user_not_found(client):
    response = client.get('/api/users/999')
    assert response.status_code == 404


def test_delete_user(client):
    client.post('/api/users', json={"name": "Charlie"})
    response = client.delete('/api/users/1')
    assert response.status_code == 200
    response2 = client.get('/api/users/1')
    assert response2.status_code == 404
