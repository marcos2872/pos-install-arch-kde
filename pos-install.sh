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
echo -e "${YELLOW}[1/9] Configurando SDDM com tema Breeze do Plasma...${NC}"

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
    echo -e "${YELLOW}[2/9] Instalando yay (AUR helper)...${NC}"
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    echo -e "${GREEN}✓ yay instalado${NC}"
else
    echo -e "${GREEN}[2/9] yay já está instalado ✓${NC}"
fi

# ===============================================
# 3. INSTALAR RUST
# ===============================================
if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}[3/9] Instalando Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo -e "${GREEN}✓ Rust instalado ($(rustc --version))${NC}"
else
    echo -e "${GREEN}[3/9] Rust já está instalado ✓ ($(rustc --version))${NC}"
fi

# ===============================================
# 4. INSTALAR NVM E NODE.JS
# ===============================================
if [ ! -d "$HOME/.nvm" ]; then
    echo -e "${YELLOW}[4/9] Instalando NVM (última versão)...${NC}"
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
    echo -e "${GREEN}[4/9] NVM já está instalado ✓${NC}"
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
# 4. INSTALAR PACOTES DO AUR (OPCIONAIS)
# ===============================================
echo -e "${YELLOW}[4/9] Instalando pacotes do AUR...${NC}"

# Instalar Discord (opcional)
read -p "Deseja instalar o Discord? (s/n) " install_discord
if [[ "$install_discord" == "s" ]]; then
    yay -S --noconfirm discord
    echo -e "${GREEN}✓ Discord instalado${NC}"
else
    echo -e "${YELLOW}✗ Discord não instalado${NC}"
fi

# Instalar LocalSend (opcional)
read -p "Deseja instalar o LocalSend? (s/n) " install_localsend
if [[ "$install_localsend" == "s" ]]; then
    yay -S --noconfirm localsend-bin
    echo -e "${GREEN}✓ LocalSend instalado${NC}"
else
    echo -e "${YELLOW}✗ LocalSend não instalado${NC}"
fi

# Instalar Brave (opcional)
read -p "Deseja instalar o Brave? (s/n) " install_brave
if [[ "$install_brave" == "s" ]]; then
    yay -S --noconfirm brave-bin
    echo -e "${GREEN}✓ Brave instalado${NC}"
else
    echo -e "${YELLOW}✗ Brave não instalado${NC}"
fi

# Instalar Zoom (opcional)
read -p "Deseja instalar o Zoom? (s/n) " install_zoom
if [[ "$install_zoom" == "s" ]]; then
    yay -S --noconfirm zoom
    echo -e "${GREEN}✓ Zoom instalado${NC}"
else
    echo -e "${YELLOW}✗ Zoom não instalado${NC}"
fi

# Instalar Obsidian (opcional)
read -p "Deseja instalar o Obsidian? (s/n) " install_obsidian
if [[ "$install_obsidian" == "s" ]]; then
    yay -S --noconfirm obsidian
    echo -e "${GREEN}✓ Obsidian instalado${NC}"
else
    echo -e "${YELLOW}✗ Obsidian não instalado${NC}"
fi

# Instalar Claude Desktop (opcional)
read -p "Deseja instalar o Claude Desktop? (s/n) " install_claude
if [[ "$install_claude" == "s" ]]; then
    yay -S --noconfirm claude-desktop-native
    echo -e "${GREEN}✓ Claude Desktop instalado${NC}"
else
    echo -e "${YELLOW}✗ Claude Desktop não instalado${NC}"
fi

# Instalar Zed (opcional)
read -p "Deseja instalar o Zed? (s/n) " install_zed
if [[ "$install_zed" == "s" ]]; then
    curl -f https://zed.dev/install.sh | sh
    echo -e "${GREEN}✓ Zed instalado${NC}"
else
    echo -e "${RED}✗ Instalação do Zed pulada${NC}"
fi

# Instalar JetBrains Toolbox (opcional)
read -p "Deseja instalar o jetbrains-toolbox? (s/n) " install_jetbrains
if [[ "$install_jetbrains" == "s" ]]; then
    yay -S --noconfirm jetbrains-toolbox
    echo -e "${GREEN}✓ JetBrains Toolbox instalado${NC}"
    
    # Desabilitar autostart do JetBrains Toolbox
    AUTOSTART_DIR="$HOME/.config/autostart"
    JETBRAINS_AUTOSTART="$AUTOSTART_DIR/jetbrains-toolbox.desktop"
    
    if [ -f "$JETBRAINS_AUTOSTART" ]; then
        rm -f "$JETBRAINS_AUTOSTART"
        echo -e "${GREEN}✓ Autostart do JetBrains Toolbox desabilitado${NC}"
    fi
    
    # Prevenir criação futura do autostart
    mkdir -p "$AUTOSTART_DIR"
    tee "$JETBRAINS_AUTOSTART" > /dev/null << 'EOF'
