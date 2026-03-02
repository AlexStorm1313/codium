FROM fedora:latest

ARG USER=codium
ARG UID=1001
ARG GID=0
ARG HOME=/home/${USER}

LABEL name="AlexStorm1313/codium" \
    vendor="AlexStorm1313" \
    version="0.0.1" \
    release="1" \
    summary="Cloud native Codium" \
    description="Cloud native variant of Codium IDE accessible through a browser"

# Set ENV variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV HOME=${HOME}
ENV SHELL=/bin/bash
ENV PATH=${HOME}/.cargo/bin:${HOME}/.bun/bin:${HOME}/.local/bin:${PATH}
ENV SSH_AGENT="${SSH_AGENT:-/tmp/ssh-agent.env}"
ENV EDITOR=codium
ENV VISUAL=codium
ENV GIT_EDITOR="codium --wait"

RUN groupadd -g ${UID} ${USER} && \
    useradd -u ${UID} -g ${UID} -m -s $SHELL ${USER}

RUN curl -fsSL https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm -o session-manager-plugin.rpm && \
    dnf install -y ./session-manager-plugin.rpm && \
    rm -f ./session-manager-plugin.rpm && \
    # Register all repos first
    curl -fsSL https://rpm.releases.hashicorp.com/fedora/hashicorp.repo -o /etc/yum.repos.d/hashicorp.repo && \
    printf '%s\n' \
    '[gitlab.com_paulcarroty_vscodium_repo]' \
    'name=gitlab.com_paulcarroty_vscodium_repo' \
    'baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/' \
    'enabled=1' \
    'gpgcheck=1' \
    'repo_gpgcheck=1' \
    'gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg' \
    'metadata_expire=1h' \
    > /etc/yum.repos.d/vscodium.repo && \
    dnf -y install dnf-plugins-core \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" && \
    # Update with all repos active
    dnf -y update && \
    # Enable COPR (requires dnf-plugins-core)
    dnf -y copr enable atim/starship && \
    # Install all packages
    dnf -y install \
        awk \
        awscli2 \
        azure-cli \
        bash-completion \
        codium \
        fira-code-fonts \
        gcc \
        git \
        hostname \
        libpq-devel \
        oci-cli \
        opentofu \
        podman \
        procps \
        rustup \
        starship \
        terraform-ls \
        tini \
        unzip && \
    # Install Rust and Cargo tools
    rustup-init -y --profile=complete --default-toolchain=nightly && \
    cargo install watchexec-cli && \
    # cargo install beacon && \
    cargo install diesel_cli --no-default-features --features "postgres" && \
    cargo install cargo-lambda && \
    # Install Bun
    curl -fsSL https://bun.sh/install | sh && \
    # Cleanup
    dnf -y clean all && \
    rm -rf /var/cache/dnf && \
    rm -rf ${HOME}/.cargo/registry ${HOME}/.cargo/git

# Install extensions
RUN codium --user-data-dir ${HOME}/.vscodium-server/data --extensions-dir ${HOME}/.vscodium-server/extensions --force \
    --install-extension WakaTime.vscode-wakatime \
    --install-extension rust-lang.rust-analyzer \
    --install-extension bradlc.vscode-tailwindcss \
    --install-extension tamasfe.even-better-toml \
    --install-extension redhat.vscode-yaml \ 
    --install-extension fill-labs.dependi \
    --install-extension Continue.continue \
    --install-extension saoudrizwan.claude-dev \
    --install-extension ms-toolsai.jupyter \
    --install-extension ms-azuretools.vscode-docker \
    --install-extension ms-kubernetes-tools.vscode-kubernetes-tools \
    --install-extension usernamehw.errorlens \
    --install-extension HashiCorp.terraform

# SHELL setup
RUN printf '%s\n' \
        'if [ -f "$SSH_AGENT" ]; then' \
        '    source "$SSH_AGENT"' \
        '    # Verify agent is running' \
        '    if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then' \
        '        ssh-agent -s > "$SSH_AGENT"' \
        '        source "$SSH_AGENT"' \
        '    fi' \
        'else' \
        '    ssh-agent -s > "$SSH_AGENT"' \
        '    source "$SSH_AGENT"' \
        'fi'  >> ${HOME}/.bashrc && \
    printf '%s\n' \
        'for key in "$HOME/.ssh/id_"*; do' \
        '    [ -f "$key" ] || continue' \
        '    if ! ssh-add -l | grep -q "$(ssh-keygen -lf "$key" | awk '\''{print $2}'\'')"; then' \
        '        ssh-add "$key" 2>/dev/null || true' \
        '    fi' \
        'done' >> ${HOME}/.bashrc && \
    echo 'eval "$(starship init bash)"' >> ${HOME}/.bashrc

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
RUN chown -R ${UID}:${GID} ${HOME} && \
    chmod -R g=u ${HOME}

# Set fixed non-root user for compatibility with Podman/Docker and Kubernetes
USER ${UID}
WORKDIR ${HOME}

# Start openvscode-server
ENV PORT=3000
ENTRYPOINT ["tini", "--"]
CMD ["/bin/sh", "-c", "exec codium serve-web --host 0.0.0.0 --port \"${PORT}\" --without-connection-token \"$@\"", "--"]