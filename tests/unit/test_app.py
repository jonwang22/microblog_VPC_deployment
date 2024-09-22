# Unit Testing
import pytest
import sys
import os
sys.path.append(os.getcwd())
from microblog import app

# Testing website HTTP Get requests
@pytest.fixture
def client():
    app.config.update({"TESTING": True,})
    return app.test_client()

def test_website(client):
    response = client.get("/", follow_redirects = True)
    assert response.status_code == 200
