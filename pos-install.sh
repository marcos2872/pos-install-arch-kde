#!/bin/bash
# Script de Pós-Instalação - Sistema Personalizado
# Execute após instalar o sistema: bash /root/pos-instalacao.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Configuração Pós-Instalação${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verificar se está rodando como usuário normal
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}ERRO: Não execute este script como root!${NC}"
    echo "Execute como usuário normal: bash /root/pos-instalacao.sh"
    exit 1
fi

# ===============================================
# 0. ATUALIZAR SISTEMA E PRÉ-REQUISITOS
# ===============================================
echo -e "${YELLOW}[0] Atualizando o sistema e instalando pré-requisitos...${NC}"
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git curl base-devel
echo -e "${GREEN}✓ Sistema atualizado e pré-requisitos instalados${NC}"

# ===============================================
# 1. CONFIGURAR SDDM COM TEMA BREEZE DO PLASMA
# ===============================================
echo -e "${YELLOW}[1/8] Configurando SDDM com tema Breeze do Plasma...${NC}"

# Criar diretório de config do SDDM se não existir
sudo mkdir -p /etc/sddm.conf.d/

# Configurar tema Breeze
sudo tee /etc/sddm.conf.d/kde_settings.conf > /dev/null << 'EOF'
[Theme]
Current=breeze

[General]
Numlock=on

[Users]
MaximumUid=60000
MinimumUid=1000
EOF

echo -e "${GREEN}✓ SDDM configurado com tema Breeze${NC}"

# ===============================================
# 2. INSTALAR YAY (AUR HELPER)
# ===============================================
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}[2/8] Instalando yay (AUR helper)...${NC}"
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    echo -e "${GREEN}✓ yay instalado${NC}"
else
    echo -e "${GREEN}[2/8] yay já está instalado ✓${NC}"
fi

# ===============================================
# 3. INSTALAR RUST
# ===============================================
if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}[3/8] Instalando Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo -e "${GREEN}✓ Rust instalado ($(rustc --version))${NC}"
else
    echo -e "${GREEN}[3/8] Rust já está instalado ✓ ($(rustc --version))${NC}"
fi

# ===============================================
# 4. INSTALAR NVM E NODE.JS
# ===============================================
if [ ! -d "$HOME/.nvm" ]; then
    echo -e "${YELLOW}[4/8] Instalando NVM (última versão)...${NC}"
    NVM_TAG=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | sed -n 's/.*"tag_name":[[:space:]]*"\(v[^"]*\)".*/\1/p' | head -n1)
    if [ -z "$NVM_TAG" ]; then
        NVM_TAG="v0.40.1"
        echo -e "${YELLOW}Não foi possível obter a última versão do NVM; usando ${NVM_TAG}${NC}"
    else
        echo -e "${GREEN}Última versão do NVM: ${NVM_TAG}${NC}"
    fi
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_TAG}/install.sh | bash
    
    # Carregar NVM no script atual
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    echo -e "${GREEN}✓ NVM instalado${NC}"
    
    echo -e "${YELLOW}Instalando Node.js LTS...${NC}"
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    echo -e "${GREEN}✓ Node.js instalado ($(node --version))${NC}"
    echo -e "${GREEN}✓ npm instalado ($(npm --version))${NC}"
    echo -e "${YELLOW}Instalando pnpm...${NC}"
    if command -v corepack &> /dev/null; then
        corepack enable
        corepack prepare pnpm@latest --activate
    else
        npm install -g pnpm
    fi
    echo -e "${GREEN}✓ pnpm instalado ($(pnpm --version))${NC}"
