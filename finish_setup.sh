#!/bin/bash
#
# Script v12 (finish_setup.sh):
# Corrige e instala os pacotes e configurações que falharam no script v9.
#

set -e

# Cores
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m"
msg() { echo -e "${BLUE}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }

msg "Iniciando script de finalização (v12)..."
msg "As senhas do sudo serão pedidas para 'pacman' e 'yay'."

# --- 1. Ambiente de Desenvolvimento (COM CORREÇÃO) ---
setup_dev_env() {
    msg "Instalando ambiente de desenvolvimento (Python, Docker, Rust, Go)..."
    
    # CORREÇÃO: 'python-venv' foi renomeado para 'python-virtualenv'
    local PACMAN_DEV=(
        python-pip 
        python-virtualenv
        docker 
        docker-compose
        git 
        nodejs 
        npm 
        go 
        rustup
    )
    sudo pacman -S --noconfirm "${PACMAN_DEV[@]}"
    
    local AUR_DEV=(
        visual-studio-code-bin
    )
    yay -S --noconfirm "${AUR_DEV[@]}"
    
    msg "Configurando Docker..."
    sudo systemctl enable docker
    # Adiciona o utilizador ao grupo docker (requer novo login para ter efeito)
    sudo usermod -aG docker "$USER"
    
    # Instala CUDA se a NVIDIA for detetada
    if lspci | grep -i nvidia &> /dev/null; then
        msg "NVIDIA detectada. Instalando CUDA e CUDNN..."
        sudo pacman -S --noconfirm cuda cudnn
    fi
    success "Ambiente de desenvolvimento instalado."
}

# --- 2. Aplicações (A etapa que falhou) ---
setup_apps() {
    msg "Instalando aplicações (Brave, 1Password, ZapZap, Rclone)..."
    sudo pacman -S --noconfirm rclone
    
    # ulauncher será 'reinstalado' ou 'ignorado' pelo yay, o que é seguro.
    local AUR_APPS=(
        1password 
        brave-bin 
        zapzap-bin
        ulauncher
    )
    yay -S --noconfirm "${AUR_APPS[@]}"
    success "Aplicações instaladas."
}

# --- 3. Configuração de Sistema (A etapa que falhou) ---
configure_system() {
    msg "Configurando sistema (NVIDIA e Hyprland)..."

    local HYPR_CONFIG_DIR="$HOME/.config/hypr"
    local HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
    local ENV_VAR_FILE="$HYPR_CONFIG_DIR/env-vars.conf"
    mkdir -p "$HYPR_CONFIG_DIR"

    # 1. Criar o arquivo NVIDIA (O utilizador confirmou que tem NVIDIA)
    if lspci | grep -i nvidia &> /dev/null; then
        msg "Criando env-vars.conf para NVIDIA..."
        cat <<EOF > "$ENV_VAR_FILE"
# Variáveis de ambiente para NVIDIA
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
EOF
    else
        msg "NVIDIA não detetada. Pulando criação do env-vars.conf."
        # Cria um ficheiro vazio para o 'source' não falhar
        touch "$ENV_VAR_FILE"
    fi
    
    # 2. SOBRESCREVER o hyprland.conf com a versão v11 funcional
    msg "Aplicando configuração v11 (funcional) do Hyprland..."
    cat <<EOF > "$HYPR_CONFIG_FILE"
# --- Configuração v11 (Limpa e Funcional) ---

# Carrega as variáveis da NVIDIA (IMPORTANTE!)
source = $ENV_VAR_FILE

# Monitor
monitor=,preferred,auto,1

# Layout ABNT
input {
    kb_layout = br
}

# Autostart
exec-once = waybar
exec-once = ulauncher --hide-window

# Atalhos
bind = SUPER, RETURN, exec, alacritty
bind = SUPER, SPACE, exec, ulauncher --toggle-window
bind = SUPER, D, exec, wofi --show drun
bind = SUPER, Q, killactive, 
bind = SUPER, M, exit, 
EOF
    success "Configuração do Hyprland e NVIDIA aplicada."
}


# --- Execução Principal ---
main() {
    setup_dev_env
    setup_apps
    configure_system
    
    success "Script de finalização concluído!"
    msg "TODAS as aplicações e configurações estão agora instaladas."
    msg "Para aplicar tudo, saia do Hyprland (Super + M) e inicie-o novamente ('exec Hyprland' no TTY)."
}

main
