#!/usr/bin/env bash
# Regenerates everything derived from the database schema.
#
# Run after bumping latestSchemaVersion (see lib/data/database/app_database.dart):
#   tool/generate_schema.sh
#
# 1. Dumps the current version to drift_schemas/. Never change or delete the dump
#    of a version that has been released: the migration tests use it to build the
#    old database.
# 2. Regenerates the step-by-step migration helpers the app uses.
# 3. Regenerates the test helpers that can open any dumped version.
#
# The app's own upgrade code depends on the generated helpers, and the dump needs
# the app to compile. So the upgrade is swapped for a no-op while the files are
# generated, then put back.
set -euo pipefail
cd "$(dirname "$0")/.."

DB=lib/data/database/app_database.dart
cp "$DB" "$DB.bak"
restore() { mv -f "$DB.bak" "$DB"; }
trap restore EXIT

python3 - "$DB" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("import 'schema_versions.dart';\n", "")
a = s.index("        onUpgrade: stepByStep(")
b = s.index("        beforeOpen:")
s = s[:a] + "        onUpgrade: (m, from, to) async {},\n" + s[b:]
open(p, "w").write(s)
PY
rm -f lib/data/database/schema_versions.dart
dart run build_runner build >/dev/null

version=$(grep -E "^const int latestSchemaVersion" "$DB.bak" | grep -oE '[0-9]+')
dart run drift_dev schema dump "$DB" "drift_schemas/drift_schema_v${version}.json"
dart run drift_dev schema steps drift_schemas/ lib/data/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/generated/

# The sync_state table has a column called table_name; the generated helper
# turns that into a Dart getter named `tableName`, which clashes with drift's
# own Table.tableName. Only the Dart name changes; the SQL name does not.
for f in test/generated/schema_v*.dart lib/data/database/schema_versions.dart; do
  sed -i -E 's/\btableName\b/syncTableName/g' "$f"
done

trap - EXIT
restore
dart run build_runner build >/dev/null
echo "Schema version $version generated."
