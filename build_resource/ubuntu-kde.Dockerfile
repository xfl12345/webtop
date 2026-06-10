FROM linuxserver/webtop:ubuntu-kde AS origin

FROM alpine:latest AS apt-builder
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
RUN apk add bash gettext wget gpg curl
SHELL ["/bin/bash", "-c"]
USER root
COPY moved_root/etc/apt/sources.list.d/*.sources.template /tmp/docker/build/apt/
COPY moved_root/etc/apt/sources.list.d/*.sources /tmp/docker/build/apt/
COPY --from=origin /etc/lsb-release /tmp/lab/etc/lsb-release
RUN <<EOF
    set -a
    source /tmp/lab/etc/lsb-release
    set +a
    export DPKG_ARCH_IS_AMD64="$([ "$(arch)" = "x86_64" ] && echo yes || echo no)"
    export DPKG_ARCH_IS_OTHERS="$([ "$(arch)" = "x86_64" ] && echo no || echo yes)"
    export
    for i in $(find /tmp/docker/build/apt -name "*.template"); do
        echo "Processing ${i} ...";
        envsubst < "$i" > $(echo "$i" | sed 's/\.template$//')
    done
EOF
# RUN mkdir -p /usr/share/keyrings
# RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
# RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
# RUN wget -qO- https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg
# RUN curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /usr/share/keyrings/antigravity-repo-key.gpg
# RUN wget -qO- https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /usr/share/keyrings/antigravity-repo-key.gpg
# RUN wget -qO- https://dbeaver.io/debs/dbeaver.gpg.key | gpg --dearmor -o /usr/share/keyrings/dbeaver-key.gpg
# RUN wget -qO- https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
# RUN wget -qO- https://apt.fury.io/nushell/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/fury-nushell.gpg
# RUN chown root:root /usr/share/keyrings/*.gpg
# RUN chmod 644 /usr/share/keyrings/*.gpg

ARG DEBIAN_FRONTEND=noninteractive
FROM linuxserver/webtop:ubuntu-kde
SHELL ["/usr/bin/bash", "-c"]
COPY --from=ubuntu-quick --chown=root:root --chmod=644 /moved_root/etc/profile.d/* /etc/profile.d/
COPY --from=apt-builder --chown=root:root --chmod=755 /tmp/docker/build/apt/ubuntu.sources /etc/apt/sources.list.d/
RUN echo '# Ubuntu sources have moved to /etc/apt/sources.list.d/ubuntu.sources' > /etc/apt/sources.list
RUN apt update
### 优先更新 apt 基础套件以优化安装性能
RUN apt install -y apt-file apt-utils apt-transport-https git curl wget openssl
### 优先修正 LINUX 字体问题
RUN apt install -y fonts-noto-mono fonts-noto-extra fonts-noto-cjk-extra fonts-unifont
### 安装 LINUX 常用基础套件
RUN apt install -y ubuntu-standard util-linux-extra file tar zip unzip p7zip-full xz-utils bc parallel pipx jq yq
### 安装 LINUX 常用离线运维套件
RUN apt install -y sudo safe-rm tree screen tmux kmod procps htop locales pigz xfsprogs btrfs-progs e2fsprogs qrencode opendoas
### 安装 LINUX 常用网络运维套件
RUN apt install -y iptables iproute2 nftables libcap2-bin netcat-openbsd resolvconf net-tools bind9-dnsutils wireguard-tools mtr openssh-server
### 安装 LINUX 常用开发包
RUN apt install -y build-essential 
### 安装 LINUX 杂项
RUN apt install -y language-pack-zh-hans libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev
### 补全 KDE 一些依赖
RUN apt install -y kde-config-flatpak kinfocenter plasma-discover
# RUN printf 'GTK_IM_MODULE=ibus\nexport QT_IM_MODULE=ibus\nexport XMODIFIERS=@im=ibus\n' >> /etc/environment
# RUN apt install -y ibus-libpinyin
# RUN mkdir -p /config/.config/ibus && printf "[General]\nDefaultEngine=libpinyin\nEnable=1\n" > /config/.config/ibus/bus.ini
# ENV QT_IM_MODULE=fcitx  QT_QPA_PLATFORM=xcb  XMODIFIERS="@im=fcitx"  GTK_IM_MODULE=fcitx  SDL_IM_MODULE=fcitx
### https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland#KDE_Plasma
ENV XMODIFIERS="@im=fcitx"
RUN apt install -y fcitx5 fcitx5-chinese-addons kde-config-fcitx5
### 安装截图工具
RUN apt install -y grim slurp
### 安装 JetBrains ToolBox 依赖
RUN apt install -y mesa-utils libgtk-3-bin dbus-user-session
### 安装 fastfetch
RUN add-apt-repository -y ppa:zhangsongcui3371/fastfetch
RUN apt install -y fastfetch
### 安装 flatpak
RUN apt install -y flatpak
RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
RUN flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub
# RUN flatpak install --noninteractive --assumeyes flathub com.rustdesk.RustDesk
# RUN flatpak install --noninteractive --assumeyes flathub com.vscodium.codium
# RUN flatpak install --noninteractive --assumeyes flathub io.dbeaver.DBeaverCommunity
RUN apt install -y ffmpeg
RUN apt install -y chromium-browser chromium-chromedriver chromium-codecs-ffmpeg-extra
### 安装 PPA 源里的 chromium 衍生软件
RUN apt install -y chromium-shell chromium-headless-shell chromium-sandbox
### 安装 PPA 源里的 firefox
RUN apt update
RUN apt install -y firefox firefox-locale-zh* firefox-locale-en
### 安装 vscode
COPY --from=apt-builder --chown=root:root --chmod=755 /tmp/docker/build/apt/*.sources  /etc/apt/sources.list.d/
COPY --chown=root:root --chmod=755 moved_root/usr/share/keyrings/*.gpg  /usr/share/keyrings/
RUN echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
RUN apt update 
### 安装 Nushell
RUN apt install -y nushell
### 安装微软的 vscode
RUN apt install -y code
### 安装完全开放自由的 vscode
RUN apt install -y codium
### 安装开源免费的数据库管理工具 dbeaver
RUN apt install -y dbeaver-ce
### 安装 Google 的 AI IDE antigravity
RUN apt install -y antigravity
RUN apt install -y brave-browser
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then apt install -y google-chrome-stable; else echo "Skipping chrome for $(dpkg --print-architecture)"; fi
