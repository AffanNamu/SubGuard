#!/usr/bin/env bash
# Runs the recognition benchmark and writes the report.
#
#   tool/bench/run_benchmark.sh              # originals + derived degraded variants
#   BENCH_VARIANTS=0 tool/bench/run_benchmark.sh   # original photographs only
#
# Needs the OCR stand-in:  pip install rapidocr-onnxruntime opencv-python-headless
# Writes docs/recognition/results/benchmark_latest.{json,md}. The numbers are only
# as good as the data in eval/dataset: read eval/README.md and the denominators.
set -euo pipefail
cd "$(dirname "$0")/../.."
BENCH=1 flutter test test/bench/benchmark_test.dart
