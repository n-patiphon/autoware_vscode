# hadolint global ignore=DL3006
ARG BASE_IMAGE
FROM $BASE_IMAGE

# Default ccache max size
ARG CCACHE_MAXSIZE="30G"

# Metadata - should come early after FROM
LABEL maintainer="The Autoware Foundation" \
      description="Autoware development container with enhanced tooling" \
      version="0.1" \
      org.opencontainers.image.source="https://github.com/autowarefoundation/autoware" \
      org.opencontainers.image.vendor="The Autoware Foundation"

# Global environment variables that don't change
ENV SHELL=/bin/bash

# Development and runtime environment variables
ENV CYCLONEDDS_URI=file:///workspace/.devcontainer/cyclonedds_config.xml \
    PYTHONPATH=/home/autoware/.local/bin \
    RCUTILS_COLORIZED_OUTPUT=1 \
    RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity} {time}] [{name}]: {message} ({function_name}() at {file_name}:{line_number})" \
    CCACHE_DIR=/ccache \
    CC=/usr/lib/ccache/gcc \
    CXX=/usr/lib/ccache/g++ \
    CCACHE_MAXSIZE=${CCACHE_MAXSIZE}

# Git prompt customization
ENV GIT_PS1_SHOWDIRTYSTATE=1 \
    GIT_PS1_SHOWSTASHSTATE=1 \
    GIT_PS1_SHOWUNTRACKEDFILES=1 \
    GIT_PS1_SHOWUPSTREAM=verbose \
    GIT_PS1_DESCRIBE_STYLE=contains \
    GIT_PS1_SHOWCOLORHINTS=1 \
    PROMPT_COMMAND="__git_ps1 '"'${VIRTUAL_ENV:+($(basename "$VIRTUAL_ENV")) }'"\[\033[01;33m\](container) \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]' '$ '"

RUN echo 'if [ -f "/workspace/install/setup.bash" ]; then' >> /etc/skel/.bashrc \
  && echo '  source "/workspace/install/setup.bash"' >> /etc/skel/.bashrc \
  && echo 'fi' >> /etc/skel/.bashrc

# Update ROS key and repository configuration, then install packages via apt
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros2-latest-archive-keyring.gpg \
  && apt update \
  && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  bash-completion \
  ccache \
  clang \
  curl \
  gdb \
  gdbserver \
  gh \
  htop \
  jq \
  kcachegrind \
  nvidia-cuda-gdb \
  python3-platformdirs \
  python3-tomli \
  python3-xmlschema \
  sudo \
  unzip \
  valgrind \
  vim \
  && apt autoremove -y && apt clean -y && rm -rf /var/lib/apt/lists/* "$HOME"/.cache

# Install packages via pip
RUN python3 -m pip install --no-cache-dir --root / \
  check-jsonschema \
  pydot \
  transforms3d==0.4.2

# Install CSpell
RUN curl -sL https://deb.nodesource.com/setup_22.x -o /tmp/nodesource_setup.sh \
  && bash /tmp/nodesource_setup.sh \
  && DEBIAN_FRONTEND=noninteractive apt install nodejs -y \
  && npm install -g cspell \
  && npm install -g yarn \
  && rm -rf /tmp/nodesource_setup.sh \
  && apt autoremove -y && apt clean -y && rm -rf /var/lib/apt/lists/* "$HOME"/.cache

# Install lichtblick
RUN LICHTBLICK_VERSION=$(curl -fsSL "https://api.github.com/repos/lichtblick-suite/lichtblick/releases/latest" | jq -r '.tag_name' | sed 's/^v//') \
  && echo "Installing Lichtblick version: $LICHTBLICK_VERSION" \
  && apt update \
  && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  libappindicator3-1 \
  libnotify4 \
  ros-$ROS_DISTRO-foxglove-bridge \
  xdg-utils \
  && wget -O /tmp/lichtblick-linux-amd64.deb "https://github.com/lichtblick-suite/lichtblick/releases/download/v${LICHTBLICK_VERSION}/lichtblick-${LICHTBLICK_VERSION}-linux-amd64.deb" \
  && dpkg -i /tmp/lichtblick-linux-amd64.deb \
  && rm -rf /tmp/lichtblick-linux-amd64.deb \
  && ln -s /workspace/.devcontainer/foxglove /usr/local/bin/foxglove \
  && apt autoremove -y && apt clean -y && rm -rf /var/lib/apt/lists/* "$HOME"/.cache

# Install clangd
RUN CLANGD_VERSION=$(curl -fsSL "https://api.github.com/repos/clangd/clangd/releases/latest" | jq -r '.tag_name') \
  && echo "Installing clangd version: $CLANGD_VERSION" \
  && apt update \
  && wget -O /tmp/clangd-linux.zip "https://github.com/clangd/clangd/releases/download/${CLANGD_VERSION}/clangd-linux-${CLANGD_VERSION}.zip" \
  && unzip /tmp/clangd-linux.zip -d /opt/ \
  && ln -s "/opt/clangd_${CLANGD_VERSION}/bin/clangd" /usr/local/bin/clangd \
  && rm -rf /tmp/clangd-linux.zip \
  && apt autoremove -y && apt clean -y && rm -rf /var/lib/apt/lists/* "$HOME"/.cache

# Add user
ARG USERNAME=autoware
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ENV XDG_RUNTIME_DIR=/tmp/xdg/$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && mkdir /home/$USERNAME/.config \
  && mkdir -p /ccache \
  && chown -R $USERNAME:$USERNAME /home/$USERNAME/.config \
  && chown -R $USERNAME:$USERNAME /ccache \
  && mkdir -p $XDG_RUNTIME_DIR \
  && chmod 700 "$XDG_RUNTIME_DIR" \
  && chown -R $USERNAME:$USERNAME "$XDG_RUNTIME_DIR"

# Install missing dependencies of current workspace
COPY src/ /tmp/src
RUN set +e \
  && echo "Attempting to install workspace dependencies..." \
  && apt update \
  && rosdep update \
  && rosdep install --from-paths /tmp/src --ignore-src --rosdistro $ROS_DISTRO -yr \
  && echo "Dependencies installation completed" \
  || echo "Info: Dependency installation can be skipped if no internet connection. This layer is not critical for container rebuild." \
  && set -e \
  && apt autoremove -y && apt clean -y && rm -rf /var/lib/apt/lists/* "$HOME"/.cache \
  && rm -rf /tmp/src

# Final user and workspace setup
USER $USERNAME
WORKDIR /workspace

# Setup ccache configuration
RUN ccache --max-size="${CCACHE_MAXSIZE}" \
  && echo 'export PATH="/usr/lib/ccache:$PATH"' >> /home/$USERNAME/.bashrc

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD echo "Container is healthy"
