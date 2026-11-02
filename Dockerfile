# 基础镜像可通过 build-arg 覆盖，发版时会固定到 ubuntu 快照 tag，例如 ubuntu:noble-20261024.1
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ENV container container

RUN apt-get update && \
    apt-get install -y \
    dbus systemd net-tools iproute2 iputils-ping curl wget vim-tiny man sudo \
    lsb-release libpam-systemd ncurses-term xauth && \
    apt-get install -y --no-install-recommends openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    yes | unminimize && \
    for p in ssh-import-id python3-launchpadlib python3-jwt \
             python3-cryptography python3-oauthlib python3-httplib2; do \
      if dpkg -s "$p" >/dev/null 2>&1; then \
        echo "ERROR: vulnerable package must not be installed: $p" >&2; \
        exit 1; \
      fi; \
    done && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN >/etc/machine-id
RUN >/var/lib/dbus/machine-id

RUN systemctl set-default multi-user.target
RUN systemctl mask \
      dev-hugepages.mount \
      sys-fs-fuse-connections.mount \
      systemd-update-utmp.service \
      systemd-tmpfiles-setup.service \
      console-getty.service
RUN systemctl disable \
      networkd-dispatcher.service

RUN sed -i -e 's/^AcceptEnv LANG LC_\*$/#AcceptEnv LANG LC_*/' /etc/ssh/sshd_config

# 移除基础镜像自带的 ubuntu 用户，避免构建期 run-plugins 误选它作为 TARGET_USER
RUN userdel -r ubuntu

# Plugins: scripts in plugins/enabled/ run at build time.
# Enable a plugin with: ln -s ../available/<name> plugins/enabled/<name>
COPY plugins/bin/run-plugins /usr/local/sbin/run-plugins

RUN --mount=type=bind,source=plugins,target=/opt/plugins,readonly \
    /usr/local/sbin/run-plugins /opt/plugins/enabled
