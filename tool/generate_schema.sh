#!/usr/bin/env bash
# Regenerates the schema dump and the migration-test helpers.
#
# Run after bumping latestSchemaVersion (see lib/data/database/migrations.dart):
#   tool/generate_schema.sh
#
# The dump for the current version is written to drift_schemas/. Never change
# or delete the dump of a version that has been released: the migration tests
# use it to build the old database.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(grep -E "^const int latestSchemaVersion" lib/data/database/app_database.dart | grep -oE '[0-9]+')
dart run drift_dev schema dump lib/data/database/app_database.dart "drift_schemas/drift_schema_v${version}.json"
dart run drift_dev schema generate drift_schemas/ test/generated/

# The sync_state table has a column called table_name; the generated helper
# turns that into a Dart getter named `tableName`, which clashes with drift's
# own Table.tableName. Only the Dart name changes; the SQL name does not.
for f in test/generated/schema_v*.dart; do
  sed -i -E 's/\btableName\b/syncTableName/g' "$f"
done