[Desktop Entry]
Type=Application
Name=JetBrains Toolbox
Exec=false
Hidden=true
NoDisplay=true
X-GNOME-Autostart-enabled=false
EOF
    echo -e "${GREEN}✓ Autostart do JetBrains Toolbox bloqueado permanentemente${NC}"
else
    echo -e "${YELLOW}✗ JetBrains Toolbox não instalado${NC}"
fi

# ===============================================
# 5. INSTALAR PACOTES DO AUR
# ===============================================
echo -e "${YELLOW}[5/9] Instalando Partition Manager...${NC}"
yay -S --noconfirm partitionmanager
echo -e "${GREEN}✓ Partition Manager instalado${NC}"

echo -e "${YELLOW}[6/9] Instalando Visual Studio Code...${NC}"
yay -S --noconfirm visual-studio-code-bin
echo -e "${GREEN}✓ VSCode instalado${NC}"

echo -e "${YELLOW}[7/9] Instalando Google Chrome...${NC}"
yay -S --noconfirm google-chrome
echo -e "${GREEN}✓ Chrome instalado${NC}"

echo -e "${YELLOW}[8/9] Instalando Postman...${NC}"
yay -S --noconfirm postman-bin
echo -e "${GREEN}✓ Postman instalado${NC}"

echo -e "${YELLOW}Instalando GitHub CLI...${NC}"
yay -S --needed --noconfirm github-cli
echo -e "${GREEN}✓ GitHub CLI instalado${NC}"

echo -e "${YELLOW}[9/9] Instalando Lazydocker...${NC}"
yay -S --noconfirm lazydocker-bin
echo -e "${GREEN}✓ Lazydocker instalado${NC}"

# Criar atalho do Lazydocker com ícone docker.png
echo -e "${YELLOW}Criando atalho do Lazydocker...${NC}"

# Diretórios e caminhos
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd || echo "")
APPLICATIONS_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$APPLICATIONS_DIR/lazydocker.desktop"
ICON_DIR="$HOME/.local/share/icons"
ICON_DEST="$ICON_DIR/docker.png"

mkdir -p "$APPLICATIONS_DIR" "$ICON_DIR"

# Encontrar a imagem docker.png preferindo repo/images, depois /images, depois ~/images
ICON_SOURCE=""
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/images/docker.png" ]; then
    ICON_SOURCE="$SCRIPT_DIR/images/docker.png"
elif [ -f "/images/docker.png" ]; then
    ICON_SOURCE="/images/docker.png"
elif [ -f "$HOME/images/docker.png" ]; then
    ICON_SOURCE="$HOME/images/docker.png"
fi

ICON_ENTRY="lazydocker"
if [ -n "$ICON_SOURCE" ]; then
    cp -f "$ICON_SOURCE" "$ICON_DEST"
    ICON_ENTRY="$ICON_DEST"
    echo -e "${GREEN}✓ Ícone copiado para $ICON_DEST${NC}"
else
    # Tentar baixar do repositório (uso direto via curl/wget)
    ICON_URL="https://raw.githubusercontent.com/marcos2872/pos-install-arch-kde/main/images/docker.png"
    if curl -fsSL "$ICON_URL" -o "$ICON_DEST"; then
        ICON_ENTRY="$ICON_DEST"
        echo -e "${GREEN}✓ Ícone baixado de $ICON_URL para $ICON_DEST${NC}"
    else
        echo -e "${YELLOW}Imagem docker.png não encontrada e download falhou; usando ícone padrão do sistema.${NC}"
    fi
fi

# Escolher comando Exec: usar Konsole se disponível
if command -v konsole &> /dev/null; then
    EXEC_CMD="konsole -e lazydocker"
    TERMINAL_FLAG="false"
else
    EXEC_CMD="lazydocker"
    TERMINAL_FLAG="true"
fi

tee "$DESKTOP_FILE" > /dev/null << EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Lazydocker
Comment=UI de terminal para Docker e Docker Compose
Exec=$EXEC_CMD
Terminal=$TERMINAL_FLAG
Icon=$ICON_ENTRY
Categories=System;Utility;Development;
StartupNotify=false
EOF

