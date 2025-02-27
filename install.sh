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

# Fungsi untuk install NVM
install_nvm() {
    echo "🔄 Mengecek apakah NVM sudah terinstall..."

    if ! command -v nvm &> /dev/null; then
        echo "❌ NVM tidak ditemukan. Menginstall NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        
        echo "🔄 Merestart shell untuk menerapkan NVM..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    else
        echo "✅ NVM sudah terinstall."
    fi
}

# Jalankan install_nvm tanpa dipanggil secara eksplisit
install_nvm

# Fungsi umum untuk install dependensi
install_dependencies() {
    echo "🔄 Menginstall Node.js dan Yarn..."
    nvm install 16
    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt install -y nodejs
    sudo npm i -g yarn

    echo "🔄 Menggunakan NVM untuk install Node.js versi 16..."
}

# Fungsi untuk install Blueprint
install_blueprint() {
    echo "🔄 Mengecek apakah Blueprint sudah terinstall..."

    # Cek apakah Blueprint sudah terinstall
    cd "$PANEL_DIR" || exit
    if yarn list | grep -q blueprint; then
        echo "✅ Blueprint sudah terinstall. Melewati instalasi."
    else
        echo "❌ Blueprint tidak ditemukan. Menginstall Blueprint..."

        # Gunakan NVM untuk install Node.js versi 20
        echo "🔄 Menggunakan NVM untuk install Node.js versi 20..."
        nvm install 20
        nvm use 20

        # Install blueprint
        cd /var/www/pterodactyl
        apt install -y zip unzip git curl wget
        wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | cut -d '"' -f 4)" -O release.zip
        unzip release.zip
        chmod +x blueprint.sh
        bash blueprint.sh

        echo "✅ Blueprint berhasil diinstall!"
    fi
}

# Fungsi untuk install tema Stellar
install_stellar() {
    echo "🔄 Menginstall tema Stellar..."

    # Hapus folder lama jika ada
    if [ -d "/root/pterodactyl" ]; then
        sudo rm -rf /root/pterodactyl
    fi

    # Download & Ekstrak tema
    wget -q -O stellarr.zip https://github.com/XieTyyOfc/themeinstaller/raw/refs/heads/master/stellarr.zip && \
    sudo unzip stellarr.zip && \
    wait && \
    sudo cp -rfT /root/pterodactyl /var/www/pterodactyl

    cd /var/www/pterodactyl

    # Install blueprint sebelum dependens

    # Install dependensi
    install_dependencies

    # Jalankan build dan migrasi
    yarn add react-feather
    php artisan migrate --force
    yarn build:production
    php artisan view:clear

    # Hapus file sementara
    sudo rm /root/stellar.zip
    sudo rm /root/pterodactyl

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

    install_blueprint
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
