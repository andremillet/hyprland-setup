# 🚀 Arch Hyprland Automated Installer (v9)

Este repositório contém os ficheiros de configuração para instalar e configurar automaticamente um ambiente de desenvolvimento robusto no Arch Linux, utilizando o **Hyprland** (um moderno *tiling window manager* Wayland), com otimizações para **NVIDIA** e um fluxo de instalação **totalmente automatizado** via `archinstall`.

O seu "installer" pessoal consiste em três ficheiros que trabalham juntos para criar um ambiente *zero-touch* (sem intervenção humana durante a instalação e primeiro login).

## ✨ Funcionalidades do Ambiente

* **Ambiente:** Hyprland, Waybar, Alacritty (Terminal), Thunar (Gerenciador de Arquivos).
* **Drivers:** Instalação robusta de `nvidia-dkms`, `nvidia-settings`, com detecção automática do hardware e configuração do bootloader (GRUB ou systemd-boot).
* **Produtividade:** 1Password, Brave Browser, ZapZap (Cliente WhatsApp), Rclone.
* **Ferramentas:** Pipewire (Áudio), Grim/Slurp (Screenshots), Brightnessctl.
* **Desenvolvimento:** Python, Docker, Go, **Rustup** (toolchain manager), VS Code.
* **Launcher:** Configuração do `ulauncher` (estilo Pop!\_OS/Spotlight) com atalho **`Super + Espaço`**.
* **Localização:** Teclado **ABNT** e idioma do sistema **Inglês (`en_US.UTF-8`)**.

---

## ⚙️ Arquitetura do Instalador

Este processo usa três ficheiros:
1.  **`install.json`:** O ficheiro de configuração do `archinstall`. Define o particionamento, o `timezone` (`America/Sao_Paulo`) e os pacotes base.
2.  **`post_install_wrapper.sh`:** Executado pelo `archinstall` (como `root`). Prepara o ambiente, configura acesso `sudo NOPASSWD` temporário e "arma" o `setup.sh` para ser executado no primeiro login.
3.  **`setup.sh` (v9):** O script principal, agora **NÃO INTERATIVO**. Instala o Hyprland, as aplicações, e remove o acesso `sudo NOPASSWD` no final.

## 🚀 Guia de Instalação (Zero-Touch)

O processo de instalação é resumido a apenas três comandos no ambiente "live" do Arch.

### 1. Preparação (No Live USB)

1.  Arranque o computador com o **Arch Linux Live USB**.
2.  Conecte-se à internet (usando `iwctl` ou `dhcpcd`).
3.  Baixe o ficheiro de configuração `install.json`:

```bash
# Baixa o ficheiro JSON
curl -O [https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/install.json](https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/install.json)