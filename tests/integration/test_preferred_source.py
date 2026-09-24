from unittest.mock import AsyncMock

import pytest
from aiohttp import web
from fastapi.responses import JSONResponse
from sqlalchemy import select

from app.db.models import ApiKeyUsageReservation
from app.db.session import SessionLocal
from app.modules.model_sources.repository import ModelSourcesRepository
from app.modules.proxy import api
from tests.integration.model_source_helpers import _create_model_source, _enable_api_key_auth, stub_source_upstreams

pytestmark = [pytest.mark.integration, pytest.mark.asyncio]


async def test_health_ignores_old_source_configuration(async_client):
    source_id = await _create_model_source(
        async_client,
        name="health-fence",
        model="gpt-5.6-sol",
        base_url="http://localhost:1/v1",
        supports_responses=True,
    )
    async with SessionLocal() as session:
        source = await ModelSourcesRepository(session).get_by_id(source_id)
        session.expunge_all()
    await async_client.patch(f"/api/model-sources/{source_id}", json={"apiKey": "changed"})
    async with SessionLocal() as session:
        await ModelSourcesRepository(session).record_health(source, "inactive")
    sources = (await async_client.get("/api/model-sources/")).json()["sources"]
    assert sources[0]["healthStatus"] == "unknown"


@pytest.mark.parametrize(
    "path", ["/v1/responses", "/v1/responses/", "/backend-api/codex/responses", "/backend-api/codex/responses/"]
)
@pytest.mark.parametrize("stream", [False, True])
@pytest.mark.parametrize("status", [401, 402, 403, 429, 503, 400])
async def test_company_rejection_fallback(async_client, monkeypatch, path, status, stream):
    calls = []

    async def upstream(request):
        calls.append(request.path)
        return web.json_response({"error": {"code": "rejected", "message": "rejected"}}, status=status)

    local = AsyncMock(return_value=JSONResponse({"local": True}))
    monkeypatch.setattr(api, "_collect_responses", local)
    monkeypatch.setattr(api, "_stream_responses", local)
    async with stub_source_upstreams() as start:
        source_id = await _create_model_source(
            async_client, name="company", model="gpt-5.6-sol", base_url=await start(upstream), supports_responses=True
        )
        patched = await async_client.patch(f"/api/model-sources/{source_id}", json={"preferForResponses": True})
        assert patched.json()["preferForResponses"] is True
        assert "apiKey" not in patched.json()
        response = await async_client.post(path, json={"model": "gpt-5.6-sol", "input": "hello", "stream": stream})
        assert calls == ["/v1/responses"]
        sources = (await async_client.get("/api/model-sources/")).json()["sources"]
        assert sources[0]["healthStatus"] == ("unknown" if status == 400 else "inactive")
        if status == 400:
            assert response.status_code == 400
            local.assert_not_awaited()
        else:
            assert response.json() == {"local": True}
            local.assert_awaited_once()
        local.reset_mock()
        await async_client.patch(f"/api/model-sources/{source_id}", json={"isEnabled": False})
        response = await async_client.post(path, json={"model": "gpt-5.6-sol", "input": "hello", "stream": stream})
        assert response.json() == {"local": True}
        assert len(calls) == 1
        local.assert_awaited_once()


