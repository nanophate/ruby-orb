#!/usr/bin/env bash

if [ "$CIRCLE_NODE_TOTAL" -eq 1 ]; then
  printf '%s\n' "Your job parallelism is set to 1."
  printf '%s\n' "The split test by timings requires at least 2 nodes to generate historical timing data."
  printf '%s\n' "Consider increasing your job parallelism to 2 or more."
  printf '%s\n' "See https://circleci.com/docs/2.0/parallelism-faster-jobs/#using-the-circleci-cli-to-split-tests for more information."
fi

# Disable bash glob expansion
# Without this, the glob parameter will be expanded before the split command is run
set -o noglob

if ! mkdir -p "$PARAM_OUT_PATH"; then
  printf '%s\n' "Failed to create output directory: \"$PARAM_OUT_PATH\""
  exit 1
fi

# Split globs per comma and run the CLI split command
read -ra globs <<< "$PARAM_INCLUDE"
test_files=($(circleci tests glob "${globs[@]}" | circleci tests run --command "xargs echo" --verbose --split-by=timings))

args=()

if [ -n "$PARAM_ORDER" ]; then
  args+=(--order "$PARAM_ORDER")
fi

if [ -n "$PARAM_TAG" ]; then
  args+=(--tag "$PARAM_TAG")
fi

# Parse array of test files to string separated by single space and run tests
# Leaving set -x here because it's useful for debugging what files are being tested
set -x
bundle exec rspec "${test_files[@]}" --profile 10 --format RspecJunitFormatter --out "$PARAM_OUT_PATH"/results.xml --format progress "${args[@]}"
set +x
