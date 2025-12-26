#!/bin/bash

sudo dnf install -y -q flatpak &> /dev/null
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo &> /dev/null
source ~/.bashrc &> /dev/null