chmod +x "$DESKTOP_FILE"
echo -e "${GREEN}✓ Atalho criado no menu: $DESKTOP_FILE${NC}"

# ===============================================
# 5.1. CONFIGURAR TEMA STARSHIP (PROMPT TERMINAL)
# ===============================================
echo -e "${YELLOW}Configurando tema Starship para o terminal...${NC}"
yay -S --needed --noconfirm starship

# Criar configuração padrão do Starship se não existir
mkdir -p "$HOME/.config"
if [ ! -f "$HOME/.config/starship.toml" ]; then
    tee "$HOME/.config/starship.toml" > /dev/null << 'EOF'
# Configuração básica do Starship
add_newline = false

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[directory]
truncation_length = 4
style = "bold blue"

[git_branch]
symbol = " "

[nodejs]
format = "via [ $version](bold green) "

[rust]
format = "via [ $version](bold red) "
EOF
    echo -e "${GREEN}✓ Configuração padrão do Starship criada em ~/.config/starship.toml${NC}"
else
    echo -e "${GREEN}Configuração do Starship já existe, mantendo atual${NC}"
fi

# Habilitar no bash
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q 'starship init bash' "$HOME/.bashrc" 2>/dev/null; then
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
        echo -e "${GREEN}✓ Starship habilitado no bash (~/.bashrc)${NC}"
    else
        echo -e "${GREEN}Starship já habilitado no bash${NC}"
    fi
else
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    echo -e "${GREEN}✓ Starship habilitado no bash (~/.bashrc criado)${NC}"
fi

# Habilitar no zsh (se existir)
if command -v zsh &> /dev/null; then
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null; then
            echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
            echo -e "${GREEN}✓ Starship habilitado no zsh (~/.zshrc)${NC}"
        else
            echo -e "${GREEN}Starship já habilitado no zsh${NC}"
        fi
    else
        echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
        echo -e "${GREEN}✓ Starship habilitado no zsh (~/.zshrc criado)${NC}"
    fi
fi

# ===============================================
# 5.2. INSTALAR DOCKER E DOCKER COMPOSE
# ===============================================
echo -e "${YELLOW}Instalando Docker e Docker Compose...${NC}"
sudo pacman -S --needed --noconfirm docker docker-compose docker-buildx
echo -e "${GREEN}✓ Docker e Docker Compose instalados${NC}"

# ===============================================
# 5.3. INSTALAR LIBVIRT E QEMU
# ===============================================
echo -e "${YELLOW}Instalando libvirt, QEMU e ferramentas de virtualização...${NC}"
sudo pacman -S --needed --noconfirm libvirt qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat
echo -e "${GREEN}✓ libvirt, QEMU e ferramentas de virtualização instalados${NC}"

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

# ===============================================
# 7.1. CONFIGURAR SUDO PARA DOCKER (NOPASSWD)
# ===============================================
echo -e "${YELLOW}Configurando sudo para docker (NOPASSWD)...${NC}"
SUDO_DOCKER_FILE="/etc/sudoers.d/10-docker-nopasswd"
sudo tee "$SUDO_DOCKER_FILE" > /dev/null << 'EOF'
Cmnd_Alias DOCKER_CMDS = /usr/bin/docker, /usr/bin/docker-compose, /usr/bin/docker-buildx
%docker ALL=(ALL) NOPASSWD: DOCKER_CMDS
EOF
sudo chmod 440 "$SUDO_DOCKER_FILE"
if sudo visudo -cf "$SUDO_DOCKER_FILE" >/dev/null; then
    echo -e "${GREEN}✓ Regra sudoers criada: $SUDO_DOCKER_FILE${NC}"
else
    echo -e "${RED}Falha ao validar sudoers ($SUDO_DOCKER_FILE). Removendo arquivo para segurança.${NC}"
    sudo rm -f "$SUDO_DOCKER_FILE"
fi

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
echo "  • Starship (prompt do terminal)"
echo ""
echo -e "${BLUE}Aplicativos instalados:${NC}"
echo "  • Visual Studio Code"
echo "  • Google Chrome"
echo "  • Lazydocker"
echo "  • Docker"
echo "  • Brave Browser"
echo "  • Discord"
echo "  • Postman"
echo ""
echo -e "${YELLOW}Para usar Node.js em novos terminais:${NC}"
echo "  source ~/.bashrc  (ou ~/.zshrc se usar zsh)"
echo ""
