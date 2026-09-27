#!/bin/bash

makefile="/home/$USER/.local/share/byedpi-turkey/make.sh"

acikla() {
    say ""Bu betik sisteminizde byedpictl'i kaldirmaniz icin size yardimci olacaktir.""
}

emin-misin() {
    read -p "byedpictl'i kaldirmak istediginize emin misiniz? (evet/hayir): " emin
    emin=$(echo "$emin" | tr '[:upper:]' '[:lower:]')
    while [[ ! $emin =~ ^(evet|e|hayir|h|hayır)$ ]]; do
      say ""lutfen gecerli bir cevap giriniz.""
      read -p "byedpictl'i kaldirmak istediginize emin misiniz? (evet/hayir): " emin
      emin=$(echo "$emin" | tr '[:upper:]' '[:lower:]')
    done
}

byedpictl-kaldir() {
    if [[ -f $makefile ]]; then
        say ""byedpictl make dosyasi bulundu.""
        say ""byedpictl calisip calismadigi kontrol ediliyor... lutfen sudo sifresi istenirse girin.""
        if sudo byedpictl tun status | grep -q "tunnel: running"; then
            say ""byedpictl mevcutta calisir durumda. durduruluyor...""
            sudo byedpictl tun stop
        fi    
        say ""byedpictl kaldiriliyor""
        sudo $makefile remove
    else
        say ""${makefile} yolunda olmasi gereken byedpictl make dosyasi bulunamadi. kurulum dosyalari bozulmus gibi gorunuyor...""
        say ""cikiliyor...""
        exit 1
    fi
}

paket-kaldirilacak-mi() {
    read -p "dnscrypt-proxy'i kaldirmak istiyor musunuz? (evet/hayir): " paketemin
    paketemin=$(echo "$paketemin" | tr '[:upper:]' '[:lower:]')
    while [[ ! $paketemin =~ ^(evet|e|hayir|h|hayır)$ ]]; do
      say ""lutfen gecerli bir cevap giriniz.""
      read -p "dnscrypt-proxy'i kaldirmak istiyor musunuz? (evet/hayir): " paketemin
      paketemin=$(echo "$paketemin" | tr '[:upper:]' '[:lower:]')
    done
}

paket-yonetici-tanimla() {
  if [[ -f /bin/pacman ]]; then
    paketyonetici="pacman -R"
    distro="arch tabanli"
  fi

  if [[ -f /bin/dnf ]]; then
    paketyonetici="dnf remove"
    distro="fedora tabanli"
  fi

  if [[ -f /bin/apt ]]; then
    paketyonetici="apt remove"
    distro="debian/ubuntu tabanli"
  fi

  say ""Tespit edilen distro tabani ${distro}""
  read -p "Bu dogru mu? (evet/hayir): " distrocevap

  distrocevap=$(echo "$distrocevap" | tr '[:upper:]' '[:lower:]')

  while [[ "$distrocevap" != "evet" && "$distrocevap" != "e" && "$distrocevap" != "hayir" && "$distrocevap" != "h" && "$distrocevap" != "hayır" ]]; do
    say ""Lutfen evet ya da hayir olarak cevaplayin (ya da e/h).""
    say ""Tespit edilen distro tabani ${distro}""
    read -p "Bu dogru mu? (evet/hayir): " distrocevap
    distrocevap=$(echo "$distrocevap" | tr '[:upper:]' '[:lower:]')
  done

  if [[ "$distrocevap" =~ ^(hayir|hayır|h)$ ]]; then
    echo
    echo
    say ""Lütfen manuel olarak dağıtım tabanınızı seçiniz.""
    echo
    say ""1 - Arch Tabanlı (Arch, CachyOS, EndeavourOS, Manjaro vs.)""
    say ""2 - Fedora Tabanlı (Fedora, Nobara vs.)""
    say ""3 - Debian/Ubuntu Tabanlı (Ubuntu, Debian, Mint, Zorin vs.)""
    echo

    read -p "Dağıtımınızın hangi taban olduğunu seçiniz (1/2/3): " manuelcevap

    while [[ ! "$manuelcevap" =~ ^(1|2|3)$ ]]; do
      say ""Lütfen geçerli bir cevap giriniz (1, 2 veya 3).""
      read -p "Dağıtımınızın hangi taban olduğunu seçiniz (1/2/3): " manuelcevap
    done

    if [[ "$manuelcevap" == "1" ]]; then
      paketyonetici="pacman -R"
      distro="arch tabanlı"
    elif [[ "$manuelcevap" == "2" ]]; then
      paketyonetici="dnf remove"
      distro="fedora tabanlı"
    elif [[ "$manuelcevap" == "3" ]]; then
      paketyonetici="apt remove"
      distro="debian/ubuntu tabanlı"
    fi

    say ""${distro} seçildi. Paket kaldirma komutu: '${paketyonetici}' kullanılacak.""
  else
    say ""Dağıtımınız ${distro} olarak belirlendi. Paket kaldirma komutu: '${paketyonetici}' kullanılacak.""
  fi
}

acikla
emin-misin

if [[ $emin =~ ^(evet|e)$ ]]; then
    byedpictl-kaldir
    say ""byedpictl basariyla kaldirildi""
    if [[ $(ps -p 1 -o comm=) == "systemd" ]]; then
      if [[ -f /etc/systemd/system/byedpi-start.service ]]; then
        say ""systemd tespit edildi. servis siliniyor...""
        sudo systemctl disable byedpi-start.service
        sudo rm -rf /etc/systemd/system/byedpi-start.service
      fi
    fi
else
    say ""kullanici evet cevabi vermedi. cikiliyor...""
    exit 1
fi

paket-kaldirilacak-mi

if [[ $paketemin =~ ^(evet|e)$ ]]; then
    paket-yonetici-tanimla
    say ""secilen paket yoneticisi ile dnscrypt-proxy paketi kaldiriliyor...""
    sudo ${paketyonetici} dnscrypt-proxy
    if command -v nmcli &> /dev/null; then
      aktif_ag=$(nmcli -t -f NAME connection show --active | head -n1)
    if [ -z "$aktif_ag" ]; then
      say ""aktif ag bulunamadi...""
    else
      nmcli connection modify "$aktif_ag" ipv4.dns "1.1.1.1"
      nmcli connection modify "$aktif_ag" ipv4.ignore-auto-dns no
      say ""${aktif_ag} aginin dns'i 1.1.1.1 olarak ayarlandi.""
      say ""network yeniden baslatiliyor...""
      nmcli connection down "$aktif_ag" 2>/dev/null
      sleep 1
      nmcli connection up "$aktif_ag"
      fi
    fi
    say ""UYARI: zenity paketi baska uygulamalarin da calismasi icin gerekli olabileceginden betik tarafindan kaldirilmayacak.""
    say ""yine de elle kaldirmak isterseniz '${paketyonetici} zenity' komutu kullanarak kaldirabilirsiniz.""
else
    say ""dnscrypt-proxy kaldirilmayacak""
fi
echo
say ""BILGI: isterseniz ~/.local/share/byedpi-turkey repo klasorunu de elinizle kaldirabilirsiniz.""
say ""betik basariyla tamamlandi""
