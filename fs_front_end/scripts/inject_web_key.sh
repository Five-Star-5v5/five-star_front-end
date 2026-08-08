#!/bin/bash
# Injecte la clé Google Maps dans index.html depuis web/.env
# Usage: bash scripts/inject_web_key.sh

set -e

ENV_FILE="web/.env"
INDEX_FILE="web/index.html"

if [ ! -f "$ENV_FILE" ]; then
  echo "Erreur : $ENV_FILE introuvable. Crée-le avec MAPS_API_KEY=ta_clé"
  exit 1
fi

source "$ENV_FILE"

if [ -z "$MAPS_API_KEY" ]; then
  echo "Erreur : MAPS_API_KEY non défini dans $ENV_FILE"
  exit 1
fi

sed -i '' "s/YOUR_API_KEY_HERE/$MAPS_API_KEY/g" "$INDEX_FILE"
echo "Clé injectée dans $INDEX_FILE"

# Empêche git de tracker les changements locaux sur index.html
git update-index --assume-unchanged "$INDEX_FILE" 2>/dev/null || true
