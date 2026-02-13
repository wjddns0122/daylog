#!/bin/bash
echo "Validating schema..."
if [ -f docs/schema_v2.json ]; then
  echo "Schema exists."
else
  echo "Schema missing."
  exit 1
fi

echo "Validating fixtures..."
if [ -f test/fixtures/mixed_docs.json ]; then
  echo "Fixtures exist."
else
  echo "Fixtures missing."
  exit 1
fi

echo "Contract Gate Passed."
exit 0
