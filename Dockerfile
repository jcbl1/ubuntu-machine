# 基础镜像可通过 build-arg 覆盖，发版时会固定到 ubuntu 快照 tag，例如 ubuntu:noble-20261024.1
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ENV container container

# CVE-2026-109518: APT's resumed HTTP downloads could install a tampered package.
# Patch APT first with retries disabled, then fail the build if the installed
# version is still below the fixed version for this Ubuntu release.
RUN set -eux; \
    apt-get update; \
    apt-get -o Acquire::Retries=0 install -y --only-upgrade '?source-package(^apt$)'; \
    . /etc/os-release; \
    case "$VERSION_CODENAME" in \
      focal)    apt_fixed=2.0.12+esm1 ;; \
      jammy)    apt_fixed=2.4.15ubuntu0.1 ;; \
      noble)    apt_fixed=2.8.4ubuntu0.1 ;; \
      resolute) apt_fixed=3.2.1ubuntu0.1 ;; \
      stonking) apt_fixed=3.3.3ubuntu0.1 ;; \
      *) echo "ERROR: no CVE-2026-109518 baseline for $VERSION_CODENAME" >&2; exit 1 ;; \
    esac; \
    apt_version="$(dpkg-query -W -f='${Version}' apt)"; \
    if ! dpkg --compare-versions "$apt_version" ge "$apt_fixed"; then \
      echo "ERROR: apt $apt_version is vulnerable to CVE-2026-109518 (need >= $apt_fixed)" >&2; \
      exit 1; \
    fi; \
    apt-get install -y \
    dbus systemd net-tools iproute2 iputils-ping curl wget vim-tiny man sudo \
    lsb-release libpam-systemd ncurses-term xauth ca-certificates && \
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
    done; \
    find /etc/apt -maxdepth 2 \
      \( -name sources.list -o -name '*.list' -o -name '*.sources' \) \
      -exec sed -Ei 's!http://((([a-z]+\.)?archive|security|ports)\.ubuntu\.com)!https://\1!' {} +; \
    apt-get -o Acquire::Retries=0 update; \
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