@pytest.mark.parametrize("failure", ["timeout", "release", "success"])
async def test_company_no_replay(async_client, monkeypatch, failure):
    local = AsyncMock(return_value=JSONResponse({"local": True}))
    monkeypatch.setattr(api, "_collect_responses", local)

    async def upstream(request):
        if failure == "success":
            return web.json_response(
                {
                    "id": "resp_company",
                    "object": "response",
                    "status": "completed",
                    "model": "gpt-5.6-sol",
                    "output": [],
                    "usage": {"input_tokens": 1, "output_tokens": 0, "total_tokens": 1},
                }
            )
        return web.json_response({"error": {"code": "quota_exceeded"}}, status=429)

    async with stub_source_upstreams() as start:
        source_id = await _create_model_source(
            async_client, name="company", model="gpt-5.6-sol", base_url=await start(upstream), supports_responses=True
        )
        await async_client.patch(f"/api/model-sources/{source_id}", json={"preferForResponses": True})
        if failure == "timeout":
            from app.modules.model_sources.forwarding import _unreachable_error

            monkeypatch.setattr(
                api, "forward_source_responses", AsyncMock(side_effect=_unreachable_error(TimeoutError()))
            )
        elif failure == "release":
            from app.modules.proxy.source_dispatch import SourceDispatch

            original = SourceDispatch.finish_with_forwarding_error

            async def failed_cleanup(self, exc):
                await original(self, exc)
                self.cleanup_failed = True

            monkeypatch.setattr(SourceDispatch, "finish_with_forwarding_error", failed_cleanup)
        response = await async_client.post(
            "/v1/responses", json={"model": "gpt-5.6-sol", "input": "hello", "stream": False}
        )
        local.assert_not_awaited()
        if failure == "success":
            assert response.status_code == 200
            assert response.json()["id"] == "resp_company"
            sources = (await async_client.get("/api/model-sources/")).json()["sources"]
            assert sources[0]["healthStatus"] == "active"
            reset = await async_client.patch(f"/api/model-sources/{source_id}", json={"apiKey": "replacement"})
            assert reset.json()["healthStatus"] == "unknown"
        else:
            assert response.status_code >= 400


@pytest.mark.parametrize("release_fails", [False, True])
async def test_company_reservation_released_before_local_attempt(async_client, monkeypatch, release_fails):
    await _enable_api_key_auth(async_client)

    async def upstream(request):
        return web.json_response({"error": {"code": "quota_exceeded"}}, status=429)

    async def local(*args, **kwargs):
        async with SessionLocal() as session:
            rows = list((await session.execute(select(ApiKeyUsageReservation))).scalars())
            assert rows and all(row.status == "released" for row in rows)
        return JSONResponse({"local": True})

    local_mock = AsyncMock(side_effect=local)
    monkeypatch.setattr(api, "_collect_responses", local_mock)
    if release_fails:
        monkeypatch.setattr(api, "_release_reservation", AsyncMock(side_effect=RuntimeError("release failed")))
    async with stub_source_upstreams() as start:
        source_id = await _create_model_source(
            async_client, name="company", model="gpt-5.6-sol", base_url=await start(upstream), supports_responses=True
        )
        await async_client.patch(f"/api/model-sources/{source_id}", json={"preferForResponses": True})
        key = await async_client.post(
            "/api/api-keys/",
            json={
                "name": "limited",
                "limits": [{"limitType": "total_tokens", "limitWindow": "weekly", "maxValue": 100000}],
            },
        )
        response = await async_client.post(
            "/v1/responses",
            headers={"Authorization": f"Bearer {key.json()['key']}"},
            json={"model": "gpt-5.6-sol", "input": "hello", "stream": False},
        )
        if release_fails:
            local_mock.assert_not_awaited()
            assert response.status_code == 429
        else:
            assert response.json() == {"local": True}
            local_mock.assert_awaited_once()


@pytest.mark.parametrize("pinned", ["previous", "turn", "file"])
async def test_company_preserves_ownership(async_client, monkeypatch, pinned):
    calls = []

    async def upstream(request):
        calls.append(request.path)
        return web.json_response({"error": {"code": "quota_exceeded"}}, status=429)

    local = AsyncMock(return_value=JSONResponse({"local": True}))
    monkeypatch.setattr(api, "_collect_responses", local)
    async with stub_source_upstreams() as start:
        source_id = await _create_model_source(
            async_client, name="company", model="gpt-5.6-sol", base_url=await start(upstream), supports_responses=True
        )
        await async_client.patch(f"/api/model-sources/{source_id}", json={"preferForResponses": True})
        body = {"model": "gpt-5.6-sol", "input": "hello", "stream": False}
        headers = {}
        if pinned == "previous":
            body["previous_response_id"] = "resp_existing"
        elif pinned == "turn":
            headers["x-codex-turn-state"] = "existing-turn"
        else:
            body["input"] = [{"role": "user", "content": [{"type": "input_file", "file_id": "file_existing"}]}]
        response = await async_client.post("/v1/responses", json=body, headers=headers)
        if pinned == "file":
            assert not calls
            local.assert_awaited_once()
        else:
            assert response.status_code == 429
            local.assert_not_awaited()
