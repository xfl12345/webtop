FROM linuxserver/webtop:alpine-kde
COPY --from=ubuntu-quick --chown=root:root --chmod=644 /moved_root/etc/profile.d/* /etc/profile.d/
RUN cp -rvp /etc/apk/repositories /etc/apk/repositories.curtin
RUN sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
RUN apk add bash bash-doc bash-completion bash-completion-doc busybox-suid coreutils mandoc man-pages screen shadow sudo tini tzdata util-linux
RUN apk add fcitx5 fcitx5-chinese-addons fcitx5-configtool fcitx5-gtk fcitx5-qt
RUN apk add firefox-esr
RUN apk add kquickcharts kinfocenter
SHELL ["/usr/bin/bash", "-c"]
