#!/bin/bash
#
# Post-install wrapper para archinstall
# Executado como root dentro do chroot
# (Baseado na sugestão do DeepSeek)
#

set -e

# --- CONFIGURAÇÃO (MUDE ISTO) ---
USERNAME="woulschneider"
REPO_URL="https://raw.githubusercontent.com/andremillet/hyprland_setup/main"
SETUP_SCRIPT="setup.sh"
# --- FIM CONFIGURAÇÃO ---

USER_HOME="/home/$USERNAME"

msg() { echo -e "\033[1;34m[*]\033[0m $1"; }
success() { echo -e "\033[1;32m[+]\033[0m $1"; }

msg "Configurando execução automática do setup..."

# 1. Baixar script de setup
msg "Baixando script de pós-instalação..."
if curl -fsSL -o "$USER_HOME/$SETUP_SCRIPT" "$REPO_URL/$SETUP_SCRIPT"; then
    chmod +x "$USER_HOME/$SETUP_SCRIPT"
    chown "$USERNAME:$USERNAME" "$USER_HOME/$SETUP_SCRIPT"
    success "Script de setup baixado."
else
    echo "AVISO: Não foi possível baixar o script. Execução manual necessária."
    exit 0
fi

# 2. Configurar execução automática no primeiro login
PROFILE_FILE="$USER_HOME/.bash_profile"

# Backup do profile original se existir
if [ -f "$PROFILE_FILE" ]; then
    cp "$PROFILE_FILE" "$PROFILE_FILE.backup"
fi

# Adicionar execução automática
cat >> "$PROFILE_FILE" << EOF

# --- Auto-setup (remove após execução) ---
if [ -f "$USER_HOME/$SETUP_SCRIPT" ]; then
    echo "Executando setup de pós-instalação (v9)..."
    cd "$USER_HOME"
    if "./$SETUP_SCRIPT"; then
        echo "Setup concluído com sucesso."
        echo "Removendo script de auto-setup..."
        # Remove estas linhas do profile
        grep -v "# --- Auto-setup" "$PROFILE_FILE" > "$PROFILE_FILE.tmp" \
            && mv "$PROFILE_FILE.tmp" "$PROFILE_FILE"
    else
        echo "AVISO: Setup falhou. Execute manualmente: ./$SETUP_SCRIPT"
    fi
fi
EOF

chown "$USERNAME:$USERNAME" "$PROFILE_FILE"

# 3. Configurar sudo sem senha para o usuário (APENAS para o setup)
msg "Configurando sudo NOPASSWD temporário..."
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10-$USERNAME-setup
chmod 440 /etc/sudoers.d/10-$USERNAME-setup

success "Configuração de pós-instalação concluída."
echo "O script $SETUP_SCRIPT será executado automaticamente no primeiro login."