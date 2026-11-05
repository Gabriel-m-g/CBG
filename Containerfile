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
# 4. Visualizador padrao: Chromium em modo app, sem abas
# ---------------------------------------------------------------
RUN echo '[Desktop Entry]' > /usr/share/applications/cbg-viewer.desktop && \
    echo 'Type=Application\nName=Visualizador CBG\nExec=chromium --app=%u\nIcon=chromium\nNoDisplay=true' >> /usr/share/applications/cbg-viewer.desktop

RUN echo '[Default Applications]' > /etc/xdg/mimeapps.list && \
    echo 'application/pdf=cbg-viewer.desktop\nx-scheme-handler/http=chromium.desktop\nx-scheme-handler/https=chromium.desktop' >> /etc/xdg/mimeapps.list && \
    cp /etc/xdg/mimeapps.list /etc/xdg/kde-mimeapps.list

# ---------------------------------------------------------------
# 5. Atalho do Google Calendar (para fixar no painel)
# ---------------------------------------------------------------
RUN cat > /usr/share/applications/cbg-calendar.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Abrir calendario
Exec=chromium-browser --app=https://calendar.google.com
Icon=office-calendar
Categories=Office;Calendar;
EOF

# ---------------------------------------------------------------
# 6. Google Drive no Dolphin via rclone (servico de usuario)
#    Antes de ativar: rodar "rclone config" e criar o remote "gdrive"
#    (use seu proprio client ID do Google).
#    Ativar com: systemctl --user enable --now rclone-gdrive.service
# ---------------------------------------------------------------
RUN cat > /usr/lib/systemd/user/rclone-gdrive.service <<'EOF'
[Unit]
Description=Google Drive (rclone mount)
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStartPre=/usr/bin/mkdir -p %h/Drive
ExecStart=/usr/bin/rclone mount gdrive: %h/Drive --vfs-cache-mode full
ExecStop=/usr/bin/fusermount3 -u %h/Drive
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# ---------------------------------------------------------------
# 7. Waydroid (A TESTAR: binder pode nao estar disponivel no kernel)
#    Teste no host: lsmod | grep binder ; ls /dev/binderfs
# ---------------------------------------------------------------
RUN systemctl enable waydroid-container.service || true

# ---------------------------------------------------------------
# 8. Painel do Plasma (painel inferior, sem agrupamento, PWAs fixados)
#    TODO: definir em um layout do Plasma, em etapa posterior.
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 9. Flathub ja configurado (sistema inteiro)
#    VERIFICAR: confirme que o flatpak le /etc/flatpak/remotes.d/ nesta versao
# ---------------------------------------------------------------
RUN mkdir -p /etc/flatpak/remotes.d && \
    curl -fsSL -o /etc/flatpak/remotes.d/flathub.flatpakrepo \
      https://dl.flathub.org/repo/flathub.flatpakrepo

# ---------------------------------------------------------------
# 10. Montar discos sem pedir senha (so para o grupo wheel, sessao local e ativa)
# ---------------------------------------------------------------
RUN mkdir -p /etc/polkit-1/rules.d && cat > /etc/polkit-1/rules.d/50-cbg-udisks.rules <<'EOF'
polkit.addRule(function(action, subject) {
  var ids = [
    "org.freedesktop.udisks2.filesystem-mount",
    "org.freedesktop.udisks2.filesystem-mount-system",
    "org.freedesktop.udisks2.filesystem-unmount-others"
  ];
  if (ids.indexOf(action.id) >= 0 &&
      subject.isInGroup("wheel") && subject.local && subject.active) {
    return polkit.Result.YES;
  }
});
EOF

# Usuario temporario para testar na VM (trocar a senha depois)
RUN useradd -m -G wheel samuel && echo 'samuel:troque-isto' | chpasswd

RUN bootc container lint
