#!/bin/bash

# Pastikan skrip dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   echo "Harap jalankan skrip ini sebagai root."
   exit 1
fi

echo "Masukkan token:"
read -r TOKEN

# Cek apakah token sesuai
if [[ "$TOKEN" != "xietyofc" ]]; then
    echo "❌ Token salah! Skrip berhenti."
    exit 1
fi

# Pilihan aksi
echo "Pilih aksi:"
echo "1) Install Tema"
echo "2) Uninstall Tema"
read -r ACTION

# Direktori panel
PANEL_DIR="/var/www/pterodactyl"

# Fungsi untuk install tema
install_theme() {
    local THEME_NAME=$1
    local THEME_URL=$2

    echo "🔄 Menginstall tema $THEME_NAME..."
    
    # Hapus folder lama jika ada
    if [ -d "/root/pterodactyl" ]; then
        sudo rm -rf /root/pterodactyl
    fi

    # Download & Ekstrak tema
    cd /root || exit
    wget -q "$THEME_URL"
    sudo unzip -o "$(basename "$THEME_URL")"
    
    # Pindahkan hasil unzip ke /var/www/pterodactyl dan timpa isinya
    sudo cp -rfT /root/pterodactyl "$PANEL_DIR"

    # Masuk ke direktori panel
    cd "$PANEL_DIR" || exit

    # Install Node.js dan Yarn
    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt install -y nodejs
    sudo npm i -g yarn

    # Jalankan build dan migrasi
    yarn add react-feather
    php artisan migrate --force
    yarn build:production
    php artisan view:clear

    # Hapus file sementara
    sudo rm "/root/$(basename "$THEME_URL")"
    sudo rm -rf /root/pterodactyl

    echo -e "                                                       "
    echo -e "${GREEN}[+] =============================================== [+]${NC}"
    echo -e "${GREEN}[+]                   INSTALL SUCCESS               [+]${NC}"
    echo -e "${GREEN}[+] =============================================== [+]${NC}"
    echo -e ""
    sleep 2
    clear
}

# Fungsi untuk uninstall tema
uninstall_theme() {
    echo "🔄 Menghapus tema dan mereset ke default..."
    cd "$PANEL_DIR" || exit

    php artisan down

    rm -r /var/www/pterodactyl/resources

    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv

    chmod -R 755 storage/* bootstrap/cache

    composer install --no-dev --optimize-autoloader

    php artisan view:clear

    php artisan config:clear

    php artisan migrate --seed --force

    chown -R www-data:www-data /var/www/pterodactyl/*

    php artisan queue:restart

    php artisan up
    echo "✅ Tema berhasil dihapus dan panel kembali ke default!"
}

if [[ "$ACTION" == "1" ]]; then
    echo "Pilih tema yang ingin diinstall:"
    echo "1) Stellar"
    echo "2) Darknate"
    echo "3) Enigma"
    echo "4) Billing"
    read -r CHOICE

    case $CHOICE in
        1) install_theme "Stellar" "https://github.com/XieTyyOfc/themeinstaller/raw/master/stellar.zip" ;;
        2) install_theme "Darknate" "https://github.com/XieTyyOfc/themeinstaller/raw/master/darknate.zip" ;;
        3) 
            echo "📲 Masukkan nomor WhatsApp untuk custom Enigma (format: 62xxxxxx):"
            read -r WA_NUMBER
            install_theme "Enigma" "https://github.com/XieTyyOfc/themeinstaller/raw/master/enigma.zip"
            sed -i "s/DEFAULT_WA_NUMBER/$WA_NUMBER/g" "$PANEL_DIR/config/enigma.json"
            ;;
        4) install_theme "Billing" "https://github.com/XieTyyOfc/themeinstaller/raw/master/billing.zip" ;;
        *) echo "❌ Pilihan tidak valid! Skrip berhenti." ;;
    esac
elif [[ "$ACTION" == "2" ]]; then
    uninstall_theme
else
    echo "❌ Pilihan tidak valid! Skrip berhenti."
fi