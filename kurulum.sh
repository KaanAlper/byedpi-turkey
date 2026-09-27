#!/bin/bash

set -e

GUM_BIN="gum"
if ! command -v gum >/dev/null 2>&1; then
    printf '\033[1;36m>> Arayuz araci (gum) indiriliyor...\033[0m\n'
    GUM_DIR="/tmp/asena_gum"
    mkdir -p "$GUM_DIR"
    curl -sL "https://github.com/charmbracelet/gum/releases/download/v2.0.2/gum_2.0.2_Linux_x86_64.tar.gz" | tar -xz -C "$GUM_DIR" 2>/dev/null || true
    GUM_BIN="$(find "$GUM_DIR" -name "gum" -type f | head -n 1)"
    [ -n "$GUM_BIN" ] && chmod +x "$GUM_BIN" || GUM_BIN="gum"
fi

banner() {
    if [ -x "$GUM_BIN" ]; then
        "$GUM_BIN" style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" --padding "1 2" "Kurulum Sihirbazi"
    else
        printf '\033[1;35m=== Kurulum Sihirbazi ===\033[0m\n'
    fi
}
say() {
    if [ -x "$GUM_BIN" ]; then
        "$GUM_BIN" style --foreground 86 ">> set -e
"
    else
        printf '\033[1;36m>> %s\033[0m\n' "set -e
"
    fi
}
die() {
    if [ -x "$GUM_BIN" ]; then
        "$GUM_BIN" style --foreground 196 "!! set -e
"
    else
        printf '\033[1;31m!! %s\033[0m\n' "set -e
" >&2
    fi
    exit 1
}
clear
banner
if [ -x "$GUM_BIN" ]; then
    "$GUM_BIN" confirm "Kurulumu baslatmak istiyor musunuz?" || { say "Iptal edildi."; exit 0; }
fi
sudo pkill -f hev-socks5-tunnel
say "Tünel Boşaltıldı"
selected_profile="varsayilan-profil"
DNS_NONE="/etc/NetworkManager/conf.d/90-dns-none.conf"

paket-yonetici-tanimla() {
if command -v pacman &> /dev/null; then
    paketyonetici="pacman -S"
    distro="arch tabanli"
  fi

if command -v dnf &> /dev/null; then
    paketyonetici="dnf install"
    distro="fedora tabanli"
  fi

if command -v apt &> /dev/null; then
    paketyonetici="apt install"
    distro="debian/ubuntu tabanli"
fi

if ! command -v pacman &> /dev/null && ! command -v dnf &> /dev/null && ! command -v apt &> /dev/null; then
    say ""desteklenen paket yoneticileri arasinda paket yoneticiniz yok""
    say ""desteklenenler:""
    say ""    pacman""
    say ""    dnf""
    exit 1
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
      paketyonetici="pacman -S"
      distro="arch tabanlı"
    elif [[ "$manuelcevap" == "2" ]]; then
      paketyonetici="dnf install"
      distro="fedora tabanlı"
    elif [[ "$manuelcevap" == "3" ]]; then
      paketyonetici="apt install"
      distro="debian/ubuntu tabanlı"
    fi

    say ""${distro} seçildi. Paket yükleme komutu: '${paketyonetici}' kullanılacak.""
  else
    say ""Dağıtımınız ${distro} olarak belirlendi. Paket yükleme komutu: '${paketyonetici}' kullanılacak.""
  fi  
}

ubuntu-check() {
    if [[ "$paketyonetici" == "apt install" ]]; then
        say ""Ubuntu destegi yapilan testler sonucunda kaldirilmistir. Ubuntu icin yeni bir script eklenecektir.""
        exit 1
    fi
}

acikla() {
  say ""Bu kurulum sihirbazi dnscrypt-proxy ile beraber byedpictl kuracaktir. Betigi kullanmak tamamen sizin sorumlulugunuzdadir.""
  echo
}

