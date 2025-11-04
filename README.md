# Pós-instalação Arch KDE (Script)

Script de pós-instalação para sistemas Arch Linux/KDE Plasma com SDDM. Automatiza configurações essenciais, instala ferramentas de desenvolvimento e aplicativos do dia a dia.

> Importante: execute como usuário normal (não root). O script usará `sudo` quando necessário.

## O que este script faz

- Atualiza o sistema (pacman -Syu) e instala pré-requisitos: `git`, `curl`, `base-devel`.
- Configura o SDDM com tema Breeze (Plasma) e Numlock on.
- Instala e configura o yay (AUR helper).
- Instala Rust (rustup) e carrega o ambiente.
- Instala NVM e Node.js LTS; define LTS como padrão.
- Garante pnpm (via Corepack; fallback `npm -g`).
- Instala apps do AUR: Visual Studio Code, Google Chrome, Lazydocker, Brave, Discord, Postman.
- Habilita serviços: `sddm`, `NetworkManager`, `bluetooth`, `docker`, `libvirtd`.
- Adiciona o usuário aos grupos: `docker`, `libvirt`, `kvm`.

## Requisitos

- Arch Linux (ou derivado) com pacman funcionando.
- KDE Plasma com SDDM (o script configura o tema do SDDM).
- Acesso à internet.
- Acesso sudo (o script pedirá sua senha quando necessário).

## Como usar sem baixar (direto do GitHub)

Você pode executar diretamente com `curl`/`wget`. Revise o conteúdo do script se desejar antes de executar.

Opção 1 (process substitution):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/marcos2872/pos-install-arch-kde/main/pos-install.sh)
```

Opção 2 (pipe com curl):

```bash
curl -fsSL https://raw.githubusercontent.com/marcos2872/pos-install-arch-kde/main/pos-install.sh | bash
```

Opção 3 (pipe com wget):

```bash
wget -qO- https://raw.githubusercontent.com/marcos2872/pos-install-arch-kde/main/pos-install.sh | bash
```

> Aviso: "pipe to bash" é prático, mas potencialmente arriscado. Use apenas se confiar no conteúdo. Alternativa: baixe o arquivo, revise e execute localmente.

## Como usar baixando/locamente

Clonando o repositório:

```bash
git clone https://github.com/marcos2872/pos-install-arch-kde.git
cd pos-install-arch-kde
chmod +x pos-install.sh
./pos-install.sh
```

Ou baixando apenas o script:

```bash
curl -fsSLO https://raw.githubusercontent.com/marcos2872/pos-install-arch-kde/main/pos-install.sh
chmod +x pos-install.sh
./pos-install.sh
```

## Notas e próximos passos

- Execute como usuário normal (não root). O script usa `sudo` quando necessário.
- Ao final, é recomendado reiniciar o sistema: `sudo reboot`.
- Para o Node.js via NVM em novos terminais, carregue seu shell:
  - bash: `source ~/.bashrc`
  - zsh: `source ~/.zshrc`
- O script tenta instalar/atualizar o NVM para a última versão disponível via GitHub Releases (com fallback).
- O pnpm é instalado e ativado via Corepack quando possível.

## Solução de problemas

- GitHub API rate limit: se a verificação da última versão do NVM falhar, o script usa uma versão fallback conhecida.
- AUR/yay falhando: verifique rede, chaves GPG e se o grupo `base-devel` está instalado (o script já cuida disso).
- Serviços (docker/libvirtd): após a execução, faça logout/login para aplicar grupos, ou reinicie.

## Licença

Este repositório tem fins pessoais/de automação. Adapte conforme necessário para o seu ambiente.
