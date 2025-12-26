#!/bin/bash

# ==============================================================================
# KDE Tahoe - Instalador (somente instalação de temas/ícones/cursores)
# Este script instala dependências e baixa/instala os assets do tema MacTahoe.
# A aplicação/configuração pós-instalação (Kvantum, Look-and-Feel, widgets etc.)
# deve ser feita em um script separado.
# ==============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Instalando MacTahoe (temas, ícones e cursores)             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Função para pausar e mostrar erros (mantém o comportamento do script original)
pause_on_error() {
  if [ $? -ne 0 ]; then
    echo ""
    echo "❌ ERRO ENCONTRADO! Pressione ENTER para continuar..."
    read
  fi
}

# 1) Dependências necessárias para instalação dos temas
echo "📦 Instalando dependências (git, kvantum, sassc, ferramentas Qt)..."
sudo dnf install -y git kvantum kvantum-qt5 sassc qt5-qttools 2>&1
pause_on_error
echo "✅ Dependências instaladas!"
echo ""

# 2) Preparar diretório temporário (limpa caso exista)
TEMP_DIR="$HOME/mactahoe-install-temp"
if [ -d "$TEMP_DIR" ]; then
  echo "🗑️ Limpando pasta temporária anterior..."
  rm -rf "$TEMP_DIR"
fi

mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
echo "📁 Pasta temporária: $(pwd)"

# 3) MacTahoe KDE (tema Plasma + Kvantum)
echo ""
echo "🎨 Baixando MacTahoe KDE Theme..."
git clone https://github.com/marcos2872/MacTahoe-kde.git 2>&1
pause_on_error

cd MacTahoe-kde
echo "⚙️ Instalando MacTahoe KDE..."
bash ./install.sh 2>&1
pause_on_error
cd ..

# 4) MacTahoe Icons
echo ""
echo "🖼️ Baixando MacTahoe Icons..."
git clone https://github.com/marcos2872/MacTahoe-icon-theme.git 2>&1
pause_on_error

cd MacTahoe-icon-theme
echo "⚙️ Instalando Ícones MacTahoe..."
bash ./install.sh 2>&1
pause_on_error
cd ..

# 5) MacTahoe Cursors
echo ""
echo "🖱️ Baixando MacTahoe Cursors..."
# Reaproveita o repositório de ícones que contém os cursores
git clone https://github.com/marcos2872/MacTahoe-icon-theme.git MacTahoe-cursors-src 2>&1
pause_on_error

cd MacTahoe-cursors-src/cursors
echo "⚙️ Instalando Cursores MacTahoe..."
bash ./install.sh 2>&1
pause_on_error
cd ../..

# 6) Limpeza de artefatos temporários
echo ""
echo "🧹 Limpando arquivos temporários..."
rm -rf "$TEMP_DIR"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ ✅ INSTALAÇÃO CONCLUÍDA                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Os temas, ícones e cursores MacTahoe foram instalados."
echo "A aplicação e configuração pós-instalação (Kvantum, Look-and-Feel, widgets,"
echo "ícone do lançador, splash screen etc.) devem ser feitas separadamente."
