#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Building web assets..."
pnpm --dir web/cartographer build

echo "Syncing dist to StoryKit/Resources/web..."
rm -rf StoryKit/Resources/web
mkdir -p StoryKit/Resources/web
cp -R web/cartographer/dist/* StoryKit/Resources/web/

echo "Web assets synced successfully."
