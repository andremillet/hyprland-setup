#!/bin/bash
#
# Script v8: Pós-instalação Arch Linux + Hyprland
#
# SÍNTESE (v8):
# - (v8) Adicionado 'nvidia-settings' para controle gráfico da NVIDIA.
# - (v8) 'rust'/'cargo' trocados por 'rustup' (padrão de dev).
# - (v8) Adicionado prompt pós-instalação para 'rustup'.
#
# - (v7) Correção: Sintaxe do 'if' no systemd-boot.
# - (v7) Correção: 'ulauncher --toggle-window'.
# - (v7) Correção: 'sed' robusto para o GRUB.
# - (v7) Correção: Removido 'egl-wayland'.
#
# - (Base) Sudo "keep-alive", detecção de NVIDIA, pacotes de áudio/screenshot,
#   idioma en_US, driver nvidia-dkms, hyprland.conf completo.
#

set -e

# Cores
BLUE="\033[1;34m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
NC="\033[0m"

# Funções de log
msg() { echo -e "${BLUE}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

if [ "$EUID" -eq 0 ]; then
    error "Este script NÃO deve ser executado como root. Rode como seu usuário normal."
fi

# Solicitar senha sudo no início
sudo -v
msg "Mantendo o 'sudo' vivo a cada 60s..."
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

# --- 1. Instalação do AUR Helper (yay) ---
setup_aur_helper() {
    msg "Configurando o AUR Helper (yay)..."
    if ! command -v yay &> /dev/null; then
        sudo pacman -S --needed --noconfirm base-devel git
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd
        success "yay instalado."
    else
        success "yay já está instalado."
    fi
}

# --- 2. Configuração de Localidade ---
setup_locale() {
    msg "Configurando idioma do sistema para Inglês (en_US.UTF-8)..."
    if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
        sudo sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
    fi
    sudo locale-gen
    echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf
    success "Idioma do sistema definido como en_US.UTF-8."
}

# --- 3. Instalação do Ambiente Básico ---
setup_base() {
    msg "Instalando ambiente Hyprland e utilitários essenciais..."
    PACMAN_PACKAGES=(
        hyprland waybar alacritty
        thunar thunar-archive-plugin tumbler
        networkmanager network-manager-applet
        bluez bluez-utils blueman
        ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
        polkit-kde-agent qt5-wayland qt6-wayland
        xdg-desktop-portal-hyprland xdg-utils
        cliphist swaybg brightnessctl slurp grim
        pipewire pipewire-pulse pipewire-alsa wireplumber
    )
    sudo pacman -Syu --noconfirm "${PACMAN_PACKAGES[@]}"
    
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth
    success "Ambiente básico instalado."
}

# --- 4. Configuração de Pacotes NVIDIA (CORRIGIDO v8) ---
setup_nvidia_pkgs() {
    if lspci | grep -i nvidia &> /dev/null; then
        msg "GPU NVIDIA detectada. Instalando drivers 'dkms' e 'settings'..."
        # v8: Adicionado 'nvidia-settings'
        sudo pacman -S --noconfirm nvidia-dkms linux-headers libva-nvidia-driver nvidia-settings
        success "Drivers NVIDIA (dkms) e painel de controle instalados."
    else
        msg "GPU NVIDIA não detectada. Pulando instalação de drivers."
    fi
}

# --- 5. Configuração do Ambiente de Desenvolvimento (CORRIGIDO v8) ---
setup_dev_env() {
    msg "Instalando ambiente de desenvolvimento (Python, Docker, Rust, Go)..."
    
    # v8: 'rust' e 'cargo' trocados por 'rustup'
    PACMAN_DEV=(
        python python-pip python-venv
        docker docker-compose
        git
        nodejs npm
        go
        rustup # Pacotes 'rust' e 'cargo' removidos
    )
    sudo pacman -S --noconfirm "${PACMAN_DEV[@]}"
    
    AUR_DEV=(
        visual-studio-code-bin
    )
    yay -S --noconfirm "${AUR_DEV[@]}"
    
    msg "Configurando Docker..."
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER"
    
    success "Ambiente de desenvolvimento instalado."
    
    # Lógica do CUDA
    if lspci | grep -i nvidia &> /dev/null; then
        read -p "NVIDIA detectada. Deseja instalar o toolkit CUDA (LLM)? [s/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            msg "Instalando CUDA e CUDNN..."
            sudo pacman -S --noconfirm cuda cudnn
            success "CUDA instalado."
        fi
    fi
}

# --- 6. Aplicações de Produtividade ---
setup_apps() {
    msg "Instalando aplicações (1Password, Brave, ZapZap, Ulauncher)..."
    sudo pacman -S --noconfirm rclone
    AUR_APPS=(
        1password 1password-cli
        brave-bin
        zapzap-bin
        ulauncher-bin
    )
    yay -S --noconfirm "${AUR_APPS[@]}"
    success "Aplicações instaladas."
}

# --- 7. Configuração Automática de Sistema (Lógica v7) ---
configure_system() {
    msg "Iniciando configuração automática do sistema..."

    local HYPR_CONFIG_DIR="$HOME/.config/hypr"
    local HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
    local ENV_VAR_FILE="$HYPR_CONFIG_DIR/env-vars.conf"
    local ENV_VAR_LINE="source = $ENV_VAR_FILE"

    mkdir -p "$HYPR_CONFIG_DIR"
    touch "$HYPR_CONFIG_FILE"

    if lspci | grep -i nvidia &> /dev/null; then
        msg "Criando env-vars.conf para NVIDIA..."
        cat <<EOF > "$ENV_VAR_FILE"
# Variáveis de ambiente para NVIDIA
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
EOF
    fi

    if [ ! -s "$HYPR_CONFIG_FILE" ]; then
        msg "hyprland.conf está vazio. Criando configuração rica..."
        cat <<EOF > "$HYPR_CONFIG_FILE"
#--- Configuração Básica Automática (Script v8) ---
source = $ENV_VAR_FILE
monitor=,preferred,auto,1
exec-once = waybar
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = ulauncher --hide-window
# exec-once = swaybg -i $HOME/Pictures/wallpaper.png

input {
    kb_layout = br
    follow_mouse = 1
    touchpad { natural_scroll = no }
    sensitivity = 0
}
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    cursor_inactive_timeout = 5
}
decoration {
    rounding = 5
    blur {
        enabled = true
        size = 5
        passes = 2
        new_optimizations = true
    }
    drop_shadow = yes
    shadow_range = 10
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}
dwindle {
    pseudotile = yes
    preserve_split = yes
}
master {
    new_is_master = true
}
gestures {
    workspace_swipe = false
}

# Atalhos de Teclado
\$mainMod = SUPER
bind = \$mainMod, RETURN, exec, alacritty
bind = \$mainMod, Q, killactive
bind = \$mainMod, M, exit
bind = \$mainMod, SPACE, exec, ulauncher --toggle-window
bind = \$mainMod, E, exec, thunar
bind = \$mainMod, V, togglefloating
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5
bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5
bindle = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
bindle = , XF86AudioLowerVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-
bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindle = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bindle = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
bind = , PRINT, exec, grim -g "\$(slurp)" - | wl-copy
bind = \$mainMod, P, exec, grim -g "\$(slurp)" - | wl-copy
EOF
        success "Configuração rica do hyprland.conf criada."
    else
        msg "hyprland.conf já existe. Adicionando 'source' da NVIDIA (se necessário)..."
        if lspci | grep -i nvidia &> /dev/null; then
            if ! grep -qF "$ENV_VAR_LINE" "$HYPR_CONFIG_FILE"; then
                sed -i "1i$ENV_VAR_LINE" "$HYPR_CONFIG_FILE"
                success "Linha 'source' adicionada ao $HYPR_CONFIG_FILE."
            fi
        fi
    fi

    # Configuração do Bootloader para NVIDIA (Lógica v7)
    if lspci | grep -i nvidia &> /dev/null; then
        msg "Configurando Bootloader para NVIDIA..."
        
        if [ -d /boot/loader/entries ]; then
            msg "Detectado systemd-boot. Configurando..."
            local ENTRY_FILE
            ENTRY_FILE=$(find /boot/loader/entries/ -name "*arch*.conf" | head -n 1)
            
            if [ -z "$ENTRY_FILE" ]; then
                ENTRY_FILE=$(find /boot/loader/entries/ -name "*.conf" | head -n 1)
            fi
            
            if [ -n "$ENTRY_FILE" ]; then
                if ! grep -q "nvidia_drm.modeset=1" "$ENTRY_FILE"; then
                    sudo sed -i '/^options/ s/$/ nvidia_drm.modeset=1/' "$ENTRY_FILE"
                    success "Parâmetro NVIDIA adicionado a $ENTRY_FILE."
                else
                    success "Parâmetro NVIDIA já existe em $ENTRY_FILE."
                fi
            else
                error "Não foi possível encontrar um arquivo .conf em /boot/loader/entries/."
            fi
        
        elif [ -f /etc/default/grub ]; then
            msg "Detectado GRUB. Configurando..."
            
            if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
                sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia_drm.modeset=1/' /etc/default/grub
                msg "Parâmetro 'nvidia_drm.modeset=1' adicionado ao /etc/default/grub."
            else
                msg "Parâmetro do kernel NVIDIA já existe no /etc/default/grub."
            fi
            
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            success "GRUB atualizado."
        else
            warning "Não foi possível detectar GRUB ou systemd-boot."
            warning "AÇÃO MANUAL NECESSÁRIA: Adicione 'nvidia_drm.modeset=1' aos parâmetros do kernel."
        fi
    fi
}

