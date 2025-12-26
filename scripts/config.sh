#!/bin/bash

# ==============================================================================
# KDE Tahoe - Configuração Pós-Instalação
# Aplica configurações após a instalação dos assets do tema MacTahoe:
# - Kvantum (MacTahoeDark)
# - Tema Global (Look-and-Feel)
# - Widgets (Cursor Eyes e System Monitor)
# - Ícone do Application Launcher
# - Splash Screen (Kuro)
# ==============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Configuração Pós-Instalação do MacTahoe (KDE)              ║"
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

# Avisos sobre ambiente Plasma/D-Bus
if ! command -v plasmashell >/dev/null 2>&1; then
  echo "⚠️  Aviso: plasmashell não encontrado no PATH. Algumas configurações podem não aplicar."
fi
if ! command -v qdbus6 >/dev/null 2>&1 && ! command -v qdbus-qt6 >/dev/null 2>&1 && ! command -v qdbus-qt5 >/dev/null 2>&1 && ! command -v qdbus >/dev/null 2>&1; then
  echo "⚠️  Aviso: qdbus6/qdbus-qt6 (Plasma 6) não encontrado. Adição de widgets/ícones por script pode falhar."
fi

echo ""
echo "🎨 Aplicando configurações de tema..."

# 1) Configurar Kvantum
echo "   - Configurando Kvantum para usar MacTahoeDark..."
mkdir -p ~/.config/Kvantum
if [ -f ~/.config/Kvantum/kvantum.kvconfig ]; then
  if grep -q "^theme=" ~/.config/Kvantum/kvantum.kvconfig; then
     sed -i 's/^theme=.*/theme=MacTahoeDark/' ~/.config/Kvantum/kvantum.kvconfig
  else
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

# 2) Aplicar Tema Global (Look-and-Feel)
echo "   - Aplicando Tema Global MacTahoe-Dark..."
if command -v lookandfeeltool &> /dev/null; then
    lookandfeeltool -a com.github.vinceliuice.MacTahoe-Dark 2>&1
elif command -v plasma-apply-lookandfeel &> /dev/null; then
    plasma-apply-lookandfeel -a com.github.vinceliuice.MacTahoe-Dark 2>&1
else
    echo "⚠️  Não foi possível encontrar lookandfeeltool/plasma-apply-lookandfeel."
fi
pause_on_error

echo "✅ Tema global e Kvantum configurados!"

# 3) Instalar e Configurar Widgets (Cursor Eyes)
echo ""
echo "🧩 Instalando/Atualizando widget 'Cursor Eyes'..."
WIDGET_TEMP="$HOME/cursor-eyes-temp"
if [ -d "$WIDGET_TEMP" ]; then rm -rf "$WIDGET_TEMP"; fi
mkdir -p "$WIDGET_TEMP"
git clone https://github.com/luisbocanegra/plasma-cursor-eyes.git "$WIDGET_TEMP" 2>&1
pause_on_error

if [ -d "$HOME/.local/share/plasma/plasmoids/luisbocanegra.cursor.eyes" ] || [ -d "/usr/share/plasma/plasmoids/luisbocanegra.cursor.eyes" ]; then
    echo "   - Widget já existe. Atualizando..."
    KPKG_ACTION="-u"
else
    echo "   - Instalando widget..."
    KPKG_ACTION="-i"
fi

if command -v kpackagetool6 &> /dev/null; then
    kpackagetool6 -t Plasma/Applet $KPKG_ACTION "$WIDGET_TEMP/package" 2>&1
elif command -v kpackagetool5 &> /dev/null; then
    kpackagetool5 -t Plasma/Applet $KPKG_ACTION "$WIDGET_TEMP/package" 2>&1
else
    echo "⚠️  Não foi possível encontrar kpackagetool para instalar o widget."
fi
rm -rf "$WIDGET_TEMP"
pause_on_error

# 4) Adicionar Widgets ao Painel (System Monitor + Cursor Eyes)
echo ""
echo "🛠️  Adicionando widgets ao painel (System Monitor + Cursor Eyes)..."
ADD_WIDGETS_SCRIPT=$(cat <<'EOF'
var allPanels = panels();
if (allPanels.length > 0) {
    var p = allPanels[0];
    // Tenta adicionar System Monitor (pode variar conforme Plasma)
    try { p.addWidget("org.kde.plasma.systemmonitor"); } catch (e) {}
    // Adiciona Cursor Eyes
    try { p.addWidget("luisbocanegra.cursor.eyes"); } catch (e) {}
}
EOF
)

if command -v qdbus6 &> /dev/null; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$ADD_WIDGETS_SCRIPT" 2>&1
elif command -v qdbus-qt6 &> /dev/null; then
    qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$ADD_WIDGETS_SCRIPT" 2>&1
