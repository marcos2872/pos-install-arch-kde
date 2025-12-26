# pos-install-fedora-kde

Coleção modular de scripts de pós-instalação para Fedora (KDE Plasma). O orquestrador principal é `install_apps.sh`, que executa scripts em `scripts/` na ordem definida.

Resumo rápido
- Instala ferramentas de desenvolvimento, editores, navegadores e personalizações do KDE.
- Projetado para ser modular: adicione/remoção de módulos via `scripts/` + `install_apps.sh`.

Pré-requisitos
- Fedora Linux (KDE Plasma recomendado para módulos visuais)
- Acesso a `sudo`
- Conexão com a internet

Quickstart
```pos-install-fedora-kde/README.md#L1-6
git clone https://github.com/marcos2872/pos-install-fedora-kde.git
cd pos-install-fedora-kde
chmod +x install_apps.sh
./install_apps.sh
```

Módulos (ordem definida em `install_apps.sh`)
- `dev_tools.sh`, `rust.sh`, `node.sh`, `git_gh.sh`, `fonts.sh`, `starship.sh`, `alacritty.sh`
- `linux_toys.sh`, `zed.sh`, `antigravity.sh`, `podman.sh`, `brave.sh`, `chrome.sh`
- `claude.sh`, `mcp.sh`, `kde_tahoe.sh`, `config.sh`

Estrutura do repositório
- `install_apps.sh` — orquestrador (fonte da verdade)
- `scripts/` — módulos individuais (cada script deve ser executável)
- `AGENTS.md` — guia para adicionar/remover módulos

Adicionar um módulo (resumido)
1. Criar `scripts/meu_modulo.sh` (idempotente, logs claros, `exit 0` em sucesso).
2. Tornar executável: `chmod +x scripts/meu_modulo.sh`.
3. Referenciar o script na posição desejada em `install_apps.sh`.
4. Testar isoladamente e depois com o instalador completo.

Remover um módulo (resumido)
1. Remover a chamada em `install_apps.sh`.
2. Excluir `scripts/meu_modulo.sh` após verificar dependências.
3. Atualizar documentação, se necessário.

Boas práticas
- Evitar interatividade (usar variáveis/flags quando necessário).
- Fornecer mensagens de início/fim e códigos de saída significativos.
- Use `install_apps.sh` como fonte da verdade para a ordem de execução.

Leitura recomendada
- `AGENTS.md` — procedimentos e convenções para agentes e contribuições.

Contribuições
- Abra uma issue para discutir mudanças maiores.
- Envie PRs com script testado + atualização em `install_apps.sh` e nota no README quando relevante.

Instalador remoto (sem clonar)
- É possível executar o instalador sem clonar o repositório usando o script remoto.
- Raw URL do instalador remoto:
  https://raw.githubusercontent.com/marcos2872/pos-install-fedora-kde/main/install_apps_remote.sh

Exemplo (baixar e executar localmente)
```pos-install-fedora-kde/README.md#L1-3
curl -fsSL https://raw.githubusercontent.com/marcos2872/pos-install-fedora-kde/main/install_apps_remote.sh -o install_apps_remote.sh
chmod +x install_apps_remote.sh
./install_apps_remote.sh
```

Inspeção segura
- Para apenas baixar os scripts e inspecioná-los antes de executar:
```pos-install-fedora-kde/README.md#L1-2
./install_apps_remote.sh --fetch-only --keep-temp
```
- Recomendo revisar os arquivos baixados antes de executar em sistemas de produção.
