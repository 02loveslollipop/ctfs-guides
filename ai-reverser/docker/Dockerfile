# Ubuntu 24.04 CTF RE/Pwn Toolbox
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG GHIDRA_VERSION=11.4.2
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    GHIDRA_HOME=/opt/ghidra \
    USER=ctf HOME=/home/ctf \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH=/usr/local/bin:$PATH

# --- Base OS & core tools ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    pipx python3-venv \
    ca-certificates curl wget git unzip xz-utils build-essential cmake pkg-config \
    python3 python3-pip openjdk-17-jre-headless \
    file binutils patchelf checksec upx-ucl \
    gdb gdbserver strace ltrace \
    radare2 \
    qemu-user-static \
    ruby-full \
    gnupg \
  && rm -rf /var/lib/apt/lists/*

RUN pipx ensurepath && pipx install ropper

# --- Build rizin from source ---
RUN apt-get update && apt-get install -y meson ninja-build libssl-dev liblz4-dev liblzma-dev libzstd-dev libzip-dev && \
    git clone --depth=1 https://github.com/rizinorg/rizin.git /tmp/rizin && \
    cd /tmp/rizin && \
    meson setup build && \
    meson compile -C build && \
    meson install -C build && \
    cd / && rm -rf /tmp/rizin && \
    apt-get remove -y meson ninja-build && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# --- Ruby gem: one_gadget ---
RUN gem install one_gadget

# --- Python stack (pwntools, angr, etc.) in venv ---
RUN python3 -m venv /opt/ctf-venv && \
    /opt/ctf-venv/bin/pip install --upgrade pip && \
    /opt/ctf-venv/bin/pip install \
      pwntools==4.* \
      angr==9.* \
      capstone unicorn keystone-engine r2pipe \
      z3-solver

ENV PATH="/opt/ctf-venv/bin:$PATH"

# --- Ghidra headless ---
RUN mkdir -p /tmp/gh && \
    curl -fSL -o /tmp/gh/ghidra.zip \
      https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_PUBLIC/ghidra_${GHIDRA_VERSION}_PUBLIC_20250826.zip && \
    unzip -q /tmp/gh/ghidra.zip -d /opt && \
    mv /opt/ghidra_* ${GHIDRA_HOME} && \
    rm -rf /tmp/gh

# --- Non-root user & dirs ---
RUN useradd -m -s /bin/bash ${USER} && \
    mkdir -p /work /opt/tools && \
    chown -R ${USER}:${USER} /work /opt/tools ${GHIDRA_HOME}
USER ${USER}
WORKDIR /work

# --- (Optional) Pwndbg ---
COPY docker/pwndbg-setup.sh /tmp/pwndbg-setup.sh
RUN bash /tmp/pwndbg-setup.sh && rm /tmp/pwndbg-setup.sh || true

# --- Helper scripts ---
COPY tools /opt/tools
RUN chmod +x /opt/tools/*.sh

# --- Entrypoint ---
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
