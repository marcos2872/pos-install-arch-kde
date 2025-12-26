#!/bin/bash
source ~/.bashrc
if [ -d "os-mcp" ]; then rm -rf os-mcp; fi
git clone https://github.com/marcos2872/os-mcp.git
cd os-mcp

echo "📦 Compilando binário (release)..."
cargo build --release

BINARY_PATH="$(pwd)/target/release/linux-mcp"
CLAUDE_CONFIG_DIR="$HOME/.config/Claude"
LINUX_MCP_CONFIG_DIR="$HOME/.config/linux-mcp"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"

# 3. Configurar Claude Desktop
echo "⚙️  Configurando Claude Desktop em: $CLAUDE_CONFIG_FILE"
mkdir -p "$CLAUDE_CONFIG_DIR"
mkdir -p "$LINUX_MCP_CONFIG_DIR"

cp $BINARY_PATH $LINUX_MCP_CONFIG_DIR

if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
    echo "Criando arquivo de configuração novo..."
    echo "{ \"mcpServers\": {} }" > "$CLAUDE_CONFIG_FILE"
fi

# Usar Python para injetar o JSON de forma segura sem precisar de jq
python3 -c "
import json
import sys

config_file = '$CLAUDE_CONFIG_FILE'
binary_path = '$LINUX_MCP_CONFIG_DIR/linux-mcp'

try:
    with open(config_file, 'r') as f:
        content = f.read().strip()
        if not content:
            data = {'mcpServers': {}}
        else:
            data = json.loads(content)
except Exception as e:
    print(f'Erro ao ler JSON: {e}')
    sys.exit(1)

if 'mcpServers' not in data:
    data['mcpServers'] = {}

# Adicionar ou atualizar configuração do linux-mcp
data['mcpServers']['linux-mcp'] = {
    'command': binary_path,
    'args': [],
    'env': {}
}

with open(config_file, 'w') as f:
    json.dump(data, f, indent=2)
    print('✅ Configuração injetada com sucesso!')
"

echo ""
echo "🎉 Instalação Concluída!"


cd ..
sudo rm -rf os-mcp
