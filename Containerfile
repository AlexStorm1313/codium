FROM fedora:latest

LABEL name="AlexStorm1313/codium" \
    vendor="AlexStorm1313" \
    version="0.0.1" \
    release="1" \
    summary="Cloud native Codium" \
    description="Cloud native variant of Codium IDE accessible through a browser"

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
    dnf -y install \
        dnf-plugins-core \
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
        cargo \
        codium \
        fira-code-fonts \
        git \
        oci-cli \
        opentofu \
        podman \
        procps \
        rust \
        starship \
        terraform-ls \
        tini && \
    # Cleanup
    dnf -y clean all && \
    rm -rf /var/cache/dnf

# User and permissions, a.k.a. userspace
ARG USER=codium
ARG UID=1001
ARG GID=0
ARG HOME=/home/${USER}

# Add the user
RUN groupadd ${USER} && \
    useradd ${USER} -g ${UID} -d ${HOME} -m

# Install extensions systemwide
RUN codium --user-data-dir ${HOME}/.vscodium-server/data --extensions-dir ${HOME}/.vscodium-server/extensions --force \
    --install-extension WakaTime.vscode-wakatime
    # --install-extension rust-lang.rust-analyzer \
    # --install-extension bradlc.vscode-tailwindcss \
    # --install-extension tamasfe.even-better-toml \
    # --install-extension redhat.vscode-yaml \ 
    # --install-extension serayuzgur.crates \
    # --install-extension Continue.continue \
    # --install-extension ms-toolsai.jupyter \
    # --install-extension ms-azuretools.vscode-docker \
    # --install-extension ms-kubernetes-tools.vscode-kubernetes-tools \
    # --install-extension usernamehw.errorlens \
    # --install-extension dannysteenman.aws-cloudformation-extension-pack

# # Install Rust and Cargo tools
# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
#     cargo install cargo-watch && \
#     cargo install diesel_cli --no-default-features --features "postgres mysql" && \
#     cargo install cargo-lambda

# # Install Bun
# RUN curl -fsSL https://bun.sh/install | sh

# # Install CloudFormation linter
# RUN pip3 install cfn-lint[full]

# # Specify okd release
# ARG OKD_RELEASE_VERSION=4.13.0-0.okd-2023-06-04-080300
# RUN curl -LO https://github.com/okd-project/okd/releases/download/${OKD_RELEASE_VERSION}/openshift-client-linux-${OKD_RELEASE_VERSION}.tar.gz && \
#     tar -xzf openshift-client-linux-${OKD_RELEASE_VERSION}.tar.gz -C /usr/bin && \
#     rm -rf openshift-client-linux-${OKD_RELEASE_VERSION}.tar.gz && \
#     chmod +x /usr/bin/oc



# Set ENV variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV HOME=${HOME}
ENV SHELL=/bin/bash
ENV EDITOR=codium
ENV VISUAL=codium
ENV GIT_EDITOR="codium --wait"

# # Completions
# RUN oc completion bash >> /etc/bash_completion.d/oc.bash_completion && \
#     helm completion bash >> /etc/bash_completion.d/helm.bash_completion && \
#     diesel completions bash >> /etc/bash_completion.d/diesel.bash_completion && \
#     rustup completions bash rustup >> /etc/bash_completion.d/rustup.bash_completion && \
#     rustup completions bash cargo >> /etc/bash_completion.d/cargo.bash_completion

# Configure and install tooling
RUN echo 'eval "$(starship init bash)"' >> ${HOME}/.bashrc && \
    echo 'source /etc/profile.d/bash_completion.sh' >> ${HOME}/.bash_profile && \
    echo 'complete -C "aws_completer" aws' >> ${HOME}/.bashrc

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