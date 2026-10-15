import pytest


@pytest.fixture(autouse=True)
def isolated_environment(monkeypatch):
    """Mock HTTP transports must not depend on a developer's proxy or wallet."""
    for name in (
        "HTTP_PROXY",
        "HTTPS_PROXY",
        "ALL_PROXY",
        "http_proxy",
        "https_proxy",
        "all_proxy",
        "PRIVATE_KEY",
    ):
        monkeypatch.delenv(name, raising=False)
