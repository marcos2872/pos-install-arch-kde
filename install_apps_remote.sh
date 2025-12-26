#!/usr/bin/env bash
#
# install_apps_remote.sh
#
# Instalador standalone que baixa scripts diretamente do repositório GitHub (raw) e executa
# a sequência definida localmente (espelhando o comportamento de install_apps.sh),
# sem necessidade de clonar o repo.
#
# Uso:
#   ./install_apps_remote.sh [--no-upgrade] [--branch BRANCH] [--base-url URL] [--modules m1,m2] [--list] [--fetch-only] [--keep-temp]
#
# Exemplos:
#   ./install_apps_remote.sh
#   ./install_apps_remote.sh --no-upgrade --branch main --modules dev_tools.sh,fonts.sh
#   ./install_apps_remote.sh --list
#
set -euo pipefail

# -----------------------
# Configurações padrão
# -----------------------
REPO_RAW_BASE_DEFAULT="https://raw.githubusercontent.com/marcos2872/pos-install-fedora-kde"
BRANCH_DEFAULT="main"
TMPDIR="$(mktemp -d -t pos-install-XXXXXXXX)"
KEEP_TEMP=false
NO_UPGRADE=false
FETCH_ONLY=false

# A ordem oficial dos módulos (copiada de install_apps.sh)
MODULE_ORDER=(
  "dev_tools.sh"
  "rust.sh"
  "pyenv.sh"
  "node.sh"
  "git_gh.sh"
  "flatpak.sh"
  "fonts.sh"
  "starship.sh"
  "alacritty.sh"
  "linux_toys.sh"
  "zed.sh"
  "antigravity.sh"
  "podman.sh"
  "datagrip.sh"
  "postman.sh"
  "brave.sh"
  "chrome.sh"
  "claude.sh"
  "mcp.sh"
  "audiorelay.sh"
  "kde_tahoe.sh"
  "config.sh"
)

# -----------------------
# Funções utilitárias
# -----------------------
usage() {
  cat <<EOF
install_apps_remote.sh - Baixa e executa módulos do repositório sem clonar.

Opções:
  --no-upgrade          Não executar 'sudo dnf upgrade -y' antes.
  --branch BRANCH       Branch do repositório raw (default: ${BRANCH_DEFAULT}).
  --base-url URL        URL base para raw (default: ${REPO_RAW_BASE_DEFAULT}).
  --modules LIST        Lista separada por vírgula com scripts a executar (ex: dev_tools.sh,fonts.sh).
  --list                Mostrar a lista de módulos disponíveis e sair.
  --fetch-only          Apenas baixar scripts para o diretório temporário e sair.
  --keep-temp           Não remover diretório temporário ao finalizar (mostra o caminho).
  -h, --help            Mostrar esta ajuda.
EOF
  exit 1
}

debug() { [ "${DEBUG:-}" = "1" ] && echo "DEBUG: $*"; }

fail() {
  echo >&2 "ERRO: $*"
  cleanup
  exit 1
}

cleanup() {
  if [ "$KEEP_TEMP" = false ] && [ -d "$TMPDIR" ]; then
    rm -rf "$TMPDIR" || true
  fi
}

trap cleanup EXIT

# Escolhe ferramenta de download (curl ou wget)
download_to() {
  local url="$1"
  local dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    fail "Nem 'curl' nem 'wget' disponíveis. Instale um dos dois para continuar."
  fi
}

# Baixa um script do raw GitHub para o tmp e torna executável
fetch_script() {
  local script_name="$1"
  local base_url="$2"
  local branch="$3"

  local url="${base_url}/${branch}/scripts/${script_name}"
  local dest="${TMPDIR}/${script_name}"

  printf "Baixando %s ... " "$script_name"
  if download_to "$url" "$dest"; then
    chmod +x "$dest"
    echo "OK"
  else
    echo "FALHOU"
    rm -f "$dest"
    return 1
  fi
}

# Executa um script local (do tmp dir) com tratamento similar ao install_apps.sh
run_local_script() {
  local script_path="$1"
  local description="$2"

  echo -e "\n\033[0;32m=== $description ===\033[0m"
  bash "$script_path" || {
    echo -e "\n\033[0;31mErro ao executar $(basename "$script_path"). Pressione ENTER para continuar ou Ctrl+C para abortar.\033[0m"
    read -r
  }
}

