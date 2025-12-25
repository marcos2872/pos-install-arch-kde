# Pos Install Fedora KDE

Coleção de scripts de pós-instalação e configuração para o **Fedora KDE Plasma**. Este projeto evoluiu de um simples aplicador de temas para um conjunto modular de ferramentas para configurar rapidamente um ambiente de desenvolvimento completo.

## Visão Geral

Este repositório fornece um script principal modular (`install_apps.sh`) que permite instalar e configurar diversas ferramentas, desde linguagens de programação até ajustes visuais complexos.

## Como Usar

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/marcos2872/pos-install-fedora-kde.git
   cd pos-install-fedora-kde
   ```

2. **Execute o instalador principal:**
   ```bash
   ./install_apps.sh
   ```
   
   O script irá apresentar logs coloridos do processo de instalação de cada módulo. Caso ocorra algum erro, ele pausará para que você possa verificar.

## Módulos Disponíveis

O script `install_apps.sh` orquestra a execução dos seguintes módulos, localizados na pasta `scripts/`:

### Ferramentas de Desenvolvimento
- **Dev Tools** (`dev_tools.sh`): Instala compiladores básicos e ferramentas essenciais (gcc, make, etc).
- **Git & GitHub** (`git_gh.sh`): Configura Git e instala a CLI do GitHub (`gh`).
- **Rust** (`rust.sh`): Instala a linguagem Rust via `rustup`.
- **Node.js** (`node.sh`): Instala o Node.js utilizando o gerenciador de versões `nvm`.
- **Podman** (`podman.sh`): Configura o Podman como substituto ao Docker e instala o `lazydocker`.

### Editores e Terminais
- **Alacritty** (`alacritty.sh`): Instala e configura o terminal Alacritty com uma estética moderna (estilo macOS).
- **Zed** (`zed.sh`): Instala o editor de código Zed.
- **Starship** (`starship.sh`): Instala e configura o prompt `starship` para o shell.
- **Fonts** (`fonts.sh`): Instala fontes nerd-fonts e outras tipografias essenciais para desenvolvimento.

### Navegadores
- **Google Chrome** (`chrome.sh`)
- **Brave Browser** (`brave.sh`)

### IA e Outros
- **Claude Desktop** (`claude.sh`): Instala o cliente desktop do Claude.
- **MCP Tools** (`mcp.sh`): Configura ferramentas relacionadas ao "Model Context Protocol".
- **Linux Toys** (`linux_toys.sh`): Utilitários divertidos para o terminal.
- **Antigravity** (`antigravity.sh`): *Script de configuração específico do agente/ambiente.*

### Personalização Visual
- **KDE Tahoe Theme** (`KdeTahoe.sh`): Script original do projeto. Aplica o tema "Tahoe", configura ícones, cores e outros ajustes visuais profundos no KDE Plasma.

## Estrutura do Projeto

- `install_apps.sh`: Ponto de entrada. Gerencia a execução sequencial dos scripts.
- `scripts/`: Diretório contendo todos os scripts individuais.
- `links.txt`: Lista de referências, links para temas na KDE Store e outros recursos.

## Requisitos

- **Sistema Operacional**: Fedora Linux (KDE Plasma recomendado para os scripts visuais).
- **Permissões**: Alguns scripts solicitarão senha de `sudo` para instalar pacotes via `dnf`.
- **Conexão**: Necessária para baixar pacotes e repositórios.

## Contribuições

Sinta-se à vontade para abrir Issues ou Pull Requests para adicionar novos scripts ou melhorar os existentes.

## Licença

Este projeto é de uso livre. Verifique os scripts individuais para licenças de terceiros (fontes, temas, etc).