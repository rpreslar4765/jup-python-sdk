import httpx
import pytest

from jup_python_sdk.clients.ultra_api_client import UltraApiClient


@pytest.mark.parametrize("status", [200, 429, 500])
def test_shield(status):
    payload = {"warnings": {}}

    def handler(request):
        assert request.method == "GET"
        assert request.url.path == "/ultra/v1/shield"
        assert request.headers["x-api-key"] == "test-api-key"
        assert request.url.params["mints"] == "mint-a,mint-b"
        return httpx.Response(status, json=payload)

    client = UltraApiClient(api_key="test-api-key")
    client.client.close()
    client.client = httpx.Client(transport=httpx.MockTransport(handler))
    try:
        if status == 200:
            assert client.shield(["mint-a", "mint-b"]) == payload
        else:
            with pytest.raises(httpx.HTTPStatusError):
                client.shield(["mint-a", "mint-b"])
    finally:
        client.close()