profil-sec() {
  echo
  say ""Mevcut profiller:""
  echo
  
  local profile_files=()
  local profile_names=()
  
  if [[ -d "profiles" ]] && [[ -n "$(ls profiles/*.conf 2>/dev/null)" ]]; then
    profile_files=(profiles/*.conf)
  fi
  
  if [[ ${#profile_files[@]} -eq 0 ]]; then
    say ""1 - Varsayılan profil (profiles klasörü bulunamadı, varsayılan profil kullanılacak)""
    echo
    say ""UYARI: profiles/ klasöründe .conf dosyası bulunamadı. Varsayılan profil kullanılacak.""
    selected_profile="varsayilan"
    return
  fi
  
  for i in "${!profile_files[@]}"; do
    profile_file="${profile_files[$i]}"
    if [[ -f "$profile_file" ]]; then
      profile_name=$(basename "$profile_file" .conf)
      profile_names+=("$profile_name")
      say ""$((i+1)) - $profile_name""
      
      local name description
      name=$(grep -E "^# Profile Name:" "$profile_file" 2>/dev/null | sed 's/^# Profile Name: *//' | xargs || echo "")
      description=$(grep -E "^# Description:" "$profile_file" 2>/dev/null | sed 's/^# Description: *//' | xargs || echo "")
      
      if [[ -n "$name" ]]; then
        say ""    İsim: $name""
      fi
      if [[ -n "$description" ]]; then
        say ""    Açıklama: $description""
      fi
      echo
    fi
  done
  
  say ""$((${#profile_files[@]}+1)) - Manuel ayar (kurulum sonrası /etc/byedpictl/desync.conf dosyasını düzenleyin)""
  echo
  
  read -p "Profil seçiminiz (1-$((${#profile_files[@]}+1))): " profil_secim
  
  while [[ ! "$profil_secim" =~ ^[0-9]+$ ]] || [[ "$profil_secim" -lt 1 ]] || [[ "$profil_secim" -gt $((${#profile_files[@]}+1)) ]]; do
    say ""Lütfen geçerli bir seçim yapın (1-$((${#profile_files[@]}+1))).""
    read -p "Profil seçiminiz (1-$((${#profile_files[@]}+1))): " profil_secim
  done
  
  if [[ "$profil_secim" -le "${#profile_files[@]}" ]]; then
    selected_profile="${profile_names[$((profil_secim-1))]}"
    say ""${profile_names[$((profil_secim-1))]} profili seçildi.""
  else
    selected_profile="manuel"
    say ""Manuel ayar seçildi. Kurulum sonrasında /etc/byedpictl/desync.conf dosyasını düzenleyebilirsiniz.""
  fi
  
  echo
}

profil-uygula() {
  if [[ ! -d "profiles" ]] || [[ -z "$(ls profiles/*.conf 2>/dev/null)" ]] || [[ "$selected_profile" == "varsayilan" ]]; then
    say ""Varsayılan profil uygulanıyor...""
    
    cat > "src/conf/desync.conf" <<'EOF'
CIADPI_DESYNC=(
    "--tlsrec=1+s"
)
EOF
    say ""Varsayılan profil başarıyla uygulandı.""
    return
  fi
  
  if [[ "$selected_profile" == "manuel" ]]; then
    say ""Manuel ayar seçildi. Varsayılan profil uygulanıyor...""
    if [[ -f "profiles/varsayilan-profil.conf" ]]; then
      cp "profiles/varsayilan-profil.conf" "src/conf/desync.conf"
      say ""Varsayılan profil başarıyla uygulandı.""
    else
      cat > "src/conf/desync.conf" <<'EOF'
CIADPI_DESYNC=(
    "--tlsrec=1+s"
)
EOF
      say ""Varsayılan profil başarıyla oluşturuldu ve uygulandı.""
    fi
    return
  fi
  
  local profil_dosyasi="profiles/${selected_profile}.conf"
  local hedef_dosya="src/conf/desync.conf"
  
  if [[ -f "$profil_dosyasi" ]]; then
    say ""Profil uygulanıyor: $selected_profile""
    cp "$profil_dosyasi" "$hedef_dosya"
    say ""Profil başarıyla uygulandı: $selected_profile""
  else
    say ""HATA: $profil_dosyasi bulunamadı!""
    say ""Mevcut profiller:""
    ls profiles/*.conf 2>/dev/null | xargs -n 1 basename | sed 's/\.conf$//' || echo "Hiç profil bulunamadı!"
    
    say ""Varsayılan profil uygulanıyor...""
    cat > "src/conf/desync.conf" <<'EOF'
CIADPI_DESYNC=(
    "--tlsrec=1+s"
)
EOF
    say ""Varsayılan profil başarıyla uygulandı.""
  fi
}

dnscrypt-check() {
  while ! command -v dnscrypt-proxy &> /dev/null; do
    say ""Sistemde dnscrypt-proxy tespit edilemedi. Paket yoneticinizle kurulum yapiliyor.""
    say ""Lutfen sudo sifresi istenirse girin.""
    say """"
    sudo ${paketyonetici} dnscrypt-proxy
    sleep 2
    say ""dnscrypt-proxy tekrar kontrol ediliyor...""
    if command -v dnscrypt-proxy &> /dev/null; then
      say ""Kontrol basarili. Devam ediliyor.""
    else
      say ""Kontrol basarisiz. Tekrar deneniyor...""
    fi
  done

  if command -v dnscrypt-proxy &> /dev/null; then
    say ""dnscrypt-proxy tespit edildi. Devam ediliyor.""
  else
    say ""dnscrypt kurulumunda bir sorun var gibi gorunuyor...""
    exit 1
  fi
}

zenity-check() {
  while ! command -v zenity &> /dev/null; do
    say ""Sistemde zenity tespit edilemedi. Paket yoneticinizle kurulum yapiliyor.""
    say ""Lutfen sudo sifresi istenirse girin.""
    say """"
    sudo ${paketyonetici} zenity
    if command -v zenity &> /dev/null; then
      say ""Kontrol basarili. Devam ediliyor.""
    else
      say ""Kontrol basarisiz. Tekrar deneniyor...""
    fi
  done

  if command -v zenity &> /dev/null; then
    say ""zenity tespit edildi. Devam ediliyor.""
  else
    say ""zenity kurulumunda bir sorun var gibi gorunuyor...""
    exit 1
  fi
}

dns-none() {
  say ""networkmanager dns-none ayarlaniyor...""
  say ""Lutfen sudo sifresi istenirse girin.""

  say ""Dosya yaziliyor: $DNS_NONE""
  sudo tee "$DNS_NONE" >/dev/null <<'EOF'
[main]
dns=none
EOF
}

resolv-conf() {
  say ""resolv.conf dosyasi guncelleniyor...""
  say ""UYARI: mevcut resolv.conf dosyasinin uzerine yazilacaktir. Orijinal resolv.conf yedekleniyor...""

  sudo cp /etc/resolv.conf /etc/resolv.conf.bak
  sudo cp configs/resolv.conf /etc/resolv.conf
}

dnscrypt-config() {
  say ""dnscrypt-proxy configi kuruluyor...""

  sudo cp configs/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml

  say ""dnscrypt-proxy'i dogru sekilde kullanmak icin masaustu ortaminizin ayarlarindan dns'i 127.0.0.1 olarak ayarlamalisiniz.""
  say ""nasil yapilacagini bilmiyorsaniz rehber videosuna bakabilirsiniz.""

  say ""Servisler baslatiliyor.""
  sudo systemctl enable dnscrypt-proxy.service
  sudo systemctl start dnscrypt-proxy.service
}

systemd-service() {
  if [[ $(ps -p 1 -o comm=) == "systemd" ]]; then
      say ""systemd kullaniliyor.""
      say ""systemd servisi kuruluyor...""
      sudo cp configs/byedpi-start.service /etc/systemd/system/byedpi-start.service
      sleep 1
      sudo systemctl daemon-reload
      sleep 2
      sudo systemctl enable byedpi-start.service
      sudo systemctl start byedpi-start.service
      echo
      say ""sistemin basinda acilmasini saglayan systemd servisini 'sudo systemctl enable/disable byedpi-start' yazarak kontrol edebilirsiniz""
  else
      say ""systemd kullanilmiyor. servis es geciliyor.""
  fi
}

dns-degis() {
  if command -v nmcli &> /dev/null; then
    aktif_ag=$(nmcli -t -f NAME connection show --active | head -n1)
    if [ -z "$aktif_ag" ]; then
        say ""aktif ag bulunamadi...""
    else
      nmcli connection modify "$aktif_ag" ipv4.dns "127.0.0.1"
      nmcli connection modify "$aktif_ag" ipv4.ignore-auto-dns yes
      say ""${aktif_ag} aginin dns'i 127.0.0.1 olarak ayarlandi.""
      say ""network yeniden baslatiliyor...""
      nmcli connection down "$aktif_ag" 2>/dev/null
      sleep 1
      nmcli connection up "$aktif_ag"
    fi
  else
    say ""networkmanager bulunamadi. dns ayari otomatik olarak yapilamiyor. lutfen manuel bir sekilde dns'inizi 127.0.0.1 olarak ayarlayin.""
  fi
}

byedpi-setup() {
  say ""byedpictl kurulum scripti calistiriliyor...""
    sudo bash make.sh install
}

byedpi-aktiflestir() {
  if command -v byedpictl &> /dev/null; then
    say ""byedpictl otomatik olarak baslatiliyor...""
    sudo byedpictl tun start
  else
    say ""byedpictl bulunamadi...""
  fi
}

acikla
paket-yonetici-tanimla
ubuntu-check
profil-sec
profil-uygula
dnscrypt-check
zenity-check
dns-none
resolv-conf
dnscrypt-config
byedpi-setup
dns-degis
systemd-service
byedpi-aktiflestir

say ""ByeDPI kuruldu. Sisteminizden byedpictl uygulamasini acarak ilk seferde aktiflestirebilirsiniz.""
if [[ -f /etc/systemd/system/byedpi-start.service ]]; then
  say ""ONEMLI: Sisteminiz yeniden basladiginda byedpictl otomatik olarak aktiflestirilecektir. Bunu devre disi birakmak istiyorsaniz 'sudo systemctl disable byedpi-start' yazin.""
fi


