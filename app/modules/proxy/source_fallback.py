"""Eligibility for a fresh Responses request to try local accounts after a source."""

from collections.abc import Mapping

from app.core.openai.model_registry import get_model_registry
from app.core.openai.requests import ResponsesRequest
from app.db.models import ModelSource
from app.modules.model_sources.forwarding import ModelSourceForwardingError


def allows_subscription_fallback(source: ModelSource, payload: ResponsesRequest, headers: Mapping[str, str]) -> bool:
    return bool(
        source.prefer_for_responses
        and payload.previous_response_id is None
        and not headers.get("x-codex-turn-state")
        and payload.model in get_model_registry().get_models_with_fallback()
    )


def is_source_rejection(exc: ModelSourceForwardingError) -> bool:
    return exc.before_dispatch or exc.upstream_status_code in {401, 402, 403, 429, 503}
