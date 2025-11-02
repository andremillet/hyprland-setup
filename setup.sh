---

### 2. O `setup.sh` 

Este é o script que o `curl` irá descarregar. 

```bash
#!/bin/bash
#
# SCRIPT DE PÓS-INSTALAÇÃO
# EXECUTAR COMO UTILIZADOR NORMAL (./setup.sh) - NÃO USAR 'sudo'
#

# --- Funções de Log ---
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"
msg() { echo -e "${BLUE}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[!]${NC} $1"; }

# --- Pedir sudo no início e manter vivo ---
msg "A pedir privilégios de sudo para a instalação..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 1. CONFIGURAR REDE (Habilitar o que foi instalado) ---
setup_network() {
    msg "A habilitar o NetworkManager para arranques futuros..."
    sudo systemctl enable NetworkManager
    success "NetworkManager habilitado."
}

# --- 2. CONFIGURAR YAY (AUR HELPER) ---
setup_yay() {
    msg "Configurando o AUR Helper (yay)..."
    if ! command -v yay &> /dev/null; then
        msg "A instalar 'base-devel' para compilar o yay..."
        sudo pacman -S --noconfirm base-devel
        
        msg "A clonar e compilar o yay (Executando 'makepkg' como $USER)..."
        # Executa como utilizador (não root), pedindo sudo internamente quando necessário.
        (
            git clone https://aur.archlinux.org/yay.git /tmp/yay &&
            cd /tmp/yay &&
            makepkg -si --noconfirm &&
            cd ~ &&
            rm -rf /tmp/yay
        )
        success "yay instalado."
    else
        success "yay já está instalado."
    fi
}

# --- 3. AMBIENTE DE BASE (HYPRLAND, ÁUDIO, FONTES) ---
setup_base_env() {
    msg "Instalando ambiente de base (Hyprland, Waybar, Alacritty, Áudio)..."
    # linux-headers (para NVIDIA) e ferramentas de screenshot/áudio
    local PACMAN_PACKAGES=(
        hyprland waybar alacritty wofi thunar
        linux-headers
        pipewire pipewire-pulse pipewire-alsa wireplumber
        polkit-kde-agent
        ttf-jetbrains-mono-nerd noto-fonts-emoji
        brightnessctl grim slurp
    )
    sudo pacman -S --noconfirm "${PACMAN_PACKAGES[@]}"
    success "Ambiente de base instalado."
}

# --- 4. DRIVERS NVIDIA (CONDICIONAL) ---
setup_nvidia() {
    if lspci | grep -i nvidia &> /dev/null; then
        msg "Placa NVIDIA detetada. A instalar drivers DKMS..."
        sudo pacman -S --noconfirm nvidia-dkms libva-nvidia-driver nvidia-settings
        
        msg "A criar ficheiro de variáveis de ambiente NVIDIA..."
        mkdir -p ~/.config/hypr
        cat <<EOF > ~/.config/hypr/env-vars.conf
# Variáveis de ambiente para NVIDIA
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
EOF
        success "Drivers NVIDIA e variáveis de ambiente configurados."
    else
        warning "Nenhuma placa NVIDIA detetada. A ignorar instalação de drivers."
    fi
}

# --- 5. AMBIENTE DE DESENVOLVIMENTO (CORRIGIDO) ---
setup_dev_env() {
    msg "Instalando ambiente de desenvolvimento (Python, Docker, Rust, Go)..."
    
    # CORRIGIDO: 'python-venv' -> 'python-virtualenv'
    local PACMAN_DEV=(
        python-pip 
        python-virtualenv
        docker 
        docker-compose
        nodejs 
        npm 
        go 
        rustup
    )
    sudo pacman -S --noconfirm "${PACMAN_DEV[@]}"
    
    msg "A configurar Docker..."
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER"
    
    if lspci | grep -i nvidia &> /dev/null; then
        msg "A instalar CUDA e CUDNN para NVIDIA..."
        sudo pacman -S --noconfirm cuda cudnn
    fi
    success "Ambiente de desenvolvimento instalado."
}

# --- 6. APLICAÇÕES (NOMES CORRIGIDOS) ---
setup_apps() {
    msg "Instalando aplicações do AUR (VSCode, 1Password, Brave, Ulauncher, ZapZap)..."
    
    # CORRIGIDO: Nomes de pacotes
    yay -S --noconfirm visual-studio-code-bin || error "Falha ao instalar VSCode"
    yay -S --noconfirm 1password || error "Falha ao instalar 1Password"
    yay -S --noconfirm brave-bin || error "Falha ao instalar Brave"
    yay -S --noconfirm ulauncher || error "Falha ao instalar Ulauncher"
    yay -S --noconfirm zapzap || error "Falha ao instalar ZapZap"
    
    sudo pacman -S --noconfirm rclone || error "Falha ao instalar Rclone"
    
    success "Aplicações instaladas."
}

# --- 7. CONFIGURAR HYPRLAND (O V12 FUNCIONAL) ---
configure_hyprland() {
    msg "A aplicar a configuração funcional v12 do Hyprland..."
    local HYPR_CONFIG_DIR="$HOME/.config/hypr"
    local HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
    mkdir -p "$HYPR_CONFIG_DIR"

    # Escreve o ficheiro de configuração (sobrescreve qualquer fallback)
    cat <<EOF > "$HYPR_CONFIG_FILE"
# --- Configuração v12 (Funcional e Corrigida) ---

# Carrega as variáveis da NVIDIA (APENAS SE O FICHEIRO EXISTIR)
$(if [ -f "$HYPR_CONFIG_DIR/env-vars.conf" ]; then echo "source = $HYPR_CONFIG_DIR/env-vars.conf"; fi)

# Monitor
monitor=,preferred,auto,1

# Layout ABNT
input {
    kb_layout = br
}

# Autostart
exec-once = waybar
exec-once = ulauncher --hide-window
exec-once = /usr/lib/polkit-kde-authentication-agent-1

# Atalhos
\$mainMod = SUPER
bind = \$mainMod, RETURN, exec, alacritty
bind = \$mainMod, SPACE, exec, ulauncher --toggle-window
bind = \$mainMod, D, exec, wofi --show drun
bind = \$mainMod, E, exec, thunar
bind = \$mainMod, Q, killactive, 
bind = \$mainMod, M, exit, 
EOF
    success "Configuração do Hyprland aplicada."
}

# --- 8. CONFIGURAR AUTO-LOGIN GRÁFICO ---
setup_autologin() {
    msg "A configurar o .bash_profile para iniciar o Hyprland automaticamente no TTY1..."
    
    # Garante que o ficheiro exista
    touch ~/.bash_profile
    
    # Adiciona a lógica ao .bash_profile (se já não existir)
    if ! grep -q "exec Hyprland" ~/.bash_profile; then
        cat <<EOF >> ~/.bash_profile

# --- Iniciar Hyprland automaticamente no TTY1 ---
if [[ -z \$DISPLAY ]] && [[ \$(tty) == /dev/tty1 ]]; then
    exec Hyprland
fi
EOF
    fi
    success "Auto-login gráfico configurado."
}

# --- Execução Principal ---
main() {
    # 'set -e' para parar se algo crítico (rede, yay) falhar
    set -e
    setup_network
    setup_yay
    setup_base_env
    setup_nvidia
    
    # 'set +e' para permitir que a instalação de apps continue
    # mesmo que um pacote falhe (ex: VSCode time-out)
    set +e
    setup_dev_env
    setup_apps
    
    # 'set -e' novamente para a configuração final
    set -e
    configure_hyprland
    setup_autologin
    
    success "INSTALAÇÃO CONCLUÍDA!"
    warning "Lembre-se de fazer as configurações manuais:"
    echo "1. (Docker) Faça logout/login para que o grupo 'docker' tenha efeito."
    echo "2. (Rust) Execute 'rustup toolchain install stable'."
    echo "3. (1Password) Execute 'op signin'."
    echo "4. (Rclone) Execute 'rclone config'."
    
    msg "O sistema irá reiniciar em 10 segundos..."
    sleep 10
    sudo reboot
}

# Inicia o script
main
