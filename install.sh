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

# Fungsi umum untuk install dependensi
install_dependencies() {
    echo "🔄 Menginstall dependensi..."
    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt install -y nodejs
    sudo npm i -g yarn
}

# Fungsi untuk install tema Stellar
install_stellar() {
    echo "🔄 Menginstall tema Stellar..."

    # Hapus folder lama jika ada
    if [ -d "/root/pterodactyl" ]; then
        sudo rm -rf /root/pterodactyl
    fi

    # Download & Ekstrak tema
    cd /root || exit
    wget -q "https://github.com/XieTyyOfc/themeinstaller/raw/master/stellar.zip"
    sudo unzip -o "stellar.zip"
    
    # Pindahkan hasil unzip ke /var/www/pterodactyl dan timpa isinya
    sudo cp -rfT /root/pterodactyl "$PANEL_DIR"

    # Masuk ke direktori panel
    cd "$PANEL_DIR" || exit

    install_dependencies

    # Jalankan build dan migrasi
    yarn add react-feather
    php artisan migrate --force
    yarn build:production
    php artisan view:clear

    # Hapus file sementara
    sudo rm "/root/stellar.zip"
    sudo rm -rf /root/pterodactyl

    echo "✅ Tema Stellar berhasil diinstall!"
}

# Fungsi untuk install tema Darknate
install_darknate() {
    echo "🔄 Menginstall tema Darknate..."

    if [ -d "/root/pterodactyl" ]; then
        sudo rm -rf /root/pterodactyl
    fi

    cd /root || exit
    wget -q "https://github.com/XieTyyOfc/themeinstaller/raw/master/darknate.zip"
    sudo unzip -o "darknate.zip"
    
    sudo cp -rfT /root/pterodactyl "$PANEL_DIR"

    cd "$PANEL_DIR" || exit

    install_dependencies

    yarn add react-feather
    yarn build:production
    php artisan view:clear

    sudo rm "/root/darknate.zip"
    sudo rm -rf /root/pterodactyl

    echo "✅ Tema Darknate berhasil diinstall!"
}

# Fungsi untuk install tema Enigma
install_enigma() {
    echo "📲 Masukkan nomor WhatsApp untuk custom Enigma (format: 62xxxxxx):"
    read -r WA_NUMBER

    echo "🔄 Menginstall tema Enigma..."

    if [ -d "/root/pterodactyl" ]; then
        sudo rm -rf /root/pterodactyl
    fi

    cd /root || exit
    wget -q "https://github.com/XieTyyOfc/themeinstaller/raw/master/enigma.zip"
    sudo unzip -o "enigma.zip"
    
    sudo cp -rfT /root/pterodactyl "$PANEL_DIR"

    cd "$PANEL_DIR" || exit

    install_dependencies

    yarn add react-feather
    php artisan migrate --force
    yarn build:production
    php artisan view:clear

    # Custom nomor WhatsApp
    sed -i "s/DEFAULT_WA_NUMBER/$WA_NUMBER/g" "$PANEL_DIR/config/enigma.json"

    sudo rm "/root/enigma.zip"
    sudo rm -rf /root/pterodactyl

    echo "✅ Tema Enigma berhasil diinstall!"
}

# Fungsi untuk install tema Billing
install_billing() {
    echo "🔄 Menginstall tema Billing..."

    if [ -d "/root/pterodactyl" ]; then
        sudo rm -rf /root/pterodactyl
    fi

    cd /root || exit
    wget -q "https://github.com/XieTyyOfc/themeinstaller/raw/master/billing.zip"
    sudo unzip -o "billing.zip"
    
    sudo cp -rfT /root/pterodactyl "$PANEL_DIR"

    cd "$PANEL_DIR" || exit

    install_dependencies

    yarn add react-feather
    php artisan billing:install stable
    php artisan migrate --force
    yarn build:production
    php artisan view:clear

    sudo rm "/root/billing.zip"
    sudo rm -rf /root/pterodactyl

    echo "✅ Tema Billing berhasil diinstall!"
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
        1) install_stellar ;;
        2) install_darknate ;;
        3) install_enigma ;;
        4) install_billing ;;
        *) echo "❌ Pilihan tidak valid! Skrip berhenti." ;;
    esac
elif [[ "$ACTION" == "2" ]]; then
    uninstall_theme
else
    echo "❌ Pilihan tidak valid! Skrip berhenti."
fi
