#!/bin/bash
curl -f https://zed.dev/install.sh | sh

# Aplicar configurações do Zed a partir do repositório do GitHub (Fedora)
set -euo pipefail

REPO_URL="https://github.com/marcos2872/my-zed-config"
CONFIG_DIR="${HOME}/.config/zed"

echo "[zed] Garantindo pré-requisitos (git, rsync) instalados (Fedora)..."
if ! command -v git >/dev/null 2>&1 || ! command -v rsync >/dev/null 2>&1; then
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf -y install git rsync
  else
    echo "[zed] ERRO: Este script é específico para Fedora e requer 'dnf'." >&2
    exit 1
  fi
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

echo "[zed] Clonando repositório de configuração: ${REPO_URL}"
git clone --depth 1 "${REPO_URL}" "${TMP_DIR}/repo"

echo "[zed] Criando diretório de configuração: ${CONFIG_DIR}"
mkdir -p "${CONFIG_DIR}"

echo "[zed] Sincronizando configurações para ${CONFIG_DIR}"
rsync -a --delete "${TMP_DIR}/repo/" "${CONFIG_DIR}/"

echo "[zed] Configuração do Zed aplicada com sucesso."
