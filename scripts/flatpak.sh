#!/bin/bash

sudo dnf install -y -q flatpak 
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak update --appstream
source ~/.bashrc
