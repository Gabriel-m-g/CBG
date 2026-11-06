# CBG (Chromebook but Good), primeira versao
# Base: Fedora Kinoite (bootc). Confira a versao estavel atual do Fedora antes de construir.
ARG FEDORA_VERSION=44
FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_VERSION}

# ---------------------------------------------------------------
# 1. Repositorio RPM Fusion (para o ffmpeg completo)
# ---------------------------------------------------------------
RUN dnf5 install -y \
      https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# ---------------------------------------------------------------
# 2. Trocar Firefox por Chromium e instalar o restante
# ---------------------------------------------------------------
RUN dnf5 remove -y firefox firefox-langpacks || true
RUN dnf5 install -y \
      chromium \
      plasma-browser-integration \
      fuse3 \
      rclone \
      waydroid
# ffmpeg completo (RPM Fusion) conflita com o ffmpeg-free; --allowerasing resolve
RUN dnf5 install -y --allowerasing ffmpeg
RUN dnf5 clean all

# ---------------------------------------------------------------
# 3. Flags do Chromium (Wayland nativo)
#    VERIFICAR: confirme que o chromium do Fedora le /etc/chromium/chromium.conf
# ---------------------------------------------------------------
RUN mkdir -p /etc/chromium && \
    echo 'CHROMIUM_FLAGS="--ozone-platform-hint=auto"' > /etc/chromium/chromium.conf

# ---------------------------------------------------------------
# 4. Visualizador padrao e atalho do Google Calendar
# ---------------------------------------------------------------
COPY files/cbg-viewer.desktop files/cbg-calendar.desktop /usr/share/applications/
COPY files/mimeapps.list /etc/xdg/mimeapps.list
COPY files/mimeapps.list /etc/xdg/kde-mimeapps.list

# ---------------------------------------------------------------
# 5. Google Drive no Dolphin via rclone (servico de usuario)
#    Antes de ativar: rodar "rclone config" e criar o remote "gdrive"
#    (use seu proprio client ID do Google).
#    Ativar com: systemctl --user enable --now rclone-gdrive.service
# ---------------------------------------------------------------
COPY files/rclone-gdrive.service /usr/lib/systemd/user/rclone-gdrive.service

# ---------------------------------------------------------------
# 6. Waydroid (A TESTAR: binder pode nao estar disponivel no kernel)
#    Teste no host: lsmod | grep binder ; ls /dev/binderfs
# ---------------------------------------------------------------
RUN systemctl enable waydroid-container.service || true

# ---------------------------------------------------------------
# 7. Painel do Plasma (TODO: definir em um layout do Plasma)
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 8. Flathub ja configurado (sistema inteiro)
#    VERIFICAR: confirme que o flatpak le /etc/flatpak/remotes.d/ nesta versao
# ---------------------------------------------------------------
RUN mkdir -p /etc/flatpak/remotes.d && \
    curl -fsSL -o /etc/flatpak/remotes.d/flathub.flatpakrepo \
      https://dl.flathub.org/repo/flathub.flatpakrepo

# ---------------------------------------------------------------
# 9. Montar discos sem pedir senha (so para o grupo wheel, sessao local e ativa)
# ---------------------------------------------------------------
COPY files/50-cbg-udisks.rules /etc/polkit-1/rules.d/50-cbg-udisks.rules

# Usuario temporario para testar na VM (trocar a senha depois)
RUN useradd -m -G wheel samuel && echo 'samuel:troque-isto' | chpasswd

RUN bootc container lint
