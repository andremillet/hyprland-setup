# 🚀 Arch Hyprland Setup (v8)

Este repositório contém o script de pós-instalação (`setup.sh`) para configurar rapidamente um ambiente de desenvolvimento robusto no Arch Linux, utilizando o **Hyprland** (um moderno *tiling window manager* Wayland) com otimizações para **NVIDIA** e ferramentas essenciais de produtividade/LLM.

O script automatiza a instalação de drivers, gerenciadores de pacotes (yay), e configurações básicas para um desktop funcional com teclado **ABNT** e idioma do sistema em **Inglês (`en_US.UTF-8`)**.

## ✨ Funcionalidades do Script

* **Ambiente:** Hyprland, Waybar, Alacritty (Terminal), Thunar (Gerenciador de Arquivos).
* **Drivers:** Instalação robusta de `nvidia-dkms`, `linux-headers`, `libva-nvidia-driver` e `nvidia-settings`, com detecção automática do hardware e configuração do bootloader (GRUB ou systemd-boot).
* **Produtividade:** Instalação de 1Password, Brave Browser, ZapZap (Cliente WhatsApp).
* **Ferramentas:** Rclone, Pipewire (Áudio), Grim/Slurp (Screenshots), Brightnessctl.
* **Desenvolvimento:** Python, Docker, Go, **Rustup** (toolchain manager), VS Code (open-source bin).
* **Launcher:** Configuração do `ulauncher` (estilo Pop!\_OS/Spotlight) com atalho **`Super + Espaço`**.
* **Configuração Inicial:** Cria um arquivo `~/.config/hypr/hyprland.conf` funcional com layout ABNT.

## 📋 Pré-requisitos

1.  Uma instalação limpa do **Arch Linux**.
2.  Um usuário não-root configurado com privilégios `sudo`.
3.  Conexão ativa com a internet.

## 💻 Guia de Pós-Instalação Rápida

O fluxo recomendado é instalar a base com o `archinstall --minimal` e, em seguida, executar este script como seu usuário normal.

### 1. Clonar e Executar

Após o primeiro boot na instalação limpa, execute os comandos abaixo no terminal (o `wget` é geralmente incluído no `archinstall --minimal`, mas o `curl` também pode ser usado):

**Usando `curl`:**

```bash
# 1. Baixa o script para o diretório atual
curl -O [https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/setup.sh](https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/setup.sh)

# 2. Concede permissão de execução
chmod +x setup.sh

# 3. Executa o script (será solicitada a senha do sudo)
./setup.sh