# -----------------------
# Parse de argumentos
# -----------------------
BRANCH="${BRANCH_DEFAULT}"
BASE_URL="${REPO_RAW_BASE_DEFAULT}"
SELECTED_MODULES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --no-upgrade)
      NO_UPGRADE=true
      shift
      ;;
    --branch)
      BRANCH="${2:-}"
      shift 2
      ;;
    --base-url)
      BASE_URL="${2:-}"
      shift 2
      ;;
    --modules)
      IFS=',' read -r -a SELECTED_MODULES <<< "${2:-}"
      shift 2
      ;;
    --list)
      echo "Módulos (ordem padrão):"
      for m in "${MODULE_ORDER[@]}"; do echo "  - $m"; done
      exit 0
      ;;
    --fetch-only)
      FETCH_ONLY=true
      shift
      ;;
    --keep-temp)
      KEEP_TEMP=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    --debug)
      DEBUG=1
      shift
      ;;
    *)
      usage
      ;;
  esac
done

# -----------------------
# Preparar lista final de módulos
# -----------------------
if [ "${#SELECTED_MODULES[@]}" -gt 0 ]; then
  # usar a lista passada pelo usuário (mantendo a ordem fornecida)
  MODULES_TO_RUN=("${SELECTED_MODULES[@]}")
else
  MODULES_TO_RUN=("${MODULE_ORDER[@]}")
fi

echo "Usando base raw: ${BASE_URL}/${BRANCH}"
echo "Diretório temporário: ${TMPDIR}"

# -----------------------
# Baixar scripts
# -----------------------
echo "Baixando scripts selecionados..."
FAILED_DOWNLOADS=0
for s in "${MODULES_TO_RUN[@]}"; do
  if ! fetch_script "$s" "$BASE_URL" "$BRANCH"; then
    echo "Não foi possível baixar $s"
    FAILED_DOWNLOADS=$((FAILED_DOWNLOADS + 1))
  fi
done

if [ "$FAILED_DOWNLOADS" -gt 0 ]; then
  fail "Houve $FAILED_DOWNLOADS falhas no download. Abortando."
fi

# Se o usuário só queria baixar, sair agora
if [ "$FETCH_ONLY" = true ]; then
  echo "Scripts baixados em: $TMPDIR"
  if [ "$KEEP_TEMP" = false ]; then
    echo "(Use --keep-temp para manter os arquivos)"
  fi
  exit 0
fi

# -----------------------
# Atualização do sistema (opcional)
# -----------------------
if [ "$NO_UPGRADE" = false ]; then
  echo -e "\n\033[0;32mExecutando sistema upgrade: sudo dnf upgrade -y\033[0m"
  if command -v sudo >/dev/null 2>&1; then
    sudo dnf upgrade -y || {
      echo -e "\033[0;31mAviso: 'dnf upgrade' falhou ou foi interrompido. Continuando com execução dos módulos.\033[0m"
    }
  else
    echo -e "\033[0;33mAviso: 'sudo' não encontrado. Pulando upgrade.\033[0m"
  fi
else
  echo "Pulando 'dnf upgrade' (--no-upgrade)."
fi

# -----------------------
# Executar scripts na ordem
# -----------------------
echo -e "\n\033[0;32mIniciando execução modular...\033[0m"
for s in "${MODULES_TO_RUN[@]}"; do
  local_path="${TMPDIR}/${s}"
  if [ ! -x "$local_path" ]; then
    echo -e "\033[0;31mArquivo não encontrado ou não executável: $local_path. Pulando.\033[0m"
    continue
  fi

  # descrição amigável
  desc="Executando ${s}"
  run_local_script "$local_path" "$desc"
done

echo -e "\n\033[0;32m=== Instalação Remota Completa! ===\033[0m"
echo "Se você deseja manter os arquivos baixados: $TMPDIR"
if [ "$KEEP_TEMP" = false ]; then
  echo "Os arquivos serão removidos automaticamente."
fi

# Não remover se o usuário pediu para manter
if [ "$KEEP_TEMP" = true ]; then
  # desativar o cleanup automático; trap permanece, então removemos o trap
  trap - EXIT
  echo "Manter o diretório temporário conforme solicitado (--keep-temp)."
else
  # limpeza será feita pelo trap EXIT
  :
fi

exit 0
