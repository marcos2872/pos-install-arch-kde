#!/bin/bash

echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Transformando Fedora KDE em macOS (MacTahoe Theme)         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 0. Capturar diretório original para referenciar arquivos de configuração
ORIGINAL_DIR=$(pwd)
echo "📂 Diretório de origem: $ORIGINAL_DIR"

# Função para pausar e mostrar erros
pause_on_error() {
  if [ $? -ne 0 ]; then
    echo ""
    echo "❌ ERRO ENCONTRADO! Pressione ENTER para continuar..."
    read
  fi
}

# 1. Instalar dependências
echo "📦 Instalando dependências..."
sudo dnf install -y git kvantum kvantum-qt5 sassc qt5-qttools 2>&1
pause_on_error
echo "✅ Dependências instaladas!"
echo ""

# 2. Criar pasta temporária e LIMPAR se já existir
if [ -d ~/mactahoe-install-temp ]; then
  echo "🗑️ Limpando pasta anterior..."
  rm -rf ~/mactahoe-install-temp
fi

mkdir -p ~/mactahoe-install-temp
cd ~/mactahoe-install-temp
echo "📁 Pasta criada em: $(pwd)"

# 3. MacTahoe KDE (tema Plasma + Kvantum)
echo ""
echo "🎨 Baixando MacTahoe KDE Theme..."
git clone https://github.com/marcos2872/MacTahoe-kde.git 2>&1
pause_on_error

cd MacTahoe-kde
echo "⚙️ Instalando MacTahoe KDE..."
bash ./install.sh 2>&1
pause_on_error
cd ..

# 4. MacTahoe Icons
echo ""
echo "🖼️ Baixando MacTahoe Icons..."
git clone https://github.com/marcos2872/MacTahoe-icon-theme.git 2>&1
pause_on_error

cd MacTahoe-icon-theme
echo "⚙️ Instalando Ícones MacTahoe..."
bash ./install.sh 2>&1
pause_on_error
cd ..

# 5. MacTahoe Cursors
echo ""
echo "🖱️ Baixando MacTahoe Cursors..."
git clone https://github.com/marcos2872/MacTahoe-icon-theme.git MacTahoe-cursors-src 2>&1
pause_on_error

cd MacTahoe-cursors-src/cursors
echo "⚙️ Instalando Cursores MacTahoe..."
bash ./install.sh 2>&1
pause_on_error
cd ../..

# Limpeza
cd ~
rm -rf ~/mactahoe-install-temp

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ ✅ INSTALAÇÃO CONCLUÍDA!                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 6. Aplicar Temas Automaticamente
echo ""
echo "🎨 Aplicando temas..."

# Configurar Kvantum
echo "   - Configurando Kvantum para usar MacTahoe-Dark..."
mkdir -p ~/.config/Kvantum
# Verifica se já existe config e atualiza, ou cria nova
if [ -f ~/.config/Kvantum/kvantum.kvconfig ]; then
  # Se já existe [General], substitui ou falha silenciosamente (sed simples)
  # Mas para simplificar e garantir, vamos usar uma abordagem segura de append se não existir ou sed se existir
  if grep -q "^theme=" ~/.config/Kvantum/kvantum.kvconfig; then
     sed -i 's/^theme=.*/theme=MacTahoeDark/' ~/.config/Kvantum/kvantum.kvconfig
  else
     # Pode ser que exista [General] mas não theme
     if grep -q "\[General\]" ~/.config/Kvantum/kvantum.kvconfig; then
         sed -i '/\[General\]/a theme=MacTahoeDark' ~/.config/Kvantum/kvantum.kvconfig
     else
         echo -e "[General]\ntheme=MacTahoeDark" >> ~/.config/Kvantum/kvantum.kvconfig
     fi
  fi
else
  echo -e "[General]\ntheme=MacTahoeDark" > ~/.config/Kvantum/kvantum.kvconfig
fi
pause_on_error

# Aplicar Tema Global
echo "   - Aplicando Tema Global MacTahoe-Dark..."
if command -v lookandfeeltool &> /dev/null; then
    lookandfeeltool -a com.github.vinceliuice.MacTahoe-Dark 2>&1
elif command -v plasma-apply-lookandfeel &> /dev/null; then
    plasma-apply-lookandfeel -a com.github.vinceliuice.MacTahoe-Dark 2>&1
else
    echo "⚠️  Não foi possível encontrar ferramenta para aplicar tema global (lookandfeeltool ou plasma-apply-lookandfeel)."
fi
pause_on_error

echo "✅ Temas aplicados!"

# 7. Instalar e Configurar Widgets no Painel
echo ""
echo "🧩 Configurando Widgets no Painel..."

# Instalar Cursor Eyes (Manual)
echo "   - Instalando widget 'Cursor Eyes'..."
if [ -d ~/cursor-eyes-temp ]; then rm -rf ~/cursor-eyes-temp; fi
mkdir -p ~/cursor-eyes-temp
git clone https://github.com/luisbocanegra/plasma-cursor-eyes.git ~/cursor-eyes-temp 2>&1
pause_on_error

# Determinar ação (Instalar ou Atualizar)
if [ -d "$HOME/.local/share/plasma/plasmoids/luisbocanegra.cursor.eyes" ] || [ -d "/usr/share/plasma/plasmoids/luisbocanegra.cursor.eyes" ]; then
    echo "   - Widget já existe. Atualizando..."
    KPKG_ACTION="-u"