elif command -v qdbus-qt5 &> /dev/null; then
    qdbus-qt5 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$ADD_WIDGETS_SCRIPT" 2>&1
elif command -v qdbus &> /dev/null; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$ADD_WIDGETS_SCRIPT" 2>&1
else
    echo "⚠️  qdbus não encontrado. Pulo a configuração automática de widgets."
fi
pause_on_error
echo "✅ Widgets configurados!"

# 5) Alterar ícone do Application Launcher
echo ""
echo "🖼️ Atualizando ícone do Application Launcher para 'fedora-logo-icon'..."
UPDATE_ICON_SCRIPT=$(cat <<'EOF'
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

if command -v qdbus6 &> /dev/null; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$UPDATE_ICON_SCRIPT" 2>&1
elif command -v qdbus-qt6 &> /dev/null; then
    qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$UPDATE_ICON_SCRIPT" 2>&1
elif command -v qdbus-qt5 &> /dev/null; then
    qdbus-qt5 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$UPDATE_ICON_SCRIPT" 2>&1
elif command -v qdbus &> /dev/null; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$UPDATE_ICON_SCRIPT" 2>&1
else
    echo "⚠️  qdbus não encontrado. Pulo a atualização do ícone do launcher."
fi
pause_on_error
echo "✅ Ícone atualizado!"

# 6) Instalar e configurar Splash Screen Kuro
echo ""
echo "🎨 Instalando Splash Screen Kuro..."
KURO_TEMP="$HOME/kuro-temp"
if [ -d "$KURO_TEMP" ]; then rm -rf "$KURO_TEMP"; fi
mkdir -p "$KURO_TEMP"
git clone https://github.com/bouteillerAlan/kuro.git "$KURO_TEMP" 2>&1
pause_on_error

mkdir -p ~/.local/share/plasma/look-and-feel/
cp -r "$KURO_TEMP/a2n.kuro" ~/.local/share/plasma/look-and-feel/ 2>&1
pause_on_error
rm -rf "$KURO_TEMP"

echo "   - Configurando Splash Screen..."
if command -v kwriteconfig6 &> /dev/null; then
    kwriteconfig6 --file ksplashrc --group KSplash --key Theme a2n.kuro
    kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
elif command -v kwriteconfig5 &> /dev/null; then
    kwriteconfig5 --file ksplashrc --group KSplash --key Theme a2n.kuro
    kwriteconfig5 --file ksplashrc --group KSplash --key Engine KSplashQML
else
    # Fallback manual
    mkdir -p ~/.config
    if ! grep -q "\[KSplash\]" ~/.config/ksplashrc 2>/dev/null; then
        echo "[KSplash]" >> ~/.config/ksplashrc
    fi
    sed -i '/^Theme=/d' ~/.config/ksplashrc 2>/dev/null
    sed -i '/^Engine=/d' ~/.config/ksplashrc 2>/dev/null
    printf "Theme=a2n.kuro\nEngine=KSplashQML\n" >> ~/.config/ksplashrc
fi
pause_on_error
echo "✅ Splash Screen configurado!"

# 7) Configurar posição do KRunner (centralizado e flutuante)
echo ""
echo "🧭 Configurando posição do KRunner (centralizado)..."
if command -v kwriteconfig6 &> /dev/null; then
    kwriteconfig6 --file krunnerrc --group General --key Position Center
    kwriteconfig6 --file krunnerrc --group General --key FreeFloating true
elif command -v kwriteconfig5 &> /dev/null; then
    kwriteconfig5 --file krunnerrc --group General --key Position Center
    kwriteconfig5 --file krunnerrc --group General --key FreeFloating true
else
    # Fallback manual
    mkdir -p ~/.config
    if ! grep -q "\[General\]" ~/.config/krunnerrc 2>/dev/null; then
        echo "[General]" >> ~/.config/krunnerrc
    fi
    sed -i '/^Position=/d' ~/.config/krunnerrc 2>/dev/null
    sed -i '/^FreeFloating=/d' ~/.config/krunnerrc 2>/dev/null
    printf "Position=Center\nFreeFloating=true\n" >> ~/.config/krunnerrc
fi
pause_on_error
echo "🔄 Reiniciando KRunner para aplicar configurações..."
pkill krunner >/dev/null 2>&1 && krunner &>/dev/null &
echo "✅ KRunner configurado para posição central e modo flutuante!"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ ✅ CONFIGURAÇÃO CONCLUÍDA                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "O tema MacTahoe-Dark foi aplicado (Kvantum + Look-and-Feel), widgets e"
echo "ícones do launcher configurados, e Splash Kuro definido."
echo "Pode ser necessário reiniciar a sessão do KDE para ver todas as alterações."
echo "Pressione ENTER para fechar..."
read
