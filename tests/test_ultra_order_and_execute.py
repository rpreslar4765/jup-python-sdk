import json

import httpx
import pytest

from jup_python_sdk.clients.ultra_api_client import UltraApiClient
from jup_python_sdk.models.ultra_api.ultra_order_request_model import UltraOrderRequest


def test_order_and_execute(monkeypatch):
    requests = []

    def handler(request):
        requests.append(request)
        if request.method == "GET":
            assert request.url.path == "/ultra/v1/order"
            assert request.url.params["inputMint"] == "input-mint"
            assert request.url.params["amount"] == "100"
            return httpx.Response(
                200, json={"requestId": "order-id", "transaction": "unsigned"}
            )
        assert request.url.path == "/ultra/v1/execute"
        assert json.loads(request.content) == {
            "requestId": "order-id",
            "signedTransaction": "signed",
        }
        return httpx.Response(200, json={"signature": "test-signature"})

    client = UltraApiClient()
    client.client.close()
    client.client = httpx.Client(transport=httpx.MockTransport(handler))
    monkeypatch.setattr(
        client,
        "_sign_base64_transaction",
        lambda transaction: (
            "signed-object"
            if transaction == "unsigned"
            else pytest.fail("unexpected transaction")
        ),
    )
    monkeypatch.setattr(
        client,
        "_serialize_versioned_transaction",
        lambda transaction: (
            "signed"
            if transaction == "signed-object"
            else pytest.fail("unexpected signed object")
        ),
    )
    try:
        response = client.order_and_execute(
            UltraOrderRequest(
                input_mint="input-mint", output_mint="output-mint", amount=100
            )
        )
        assert response == {"signature": "test-signature"}
        assert len(requests) == 2
    finally:
        client.close()


def test_failed_order_never_executes():
    requests = []

    def handler(request):
        requests.append(request)
        return httpx.Response(503, json={"error": "unavailable"})

    client = UltraApiClient()
    client.client.close()
    client.client = httpx.Client(transport=httpx.MockTransport(handler))
    try:
        with pytest.raises(httpx.HTTPStatusError):
            client.order_and_execute(
                UltraOrderRequest(input_mint="in", output_mint="out", amount=1)
            )
        assert len(requests) == 1
        assert requests[0].method == "GET"
    finally:
        client.close()
