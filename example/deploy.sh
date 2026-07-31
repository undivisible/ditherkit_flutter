#!/bin/sh
set -eu

flutter build web --release --no-wasm-dry-run
cp web/_headers web/flutter_service_worker.js build/web/
wrangler pages deploy build/web --project-name=ditherkit-flutter --branch=main
