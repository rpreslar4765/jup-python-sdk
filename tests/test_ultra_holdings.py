import httpx
import pytest

from jup_python_sdk.clients.ultra_api_client import UltraApiClient


@pytest.mark.parametrize("status", [200, 429, 500])
def test_holdings(status):
    payload = {"amount": "42", "tokens": {}}

    def handler(request):
        assert request.method == "GET"
        assert request.url.path == "/ultra/v1/holdings/wallet"
        assert request.headers["x-api-key"] == "test-api-key"
        return httpx.Response(status, json=payload)

    client = UltraApiClient(api_key="test-api-key")
    client.client.close()
    client.client = httpx.Client(transport=httpx.MockTransport(handler))
    try:
        if status == 200:
            assert client.holdings("wallet") == payload
        else:
            with pytest.raises(httpx.HTTPStatusError):
                client.holdings("wallet")
    finally:
        client.close()
