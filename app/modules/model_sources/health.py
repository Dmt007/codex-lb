"""Observed Responses availability, independent of operator enablement."""


def observed_health(status: str, error_code: str | None, upstream_status: int | None) -> str | None:
    if status == "success":
        return "active"
    if status != "error" or error_code == "usage_settlement_failed":
        return None
    if upstream_status in {401, 402, 403, 429} or (upstream_status is not None and upstream_status >= 500):
        return "inactive"
    if error_code in {
        "model_source_unreachable",
        "model_source_timeout",
        "model_source_idle_timeout",
        "model_source_response_failed",
        "model_source_stream_truncated",
        "model_source_response_invalid",
        "invalid_upstream_response",
    }:
        return "inactive"
    return None
