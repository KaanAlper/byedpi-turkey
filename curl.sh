#!/bin/bash

if ! command -v git &> /dev/null; then
    say ""Sisteminizde 'git' bulunamadı.""
    say ""Otomatik olarak kuruluyor... Lütfen sudo şifresi istenirse girin.""

    if [[ -f /bin/pacman ]]; then
        sudo pacman -S --noconfirm git
    elif [[ -f /bin/dnf ]]; then
        sudo dnf install -y git
    elif [[ -f /bin/apt ]]; then
        sudo apt update && sudo apt install -y git
    else
        say ""Uygun paket yöneticisi bulunamadı. Lütfen git'i elle kurun.""
        exit 1
    fi
    if ! command -v git &> /dev/null; then
        say ""Git kurulumu başarısız oldu. Script durduruluyor.""
        exit 1
    fi

    say ""Git başarıyla kuruldu.""
fi

BYEDPI_DIR="$HOME/.local/share/byedpi-turkey"
if [[ -d "$BYEDPI_DIR" ]]; then
    say ""Mevcut byedpi-turkey reposu siliniyor ve yenisi yükleniyor...""
    rm -rf "$BYEDPI_DIR"
fi

git clone https://github.com/elrondforwin/byedpi-turkey.git "$BYEDPI_DIR"

if [[ $? -eq 0 ]]; then
    say ""byedpi-turkey başarıyla klonlandı. Lütfen devam etmek için sonraki komutu yapıştırın.""
else
    say ""Git clone işlemi başarısız oldu.""
    exit 1
fi

