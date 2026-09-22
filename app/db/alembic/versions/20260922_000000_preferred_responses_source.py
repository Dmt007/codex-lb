"""Merge existing heads and add opt-in Responses source preference."""

import sqlalchemy as sa
from alembic import op

revision = "20260922_000000_preferred_responses_source"
down_revision = (
    "20260914_000000_add_scim_tokens",
    "20260914_000000_drop_subscription_overflow_schema",
)
branch_labels = None
depends_on = None


def upgrade() -> None:
    columns = sa.inspect(op.get_bind()).get_columns("model_sources")
    if not any(column["name"] == "prefer_for_responses" for column in columns):
        op.add_column(
            "model_sources",
            sa.Column("prefer_for_responses", sa.Boolean(), nullable=False, server_default=sa.false()),
        )


def downgrade() -> None:
    with op.batch_alter_table("model_sources") as batch_op:
        batch_op.drop_column("prefer_for_responses")
