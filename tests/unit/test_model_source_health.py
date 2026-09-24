import pytest

from app.modules.model_sources.health import observed_health


@pytest.mark.parametrize(
    ("status", "code", "http_status", "expected"),
    [
        ("success", None, 200, "active"),
        ("error", "rejected", 401, "inactive"),
        ("error", "rejected", 429, "inactive"),
        ("error", "rejected", 503, "inactive"),
        ("error", "bad_request", 400, None),
        ("cancelled", "client_disconnected", 200, None),
        ("error", "usage_settlement_failed", 200, None),
        ("error", "model_source_unreachable", None, "inactive"),
        ("error", "model_source_stream_truncated", 200, "inactive"),
    ],
)
def test_observed_health(status, code, http_status, expected):
    assert observed_health(status, code, http_status) == expected
