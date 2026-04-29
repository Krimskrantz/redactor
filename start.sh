#!/bin/bash
# PII Redaktor – starta servern

cd "$(dirname "$0")"

# Installera beroenden om de saknas
if ! python3 -c "import fastapi" 2>/dev/null; then
  echo "Installerar beroenden..."
  pip install -r requirements.txt
fi

echo ""
echo "  PII Redaktor"
echo "  ─────────────────────────────"
echo "  Öppna: http://localhost:8000"
echo "  OBS: Modellen laddas vid första uppladdning (~30 sek)"
echo ""

uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
