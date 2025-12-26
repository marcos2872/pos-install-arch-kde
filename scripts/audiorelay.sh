#!/bin/bash
#
# Instalador do AudioRelay - Flatpak only
#
# Comportamento:
# - Idempotente: não fará nada se o app já estiver instalado.
# - Procura por pacotes Flatpak contendo 'audiorelay' e instala o primeiro resultado.
# - Adiciona o repositório Flathub se necessário.
# - Sai com código 0 em sucesso, >0 em falha.
#
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

APP_NAME="AudioRelay"
EXPECTED_BIN_NAMES=("audiorelay" "AudioRelay")

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*" 1>&2; }

is_installed() {
    # Verifica se um dos binários esperados está no PATH
    for b in "${EXPECTED_BIN_NAMES[@]}"; do
        if command -v "$b" >/dev/null 2>&1; then
            echo "$b"
            return 0
        fi
    done

    # Verifica se há um pacote flatpak instalado contendo 'audiorelay' no nome ou na descrição
    if command -v flatpak >/dev/null 2>&1; then
        if flatpak list --app --columns=application | grep -i audiorelay >/dev/null 2>&1; then
            echo "flatpak"
            return 0
        fi
    fi

    return 1
}

echo -e "\n${GREEN}=== Instalador (Flatpak-only): $APP_NAME ===${NC}"

if installed_loc="$(is_installed)"; then
    info "$APP_NAME já instalado: $installed_loc"
    info "Nada a fazer."
    exit 0
fi

if ! command -v flatpak >/dev/null 2>&1; then
    err "Flatpak não está instalado. Instale o flatpak primeiro e reexecute este script."
    echo "Em Fedora, por exemplo: sudo dnf install -y flatpak"
    exit 2
fi

info "Procurando pacotes Flatpak relacionados a 'audiorelay'..."
# Tenta obter IDs de aplicações; adapta se a saída do flatpak search variar entre versões
search_output="$(flatpak search audiorelay --columns=application 2>/dev/null || flatpak search audiorelay 2>/dev/null || true)"
if [ -z "$search_output" ]; then
    warn "Nenhum resultado de busca para 'audiorelay' via flatpak."
    echo
    echo "Verifique manualmente: flatpak search audiorelay"
    exit 3
fi

# Extrai o primeiro identificador que pareça com um ID de aplicação (contendo ponto) ou a primeira linha útil
package_name="$(printf '%s\n' \"$search_output\" | awk 'NF {print $1; exit}')"

if [ -z "$package_name" ]; then
    warn "Não foi possível identificar um pacote Flatpak a partir da busca."
    exit 4
fi

info "Pacote selecionado para instalação: $package_name"

# Garantir Flathub remoto
if ! flatpak remote-list | grep -qi flathub; then
    info "Adicionando repositório Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

info "Instalando $package_name via Flatpak (modo --user)..."
if flatpak install --user -y "$package_name"; then
    info "$APP_NAME instalado com sucesso via Flatpak: $package_name"
    exit 0
else
    err "Falha ao instalar $package_name via Flatpak."
    echo "Tente executar manualmente:"
    echo "  flatpak install --user -y $package_name"
    exit 5
fi
