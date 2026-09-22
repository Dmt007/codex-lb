import importlib

import sqlalchemy as sa
from alembic.migration import MigrationContext
from alembic.operations import Operations


def test_preferred_source_migration_preserves_historical_rows():
    migration = importlib.import_module("app.db.alembic.versions.20260922_000000_preferred_responses_source")
    engine = sa.create_engine("sqlite://")
    try:
        with engine.begin() as connection:
            connection.exec_driver_sql("CREATE TABLE model_sources (id TEXT PRIMARY KEY)")
            connection.exec_driver_sql("INSERT INTO model_sources VALUES ('existing')")
            with Operations.context(MigrationContext.configure(connection)):
                migration.upgrade()
                migration.upgrade()
                assert connection.exec_driver_sql("SELECT prefer_for_responses FROM model_sources").scalar() == 0
                migration.downgrade()
                assert "prefer_for_responses" not in {
                    column["name"] for column in sa.inspect(connection).get_columns("model_sources")
                }
                migration.upgrade()
                assert connection.exec_driver_sql("SELECT prefer_for_responses FROM model_sources").scalar() == 0
                assert connection.exec_driver_sql("SELECT id FROM model_sources").scalar() == "existing"
    finally:
        engine.dispose()