# --- 8. Prompt Pós-Instalação (CORRIGIDO v8) ---
post_install_prompts() {
    success "Instalação principal concluída!"
    msg "--- AÇÕES MANUAIS OBRIGATÓRIAS ---"
    
    echo -e "\n${GREEN}1. Rclone (Google Drive):${NC}"
    echo "   Rode o comando abaixo para configurar sua conta (requer navegador):"
    echo "   ${YELLOW}rclone config${NC}"
    
    echo -e "\n${GREEN}2. 1Password:${NC}"
    echo "   Abra o app 1Password ou rode no terminal para fazer login:"
    echo "   ${YELLOW}op signin${NC}"

    echo -e "\n${GREEN}3. Docker:${NC}"
    echo "   Você DEVE reiniciar (ou fazer logoff) para usar o Docker sem 'sudo'."

    # v8: Novo prompt para Rustup
    echo -e "\n${GREEN}4. Rust (rustup):${NC}"
    echo "   O gerenciador 'rustup' está instalado. Para instalar o Rust, rode:"
    echo "   ${YELLOW}rustup toolchain install stable${NC}"

    # Re-numerado
    echo -e "\n${GREEN}5. Ulauncher:${NC}"
    echo "   Após reiniciar, aperte 'Super + Espaço'. Na primeira vez,"
    echo "   o Ulauncher pedirá para configurar o tema (recomendo 'Adwaita Dark')."
    
    # Re-numerado
    echo -e "\n${GREEN}6. Wallpaper:${NC}"
    echo "   Edite '~/.config/hypr/hyprland.conf' e descomente a linha 'exec-once = swaybg ...'"
    echo "   com o caminho para sua imagem preferida."

    echo -e "\n--------------------------------------------------------"
    
    read -p "REINICIAR é necessário. Deseja reiniciar agora? [s/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        msg "Reiniciando o sistema em 3 segundos..."
        sleep 3
        sudo reboot
    else
        msg "OK. Lembre-se de reiniciar manualmente."
    fi
}

# --- Execução Principal ---
main() {
    setup_aur_helper
    setup_locale
    setup_base
    setup_nvidia_pkgs
    setup_dev_env
    setup_apps
    configure_system
    post_install_prompts
}

main
