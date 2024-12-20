FROM fedora:latest

LABEL name="AlexStorm1313/codium" \
    vendor="AlexStorm1313" \
    version="0.0.1" \
    release="1" \
    summary="Cloud native Codium" \
    description="Cloud native variant of Codium IDE accessible through a browser"

# Enable RPMFusion & copr & flatpak
RUN dnf -y update && \ 
    dnf -y install dnf-plugins-core https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    # dnf -y update && \
    dnf -y copr enable atim/starship && \
    dnf -y install \
    flatpak \
    starship \
    git \
    gcc \
    clang \
    clang-libs \
    podman \
    bash-completion \
    helm \
    ImageMagick \
    ImageMagick-devel \
    ffmpeg-free \
    ffmpeg-free-devel \
    libavutil-free \
    openssl \
    openssl-devel \
    iputils \
    mariadb \
    mariadb-devel \
    libpq \
    libpq-devel \
    unzip \
    nodejs \
    java-latest-openjdk.x86_64 \
    java-latest-openjdk-devel.x86_64 \
    neovim \
    python3-neovim \
    ripgrep \
    fira-code-fonts \
    @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin && \
    dnf -y swap ffmpeg-free ffmpeg --allowerasing && \
    dnf -y clean all

# Systemwide a.k.a. root user
ARG HOME_DIR=/root
# Set ENV variables
ENV PATH=${HOME_DIR}/.cargo/bin:${HOME_DIR}/.bun/bin:${HOME_DIR}/.local/bin:${PATH}

WORKDIR ${HOME_DIR}

# Specify openvscode-server release, SHOULD MOVE THIS DOWN AFTER INSTALLING TOOLING
ARG OPENVSCODE_SERVER_RELEASE_VERSION=1.95.2
ARG OPENVSCODE_SERVER_RELEASE_TAG=openvscode-server-v${OPENVSCODE_SERVER_RELEASE_VERSION}
ARG OPENVSCODE_SERVER_RELEASE_ORG=gitpod-io
ARG OPENVSCODE_SERVER_INSTALL_DIR=${HOME_DIR}/.openvscode-server
ARG OPENVSCODE_SERVER=${OPENVSCODE_SERVER_INSTALL_DIR}/bin/openvscode-server

# Install openvscode-server
RUN if [ -z "${OPENVSCODE_SERVER_RELEASE_TAG}" ]; then \
    echo "The RELEASE_TAG build arg must be set." >&2 && \
    exit 1; \
    fi && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
    arch="x64"; \
    elif [ "${arch}" = "aarch64" ]; then \
    arch="arm64"; \
    elif [ "${arch}" = "armv7l" ]; then \
    arch="armhf"; \
    fi && \
    curl -LO https://github.com/${OPENVSCODE_SERVER_RELEASE_ORG}/openvscode-server/releases/download/${OPENVSCODE_SERVER_RELEASE_TAG}/${OPENVSCODE_SERVER_RELEASE_TAG}-linux-${arch}.tar.gz && \
    tar -xzf ${OPENVSCODE_SERVER_RELEASE_TAG}-linux-${arch}.tar.gz && \
    mv -f ${OPENVSCODE_SERVER_RELEASE_TAG}-linux-${arch} ${OPENVSCODE_SERVER_INSTALL_DIR} && \
    cp ${OPENVSCODE_SERVER_INSTALL_DIR}/bin/remote-cli/openvscode-server ${OPENVSCODE_SERVER_INSTALL_DIR}/bin/remote-cli/code && \
    rm -f ${OPENVSCODE_SERVER_RELEASE_TAG}-linux-${arch}.tar.gz

# Install extensions systemwide
RUN ${OPENVSCODE_SERVER} --force \
    --install-extension WakaTime.vscode-wakatime \
    --install-extension rust-lang.rust-analyzer \
    --install-extension bradlc.vscode-tailwindcss \
    --install-extension tamasfe.even-better-toml \
    --install-extension redhat.vscode-yaml \ 
    --install-extension serayuzgur.crates \
    --install-extension rjmacarthy.twinny \
    --install-extension ms-toolsai.jupyter \
    --install-extension ms-azuretools.vscode-docker \
    --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

