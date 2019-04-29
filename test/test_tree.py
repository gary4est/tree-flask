"""
You can auto-discover and run all tests with this command:

    $ pytest

Documentation:

* https://docs.pytest.org/en/latest/
* https://docs.pytest.org/en/latest/fixture.html
* http://flask.pocoo.org/docs/latest/testing/
"""

import pytest

import app


@pytest.fixture
def apptox():
    apptox= app.create_app()
    apptox.debug = True
    return apptox.test_client()


def test_hello_tree(apptox):
    res = apptox.get("/")
    # print(dir(res), res.status_code)
    assert res.status_code == 200
    assert b"Hello Tree" in res.data

def test_public_health(apptox):
    res = apptox.get("/public/health")
    assert res.status_code == 200
    assert b"healthy" in res.data

def test_public_connection(apptox):
    res = apptox.get("/public/health")
    assert res.status_code == 200
    assert b"connection" in res.data


