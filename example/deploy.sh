#!/bin/sh
set -eu

flutter build web --release --wasm
cp web/_headers build/web/
wrangler pages deploy build/web --project-name=ditherkit-flutter --branch=main
