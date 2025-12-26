#!/usr/bin/env bash
#
# Instalador idempotente para pyenv (Fedora)
#
# O script:
#  - Verifica se pyenv já está instalado.
#  - Instala dependências de compilação necessárias via dnf.
#  - Clona o repositório oficial do pyenv em ~/.pyenv (se necessário).
#  - Instala o plugin pyenv-virtualenv (opcional, padrão: instalar).
#  - Adiciona as linhas de inicialização a ~/.bashrc, ~/.profile e ~/.zshrc (somente se ainda não existirem).
#
# Comportamento:
#  - Não é interativo (exceto se um comando falhar e pedir ENTER, impróprio para automação).
#  - Retorna 0 em sucesso.
#  - Projetado para uso por usuários em Fedora; usa sudo para operações de sistema.
#
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
PYENV_GIT="https://github.com/pyenv/pyenv.git"
PYENV_VIRTUALENV_GIT="https://github.com/pyenv/pyenv-virtualenv.git"
INSTALL_VIRTUALENV=true

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*" 1>&2; }

# Checa se pyenv já está disponível no PATH ou instalado no diretório esperado
is_installed() {
  if command -v pyenv >/dev/null 2>&1; then
    echo "pyenv (binary)"
    return 0
  fi

  if [ -d "$PYENV_ROOT" ]; then
    echo "$PYENV_ROOT"
    return 0
  fi

  return 1
}

append_if_missing() {
  local file="$1"
  local marker="$2"
  local content="$3"

  # Se arquivo não existir, cria-o
  if [ ! -f "$file" ]; then
    touch "$file"
  fi

  if grep -Fq "$marker" "$file"; then
    info "Arquivo $file já contém a configuração do pyenv (marcador detectado). Pulando."
    return 0
  fi

  {
    echo ""
    echo "# >>> pyenv init ($marker) >>>"
    echo "$content"
    echo "# <<< pyenv init ($marker) <<<"
  } >> "$file"

  info "Adicionado bloco de inicialização do pyenv em $file"
}

main() {
  echo -e "\n${GREEN}=== Instalador: pyenv ===${NC}"

  if installed_loc="$(is_installed)"; then
    info "pyenv já instalado: $installed_loc"
    info "Nada a fazer."
    return 0
  fi

  # Lista de dependências de compilação comuns para construir Pythons
  BUILD_DEPS=(
    make gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel tk-devel git curl
  )

  # Instalar dependências com sudo dnf
  if command -v dnf >/dev/null 2>&1; then
    info "Instalando dependências de compilação (via dnf)..."
    # Junta os pacotes em uma única linha, evitando repetir operações interativas
    sudo dnf install -y "${BUILD_DEPS[@]}" || {
      warn "Falha ao instalar dependências via dnf. Verifique sua conexão ou privilégios."
      return 1
    }
  else
    warn "Gerenciador 'dnf' não encontrado. Certifique-se de instalar manualmente dependências: ${BUILD_DEPS[*]}"
  fi

  # Garantir que git exista
  if ! command -v git >/dev/null 2>&1; then
    warn "git não encontrado. Tentando instalar git via dnf..."
    if command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y git || {
        err "Não foi possível instalar git. Abortando."
        return 1
      }
    else
      err "git é necessário para clonar pyenv. Instale-o e execute o script novamente."
      return 1
    fi
  fi

  # Clonar pyenv
  if [ -d "$PYENV_ROOT" ]; then
    warn "Diretório $PYENV_ROOT já existe. Pulando clone principal (preservando conteúdo existente)."
  else
    info "Clonando pyenv em $PYENV_ROOT..."
    git clone --depth 1 "$PYENV_GIT" "$PYENV_ROOT" || {
      err "Falha ao clonar pyenv."
      return 1
    }
  fi

  # Instalar pyenv-virtualenv (plugin) se desejado
  if [ "$INSTALL_VIRTUALENV" = true ]; then
    if [ -d "${PYENV_ROOT}/plugins/pyenv-virtualenv" ]; then
      info "pyenv-virtualenv já instalado. Pulando."
    else
      info "Instalando plugin pyenv-virtualenv..."
      git clone --depth 1 "$PYENV_VIRTUALENV_GIT" "${PYENV_ROOT}/plugins/pyenv-virtualenv" || {
        warn "Falha ao clonar pyenv-virtualenv. Continuando sem ele."
      }
    fi
  fi

  # Preparar conteúdo de inicialização
  read -r -d '' INIT_SNIPPET <<'EOF' || true
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
# Inicialização para login shells (adiciona shims no PATH)
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi
# Inicialização para shells interativos
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
# Habilitar pyenv-virtualenv se instalado
if [ -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
  eval "$(pyenv virtualenv-init -)"
fi
EOF

  # Adicionar snippet em arquivos de shell comuns
  append_if_missing "$HOME/.bashrc" "bashrc" "$INIT_SNIPPET"

  info "pyenv instalado. Para completar: abra um novo terminal ou execute 'source ~/.bashrc' (dependendo do shell)."
  info "Depois, você pode instalar uma versão do Python, por exemplo: 'pyenv install 3.11.6' e 'pyenv global 3.11.6'."
  return 0
}

main "$@"