else
    echo -e "${GREEN}[4/8] NVM já está instalado ✓${NC}"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if command -v node &> /dev/null; then
        echo -e "${GREEN}Node.js: $(node --version)${NC}"
    fi
    # Verificar se há versão mais recente do NVM e atualizar se necessário
    CURRENT_NVM_VER=$(nvm --version 2>/dev/null || true)
    NVM_LATEST_TAG=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | sed -n 's/.*"tag_name":[[:space:]]*"\(v[^"]*\)".*/\1/p' | head -n1)
    if [ -n "$NVM_LATEST_TAG" ] && [ -n "$CURRENT_NVM_VER" ] && [ "$CURRENT_NVM_VER" != "${NVM_LATEST_TAG#v}" ]; then
        echo -e "${YELLOW}Atualizando NVM de v${CURRENT_NVM_VER} para ${NVM_LATEST_TAG}...${NC}"
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST_TAG}/install.sh | bash
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        echo -e "${GREEN}✓ NVM atualizado para ${NVM_LATEST_TAG}${NC}"
    elif [ -n "$CURRENT_NVM_VER" ]; then
        echo -e "${GREEN}NVM já está na última versão (${CURRENT_NVM_VER})${NC}"
    else
        echo -e "${YELLOW}Não foi possível verificar a última versão do NVM (sem internet ou limite da API). Mantendo versão atual.${NC}"
    fi
    # Instalar pnpm se ainda não estiver disponível
    if ! command -v pnpm &> /dev/null; then
        echo -e "${YELLOW}Instalando pnpm...${NC}"
        if command -v corepack &> /dev/null; then
            corepack enable
            corepack prepare pnpm@latest --activate
        else
            npm install -g pnpm
        fi
        echo -e "${GREEN}✓ pnpm instalado ($(pnpm --version))${NC}"
    else
        echo -e "${GREEN}pnpm já está instalado ✓ ($(pnpm --version))${NC}"
    fi
fi

# ===============================================
# 5. INSTALAR PACOTES DO AUR
# ===============================================
echo -e "${YELLOW}[5/8] Instalando Visual Studio Code...${NC}"
yay -S --noconfirm visual-studio-code-bin
echo -e "${GREEN}✓ VSCode instalado${NC}"

echo -e "${YELLOW}[6/8] Instalando Google Chrome...${NC}"
yay -S --noconfirm google-chrome
echo -e "${GREEN}✓ Chrome instalado${NC}"

echo -e "${YELLOW}[7/8] Instalando Lazydocker...${NC}"
yay -S --noconfirm lazydocker-bin
echo -e "${GREEN}✓ Lazydocker instalado${NC}"

echo -e "${YELLOW}[8/8] Instalando pacotes extras...${NC}"
yay -S --noconfirm brave-bin discord postman-bin
echo -e "${GREEN}✓ Pacotes extras instalados${NC}"

# ===============================================
# 6. HABILITAR SERVIÇOS
# ===============================================
echo -e "${YELLOW}Habilitando serviços do sistema...${NC}"
sudo systemctl enable sddm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable docker
sudo systemctl enable libvirtd
echo -e "${GREEN}✓ Serviços habilitados${NC}"

# ===============================================
# 7. ADICIONAR USUÁRIO AOS GRUPOS
# ===============================================
echo -e "${YELLOW}Adicionando usuário aos grupos necessários...${NC}"
sudo usermod -aG docker,libvirt,kvm $USER
echo -e "${GREEN}✓ Usuário adicionado aos grupos${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Configuração concluída!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Reinicie o sistema: sudo reboot"
echo "2. A tela de login Breeze do Plasma será exibida"
echo "3. Faça logout e login novamente para aplicar os grupos"
echo ""
echo -e "${BLUE}Ferramentas de desenvolvimento instaladas:${NC}"
echo "  • Rust (rustc, cargo)"
echo "  • Node.js (via NVM)"
echo "  • npm"
echo "  • pnpm"
echo ""
echo -e "${BLUE}Aplicativos instalados:${NC}"
echo "  • Visual Studio Code"
echo "  • Google Chrome"
echo "  • Lazydocker"
echo "  • Brave Browser"
echo "  • Discord"
echo "  • Postman"
echo ""
echo -e "${YELLOW}Para usar Node.js em novos terminais:${NC}"
echo "  source ~/.bashrc  (ou ~/.zshrc se usar zsh)"
echo ""
