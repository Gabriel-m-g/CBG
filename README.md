# CBG (Chromebook but Good)

Uma distro experimental no estilo ChromeOS, mas aberta e auditável. Usa o Chromium como centro do sistema, PWAs como apps, e serviços do Google só quando necessário.

> **Status: experimental.** Muita coisa ainda não foi testada.

## Aviso importante: senha padrão

A imagem vem com um usuário de teste:

- usuário: `samuel`
- senha: `troque-isto`

**Troque a senha no primeiro uso**, abrindo um terminal e rodando:

```
passwd
```

Não use esta imagem em um computador de verdade sem trocar a senha.

## O que tem

- Base: Fedora Kinoite (KDE Plasma), imutável, via [bootc](https://github.com/bootc-dev/bootc)
- Chromium no lugar do Firefox, com Wayland nativo
- Chromium em modo app como visualizador padrão de PDF, imagem e vídeo
- ffmpeg completo (RPM Fusion) para H.264 e AAC
- rclone para montar o Google Drive como pasta
- Waydroid para apps Android (a testar)
- Flathub já configurado
- Regra do polkit para montar discos sem pedir senha (grupo `wheel`)

## Como obter a imagem

O GitHub Actions constrói a imagem a cada mudança e faz duas coisas:

1. Publica a imagem no registry do GitHub (`ghcr.io`).
2. Gera um disco `qcow2` para teste, disponível em *Actions*, na aba *Artifacts* da última execução.

### Testar o disco no QEMU

```
qemu-system-x86_64 -drive format=qcow2,file=disk.qcow2 -m 8G -smp 2 -enable-kvm -bios /usr/share/edk2/ovmf/OVMF_CODE.fd -display gtk,gl=on -device virtio-vga-gl -usb -device usb-tablet
```

O caminho do OVMF pode variar na sua distro.

### Instalar em um Fedora Atomic já instalado

```
sudo bootc switch ghcr.io/<seu-usuario>/cbg:latest
```

## Construir localmente

```
podman build -t localhost/cbg:latest -f Containerfile .
```

## A testar

- [ ] Waydroid funcionando (depende do módulo binder no kernel)
- [ ] H.264 e AAC tocando no Chromium
- [ ] Flags do Chromium lidas de `/etc/chromium/chromium.conf`
- [ ] Sync do Google no Chromium
- [ ] Serviço do Drive via rclone

## Ideias futuras

- Assistente guiado de primeiro uso (conta Google, Drive, Calendar)
- Menu de configurações simples
- Variante mínima com Sway ou labwc
- Perfil "prova", com sessão restrita e rede limitada

## Licença

Veja o arquivo `LICENSE`.