else
    echo "   - Instalando widget..."
    KPKG_ACTION="-i"
fi

# Tenta instalar/atualizar usando kpackagetool6 (Plasma 6) ou kpackagetool5 (Plasma 5)
if command -v kpackagetool6 &> /dev/null; then
    kpackagetool6 -t Plasma/Applet $KPKG_ACTION ~/cursor-eyes-temp/package 2>&1
elif command -v kpackagetool5 &> /dev/null; then
    kpackagetool5 -t Plasma/Applet $KPKG_ACTION ~/cursor-eyes-temp/package 2>&1
else
    echo "⚠️  Não foi possível encontrar kpackagetool para instalar o widget."
fi
rm -rf ~/cursor-eyes-temp

# 8. Restaurar Configuração do Painel (Personalizada)
echo ""
# Adicionar Widgets ao Painel via Script Plasma
echo "   - Adicionando 'System Monitor' e 'Cursor Eyes' ao painel..."
# Nota: O widget ID 'luisbocanegra.cursor.eyes' correspode ao item da KDE Store: https://store.kde.org/p/2183752
ADD_WIDGETS_vn_SCRIPT=$(cat <<EOF
var allPanels = panels();
if (allPanels.length > 0) {
    var p = allPanels[0];
    
    // Adiciona System Monitor Sensor
    // ID genérico para o monitor do sistema gráficos. Pode variar, tentando org.kde.plasma.systemmonitor
    p.addWidget("org.kde.plasma.systemmonitor");

    // Adiciona Cursor Eyes (https://store.kde.org/p/2183752)
    p.addWidget("luisbocanegra.cursor.eyes");
}
EOF
)

# Executa o script JS no Plasma Shell
if command -v qdbus-qt5 &> /dev/null; then
    qdbus-qt5 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$ADD_WIDGETS_vn_SCRIPT" 2>&1
elif command -v qdbus &> /dev/null; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$ADD_WIDGETS_vn_SCRIPT" 2>&1
else
    echo "⚠️  Não foi possível encontrar qdbus para configurar o painel automaticamente."
fi
pause_on_error
echo "✅ Widgets configurados!"

# 9. Alterar ícone do Application Launcher
echo ""
echo "   - Atualizando ícone do Application Launcher para 'fedora-logo-icon'..."
UPDATE_ICON_SCRIPT=$(cat <<EOF
var allPanels = panels();
for (var i = 0; i < allPanels.length; i++) {
    var p = allPanels[i];
    var widgets = p.widgets();
    for (var j = 0; j < widgets.length; j++) {
        var w = widgets[j];
        if (w.type == "org.kde.plasma.kickoff" || w.type == "org.kde.plasma.kicker" || w.type == "org.kde.plasma.kickerdash") {
            w.currentConfigGroup = ["General"];
            w.writeConfig("icon", "fedora-logo-icon");
            w.reloadConfig();
        }
    }
}
EOF
)

if command -v qdbus-qt5 &> /dev/null; then
    qdbus-qt5 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$UPDATE_ICON_SCRIPT" 2>&1
elif command -v qdbus &> /dev/null; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$UPDATE_ICON_SCRIPT" 2>&1
else
    echo "⚠️  Não foi possível encontrar qdbus para alterar o ícone."
fi
pause_on_error
echo "✅ Ícone atualizado!"

# 10. Instalar Splash Screen Kuro
echo ""
echo "🎨 Instalando Splash Screen Kuro..."
if [ -d ~/kuro-temp ]; then rm -rf ~/kuro-temp; fi
mkdir -p ~/kuro-temp
git clone https://github.com/bouteillerAlan/kuro.git ~/kuro-temp 2>&1
pause_on_error

mkdir -p ~/.local/share/plasma/look-and-feel/
cp -r ~/kuro-temp/a2n.kuro ~/.local/share/plasma/look-and-feel/
rm -rf ~/kuro-temp

# Configurar Splash Screen
echo "   - Configurando Splash Screen..."
if command -v kwriteconfig6 &> /dev/null; then
    kwriteconfig6 --file ksplashrc --group KSplash --key Theme a2n.kuro
    kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
elif command -v kwriteconfig5 &> /dev/null; then
    kwriteconfig5 --file ksplashrc --group KSplash --key Theme a2n.kuro
    kwriteconfig5 --file ksplashrc --group KSplash --key Engine KSplashQML
else
    # Fallback manual
    if ! grep -q "\[KSplash\]" ~/.config/ksplashrc; then
        echo "[KSplash]" >> ~/.config/ksplashrc
    fi
    # Remove existing keys if any
    sed -i '/^Theme=/d' ~/.config/ksplashrc
    sed -i '/^Engine=/d' ~/.config/ksplashrc
    # Add new keys
    sed -i '/\[KSplash\]/a Theme=a2n.kuro\nEngine=KSplashQML' ~/.config/ksplashrc
fi
echo "✅ Splash Screen instalado!"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ ✅ INSTALAÇÃO CONCLUÍDA!                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "O tema MacTahoe-Dark foi aplicado."
echo "Pressione ENTER para fechar..."
read
