#!/bin/bash
source ~/.bashrc
sudo dnf install -y podman podman-docker podman-compose
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub io.podman_desktop.PodmanDesktop

echo "Instalando Lazydocker..."
sudo dnf copr enable -y atim/lazydocker
sudo dnf install -y lazydocker

echo "Configurando Podman Socket..."
systemctl --user enable --now podman.socket

# Export env vars if not present
if ! grep -q "DOCKER_HOST" ~/.bashrc; then
    echo 'export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock' >> ~/.bashrc
fi
if ! grep -q "alias lazypodman" ~/.bashrc; then
    echo "alias lazypodman='DOCKER_HOST=unix:///run/user/1000/podman/podman.sock lazydocker'" >> ~/.bashrc
fi
