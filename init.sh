#!/usr/bin/env bash
set -euo pipefail

# Permette di sovrascrivere il path di python3.11 con la variabile PYTHON
PYTHON="${PYTHON:-python3.11}"
REQ_FILE="./sim/requirements.txt"

# Controllo presenza Python
if ! command -v "$PYTHON" >/dev/null 2>&1; then
  echo "Errore: $PYTHON non trovato. Installa Python 3.11 o modifica la variabile PYTHON."
  exit 1
fi

# Controllo esistenza file requirements
if [ ! -f "$REQ_FILE" ]; then
  echo "Errore: file dei requisiti non trovato in $REQ_FILE"
  exit 1
fi

# Creazione virtual environment
echo "Creo virtual environment con $PYTHON..."
"$PYTHON" -m venv .venv

# Attivazione
echo "Attivo l'ambiente..."
# shellcheck disable=SC1091
source .venv/bin/activate

# Aggiorno pip e installo dipendenze
echo "Aggiorno pip e installo dipendenze da $REQ_FILE..."
pip install --upgrade pip
pip install -r "$REQ_FILE"

echo "✓ Ambiente pronto: usa 'source .venv/bin/activate' per attivarlo in futuro."