# Install Rust and Cargo tools
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    cargo install cargo-watch && \
    cargo install diesel_cli --no-default-features --features "postgres mysql"

# Install Bun
RUN curl -fsSL https://bun.sh/install | sh

# Specify okd release
ARG OKD_RELEASE_VERSION=4.13.0-0.okd-2023-06-04-080300
RUN curl -LO https://github.com/okd-project/okd/releases/download/${OKD_RELEASE_VERSION}/openshift-client-linux-${OKD_RELEASE_VERSION}.tar.gz && \
    tar -xzf openshift-client-linux-${OKD_RELEASE_VERSION}.tar.gz -C /usr/bin && \
    rm -rf openshift-client-linux-${OKD_RELEASE_VERSION}.tar.gz && \
    chmod +x /usr/bin/oc

# Completions
RUN oc completion bash >> /etc/bash_completion.d/oc.bash_completion && \
    helm completion bash >> /etc/bash_completion.d/helm.bash_completion && \
    diesel completions bash >> /etc/bash_completion.d/diesel.bash_completion && \
    rustup completions bash rustup >> /etc/bash_completion.d/rustup.bash_completion && \
    rustup completions bash cargo >> /etc/bash_completion.d/cargo.bash_completion

# User and permissions, a.k.a. userspace
ARG USER=codium
ARG UID=1001
ARG GID=0
ARG HOME_DIR=/home/${USER}

# Add the user
RUN groupadd ${USER} && \
    useradd -g ${USER} ${USER}

# Make directories
RUN mkdir -p ${HOME_DIR}/.openvscode-server/data && \
    mkdir -p ${HOME_DIR}/.openvscode-server/data/CachedProfilesData && \
    mkdir -p ${HOME_DIR}/.openvscode-server/data/Machine && \
    mkdir -p ${HOME_DIR}/.openvscode-server/data/User && \
    mkdir -p ${HOME_DIR}/.openvscode-server/data/logs && \
    mkdir -p ${HOME_DIR}/.openvscode-server/extensions && \
    mkdir -p ${HOME_DIR}/workspace

WORKDIR ${HOME_DIR}

# Set ENV variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV HOME=${HOME_DIR}
ENV SHELL=/bin/bash
ENV PATH=${HOME_DIR}/.cargo/bin:${HOME_DIR}/.bun/bin:${HOME_DIR}/.local/bin:${PATH}
ENV EDITOR=code
ENV VISUAL=code
ENV GIT_EDITOR="code --wait"
ENV OPENVSCODE_SERVER=${OPENVSCODE_SERVER_INSTALL_DIR}/bin/openvscode-server

# NvChad
RUN git clone https://github.com/NvChad/starter ${HOME_DIR}/.config/nvim

# Configure and install tooling
RUN echo 'eval "$(starship init bash)"' >> ${HOME_DIR}/.bashrc && \
    echo 'source /etc/profile.d/bash_completion.sh' >> ${HOME_DIR}/.bash_profile && \
    echo 'eval "$(ssh-agent -s)"' >> ${HOME_DIR}/.bash_profile && \
    echo 'eval "$(ssh-add ${HOME}/.ssh/privatekey)"' >> ${HOME_DIR}/.bash_profile && \
    rustup default stable

# Changing ownership and user rights to support following use-cases:
# 1) running container on OpenShift, whose default security model
#    is to run the container under random UID, but GID=0
# 2) for working root-less container with UID=1001, which does not have
#    to have GID=0
# 3) for default use-case, that is running container directly on operating system,
#    with default UID and GID (1001:0)
# Supported combinations of UID:GID are thus following:
# UID=1001 && GID=0
# UID=<any>&& GID=0
# UID=1001 && GID=<any>
RUN chown -R ${UID}:${GID} ${HOME_DIR} && \
    chmod -R g=u ${HOME_DIR}

# Set fixed non-root user for compatibility with Podman/Docker and Kubernetes
USER ${UID}

# Start openvscode-server
ENV PORT=3000
ENTRYPOINT [ "/bin/sh", "-c", "exec ${OPENVSCODE_SERVER} --host 0.0.0.0 --port ${PORT} --without-connection-token \"${@}\"", "--" ]